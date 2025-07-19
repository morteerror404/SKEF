#!/bin/bash

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
ASK=""
TARGET=""
TARGET_IPv4=""
TARGET_IPv6=""
TYPE_TARGET=""
CHECKLIST=()
JSON_FILE="scan_results_$(date +%s).json"
WORDLISTS_DIR="$HOME/wordlists"
NMAP_SILENCE=""
START_TIME=$(date +%s)

# Arrays associativos para rastrear estados das portas
declare -A PORT_STATUS_IPV4
declare -A PORT_STATUS_IPV6
declare -A PORT_TESTS_IPV4
declare -A PORT_TESTS_IPV6

#------------#------------# VARIÁVEIS COMANDOS #------------#------------#
NMAP_COMMANDS_IPV4=(
    "nmap {TARGET_IP} --top-ports 100 -T4 -v {NMAP_SILENCE}"
    "nmap {TARGET_IP} -vv -O {NMAP_SILENCE}"
    "nmap {TARGET_IP} -sV -O -vv {NMAP_SILENCE}"
)
NMAP_COMMANDS_IPV6=(
    "nmap -6 {TARGET_IP} --top-ports 100 -T4 -v {NMAP_SILENCE}"
    "nmap -6 {TARGET_IP} -vv -O {NMAP_SILENCE}"
    "nmap -6 {TARGET_IP} -sV -O -vv {NMAP_SILENCE}"
)
FFUF_COMMANDS=(
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -o ffuf_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -fc 404 -o ffuf_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -t 50 -recursion -recursion-depth 1 -o ffuf_output.csv -of csv"
)
FFUF_WEB_COMMANDS=(
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -o ffuf_web_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -e .php,.txt,.html -o ffuf_web_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -recursion -recursion-depth 2 -o ffuf_web_output.csv -of csv"
)
ASM_COMMANDS=(
    "python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -sth"
    "python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -exp"
    "python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -sth -api"
)
AR_COMMANDS=(
    "autorecon {TARGET_IP} --dir autorecon_output --only-scans"
    "autorecon {TARGET_IP} --dir autorecon_output"
    "autorecon {TARGET_IP} --dir autorecon_output --web"
)
GL_COMMAND="gitleaks detect --source . --no-git -c {TARGET} -o gitleaks_output.json"
SH_COMMAND="python3 -m sherlock {TARGET} --output sherlock_output.txt"
XRAY_COMMAND="xray ws --url {PROTOCOL}://{TARGET} --json-output xray_output.json"
FIERCE_COMMAND="fierce --domain {TARGET} --subdomain-file {WORDLIST_SUBDOMAINS} --output fierce_output.txt"
FR_COMMAND="python3 -m finalrecon --full {PROTOCOL}://{TARGET} --out finalrecon_output.txt"
FW_COMMAND="firewalk -S1-1024 -i eth0 -n {TARGET_IP} -o firewalk_output.txt"
CL_COMMAND="python3 -m clusterd -t {TARGET} -o clusterd_output.txt"

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

