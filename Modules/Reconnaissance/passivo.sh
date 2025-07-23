#!/bin/bash

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
ASK=""
TARGET=""
TARGET_IPv4=""
TARGET_IPv6=""
TYPE_TARGET=""
CHECKLIST=()
JSON_FILE="scan_results_passivo_$(date +%s).json"
WORDLISTS_DIR="$HOME/wordlists"
START_TIME=$(date +%s)

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

#------------#------------# VARIÁVEIS COMANDOS #------------#------------#
FFUF_COMMANDS=(
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -o ffuf_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -fc 404 -o ffuf_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -t 50 -recursion -recursion-depth 1 -o ffuf_output.csv -of csv"
)
ASM_COMMANDS=(
    "python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -sth"
    "python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -exp"
    "python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -sth -api"
)
GL_COMMAND="gitleaks detect --source . --no-git -c {TARGET} -o gitleaks_output.json"
SH_COMMAND="python3 -m sherlock {TARGET} --output sherlock_output.txt"
FIERCE_COMMAND="fierce --domain {TARGET} --subdomain-file {WORDLIST_SUBDOMAINS} --output fierce_output.txt"
FR_COMMAND="python3 -m finalrecon --full {PROTOCOL}://{TARGET} --out finalrecon_output.txt"

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
            4 echo -e " ${RED}✖ $item_sanitized${NC}"
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

determinar_protocolo() {
    local protocol="http"
    echo "$protocol"
}

substituir_variaveis() {
    local cmd="$1" ip="$2"
    local wordlist_subdomains="$WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
    [ ! -f "$wordlist_subdomains" ] && { wordlist_subdomains="/tmp/subdomains.txt"; curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o "$wordlist_subdomains"; }
    local protocol=$(determinar_protocolo)
    echo "$cmd" | sed "s/{TARGET}/$TARGET/g; s/{TARGET_IP}/$ip/g; s/{PROTOCOL}/$protocol/g; s|{WORDLIST_SUBDOMAINS}|$wordlist_subdomains|g"
}

salvar_json() {
    local json_data="{"
    json_data+="\"script\": {\"name\": \"Passivo Recon Script\", \"version\": \"1.0\", \"os\": \"$(uname -a | tr -d '\n' | sed 's/[^[:print:]]//g')\", \"start_time\": \"$(date -d @$START_TIME '+%Y-%m-%dT%H:%M:%S')\", \"user\": \"$(whoami | tr -d '\n' | sed 's/[^[:print:]]//g')\"},"
    json_data+="\"target\": {\"input\": \"$TARGET\", \"resolved_ipv4\": \"$TARGET_IPv4\", \"resolved_ipv6\": \"$TARGET_IPv6\", \"type\": \"$TYPE_TARGET\", \"protocol\": \"$(determinar_protocolo)\", \"resolution_time\": \"$(date +'%Y-%m-%dT%H:%M:%S')\"},"
    json_data+="\"tools_config\": {\"ffuf\": {\"subdomain_commands\": $(printf '%s\n' "${FFUF_COMMANDS[@]}" | jq -R . | jq -s .)}, \"attacksurfacemapper\": $(printf '%s\n' "${ASM_COMMANDS[@]}" | jq -R . | jq -s .), \"gitleaks\": \"$GL_COMMAND\", \"sherlock\": \"$SH_COMMAND\", \"fierce\": \"$FIERCE_COMMAND\", \"finalrecon\": \"$FR_COMMAND\"},"
    json_data+="\"dependencies\": {\"jq\": \"$(command -v jq &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"python3\": \"$(command -v python3 &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"attacksurfacemapper\": \"$(python3 -m pip show attacksurfacemapper &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"gitleaks\": \"$(command -v gitleaks &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"sherlock\": \"$(python3 -m pip show sherlock-project &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"fierce\": \"$(command -v fierce &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"finalrecon\": \"$(python3 -m pip show finalrecon &>/dev/null && echo 'Instalado' || echo 'Não instalado')\"},"
    json_data+="\"tests\": ["
    local success_count=0 failure_count=0
    for item in "${CHECKLIST[@]}"; do
        item_sanitized=$(echo "$item" | sed 's/[^[:print:]]//g')
        IFS=':' read -ra parts <<< "$item_sanitized"
        test_name=$(echo "${parts[0]}" | xargs)
        status=$(echo "${parts[1]}" | xargs)
        message=$(echo "${parts[1]}" | cut -d' ' -f2- | xargs)
        json_data+="{\"name\": \"$test_name\", \"status\": $([[ "$status" == *"✓"* ]] && echo "true" || echo "false"), \"message\": \"$message\", \"timestamp\": \"$(date +'%Y-%m-%dT%H:%M:%S')\", \"details\": {"
        case $test_name in
            "DNS"|"DNS Personalizado")
                json_data+="\"command\": \"dig $TARGET +short\", \"resolved_ips\": \"${ips:-N/A}\"}"
                ;;
            *) json_data+="\"command\": \"N/A\"}" ;;
        esac
        json_data+="}, \"raw_output_file\": \"$(echo $test_name | tr ' ' '_' | tr -d ':').txt\"},"
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    json_data="${json_data%,]}"
    json_data+="],\"statistics\": {\"total_tests\": ${#CHECKLIST[@]}, \"success_count\": $success_count, \"failure_count\": $failure_count, \"total_execution_time\": \"$(( $(date +%s) - START_TIME )) seconds\"}"
    json_data+="}"
    echo "$json_data" | jq '.' > "$JSON_FILE" 2>/dev/null || { print_status "error" "Falha ao salvar JSON (verifique se jq está instalado)"; return 1; }
    print_status "success" "Resultados salvos em $JSON_FILE"
}

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