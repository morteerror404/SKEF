#!/bin/bash

#------------#------------# GLOBAL VARIABLES #------------#------------#
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

# Tool Commands
NMAP_COMMANDS_IPV4=(
    "nmap {TARGET_IP} --top-ports 100 -T4 -v $NMAP_SILENCE"
    "nmap {TARGET_IP} -vv -O $NMAP_SILENCE"
    "nmap {TARGET_IP} -sT -O -vv $NMAP_SILENCE"
    "nmap {TARGET_IP} -sV -O -vv $NMAP_SILENCE"
    "nmap {TARGET_IP} -sA -sW -v -p- $NMAP_SILENCE"
)
NMAP_COMMANDS_IPV6=(
    "nmap -6 {TARGET_IP} --top-ports 100 -T4 -v $NMAP_SILENCE"
    "nmap -6 {TARGET_IP} -vv -O $NMAP_SILENCE"
    "nmap -6 {TARGET_IP} -sT -O -vv $NMAP_SILENCE"
    "nmap -6 {TARGET_IP} -sV -O -vv $NMAP_SILENCE"
    "nmap -6 {TARGET_IP} -sA -sW -v -p- $NMAP_SILENCE"
)
FFUF_COMMANDS=(
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w $WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt -mc 200,301,302 -o ffuf_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w $WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-20000.txt -mc 200,301,302 -fc 404 -o ffuf_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w $WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-20000.txt -mc 200,301,302 -t 50 -recursion -recursion-depth 1 -o ffuf_output.csv -of csv"
)
FFUF_WEB_COMMANDS=(
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w $WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt -mc 200,301,302 -o ffuf_web_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w $WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt -mc 200,301,302 -e .php,.txt,.html -o ffuf_web_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w $WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt -mc 200,301,302 -recursion -recursion-depth 2 -o ffuf_web_output.csv -of csv"
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
FIERCE_COMMAND="fierce --domain {TARGET} --subdomain-file $WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt --output fierce_output.txt"
FR_COMMAND="python3 -m finalrecon --full {PROTOCOL}://{TARGET} --out finalrecon_output.txt"
FW_COMMAND="firewalk -S1-1024 -i eth0 -n {TARGET_IP} -o firewalk_output.txt"
CL_COMMAND="python3 -m clusterd -t {TARGET} -o clusterd_output.txt"

#------------#------------# HELPER FUNCTIONS #------------#------------#
print_status() {
    local color="$1" message="$2"
    case "$color" in
        "info") echo -e "\033[1;34m[+] $message\033[0m" ;;
        "action") echo -e "\033[1;33m[▶] $message\033[0m" ;;
        "success") echo -e "\033[1;32m[✔] $message\033[0m" ;;
        "error") echo -e "\033[1;31m[✗] $message\033[0m" ;;
    esac
}

loading_clock() {
    local task="$1" duration="$2"
    local chars="/-\|"
    local i=0
    while [ $i -lt $((duration*4)) ]; do
        printf "\r$task [${chars:$((i%4)):1}]"
        sleep 0.25
        ((i++))
    done
    printf "\r%-*s\r" 50 ""
}