print_clock_frame() {
    local frame=$1 task=$2 hora=$(date +"%H:%M:%S")
    clear
    
    # Display target information at the top
    echo -e "${BLUE}=== Target: ${CYAN}$TARGET ${BLUE}(${TYPE_TARGET}) ===${NC}"
    [ -n "$TARGET_IPv4" ] && echo -e "${GREEN}IPv4: $TARGET_IPv4${NC}"
    [ -n "$TARGET_IPv6" ] && echo -e "${GREEN}IPv6: $TARGET_IPv6${NC}"
    
    # Animated clock with RECON on the right, adjusted for terminal width
    local cols=$(tput cols)
    local spacing=$((cols - 40 > 0 ? cols - 40 : 0))
    printf "%-${spacing}s" " "
    echo -e "\n   ${PURPLE}______${NC}       ${RED}██████╗ ${GREEN}███████╗${YELLOW} ██████╗${BLUE} ██████╗ ${PURPLE} ███╗   ██╗${NC}"
    printf "%-${spacing}s" " "
    echo -e " ${PURPLE}/${YELLOW}________${PURPLE}\\${NC}     ${RED}██╔══██╗${GREEN}██╔════╝${YELLOW}██╔════╝${BLUE}██╔═══██╗${PURPLE} ████╗  ██║${NC}"
    printf "%-${spacing}s" " "
    echo -e " ${PURPLE}|${CYAN}$hora${PURPLE}|${NC}    ${RED}██████╔╝${GREEN}█████╗  ${YELLOW}██║     ${BLUE}██║   ██║${PURPLE} ██╔██╗ ██║${NC}"
    printf "%-${spacing}s" " "
    echo -e " ${PURPLE}|${YELLOW}________${PURPLE}|${NC}    ${RED}██╔══██╗${GREEN}██╔══╝  ${YELLOW}██║     ${BLUE}██║   ██║${PURPLE} ██║╚██╗██║${NC}"
    if [ "$frame" -eq 1 ]; then
        printf "%-${spacing}s" " "
        echo -e " ${PURPLE}|${YELLOW}........${PURPLE}|${NC}    ${RED}██║  ██║${GREEN}███████╗${YELLOW}╚██████╗${BLUE}╚██████╔╝${PURPLE} ██║ ╚████║${NC}"
        printf "%-${spacing}s" " "
        echo -e " ${PURPLE}|${YELLOW}........${PURPLE}|${NC}    ${RED}╚═╝  ╚═╝${GREEN}╚══════╝${YELLOW} ╚═════╝${BLUE} ╚═════╝ ${PURPLE} ╚═╝  ╚═══╝${NC}"
    else
        printf "%-${spacing}s" " "
        echo -e " ${PURPLE}|${YELLOW}        ${PURPLE}|${NC}    ${RED}██║  ██║${GREEN}███████╗${YELLOW}╚██████╗${BLUE}╚██████╔╝${PURPLE} ██║ ╚████║${NC}"
        printf "%-${spacing}s" " "
        echo -e " ${PURPLE}|${YELLOW}        ${PURPLE}|${NC}    ${RED}╚═╝  ╚═╝${GREEN}╚══════╝${YELLOW} ╚═════╝${BLUE} ╚═════╝ ${PURPLE} ╚═╝  ╚═══╝${NC}"
    fi
    printf "%-${spacing}s" " "
    echo -e " ${PURPLE}\\ ${YELLOW}______${PURPLE} /${NC}"
    
    # Current task and checklist
    echo -e "\n${WHITE}Executando: ${CYAN}$task${NC}"
    echo -e "\n${GREEN}Checklist:${NC}"
    for item in "${CHECKLIST[@]}"; do
        # Sanitizar item para evitar caracteres de controle
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
        sleep 0.3  # Ajustado para animação mais fluida
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
    { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
    echo "$protocol"
}

substituir_variaveis() {
    local cmd="$1" ip="$2"
    local wordlist_subdomains="$WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
    local wordlist_web="$WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt"
    [ ! -f "$wordlist_subdomains" ] && { wordlist_subdomains="/tmp/subdomains.txt"; curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o "$wordlist_subdomains"; }
    [ ! -f "$wordlist_web" ] && { wordlist_web="/tmp/common.txt"; curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o "$wordlist_web"; }
    local protocol=$(determinar_protocolo)
    echo "$cmd" | sed "s/{TARGET}/$TARGET/g; s/{TARGET_IP}/$ip/g; s/{PROTOCOL}/$protocol/g; s|{WORDLIST_SUBDOMAINS}|$wordlist_subdomains|g; s|{WORDLIST_WEB}|$wordlist_web|g"
}

salvar_json() {
    local json_data="{"
    json_data+="\"script\": {\"name\": \"Network Recon Script\", \"version\": \"1.2.3\", \"os\": \"$(uname -a | tr -d '\n' | sed 's/[^[:print:]]//g')\", \"start_time\": \"$(date -d @$START_TIME '+%Y-%m-%dT%H:%M:%S')\", \"user\": \"$(whoami | tr -d '\n' | sed 's/[^[:print:]]//g')\"},"
    json_data+="\"target\": {\"input\": \"$TARGET\", \"resolved_ipv4\": \"$TARGET_IPv4\", \"resolved_ipv6\": \"$TARGET_IPv6\", \"type\": \"$TYPE_TARGET\", \"protocol\": \"$(determinar_protocolo)\", \"resolution_time\": \"$(date +'%Y-%m-%dT%H:%M:%S')\"},"
    json_data+="\"tools_config\": {\"nmap\": {\"ipv4_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV4[@]}" | jq -R . | jq -s .), \"ipv6_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV6[@]}" | jq -R . | jq -s .), \"silence\": \"$NMAP_SILENCE\"}, \"ffuf\": {\"subdomain_commands\": $(printf '%s\n' "${FFUF_COMMANDS[@]}" | jq -R . | jq -s .), \"web_commands\": $(printf '%s\n' "${FFUF_WEB_COMMANDS[@]}" | jq -R . | jq -s .)}, \"attacksurfacemapper\": $(printf '%s\n' "${ASM_COMMANDS[@]}" | jq -R . | jq -s .), \"autorecon\": $(printf '%s\n' "${AR_COMMANDS[@]}" | jq -R . | jq -s .), \"gitleaks\": \"$GL_COMMAND\", \"sherlock\": \"$SH_COMMAND\", \"xray\": \"$XRAY_COMMAND\", \"fierce\": \"$FIERCE_COMMAND\", \"finalrecon\": \"$FR_COMMAND\", \"firewalk\": \"$FW_COMMAND\", \"clusterd\": \"$CL_COMMAND\"},"
    json_data+="\"dependencies\": {\"jq\": \"$(command -v jq &>/dev/null && jq --version | tr -d '\n' | sed 's/[^[:print:]]//g' || echo 'Não instalado')\", \"nmap\": \"$(command -v nmap &>/dev/null && nmap --version | head -1 | tr -d '\n' | sed 's/[^[:print:]]//g' || echo 'Não instalado')\", \"ffuf\": \"$(command -v ffuf &>/dev/null && ffuf --version | tr -d '\n' | sed 's/[^[:print:]]//g' || echo 'Não instalado')\", \"python3\": \"$(command -v python3 &>/dev/null && python3 --version | tr -d '\n' | sed 's/[^[:print:]]//g' || echo 'Não instalado')\", \"attacksurfacemapper\": \"$(python3 -m pip show attacksurfacemapper &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"autorecon\": \"$(command -v autorecon &>/dev/null && autorecon --version | tr -d '\n' | sed 's/[^[:print:]]//g' || echo 'Não instalado')\", \"gitleaks\": \"$(command -v gitleaks &>/dev/null && gitleaks --version | tr -d '\n' | sed 's/[^[:print:]]//g' || echo 'Não instalado')\", \"sherlock\": \"$(python3 -m pip show sherlock-project &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"xray\": \"$(command -v xray &>/dev/null && xray --version | tr -d '\n' | sed 's/[^[:print:]]//g' || echo 'Não instalado')\", \"fierce\": \"$(command -v fierce &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"finalrecon\": \"$(python3 -m pip show finalrecon &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"firewalk\": \"$(command -v firewalk &>/dev/null && firewalk --version | tr -d '\n' | sed 's/[^[:print:]]//g' || echo 'Não instalado')\", \"clusterd\": \"$(python3 -m pip show clusterd &>/dev/null && echo 'Instalado' || echo 'Não instalado')\"},"
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
            "Ping"|"Ping Personalizado")
                json_data+="\"command\": \"ping -c 4 $TARGET_IPv4\", \"packet_loss\": \"${packet_loss:-N/A}\", \"avg_latency\": \"${avg_latency:-N/A}\", \"ipv6_command\": \"ping6 -c 4 $TARGET_IPv6\"}"
                ;;
            "DNS"|"DNS Personalizado")
                json_data+="\"command\": \"dig $TARGET +short\", \"resolved_ips\": \"${ips:-N/A}\"}"
                ;;
            "Porta "*)
                json_data+="\"port\": \"$(echo $test_name | grep -oP '\d+')\", \"ipv4_command\": \"nc -zv -w 2 $TARGET_IPv4 $(echo $test_name | grep -oP '\d+')\", \"ipv6_command\": \"nc -zv -w 2 $TARGET_IPv6 $(echo $test_name | grep -oP '\d+')\", \"filtered_details\": \"${filtered_details:-N/A}\"}"
                ;;
            "Nmap"*)
                json_data+="\"command\": \"${nmap_cmd:-N/A}\", \"open_ports\": \"${open_ports:-N/A}\"}"
                ;;
            *) json_data+="\"command\": \"N/A\"}" ;;
        esac
        json_data+="}, \"raw_output_file\": \"$(echo $test_name | tr ' ' '_' | tr -d ':').txt\"},"
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    json_data="${json_data%,]}"
    json_data+="],\"statistics\": {\"total_tests\": ${#CHECKLIST[@]}, \"success_count\": $success_count, \"failure_count\": $failure_count, \"total_execution_time\": \"$(( $(date +%s) - START_TIME )) seconds\"}"
    json_data+="}"
    echo "$json_data" | jq '.' > "$JSON_FILE" 2>/dev/null || { print_status "error" "Falha ao salvar JSON"; return 1; }
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
        if [[ $TARGET =~ : ]]; then
            TARGET_IPv6="$TARGET"
            CHECKLIST+=("Alvo definido: ✓ $TARGET (IPv6)")
        else
            TARGET_IPv4="$TARGET"
            CHECKLIST+=("Alvo definido: ✓ $TARGET (IPv4)")
        fi
    fi
    salvar_json
}

