#!/bin/bash

# Carrega o arquivo JSON.sh para usar suas funções e variáveis
source ./JSON.sh

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
validar_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}[✗] Este script requer privilégios de root. Execute com sudo.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✔] Executando como root.${NC}"
}

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

#------------#------------# FUNÇÕES DE TESTE #------------#------------#
definir_alvo() {
    print_status "action" "Definindo alvo"
    read -p "Digite o IP, domínio ou URL alvo: " TARGET
    TYPE_TARGET=$(verificar_tipo_alvo "$TARGET")
    if [ "$TYPE_TARGET" = "INVÁLIDO" ]; then
        print_status "error" "Entrada inválida. Digite um IP, domínio ou URL válido."
        CHECKLIST+=("Alvo definido: ✗ Entrada inválida")
        salvar_json
        return 1
    fi
    TARGET=$(echo "$TARGET" | sed -E 's|^https?://||; s|/.*$||; s|:[0-9]+$||')
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        TARGET_IPv4=$(dig +short A "$TARGET" | grep -oP '^\d+\.\d+\.\d+\.\d+$' | head -1)
        TARGET_IPv6=$(dig +short AAAA "$TARGET" | grep -oP '^[0-9a-fA-F:]+$' | head -1)
        if [ -z "$TARGET_IPv4" ] && [ -z "$TARGET_IPv6" ]; then
            CHECKLIST+=("Resolução de IP: ✗ Não foi possível resolver IP para $TARGET")
            salvar_json
            return 1
        fi
        [ -n "$TARGET_IPv4" ] && CHECKLIST+=("Resolução IPv4: ✓ $TARGET_IPv4")
        [ -n "$TARGET_IPv6" ] && CHECKLIST+=("Resolução IPv6: ✓ $TARGET_IPv6")
    else
        TARGET_IPv4="$TARGET"
        CHECKLIST+=("Alvo definido: ✓ $TARGET (IPv4)")
    fi
    salvar_json
}

executar_comando() {
    local cmd="$1" name="$2" output_file="$3" success_msg="$4" fail_msg="$5"
    print_status "action" "Executando $name"
    local temp_output=$(mktemp)
    if $cmd >"$temp_output" 2>&1; then
        local results=$(wc -l < "$temp_output")
        [ "$results" -gt 0 ] && CHECKLIST+=("$name: ✓ $success_msg $results") || CHECKLIST+=("$name: ✓ $fail_msg")
    else
        CHECKLIST+=("$name: ✗ Falha")
    fi
    mv "$temp_output" "$output_file"
}

testar_ferramenta() {
    local tool="$1" cmd="$2" success_msg="$3" fail_msg="$4"
    if ! command -v ${tool,,} &>/dev/null && ! python3 -m pip show ${tool,,} &>/dev/null; then
        CHECKLIST+=("$tool: ✗ Não instalado")
        return 1
    fi
    local output_file="${tool,,}_output.txt"
    local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4")
    loading_clock "$tool" 10 &
    pid=$!
    executar_comando "$cmd_substituido" "$tool" "$output_file" "$success_msg" "$fail_msg"
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

#------------#------------# FUNÇÕES DE TESTE #------------#------------#
Passivo_basico() {
    print_status "info" "Executando testes PASSIVOS BÁSICOS em $TARGET"
    loading_clock "Testes Passivos Básicos" 3 &
    pid=$!
    if [ "$TYPE_TARGET" = "DOMAIN" ] && whois "$TARGET" &>/dev/null; then
        CHECKLIST+=("WHOIS: ✓ Informações obtidas")
    else
        CHECKLIST+=("WHOIS: ✗ Falha ou não aplicável")
    fi
    [ "$TYPE_TARGET" = "DOMAIN" ] && CHECKLIST+=("DNS Histórico: ⚠ Simulado")
    [ "$TYPE_TARGET" = "DOMAIN" ] && CHECKLIST+=("Threat Intel: ⚠ Simulado")
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

Passivo_complexo() {
    [ "$TYPE_TARGET" != "DOMAIN" ] && { print_status "error" "Passivo Complexo: Requer domínio"; CHECKLIST+=("Passivo Complexo: ✗ Requer domínio"); salvar_json; return 1; }
    print_status "info" "Executando testes PASSIVOS COMPLEXOS em $TARGET"
    if ! command -v python3 &>/dev/null; then
        CHECKLIST+=("Python3: ✗ Não instalado")
        salvar_json
        return 1
    fi
    python_version=$(python3 --version | grep -oP '\d+\.\d+\.\d+')
    python_major=$(echo $python_version | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d'.' -f2)
    if [ $python_major -lt 3 ] || { [ $python_major -eq 3 ] && [ $python_minor -lt 7 ]; }; then
        CHECKLIST+=("Python: ✗ Versão 3.7+ necessária")
        salvar_json
        return 1
    fi
    for tool in "AttackSurfaceMapper" "FFuf Subdomains" "Gitleaks" "Sherlock" "Fierce" "FinalRecon"; do
        read -p "Deseja executar $tool para $TARGET? (s/n): " ASK
        if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
            case $tool in
                "AttackSurfaceMapper") testar_ferramenta "AttackSurfaceMapper" "${ASM_COMMANDS[0]}" "Subdomínios encontrados:" "Nenhum subdomínio encontrado" ;;
                "FFuf Subdomains") testar_ferramenta "ffuf" "${FFUF_COMMANDS[0]}" "Subdomínios encontrados:" "Nenhum subdomínio encontrado" ;;
                "Gitleaks") testar_ferramenta "gitleaks" "$GL_COMMAND" "Vazamentos encontrados:" "Nenhum vazamento encontrado" ;;
                "Sherlock") testar_ferramenta "sherlock" "$SH_COMMAND" "Perfis encontrados:" "Nenhum perfil encontrado" ;;
                "Fierce") testar_ferramenta "fierce" "$FIERCE_COMMAND" "Subdomínios encontrados:" "Nenhum subdomínio encontrado" ;;
                "FinalRecon") testar_ferramenta "finalrecon" "$FR_COMMAND" "Linhas de resultados:" "Nenhum resultado encontrado" ;;
            esac
            salvar_json
        fi
    done
}