verificar_tipo_alvo() {
    local entrada="$1"
    entrada=$(echo "$entrada" | sed -E 's|^https?://||; s|/.*$||; s|:[0-9]+$||')
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

salvar_json() {
    local json_data="{"
    json_data+="\"script\": {\"name\": \"Network Recon Script\", \"version\": \"1.2.0\", \"os\": \"$(uname -a)\", \"start_time\": \"$(date -d @$START_TIME '+%Y-%m-%dT%H:%M:%S')\", \"user\": \"$(whoami)\"},"
    json_data+="\"target\": {\"input\": \"$TARGET\", \"resolved_ipv4\": \"$TARGET_IPv4\", \"resolved_ipv6\": \"$TARGET_IPv6\", \"type\": \"$TYPE_TARGET\", \"protocol\": \"$(nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null && echo 'https' || echo 'http')\", \"resolution_time\": \"$(date +'%Y-%m-%dT%H:%M:%S')\"},"
    json_data+="\"tools_config\": {\"nmap\": {\"ipv4_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV4[@]}" | jq -R . | jq -s .), \"ipv6_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV6[@]}" | jq -R . | jq -s .), \"silence\": \"$NMAP_SILENCE\"}, \"ffuf\": {\"subdomain_commands\": $(printf '%s\n' "${FFUF_COMMANDS[@]}" | jq -R . | jq -s .), \"web_commands\": $(printf '%s\n' "${FFUF_WEB_COMMANDS[@]}" | jq -R . | jq -s .)}, \"attacksurfacemapper\": $(printf '%s\n' "${ASM_COMMANDS[@]}" | jq -R . | jq -s .), \"autorecon\": $(printf '%s\n' "${AR_COMMANDS[@]}" | jq -R . | jq -s .), \"gitleaks\": \"$GL_COMMAND\", \"sherlock\": \"$SH_COMMAND\", \"xray\": \"$XRAY_COMMAND\", \"fierce\": \"$FIERCE_COMMAND\", \"finalrecon\": \"$FR_COMMAND\", \"firewalk\": \"$FW_COMMAND\", \"clusterd\": \"$CL_COMMAND\"},"
    json_data+="\"dependencies\": {\"jq\": \"$(command -v jq &>/dev/null && jq --version || echo 'Não instalado')\", \"nmap\": \"$(command -v nmap &>/dev/null && nmap --version | head -1 || echo 'Não instalado')\", \"ffuf\": \"$(command -v ffuf &>/dev/null && ffuf --version || echo 'Não instalado')\", \"python3\": \"$(command -v python3 &>/dev/null && python3 --version || echo 'Não instalado')\", \"attacksurfacemapper\": \"$(python3 -m pip show attacksurfacemapper &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"autorecon\": \"$(command -v autorecon &>/dev/null && autorecon --version || echo 'Não instalado')\", \"gitleaks\": \"$(command -v gitleaks &>/dev/null && gitleaks --version || echo 'Não instalado')\", \"sherlock\": \"$(python3 -m pip show sherlock-project &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"xray\": \"$(command -v xray &>/dev/null && xray --version || echo 'Não instalado')\", \"fierce\": \"$(command -v fierce &>/dev/null && fierce --version || echo 'Não instalado')\", \"finalrecon\": \"$(python3 -m pip show finalrecon &>/dev/null && echo 'Instalado' || echo 'Não instalado')\", \"firewalk\": \"$(command -v firewalk &>/dev/null && firewalk --version || echo 'Não instalado')\", \"clusterd\": \"$(python3 -m pip show clusterd &>/dev/null && echo 'Instalado' || echo 'Não instalado')\"},"
    json_data+="\"tests\": ["
    local success_count=0 failure_count=0
    for item in "${CHECKLIST[@]}"; do
        IFS=':' read -ra parts <<< "$item"
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
                json_data+="\"port\": \"$(echo $test_name | grep -oP '\d+')\", \"ipv4_command\": \"nc -zv -w 2 $TARGET_IPv4 $(echo $test_name | grep -oP '\d+')\", \"ipv6_command\": \"nc -zv -w 2 $TARGET_IPv6 $(echo $test_name | grep -oP '\d+')\"}"
                ;;
            "Nmap Avançado")
                json_data+="\"command\": \"$nmap_cmd\", \"open_ports\": \"${open_ports:-N/A}\"}"
                ;;
            *) json_data+="\"command\": \"N/A\"}" ;;
        esac
        json_data+="},"
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    json_data="${json_data%,}]"
    json_data+="],\"statistics\": {\"total_tests\": ${#CHECKLIST[@]}, \"success_count\": $success_count, \"failure_count\": $failure_count, \"total_execution_time\": \"$(( $(date +%s) - START_TIME )) seconds\"}"
    json_data+="}"
    echo "$json_data" | jq '.' > "$JSON_FILE"
    print_status "success" "Resultados salvos em $JSON_FILE"
}