test_ping() {
    local ip="$1" version="$2"
    local ping_cmd="ping -c 4 $ip" && [ "$version" = "IPv6" ] && ping_cmd="ping6 -c 4 $ip"
    print_status "action" "Testando PING $version"
    local ping_result=$($ping_cmd 2>&1)
    if [ $? -eq 0 ]; then
        packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
        avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1)
        CHECKLIST+=("Ping $version: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
    else
        CHECKLIST+=("Ping $version: ✗ Falha")
    fi
}

test_ports() {
    local ip="$1" version="$2" ports=("${@:3}")
    for port in "${ports[@]}"; do
        print_status "action" "Testando Porta $port ($version)"
        if nc -zv -w 2 "$ip" $port &>/dev/null; then
            CHECKLIST+=("Porta $port ($version): ✓ Aberta")
        else
            CHECKLIST+=("Porta $port ($version): ✗ Fechada")
        fi
    done
}

analyze_nmap_results() {
    local xml_file="$1" ip_version="$2"
    local -n port_status="PORT_STATUS_$ip_version"
    local -n port_tests="PORT_TESTS_$ip_version"
    local ports=($(grep -oP 'portid="\d+"' "$xml_file" | cut -d'"' -f2 | sort -u))
    for port in "${ports[@]}"; do
        state=$(grep -oP "portid=\"$port\".*state=\"\K[^\"]+(?=\")" "$xml_file" | head -1)
        port_status["$port"]+="$state,"
        port_tests["$port"]=$((port_tests["$port"] + 1))
    done
}

