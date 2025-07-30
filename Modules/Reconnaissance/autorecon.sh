#!/bin/bash

# Carrega os arquivos JSON.sh, passivo.sh e ativo.sh
source ./JSON.sh
source ./passivo.sh
source ./ativo.sh

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
ASK=""
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
        centralizar "1. Teste de Ping"
        centralizar "2. Teste DNS"
        centralizar "3. Teste de Portas"
        centralizar "4. Teste HTTP"
        centralizar "5. Use o FFUF"
        centralizar "6. Teste Passivo Completo"
        centralizar "7. Teste Ativo Completo"
        centralizar "8. Voltar ao menu principal"
        echo
        read -p "[+] Escolha uma opção (1-8): " OPCAO
        case $OPCAO in
            1)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                [ -n "$TARGET_IPv4" ] && test_ping "$TARGET_IPv4" "IPv4"
                [ -n "$TARGET_IPv6" ] && test_ping "$TARGET_IPv6" "IPv6"
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            2)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                [ "$TYPE_TARGET" = "DOMAIN" ] && test_dns
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            3)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                read -p "Digite as portas a testar (ex: 22,80,443): " PORTS
                IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
                [ -n "$TARGET_IPv4" ] && test_ports "$TARGET_IPv4" "IPv4" "${PORT_ARRAY[@]}"
                [ -n "$TARGET_IPv6" ] && test_ports "$TARGET_IPv6" "IPv6" "${PORT_ARRAY[@]}"
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            4)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                test_http
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            5)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                test_whois
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            6)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Passivo_basico
                Passivo_complexo
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            7)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Ativo_basico
                Ativo_complexo
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            8) break ;;
            *) print_status "error" "Opção inválida" ;;
        esac
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
        centralizar "=============================="
        centralizar "      AUTORECON v1.2.4      "
        centralizar "=============================="
        echo
        centralizar "1. Passivo + Ativo"
        centralizar "2. Ativo + Passivo"
        centralizar "3. Passivo"
        centralizar "4. Ativo"
        centralizar "5. Personalizado"
        centralizar "6. Sair"
        echo
        read -p "[+] Escolha uma estratégia (1-6): " estrategia
        case $estrategia in
            1)
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                print_status "action" "Executando Reconhecimento Passivo..."
                Passivo_basico
                Passivo_complexo
                print_status "action" "Executando Reconhecimento Ativo..."
                Ativo_basico
                Ativo_complexo
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            2)
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                print_status "action" "Executando Reconhecimento Ativo..."
                Ativo_basico
                Ativo_complexo
                print_status "action" "Executando Reconhecimento Passivo..."
                Passivo_basico
                Passivo_complexo
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            3)
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Passivo_basico
                Passivo_complexo
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            4)
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Ativo_basico
                Ativo_complexo
                [ ${#CHECKLIST[@]} -gt 0 ] && salvar_json
                ;;
            5) menu_personalizado ;;
            6) print_status "info" "Saindo..."; exit 0 ;;
            *) print_status "error" "Opção inválida" ;;
        esac
    done
}

# Inicia o script
validar_root
menu_inicial