#------------#------------# TEST FUNCTIONS #------------#------------#
test_ping() {
    local ip="$1" version="$2"
    local ping_cmd="ping -c 4 $ip" && [ "$version" = "IPv6" ] && ping_cmd="ping6 -c 4 $ip"
    print_status "action" "Testando PING $version"
    local ping_result=$($ping_cmd 2>&1)
    if [ $? -eq 0 ]; then
        local packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
        local avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1)
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
    declare -n port_map="port_status_$ip_version"
    declare -n test_map="port_tests_$ip_version"
    while read -r line; do
        port=$(echo "$line" | grep -oP 'portid="\K\d+')
        state=$(echo "$line" | grep -oP 'state="\K[^"]+')
        port_map["$port"]="$state"
        ((test_map["$port"]++))
    done < <(grep -oP '<port protocol="tcp".*?>.*?</port>' "$xml_file" | tr -d '\n' | sed 's/<\/port>/\n/g')
}

generate_port_report() {
    local ip_version="$1"
    declare -n port_map="port_status_$ip_version"
    declare -n test_map="port_tests_$ip_version"
    for port in "${!port_map[@]}"; do
        local state="${port_map[$port]}"
        local test_count="${test_map[$port]:-0}"
        local open_count=0 closed_count=0
        if [ "$state" = "open" ]; then
            ((open_count++))
        else
            ((closed_count++))
        fi
        if [ "$open_count" -gt 0 ] && [ "$closed_count" -gt 0 ]; then
            CHECKLIST+=("Porta $port ($ip_version): ⚠ Filtrada ($open_count aberta & $closed_count fechada)")
        elif [ "$open_count" -gt 0 ]; then
            CHECKLIST+=("Porta $port ($ip_version): ✓ Aberta (confirmada)")
        else
            CHECKLIST+=("Porta $port ($ip_version): ✗ Fechada (confirmada)")
        fi
    done
}

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
    kill $pid
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

    local protocol="http"
    { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
    local wordlist="$WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
    [ ! -f "$wordlist" ] && { wordlist="/tmp/subdomains.txt"; curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o "$wordlist"; }

    for tool in "AttackSurfaceMapper" "FFuf Subdomains" "Gitleaks" "Sherlock" "Fierce" "FinalRecon"; do
        read -p "Deseja executar $tool para $TARGET? (s/n): " ASK
        if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
            case $tool in
                "AttackSurfaceMapper")
                    if ! python3 -m pip show attacksurfacemapper &>/dev/null; then
                        CHECKLIST+=("AttackSurfaceMapper: ✗ Não instalado")
                    else
                        loading_clock "AttackSurfaceMapper (Subdomínios)" 15 &
                        pid=$!
                        local asm_output=$(mktemp)
                        local asm_cmd=$(echo "${ASM_COMMANDS[0]}" | sed "s/{TARGET}/$TARGET/g")
                        if $asm_cmd &>/dev/null; then
                            local asm_results=$(grep -oP 'Found \d+ subdomains' "$asm_output" | grep -oP '\d+')
                            [ -n "$asm_results" ] && CHECKLIST+=("AttackSurfaceMapper: ✓ $asm_results subdomínios encontrados") || CHECKLIST+=("AttackSurfaceMapper: ✗ Nenhum subdomínio encontrado")
                        else
                            CHECKLIST+=("AttackSurfaceMapper: ✗ Falha")
                        fi
                        rm -f "$asm_output"
                        kill $pid
                        wait $pid 2>/dev/null
                    fi
                    ;;
                "FFuf Subdomains")
                    if ! command -v ffuf &>/dev/null; then
                        CHECKLIST+=("FFuf: ✗ Não instalado")
                    else
                        loading_clock "FFuf (Brute Force de Subdomínios)" 10 &
                        pid=$!
                        local ffuf_output=$(mktemp)
                        local ffuf_cmd=$(echo "${FFUF_COMMANDS[0]}" | sed "s/{TARGET}/$TARGET/g; s/{PROTOCOL}/$protocol/g")
                        if $ffuf_cmd &>/dev/null; then
                            local found_subdomains=$(awk -F',' 'NR>1 {print $2}' "$ffuf_output" | tr '\n' ',' | sed 's/,$//')
                            [ -n "$found_subdomains" ] && CHECKLIST+=("FFuf Subdomínios: ✓ Subdomínios encontrados: $found_subdomains") || CHECKLIST+=("FFuf Subdomínios: ✗ Nenhum subdomínio encontrado")
                        else
                            CHECKLIST+=("FFuf Subdomínios: ✗ Falha")
                        fi
                        rm -f "$ffuf_output"
                        [ "$wordlist" = "/tmp/subdomains.txt" ] && rm -f "$wordlist"
                        kill $pid
                        wait $pid 2>/dev/null
                    fi
                    ;;
                "Gitleaks")
                    if ! command -v gitleaks &>/dev/null; then
                        CHECKLIST+=("Gitleaks: ✗ Não instalado")
                    else
                        loading_clock "Gitleaks (Detecção de Vazamentos)" 10 &
                        pid=$!
                        local gl_output=$(mktemp)
                        local gl_cmd=$(echo "$GL_COMMAND" | sed "s/{TARGET}/$TARGET/g")
                        if $gl_cmd &>/dev/null; then
                            local gl_results=$(jq '. | length' "$gl_output" 2>/dev/null || echo 0)
                            [ "$gl_results" -gt 0 ] && CHECKLIST+=("Gitleaks: ✓ $gl_results vazamentos encontrados") || CHECKLIST+=("Gitleaks: ✓ Nenhum vazamento encontrado")
                        else
                            CHECKLIST+=("Gitleaks: ✗ Falha")
                        fi
                        rm -f "$gl_output"
                        kill $pid
                        wait $pid 2>/dev/null
                    fi
                    ;;
                "Sherlock")
                    if ! python3 -m pip show sherlock-project &>/dev/null; then
                        CHECKLIST+=("Sherlock: ✗ Não instalado")
                    else
                        loading_clock "Sherlock (OSINT)" 15 &
                        pid=$!
                        local sh_output=$(mktemp)
                        local sh_cmd=$(echo "$SH_COMMAND" | sed "s/{TARGET}/$TARGET/g")
                        if $sh_cmd &>/dev/null; then
                            local sh_results=$(wc -l < "$sh_output")
                            [ "$sh_results" -gt 0 ] && CHECKLIST+=("Sherlock: ✓ $sh_results perfis encontrados") || CHECKLIST+=("Sherlock: ✓ Nenhum perfil encontrado")
                        else
                            CHECKLIST+=("Sherlock: ✗ Falha")
                        fi
                        rm -f "$sh_output"
                        kill $pid
                        wait $pid 2>/dev/null
                    fi
                    ;;
                "Fierce")
                    if ! command -v fierce &>/dev/null; then
                        CHECKLIST+=("Fierce: ✗ Não instalado")
                    else
                        loading_clock "Fierce (Subdomínios)" 10 &
                        pid=$!
                        local fierce_output=$(mktemp)
                        local fierce_cmd=$(echo "$FIERCE_COMMAND" | sed "s/{TARGET}/$TARGET/g")
                        if $fierce_cmd &>/dev/null; then
                            local fierce_results=$(grep -oP 'Found:.*$' "$fierce_output" | wc -l)
                            [ "$fierce_results" -gt 0 ] && CHECKLIST+=("Fierce: ✓ $fierce_results subdomínios encontrados") || CHECKLIST+=("Fierce: ✓ Nenhum subdomínio encontrado")
                        else
                            CHECKLIST+=("Fierce: ✗ Falha")
                        fi
                        rm -f "$fierce_output"
                        [ "$wordlist" = "/tmp/subdomains.txt" ] && rm -f "$wordlist"
                        kill $pid
                        wait $pid 2>/dev/null
                    fi
                    ;;
                "FinalRecon")
                    if ! python3 -m pip show finalrecon &>/dev/null; then
                        CHECKLIST+=("FinalRecon: ✗ Não instalado")
                    else
                        loading_clock "FinalRecon (OSINT)" 15 &
                        pid=$!
                        local fr_output=$(mktemp)
                        local fr_cmd=$(echo "$FR_COMMAND" | sed "s/{TARGET}/$TARGET/g; s/{PROTOCOL}/$protocol/g")
                        if $fr_cmd &>/dev/null; then
                            local fr_results=$(wc -l < "$fr_output")
                            [ "$fr_results" -gt 0 ] && CHECKLIST+=("FinalRecon: ✓ $fr_results linhas de resultados") || CHECKLIST+=("FinalRecon: ✓ Nenhum resultado encontrado")
                        else
                            CHECKLIST+=("FinalRecon: ✗ Falha")
                        fi
                        rm -f "$fr_output"
                        kill $pid
                        wait $pid 2>/dev/null
                    fi
                    ;;
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
    kill $pid
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
    kill $pid
    wait $pid 2>/dev/null

    loading_clock "Teste de Portas" 5 &
    pid=$!
    [ -n "$TARGET_IPv4" ] && test_ports "$TARGET_IPv4" "IPv4" 22 80 443
    [ -n "$TARGET_IPv6" ] && test_ports "$TARGET_IPv6" "IPv6" 22 80 443
    kill $pid
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

    declare -A port_status_ipv4 port_status_ipv6 port_tests_ipv4 port_tests_ipv6
    if [ -n "$TARGET_IPv4" ]; then
        print_status "action" "Executando varredura Nmap (IPv4)"
        for ((i=0; i<${#NMAP_COMMANDS_IPV4[@]}; i++)); do
            loading_clock "Teste Nmap IPv4 ($((i+1))/${#NMAP_COMMANDS_IPV4[@]})" 10 &
            pid=$!
            local nmap_output=$(mktemp)
            local nmap_cmd=$(echo "${NMAP_COMMANDS_IPV4[$i]}" | sed "s/{TARGET_IP}/$TARGET_IPv4/g")
            print_status "info" "Comando: $nmap_cmd"
            if $nmap_cmd -oX "$nmap_output" &>/dev/null; then
                analyze_nmap_results "$nmap_output" "ipv4"
                CHECKLIST+=("Nmap IPv4 Teste $((i+1)): ✓ Concluído")
            else
                CHECKLIST+=("Nmap IPv4 Teste $((i+1)): ✗ Falha")
            fi
            rm -f "$nmap_output"
            kill $pid
            wait $pid 2>/dev/null
        done
        generate_port_report "ipv4"
        salvar_json
    fi

    if [ -n "$TARGET_IPv6" ]; then
        print_status "action" "Executando varredura Nmap (IPv6)"
        for ((i=0; i<${#NMAP_COMMANDS_IPV6[@]}; i++)); do
            loading_clock "Teste Nmap IPv6 ($((i+1))/${#NMAP_COMMANDS_IPV6[@]})" 10 &
            pid=$!
            local nmap_output=$(mktemp)
            local nmap_cmd=$(echo "${NMAP_COMMANDS_IPV6[$i]}" | sed "s/{TARGET_IP}/$TARGET_IPv6/g")
            print_status "info" "Comando: $nmap_cmd"
            if $nmap_cmd -oX "$nmap_output" &>/dev/null; then
                analyze_nmap_results "$nmap_output" "ipv6"
                CHECKLIST+=("Nmap IPv6 Teste $((i+1)): ✓ Concluído")
            else
                CHECKLIST+=("Nmap IPv6 Teste $((i+1)): ✗ Falha")
            fi
            rm -f "$nmap_output"
            kill $pid
            wait $pid 2>/dev/null
        done
        generate_port_report "ipv6"
        salvar_json
    fi

    local protocol="http"
    { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
    local wordlist="$WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt"
    [ ! -f "$wordlist" ] && { wordlist="/tmp/common.txt"; curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o "$wordlist"; }

    if [ "$TYPE_TARGET" = "DOMAIN" ] && { nc -zv -w 2 "$TARGET_IPv4" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; }; then
        for ((i=0; i<${#FFUF_WEB_COMMANDS[@]}; i++)); do
            read -p "Deseja executar FFuf Web Teste $((i+1)) para $TARGET? (s/n): " ASK
            if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
                loading_clock "FFuf Fuzzing Web ($protocol, Teste $((i+1)))" 10 &
                pid=$!
                local ffuf_output=$(mktemp)
                local ffuf_cmd=$(echo "${FFUF_WEB_COMMANDS[$i]}" | sed "s/{TARGET}/$TARGET/g; s/{PROTOCOL}/$protocol/g")
                if $ffuf_cmd &>/dev/null; then
                    local found_dirs=$(awk -F',' 'NR>1 {print $2}' "$ffuf_output" | tr '\n' ',' | sed 's/,$//')
                    [ -n "$found_dirs" ] && CHECKLIST+=("FFuf Web Teste $((i+1)): ✓ Diretórios encontrados: $found_dirs") || CHECKLIST+=("FFuf Web Teste $((i+1)): ✗ Nenhum diretório encontrado")
                else
                    CHECKLIST+=("FFuf Web Teste $((i+1)): ✗ Falha")
                fi
                rm -f "$ffuf_output"
                [ "$wordlist" = "/tmp/common.txt" ] && rm -f "$wordlist"
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
            fi
        done
    else
        CHECKLIST+=("FFuf Web: ✗ Portas HTTP/HTTPS não abertas")
        salvar_json
    fi

    for tool in "AutoRecon" "XRay"; do
        read -p "Deseja executar $tool para $TARGET? (s/n): " ASK
        if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
            case $tool in
                "AutoRecon")
                    if ! command -v autorecon &>/dev/null; then
                        CHECKLIST+=("AutoRecon: ✗ Não instalado")
                    else
                        loading_clock "AutoRecon" 20 &
                        pid=$!
                        local autorecon_output_dir=$(mktemp -d)
                        local ar_cmd=""
                        if [ -n "$TARGET_IPv4" ]; then
                            ar_cmd=$(echo "${AR_COMMANDS[0]}" | sed "s/{TARGET_IP}/$TARGET_IPv4/g")
                        elif [ -n "$TARGET_IPv6" ]; then
                            ar_cmd=$(echo "${AR_COMMANDS[0]}" | sed "s/{TARGET_IP}/$TARGET_IPv6/g")
                        fi
                        if $ar_cmd &>/dev/null; then
                            local autorecon_results=$(find "$autorecon_output_dir" -type f | wc -l)
                            CHECKLIST+=("AutoRecon: ✓ $autorecon_results arquivos de resultado gerados")
                        else
                            CHECKLIST+=("AutoRecon: ✗ Falha")
                        fi
                        rm -rf "$autorecon_output_dir"
                        kill $pid
                        wait $pid 2>/dev/null
                    fi
                    ;;
                "XRay")
                    if ! command -v xray &>/dev/null; then
                        CHECKLIST+=("XRay: ✗ Não instalado")
                    elif [ "$TYPE_TARGET" = "DOMAIN" ] && { nc -zv -w 2 "$TARGET_IPv4" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; }; then
                        loading_clock "XRay (Varredura de Vulnerabilidades)" 15 &
                        pid=$!
                        local xray_output=$(mktemp)
                        local xray_cmd=$(echo "$XRAY_COMMAND" | sed "s/{TARGET}/$TARGET/g; s/{PROTOCOL}/$protocol/g")
                        if $xray_cmd &>/dev/null; then
                            local xray_results=$(jq '. | length' "$xray_output" 2>/dev/null || echo 0)
                            [ "$xray_results" -gt 0 ] && CHECKLIST+=("XRay: ✓ $xray_results vulnerabilidades encontradas") || CHECKLIST+=("XRay: ✓ Nenhuma vulnerabilidade encontrada")
                        else
                            CHECKLIST+=("XRay: ✗ Falha")
                        fi
                        rm -f "$xray_output"
                        kill $pid
                        wait $pid 2>/dev/null
                    else
                        CHECKLIST+=("XRay: ✗ Portas HTTP/HTTPS não abertas")
                    fi
                    ;;
            esac
            salvar_json
        fi
    done
}

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
                kill $pid
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
                kill $pid
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
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            4)
                [ -z "$TARGET" ] && definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                if [ "$TYPE_TARGET" = "DOMAIN" ]; then
                    local protocol="http"
                    { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
                    loading_clock "Teste HTTP ($protocol)" 3 &
                    pid=$!
                    http_code=$(curl -sI "$protocol://$TARGET" | head -1 | cut -d' ' -f2)
                    if [ -n "$http_code" ]; then
                        CHECKLIST+=("HTTP ($protocol): ✓ Código $http_code")
                    else
                        CHECKLIST+=("HTTP ($protocol): ✗ Falha")
                    fi
                    kill $pid
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
                kill $pid
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

# Start the script
menu_inicial