consolidar_portas() {
    local ip_version="$1"
    local -n port_status="PORT_STATUS_$ip_version"
    local -n port_tests="PORT_TESTS_$ip_version"
    for port in "${!port_status[@]}"; do
        local states=(${port_status[$port]//,/ })
        local open_count=0 closed_count=0 filtered_count=0
        for state in "${states[@]}"; do
            case "$state" in
                "open") ((open_count++)) ;;
                "closed") ((closed_count++)) ;;
                "filtered") ((filtered_count++)) ;;
            esac
        done
        local total_tests=${port_tests[$port]}
        local filtered_details="Testes: $total_tests, Abertas: $open_count, Fechadas: $closed_count, Filtradas: $filtered_count"
        if [ $open_count -eq $total_tests ]; then
            CHECKLIST+=("Porta $port ($ip_version): ✓ Aberta")
        elif [ $closed_count -eq $total_tests ]; then
            CHECKLIST+=("Porta $port ($ip_version): ✗ Fechada")
        else
            CHECKLIST+=("Porta $port ($ip_version): ⚠ Filtrada ($open_count aberta & $closed_count fechada & $filtered_count filtrada)")
        fi
    done
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
    if whois "$TARGET" &>/dev/null; then
        CHECKLIST+=("WHOIS: ✓ Informações obtidas")
    else
        CHECKLIST+=("WHOIS: ✗ Falha")
    fi
    CHECKLIST+=("DNS Histórico: ⚠ Simulado")
    CHECKLIST+=("Threat Intel: ⚠ Simulado")
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

