#!/bin/bash

# utils.sh
# Função: Funções compartilhadas entre scripts
# Dependências: Variáveis globais TARGET, TYPE_TARGET, TARGET_IPv4, TARGET_IPv6, CHECKLIST

# Definir cores ANSI
if [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
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

print_status() {
    local color="$1" message="$2"
    case "$color" in
        "info") echo -e "${BLUE}[+] $message${NC}" ;;
        "action") echo -e "${YELLOW}[▶] $message${NC}" ;;
        "success") echo -e "${GREEN}[✔] $message${NC}" ;;
        "error") echo -e "${RED}[✗] $message${NC}" ;;
    esac
}

centralizar() {
    local texto="$1"
    if ! command -v tput &>/dev/null; then
        echo "$texto"
        return
    fi
    local largura_terminal=$(tput cols)
    local comprimento_texto=${#texto}
    local espaco=$(( (largura_terminal - comprimento_texto) / 2 ))
    printf "%*s%s\n" $espaco "" "$texto"
}

print_clock_frame() {
    local frame=$1 task=$2
    local hora=$(date +"%H:%M:%S")
    clear
    centralizar "=============================="
    centralizar " AutoRecon v1.3.0 - Status "
    centralizar "=============================="
    echo
    # Seção: Metadados do Alvo
    echo -e "${BLUE}Metadados do Alvo:${NC}"
    echo -e "${CYAN}  Alvo: ${TARGET:-N/A} (${TYPE_TARGET:-N/A})${NC}"
    [ -n "$TARGET_IPv4" ] && echo -e "${CYAN}  IPv4: $TARGET_IPv4${NC}"
    [ -n "$TARGET_IPv6" ] && echo -e "${CYAN}  IPv6: $TARGET_IPv6${NC}"
    [ -n "$URL_PROTOCOLO" ] && echo -e "${CYAN}  Protocolo: $URL_PROTOCOLO${NC}"
    [ -n "$URL_PATH" ] && echo -e "${CYAN}  Path: $URL_PATH${NC}"
    echo
    # Seção: Teste em Andamento
    echo -e "${BLUE}Teste em Andamento:${NC}"
    centralizar "${YELLOW}$task${NC}"
    echo -e "${CYAN}  Hora: $hora${NC}"
    echo
    # Seção: Checklist
    echo -e "${BLUE}Checklist:${NC}"
    local config_items=()
    local network_items=()
    local enum_items=()
    for item in "${CHECKLIST[@]}"; do
        item_sanitized=$(echo "$item" | sed 's/[^[:print:]]//g')
        if [[ "$item_sanitized" =~ ^(URL completa|Domínio principal|Subdomínio|Protocolo|Path|Resolução IPv4|Resolução IPv6|Alvo definido): ]]; then
            config_items+=("$item_sanitized")
        elif [[ "$item_sanitized" =~ ^(Ping|Porta|Nmap|HTTP|Traceroute|DNS): ]]; then
            network_items+=("$item_sanitized")
        elif [[ "$item_sanitized" =~ ^(FFUF): ]]; then
            enum_items+=("$item_sanitized")
        fi
    done
    # Exibir Configuração do Alvo
    if [ ${#config_items[@]} -gt 0 ]; then
        echo -e "${WHITE}  Configuração do Alvo:${NC}"
        for item in "${config_items[@]}"; do
            if [[ "$item" == *"✓"* ]]; then
                echo -e "${GREEN}    ✔ $item${NC}"
            elif [[ "$item" == *"✗"* ]]; then
                echo -e "${RED}    ✖ $item${NC}"
            elif [[ "$item" == *"⚠"* ]]; then
                echo -e "${YELLOW}    ⚠ $item${NC}"
            else
                echo -e "    - $item"
            fi
        done
    fi
    # Exibir Testes de Rede
    if [ ${#network_items[@]} -gt 0 ]; then
        echo -e "${WHITE}  Testes de Rede:${NC}"
        for item in "${network_items[@]}"; do
            if [[ "$item" == *"✓"* ]]; then
                echo -e "${GREEN}    ✔ $item${NC}"
            elif [[ "$item" == *"✗"* ]]; then
                echo -e "${RED}    ✖ $item${NC}"
            elif [[ "$item" == *"⚠"* ]]; then
                echo -e "${YELLOW}    ⚠ $item${NC}"
            else
                echo -e "    - $item"
            fi
        done
    fi
    # Exibir Testes de Enumeração
    if [ ${#enum_items[@]} -gt 0 ]; then
        echo -e "${WHITE}  Testes de Enumeração:${NC}"
        for item in "${enum_items[@]}"; do
            if [[ "$item" == *"✓"* ]]; then
                echo -e "${GREEN}    ✔ $item${NC}"
            elif [[ "$item" == *"✗"* ]]; then
                echo -e "${RED}    ✖ $item${NC}"
            elif [[ "$item" == *"⚠"* ]]; then
                echo -e "${YELLOW}    ⚠ $item${NC}"
            else
                echo -e "    - $item"
            fi
        done
    fi
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