#------------#------------# MENUS #------------#------------#
menu_personalizado() {
    while true; do
        clear
        print_status "info" "Menu de Ferramentas de Rede (PASSIVO)"
        echo "1. Teste DNS"
        echo "2. Teste WHOIS"
        echo "3. Teste Passivo Completo"
        echo "4. Voltar ao menu principal"
        read -p "Escolha uma opção (1-4): " OPCAO
        case $OPCAO in
            1)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                [ "$TYPE_TARGET" = "DOMAIN" ] && {
                    loading_clock "Teste DNS" 3 &
                    pid=$!
                    local dns_result=$(dig "$TARGET" +short 2>&1)
                    if [ -n "$dns_result" ]; then
                        local ips=$(echo "$dns_result" | grep -oP '(\d+\.){3}\d+|[0-9a-fA-F:]+' | tr '\n' ',' | sed 's/,$//')
                        CHECKLIST+=("DNS Personalizado: ✓ Resolvido (IPs: $ips)")
                    else
                        CHECKLIST+=("DNS Personalizado: ✗ Falha")
                    fi
                    kill -0 $pid 2>/dev/null && kill $pid
                    wait $pid 2>/dev/null
                }
                ;;
            2)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                [ "$TYPE_TARGET" = "DOMAIN" ] && {
                    loading_clock "Teste WHOIS" 3 &
                    pid=$!
                    if whois "$TARGET" &>/dev/null; then
                        CHECKLIST+=("WHOIS Personalizado: ✓ Informações obtidas")
                    else
                        CHECKLIST+=("WHOIS Personalizado: ✗ Falha")
                    fi
                    kill -0 $pid 2>/dev/null && kill $pid
                    wait $pid 2>/dev/null
                }
                ;;
            3)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Passivo_basico
                Passivo_complexo
                ;;
            4) break ;;
            *) print_status "error" "Opção inválida" ;;
        esac
        salvar_json
    done
}

menu_inicial() {
    if ! command -v jq &>/dev/null; then
        print_status "info" "Instalando jq..."
        sudo apt-get install -y jq >/dev/null || sudo yum install -y jq >/dev/null
    fi
    if ! command -v dig &>/dev/null; then
        print_status "info" "Instalando dnsutils..."
        sudo apt-get install -y dnsutils >/dev/null || sudo yum install -y bind-utils >/dev/null
    fi
    while true; do
        clear
        print_status "info" "MENU INICIAL (PASSIVO)"
        echo "1. PASSIVO BÁSICO"
        echo "2. PASSIVO COMPLETO"
        echo "3. PERSONALIZADO"
        echo "4. SAIR"
        read -p "Escolha uma estratégia (1-4): " estrategia
        case $estrategia in
            1) definir_alvo; [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue; Passivo_basico ;;
            2) definir_alvo; [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue; Passivo_basico; Passivo_complexo ;;
            3) menu_personalizado ;;
            4) print_status "info" "Saindo..."; exit 0 ;;
            *) print_status "error" "Opção inválida" ;;
        esac
    done
}

# Inicia o script
validar_root
menu_inicial