Ativo_basico() {
    print_status "info" "Executando testes ATIVOS BÁSICOS em $TARGET"
    loading_clock "Testes Ativos Básicos" 3 &
    pid=$!
    [ -n "$TARGET_IPv4" ] && test_ping "$TARGET_IPv4" "IPv4"
    [ -n "$TARGET_IPv6" ] && test_ping "$TARGET_IPv6" "IPv6"
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
    loading_clock "Teste DNS" 3 &
    pid=$!
    local dns_result=$(dig "$TARGET" +short 2>&1)
    if [ -n "$dns_result" ]; then
        local ips=$(echo "$dns_result" | grep -oP '(\d+\.){3}\d+|[0-9a-fA-F:]+' | tr '\n' ',' | sed 's/,$//')
        CHECKLIST+=("DNS: ✓ Resolvido (IPs: $ips)")
    else
        CHECKLIST+=("DNS: ✗ Falha")
    fi
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
    loading_clock "Teste de Portas" 5 &
    pid=$!
    [ -n "$TARGET_IPv4" ] && test_ports "$TARGET_IPv4" "IPv4" 22 80 443
    [ -n "$TARGET_IPv6" ] && test_ports "$TARGET_IPv6" "IPv6" 22 80 443
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

Ativo_complexo() {
    print_status "info" "Executando testes ATIVOS COMPLEXOS em $TARGET"
    [ -z "$TARGET" ] && definir_alvo
    [ "$TYPE_TARGET" = "INVÁLIDO" ] && { print_status "error" "Alvo inválido"; return 1; }
    for cmd in nmap ffuf python3; do
        if ! command -v $cmd &>/dev/null; then
            CHECKLIST+=("$cmd: ✗ Não instalado")
            salvar_json
            return 1
        fi
    done
    python_version=$(python3 --version | grep -oP '\d+\.\d+\.\d+')
    python_major=$(echo $python_version | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d'.' -f2)
    if [ $python_major -lt 3 ] || { [ $python_major -eq 3 ] && [ $python_minor -lt 7 ]; }; then
        CHECKLIST+=("Python: ✗ Versão 3.7+ necessária")
        salvar_json
        return 1
    fi
    read -p "Deseja executar o Nmap em modo silencioso (-Pn)? (s/n): " ASK
    [ "$ASK" = "s" ] || [ "$ASK" = "S" ] && NMAP_SILENCE="-Pn"
    
    # Limpar arrays de portas antes de novas varreduras
    unset PORT_STATUS_IPV4 PORT_STATUS_IPV6 PORT_TESTS_IPV4 PORT_TESTS_IPV6
    declare -A PORT_STATUS_IPV4 PORT_STATUS_IPV6 PORT_TESTS_IPV4 PORT_TESTS_IPV6

    if [ -n "$TARGET_IPv4" ]; then
        print_status "action" "Executando varredura Nmap (IPv4)"
        for ((i=0; i<${#NMAP_COMMANDS_IPV4[@]}; i++)); do
            loading_clock "Teste Nmap IPv4 ($((i+1))/${#NMAP_COMMANDS_IPV4[@]})" 10 &
            pid=$!
            local nmap_output=$(mktemp)
            local nmap_cmd=$(substituir_variaveis "${NMAP_COMMANDS_IPV4[$i]}" "$TARGET_IPv4")
            print_status "info" "Comando: $nmap_cmd"
            if $nmap_cmd -oX "$nmap_output" &>/dev/null; then
                analyze_nmap_results "$nmap_output" "IPv4"
                CHECKLIST+=("Nmap IPv4 Teste $((i+1)): ✓ Concluído")
            else
                CHECKLIST+=("Nmap IPv4 Teste $((i+1)): ✗ Falha")
            fi
            rm -f "$nmap_output"
            kill -0 $pid 2>/dev/null && kill $pid
            wait $pid 2>/dev/null
        done
        consolidar_portas "IPv4"
        salvar_json
    fi
    if [ -n "$TARGET_IPv6" ]; then
        print_status "action" "Executando varredura Nmap (IPv6)"
        for ((i=0; i<${#NMAP_COMMANDS_IPV6[@]}; i++)); do
            loading_clock "Teste Nmap IPv6 ($((i+1))/${#NMAP_COMMANDS_IPV6[@]})" 10 &
            pid=$!
            local nmap_output=$(mktemp)
            local nmap_cmd=$(substituir_variaveis "${NMAP_COMMANDS_IPV6[$i]}" "$TARGET_IPv6")
            print_status "info" "Comando: $nmap_cmd"
            if $nmap_cmd -oX "$nmap_output" &>/dev/null; then
                analyze_nmap_results "$nmap_output" "IPv6"
                CHECKLIST+=("Nmap IPv6 Teste $((i+1)): ✓ Concluído")
            else
                CHECKLIST+=("Nmap IPv6 Teste $((i+1)): ✗ Falha")
            fi
            rm -f "$nmap_output"
            kill -0 $pid 2>/dev/null && kill $pid
            wait $pid 2>/dev/null
        done
        consolidar_portas "IPv6"
        salvar_json
    fi
    if [ "$TYPE_TARGET" = "DOMAIN" ] && { nc -zv -w 2 "$TARGET_IPv4" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; }; then
        for ((i=0; i<${#FFUF_WEB_COMMANDS[@]}; i++)); do
            read -p "Deseja executar FFuf Web Teste $((i+1)) para $TARGET? (s/n): " ASK
            if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
                testar_ferramenta "ffuf" "${FFUF_WEB_COMMANDS[$i]}" "Diretórios encontrados:" "Nenhum diretório encontrado"
                salvar_json
            fi
        done
    else
        CHECKLIST+=("FFuf Web: ✗ Portas HTTP/HTTPS não abertas")
        salvar_json
    fi
    for tool in "AutoRecon" "XRay" "Firewalk" "Clusterd"; do
        read -p "Deseja executar $tool para $TARGET? (s/n): " ASK
        if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
            case $tool in
                "AutoRecon") testar_ferramenta "autorecon" "${AR_COMMANDS[0]}" "Arquivos de resultado gerados:" "Nenhum resultado gerado" ;;
                "XRay") testar_ferramenta "xray" "$XRAY_COMMAND" "Vulnerabilidades encontradas:" "Nenhuma vulnerabilidade encontrada" ;;
                "Firewalk") testar_ferramenta "firewalk" "$FW_COMMAND" "Regras de firewall mapeadas:" "Nenhuma regra encontrada" ;;
                "Clusterd") testar_ferramenta "clusterd" "$CL_COMMAND" "Resultados encontrados:" "Nenhum resultado encontrado" ;;
            esac
            salvar_json
        fi
    done
}

#------------#------------# MENUS #------------#------------#
menu_personalizado() {
    while true; do
        clear
        print_status "info" "Menu de Ferramentas de Rede (PERSONALIZADO)"
        echo "1. Teste de Ping"
        echo "2. Teste DNS"
        echo "3. Teste de Portas"
        echo "4. Teste HTTP"
        echo "5. Teste WHOIS"
        echo "6. Teste Passivo Completo"
        echo "7. Teste Ativo Completo"
        echo "8. Voltar ao menu principal"
        read -p "Escolha uma opção (1-8): " OPCAO
        case $OPCAO in
            1)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                loading_clock "Teste de Ping" 3 &
                pid=$!
                [ -n "$TARGET_IPv4" ] && test_ping "$TARGET_IPv4" "IPv4"
                [ -n "$TARGET_IPv6" ] && test_ping "$TARGET_IPv6" "IPv6"
                kill -0 $pid 2>/dev/null && kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            2)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                loading_clock "Teste DNS" 3 &
                pid=$!
                if host "$TARGET" &>/dev/null; then
                    CHECKLIST+=("DNS Personalizado: ✓ Resolvido")
                else
                    CHECKLIST+=("DNS Personalizado: ✗ Falha")
                fi
                kill -0 $pid 2>/dev/null && kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            3)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                read -p "Digite as portas a testar (ex: 22,80,443): " PORTS
                IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
                loading_clock "Teste de Portas" 5 &
                pid=$!
                [ -n "$TARGET_IPv4" ] && test_ports "$TARGET_IPv4" "IPv4" "${PORT_ARRAY[@]}"
                [ -n "$TARGET_IPv6" ] && test_ports "$TARGET_IPv6" "IPv6" "${PORT_ARRAY[@]}"
                kill -0 $pid 2>/dev/null && kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            4)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                if [ "$TYPE_TARGET" = "DOMAIN" ]; then
                    local protocol=$(determinar_protocolo)
                    loading_clock "Teste HTTP ($protocol)" 3 &
                    pid=$!
                    http_code=$(curl -sI "$protocol://$TARGET" | head -1 | cut -d' ' -f2)
                    if [ -n "$http_code" ]; then
                        CHECKLIST+=("HTTP ($protocol): ✓ Código $http_code")
                    else
                        CHECKLIST+=("HTTP ($protocol): ✗ Falha")
                    fi
                    kill -0 $pid 2>/dev/null && kill $pid
                    wait $pid 2>/dev/null
                    salvar_json
                else
                    CHECKLIST+=("HTTP: ✗ Teste requer domínio")
                    salvar_json
                fi
                ;;
            5)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                loading_clock "Teste WHOIS" 3 &
                pid=$!
                if whois "$TARGET" &>/dev/null; then
                    CHECKLIST+=("WHOIS Personalizado: ✓ Informações obtidas")
                else
                    CHECKLIST+=("WHOIS Personalizado: ✗ Falha")
                fi
                kill -0 $pid 2>/dev/null && kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            6)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Passivo_basico
                Passivo_complexo
                ;;
            7)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Ativo_basico
                Ativo_complexo
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
        print_status "info" "MENU INICIAL"
        echo "1. PASSIVO + ATIVO"
        echo "2. ATIVO + PASSIVO"
        echo "3. PASSIVO"
        echo "4. ATIVO"
        echo "5. PERSONALIZADO"
        echo "6. SAIR"
        read -p "Escolha uma estratégia (1-6): " estrategia
        case $estrategia in
            1) definir_alvo; [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue; Passivo_basico; Passivo_complexo; Ativo_basico; Ativo_complexo ;;
            2) definir_alvo; [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue; Ativo_basico; Ativo_complexo; Passivo_basico; Passivo_complexo ;;
            3) definir_alvo; [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue; Passivo_basico; Passivo_complexo ;;
            4) definir_alvo; [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue; Ativo_basico; Ativo_complexo ;;
            5) menu_personalizado ;;
            6) print_status "info" "Saindo..."; exit 0 ;;
            *) print_status "error" "Opção inválida" ;;
        esac
    done
}

# Inicia o script
validar_root
menu_inicial