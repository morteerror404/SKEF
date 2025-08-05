#!/bin/bash

# autorecon.sh
# Função: Controlador principal, gerencia menus, chama testes e organiza resultados para Generate-result.sh
# Dependências: utils.sh, ativo.sh, Generate-result.sh

source ./utils.sh
source ./ativo.sh
# source ./passivo.sh  # Descomentar quando passivo.sh estiver implementado

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
TARGET=""
TARGET_IPv4=""
TARGET_IPv6=""
TYPE_TARGET=""
URL_PROTOCOLO=""
URL_SUB_DOMINIO=""
URL_DOMINIO=""
URL_PATH=""
URL_PORT=""
CHECKLIST=()
START_TIME=$(date +%s)
RESULTS_DIR="results"
CLEAN_RESULTS="yes"  # Opção para ativar/desativar limpeza automática (yes/no)

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
validar_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_status "error" "Este script requer privilégios de root. Execute com sudo."
        exit 1
    fi
    print_status "success" "Executando como root."
}

clean_results() {
    if [ "$CLEAN_RESULTS" = "yes" ]; then
        print_status "info" "Limpando arquivos residuais em $RESULTS_DIR..."
        if [ -d "$RESULTS_DIR" ]; then
            rm -f "$RESULTS_DIR"/* 2>/dev/null
            print_status "success" "Diretório $RESULTS_DIR limpo."
        else
            print_status "info" "Diretório $RESULTS_DIR não existe, criando..."
            mkdir -p "$RESULTS_DIR"
        fi
    else
        print_status "info" "Limpeza de $RESULTS_DIR desativada (CLEAN_RESULTS=$CLEAN_RESULTS)."
    fi
}

verificar_tipo_alvo() {
    local entrada=$(echo "$1" | sed -E 's|^https?://||; s|/.*$||; s|:[0-9]+$||')
    if [[ $entrada =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "IP"
    elif [[ $entrada =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
        echo "IP"
    elif [[ $entrada =~ ^([a-zA-Z0-9][-a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$ ]]; then
        echo "DOMAIN"
    else
        echo "INVÁLIDO"
    fi
}
definir_alvo() {
    print_status "action" "Definindo alvo"
    read -p "Digite o IP, domínio ou URL alvo: " TARGET
    
    # Limpeza inicial da URL
    URL_ORIGINAL="$TARGET"
    URL_PROTOCOLO=""
    URL_SUB_DOMINIO=""
    URL_DOMINIO=""
    URL_PATH=""
    URL_PORT=""
    
    # Extrair protocolo se existir
    if [[ "$TARGET" =~ ^(https?://)([^/:]+) ]]; then
        URL_PROTOCOLO="${BASH_REMATCH[1]%%://*}"  # Extrai apenas 'http' ou 'https'
        TARGET="${TARGET#${BASH_REMATCH[1]}}"
    fi
    
    # Extrair porta se existir
    if [[ "$TARGET" =~ ^([^:]+):([0-9]+) ]]; then
        URL_PORT=":${BASH_REMATCH[2]}"
        TARGET="${BASH_REMATCH[1]}"
    fi
    
    # Extrair path se existir
    if [[ "$TARGET" =~ ^([^/]+)(/.*) ]]; then
        URL_PATH="${BASH_REMATCH[2]}"
        TARGET="${BASH_REMATCH[1]}"
    fi
    
    # Processar domínio e subdomínio
    if [[ "$TARGET" =~ ^(([^\.]+)\.)?([^\.]+\.[^\.]+)$ ]]; then
        URL_SUB_DOMINIO="${BASH_REMATCH[2]}"
        URL_DOMINIO="${BASH_REMATCH[3]}"
    else
        URL_DOMINIO="$TARGET"
    fi
    
    # Verificar tipo de alvo
    TYPE_TARGET=$(verificar_tipo_alvo "$TARGET")
    if [ "$TYPE_TARGET" = "INVÁLIDO" ]; then
        print_status "error" "Entrada inválida. Digite um IP, domínio ou URL válido."
        CHECKLIST+=("Alvo definido: ✗ Entrada inválida")
        return 1
    fi
    
    # Para URLs, formatar saídas para ffuf
    if [ -n "$URL_PROTOCOLO" ]; then
        CHECKLIST+=("URL completa: ✓ ${URL_PROTOCOLO}://${TARGET}${URL_PORT}${URL_PATH}")
        [ -n "$URL_SUB_DOMINIO" ] && CHECKLIST+=("Subdomínio: ✓ $URL_SUB_DOMINIO")
        CHECKLIST+=("Domínio principal: ✓ $URL_DOMINIO")
        CHECKLIST+=("Protocolo: ✓ $URL_PROTOCOLO")
        [ -n "$URL_PORT" ] && CHECKLIST+=("Porta: ✓ $URL_PORT")
        [ -n "$URL_PATH" ] && CHECKLIST+=("Path: ✓ $URL_PATH")
        
        # Formatar para ffuf
        FFUF_DOMAIN="${URL_SUB_DOMINIO}.${URL_DOMINIO}"
        FFUF_URL="${URL_PROTOCOLO}://${FFUF_DOMAIN}${URL_PORT}"
    fi
    
    # Resolução DNS para domínios
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        if ! dig +short A "$TARGET" &>/dev/null; then
            print_status "error" "Falha ao resolver DNS. Verifique a conectividade ou o domínio."
            CHECKLIST+=("Resolução de IP: ✗ Falha na resolução DNS para $TARGET")
            return 1
        fi
        TARGET_IPv4=$(dig +short A "$TARGET" | grep -oP '^\d+\.\d+\.\d+\.\d+$' | head -1)
        TARGET_IPv6=$(dig +short AAAA "$TARGET" | grep -oP '^[0-9a-fA-F:]+$' | head -1)
        if [ -z "$TARGET_IPv4" ] && [ -z "$TARGET_IPv6" ]; then
            CHECKLIST+=("Resolução de IP: ✗ Não foi possível resolver IP para $TARGET")
            return 1
        fi
        [ -n "$TARGET_IPv4" ] && CHECKLIST+=("Resolução IPv4: ✓ $TARGET_IPv4")
        [ -n "$TARGET_IPv6" ] && CHECKLIST+=("Resolução IPv6: ✓ $TARGET_IPv6")
    else
        TARGET_IPv4="$TARGET"
        CHECKLIST+=("Alvo definido: ✓ $TARGET (IPv4)")
    fi
    
    # Adicionar variáveis globais para uso posterior
    if [ -n "$URL_PROTOCOLO" ]; then
        export URL_ORIGINAL URL_PROTOCOLO URL_SUB_DOMINIO URL_DOMINIO URL_PATH URL_PORT FFUF_DOMAIN FFUF_URL
    fi
}

#------------#------------# FUNÇÕES DE TESTE #------------#------------#
test_dig() {
    print_status "action" "Executando teste DNS com dig"
    local output_file="$RESULTS_DIR/dig_output.txt"
    local dig_result=$(dig "$TARGET" ANY +short >"$output_file" 2>&1)
    if [ $? -eq 0 ]; then
        local resolved_ips=$(cat "$output_file" | grep -oP '(\d+\.\d+\.\d+\.\d+|[:0-9a-fA-F]+)' | tr '\n' ',' | sed 's/,$//')
        [ -n "$resolved_ips" ] && CHECKLIST+=("DNS: ✓ IPs resolvidos ($resolved_ips)") || CHECKLIST+=("DNS: ✗ Nenhum IP resolvido")
    else
        CHECKLIST+=("DNS: ✗ Falha")
    fi
}

test_traceroute() {
    print_status "action" "Executando traceroute"
    local output_file="$RESULTS_DIR/traceroute_output.txt"
    local traceroute_cmd="traceroute $TARGET_IPv4" && [ -n "$TARGET_IPv6" ] && traceroute_cmd="traceroute6 $TARGET_IPv6"
    local traceroute_result=$($traceroute_cmd >"$output_file" 2>&1)
    if [ $? -eq 0 ]; then
        CHECKLIST+=("Traceroute: ✓ Sucesso")
    else
        CHECKLIST+=("Traceroute: ✗ Falha")
    fi
}

test_curl_headers() {
    print_status "action" "Verificando headers HTTP com curl"
    local output_file="$RESULTS_DIR/curl_headers.txt"
    local protocol=$(determinar_protocolo)
    local curl_result=$(curl -sI "$protocol://$TARGET" >"$output_file" 2>&1)
    if [ $? -eq 0 ]; then
        local http_code=$(head -1 "$output_file" | cut -d' ' -f2)
        CHECKLIST+=("HTTP Headers ($protocol): ✓ Código $http_code")
    else
        CHECKLIST+=("HTTP Headers ($protocol): ✗ Falha")
    fi
}

#------------#------------# MENUS #------------#------------#
menu_personalizado() {
    while true; do
        clear
        centralizar "=============================="
        centralizar " Menu de Ferramentas de Rede "
        centralizar "=============================="
        echo
        centralizar "------ FFUF Enumeration ------"
        centralizar "1. Enumeração de Subdomínios"
        centralizar "2. Enumeração de Diretórios"
        centralizar "3. Enumeração de Extensões de Arquivos"
        echo
        centralizar "------ Testes Básicos -------"
        centralizar "4. Teste de Ping"
        centralizar "5. Teste DNS (dig)"
        centralizar "6. Traceroute"
        centralizar "7. Verificar Headers HTTP (curl)"
        echo
        centralizar "8. Voltar ao menu principal"
        echo
        read -p "[+] Escolha uma opção (1-8): " OPCAO
        case $OPCAO in
            1|2|3|4|5|6|7)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                case $OPCAO in
                    1) test_ffuf_subdomains ;;
                    2) test_ffuf_directories ;;
                    3) test_ffuf_extensions ;;
                    4) test_ping "$TARGET_IPv4" "IPv4"; [ -n "$TARGET_IPv6" ] && test_ping "$TARGET_IPv6" "IPv6" ;;
                    5) test_dig ;;
                    6) test_traceroute ;;
                    7) test_curl_headers ;;
                esac
                source ./Generate-result.sh
                save_report
                ;;
            8) break ;;
            *) print_status "error" "Opção inválida" ;;
        esac
    done
}

menu_inicial() {
    clean_results  # Limpar arquivos residuais antes de iniciar
    # Instalar dependências
    for cmd in jq dig nmap ffuf traceroute curl nc; do
        if ! command -v $cmd &>/dev/null; then
            print_status "info" "Instalando $cmd..."
            if command -v apt-get &>/dev/null; then
                sudo apt-get install -y ${cmd/dig/dnsutils} ${cmd/nc/netcat-traditional} >/dev/null
            elif command -v yum &>/dev/null; then
                sudo yum install -y ${cmd/dig/bind-utils} ${cmd/nc/nmap-ncat} >/dev/null
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm ${cmd/dig/bind-tools} ${cmd/nc/nc} >/dev/null
            else
                print_status "error" "Nenhum gerenciador de pacotes suportado encontrado para $cmd."
                exit 1
            fi
        fi
    done

    while true; do
        clear
        centralizar "=============================="
        centralizar "      AUTORECON v1.2.4      "
        centralizar "=============================="
        echo
        centralizar "1. Ativo"
        centralizar "2. Personalizado"
        centralizar "3. Sair"
        echo
        read -p "[+] Escolha uma estratégia (1-3): " estrategia
        case $estrategia in
            1)
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                print_status "action" "Executando Reconhecimento Ativo..."
                Ativo_basico
                Ativo_complexo
                source ./Generate-result.sh
                save_report
                ;;
            2)
                menu_personalizado
                ;;
            3) print_status "info" "Saindo..."; exit 0 ;;
            *) print_status "error" "Opção inválida" ;;
        esac
    done
}

# Inicia o script
validar_root
menu_inicial