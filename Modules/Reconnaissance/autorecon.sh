#!/bin/bash

# autorecon.sh
# Função: Controlador principal, gerencia menus, chama testes e organiza resultados para Generate-result.sh

# Carrega os scripts de teste
source ./ativo.sh
# source ./passivo.sh  # Descomentar quando passivo.sh estiver implementado

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
TARGET=""
TARGET_IPv4=""
TARGET_IPv6=""
TYPE_TARGET=""
CHECKLIST=()
START_TIME=$(date +%s)
RESULTS_DIR="results"

# Definir cores ANSI
if [ "$(tput colors)" -ge 8 ]; then
    BLUE="\033[1;34m"
    CYAN="\033[1;36m"
    GREEN="\033[1;32m"
    YELLOW="\033[1;33m"
    PURPLE="\033[1;35m"
    WHITE="\033[1;37m"
    RED="\033[1;31m"
    NC="\033[0m"
else
    BLUE=""
    CYAN=""
    GREEN=""
    YELLOW=""
    PURPLE=""
    WHITE=""
    RED=""
    NC=""
fi

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
validar_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}[✗] Este script requer privilégios de root. Execute com sudo.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✔] Executando como root.${NC}"
}

centralizar() {
    local texto="$1"
    local largura_terminal=$(tput cols)
    local comprimento_texto=${#texto}
    local espaco=$(( (largura_terminal - comprimento_texto) / 2 ))
    printf "%*s%s\n" $espaco "" "$texto"
}

#------------#------------# FUNÇÕES GRÁFICAS #------------#------------#

print_status() {
    local color="$1" message="$2"
    case "$color" in
        "info") echo -e "${BLUE}[+] $message${NC}" ;;
        "action") echo -e "${YELLOW}[▶] $message${NC}" ;;
        "success") echo -e "${GREEN}[✔] $message${NC}" ;;
        "error") echo -e "${RED}[✗] $message${NC}" ;;
    esac
}

print_clock_frame() {
    local frame=$1 task=$2 hora=$(date +"%H:%M:%S")
    clear
    echo -e "${BLUE}=== Target: ${CYAN}$TARGET ${BLUE}(${TYPE_TARGET}) ===${NC}"
    [ -n "$TARGET_IPv4" ] && echo -e "${GREEN}IPv4: $TARGET_IPv4${NC}"
    [ -n "$TARGET_IPv6" ] && echo -e "${GREEN}IPv6: $TARGET_IPv6${NC}"
    echo -e "\n   ${PURPLE}______${NC}"
    echo -e " ${PURPLE}/${YELLOW}________${PURPLE}\\${NC}"
    echo -e " ${PURPLE}|${CYAN}$hora${PURPLE}|${NC}"
    echo -e " ${PURPLE}|${YELLOW}________${PURPLE}|${NC}"
    if [ "$frame" -eq 1 ]; then
        echo -e " ${PURPLE}|${YELLOW}........${PURPLE}|${NC}"
        echo -e " ${PURPLE}|${YELLOW}........${PURPLE}|${NC}"
    else
        echo -e " ${PURPLE}|${YELLOW}        ${PURPLE}|${NC}"
        echo -e " ${PURPLE}|${YELLOW}        ${PURPLE}|${NC}"
    fi
    echo -e " ${PURPLE}\\ ${YELLOW}______${PURPLE} /${NC}"
    echo -e "\n${WHITE}Executando: ${CYAN}$task${NC}"
    echo -e "\n${GREEN}Checklist:${NC}"
    for item in "${CHECKLIST[@]}"; do
        item_sanitized=$(echo "$item" | sed 's/[^[:print:]]//g')
        if [[ "$item_sanitized" == *"✓"* ]]; then
            echo -e " ${GREEN}✔ $item_sanitized${NC}"
        elif [[ "$item_sanitized" == *"✗"* ]]; then
            echo -e " ${RED}✖ $item_sanitized${NC}"
        elif [[ "$item_sanitized" == *"⚠"* ]]; then
            echo -e " ${YELLOW}⚠ $item_sanitized${NC}"
        else
            echo -e " - $item_sanitized"
        fi
    done
}

loading_clock() {
    local task="$1" duration=${2:-3}
    local end_time=$((SECONDS + duration))
    local pid
    while [ $SECONDS -lt $end_time ]; do
        print_clock_frame 1 "$task" &
        pid=$!
        sleep 0.3
        kill -0 $pid 2>/dev/null && kill $pid
        wait $pid 2>/dev/null
        print_clock_frame 2 "$task" &
        pid=$!
        sleep 0.3
        kill -0 $pid 2>/dev/null && kill $pid
        wait $pid 2>/dev/null
    done
}

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#

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
    TYPE_TARGET=$(verificar_tipo_alvo "$TARGET")
    if [ "$TYPE_TARGET" = "INVÁLIDO" ]; then
        print_status "error" "Entrada inválida. Digite um IP, domínio ou URL válido."
        CHECKLIST+=("Alvo definido: ✗ Entrada inválida")
        return 1
    fi
    TARGET=$(echo "$TARGET" | sed -E 's|^https?://||; s|/.*$||; s|:[0-9]+$||')
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
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
    # Instalar dependências
    for cmd in jq dig; do
        if ! command -v $cmd &>/dev/null; then
            print_status "info" "Instalando $cmd..."
            if command -v apt-get &>/dev/null; then
                sudo apt-get install -y ${cmd/dig/dnsutils} >/dev/null
            elif command -v yum &>/dev/null; then
                sudo yum install -y ${cmd/dig/bind-utils} >/dev/null
            else
                print_status "error" "Nenhum gerenciador de pacotes suportado encontrado."
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