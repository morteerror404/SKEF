#!/bin/bash

# ativo.sh
# Função: Executar testes ativos (ping, portas, Nmap, FFUF, dig, traceroute, curl) e retornar resultados para autorecon.sh

# Exportar funções para uso em outros scripts
export -f determinar_protocolo

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
WORDLISTS_DIR="$HOME/wordlists"
declare -A PORT_STATUS_IPV4
declare -A PORT_STATUS_IPV6
declare -A PORT_TESTS_IPV4
declare -A PORT_TESTS_IPV6
RESULTS_DIR="results"

#------------#------------# VARIÁVEIS COMANDOS #------------#------------#
NMAP_COMMANDS_IPV4=(
    "nmap {TARGET_IP} -sT -vv -Pn"
    "nmap {TARGET_IP} -vv -O -Pn"
    "nmap {TARGET_IP} -sV -O -vv -Pn"
)
NMAP_COMMANDS_IPV6=(
    "nmap -6 {TARGET_IP} -sT -vv -Pn"
    "nmap -6 {TARGET_IP} -vv -O -Pn"
    "nmap -6 {TARGET_IP} -sV -O -vv -Pn"
)
FFUF_SUBDOMAIN=(
    "ffuf -u {URL}/ -H \"Host: FUZZ.{TARGET}\" -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -o $RESULTS_DIR/ffuf_subdomains.csv -of csv"
)
FFUF_DOMAINS=(
    "ffuf -u {URL}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -o $RESULTS_DIR/ffuf_web.csv -of csv"
)
FFUF_EXTENSIONS=(
    "ffuf -u {URL}/index.FUZZ -w $WORDLISTS_DIR/SecLists/Discovery/Web-Content/web-extensions.txt -mc 200,301,302 -o $RESULTS_DIR/ffuf_extensions.csv -of csv"
)

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
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
    local url="$protocol://$ip"
    echo "$cmd" | sed "s/{TARGET}/$TARGET/g; s/{TARGET_IP}/$ip/g; s/{URL}/$url/g; s|{WORDLIST_SUBDOMAINS}|$wordlist_subdomains|g; s|{WORDLIST_WEB}|$wordlist_web|g"
}

executar_comando() {
    local cmd="$1" name="$2" output_file="$3" success_msg="$4" fail_msg="$5"
    print_status "action" "Executando $name"
    local temp_output=$(mktemp)
    if $cmd >"$temp_output" 2>&1; then
        local results=$(wc -l < "$temp_output")
        [ "$results" -gt 0 ] && CHECKLIST+=("$name: ✓ $success_msg ($results linhas)") || CHECKLIST+=("$name: ✓ $fail_msg")
    else
        CHECKLIST+=("$name: ✗ Falha")
    fi
    mv "$temp_output" "$output_file" 2>>"$RESULTS_DIR/error.log"
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
        if [ $open_count -eq $total_tests ]; then
            CHECKLIST+=("Porta $port ($ip_version): ✓ Aberta")
        elif [ $closed_count -eq $total_tests ]; then
            CHECKLIST+=("Porta $port ($ip_version): ✗ Fechada")
        else
            CHECKLIST+=("Porta $port ($ip_version): ⚠ Filtrada ($open_count aberta, $closed_count fechada, $filtered_count filtrada)")
        fi
    done
}

#------------#------------# FUNÇÕES DE TESTE ATIVO #------------#------------#
test_ping() {
    local ip="$1" version="$2"
    local ping_cmd="ping -c 4 $ip" && [ "$version" = "IPv6" ] && ping_cmd="ping6 -c 4 $ip"
    print_status "action" "Testando PING $version"
    loading_clock "Testando PING $version" 3 &
    pid=$!
    local ping_result=$($ping_cmd 2>&1)
    if [ $? -eq 0 ]; then
        packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
        avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1)
        CHECKLIST+=("Ping $version: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
    else
        CHECKLIST+=("Ping $version: ✗ Falha")
    fi
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

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

test_ffuf_subdomains() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_SUBDOMAIN[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4")
            executar_comando "$cmd_substituido" "FFUF Subdomínios" "$RESULTS_DIR/ffuf_subdomains.csv" "Subdomínios encontrados" "Nenhum subdomínio encontrado"
        done
    else
        CHECKLIST+=("FFUF Subdomínios: ✗ Teste requer domínio")
    fi
}

test_ffuf_directories() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_DOMAINS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4")
            executar_comando "$cmd_substituido" "FFUF Web" "$RESULTS_DIR/ffuf_web.csv" "Recursos web encontrados" "Nenhum recurso web encontrado"
        done
    else
        CHECKLIST+=("FFUF Web: ✗ Teste requer domínio")
    fi
}

test_ffuf_extensions() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_EXTENSIONS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4")
            executar_comando "$cmd_substituido" "FFUF Extensões" "$RESULTS_DIR/ffuf_extensions.csv" "Extensões encontradas" "Nenhuma extensão encontrada"
        done
    else
        CHECKLIST+=("FFUF Extensões: ✗ Teste requer domínio")
    fi
}

Ativo_basico() {
    print_status "info" "Executando testes ATIVOS BÁSICOS em $TARGET"
    loading_clock "Testes Ativos Básicos" 3 &
    pid=$!
    [ -n "$TARGET_IPv4" ] && test_ping "$TARGET_IPv4" "IPv4"
    [ -n "$TARGET_IPv6" ] && test_ping "$TARGET_IPv6" "IPv6"
    [ -n "$TARGET_IPv4" ] && test_ports "$TARGET_IPv4" "IPv4" 22 80 443
    [ -n "$TARGET_IPv6" ] && test_ports "$TARGET_IPv6" "IPv6" 22 80 443
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_http
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

Ativo_complexo() {
    print_status "info" "Executando testes ATIVOS COMPLEXOS em $TARGET"
    mkdir -p "$RESULTS_DIR"
    if [ -n "$TARGET_IPv4" ]; then
        for cmd in "${NMAP_COMMANDS_IPV4[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4")
            local output_file="$RESULTS_DIR/nmap_ipv4_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv4" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            analyze_nmap_results "$output_file" "IPv4"
        done
        consolidar_portas "IPv4"
    fi
    if [ -n "$TARGET_IPv6" ]; then
        for cmd in "${NMAP_COMMANDS_IPV6[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv6")
            local output_file="$RESULTS_DIR/nmap_ipv6_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv6" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            analyze_nmap_results "$output_file" "IPv6"
        done
        consolidar_portas "IPv6"
    fi
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_subdomains
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_directories
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_extensions
}