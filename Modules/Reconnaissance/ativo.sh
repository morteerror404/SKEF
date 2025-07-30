#!/bin/bash

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
# Variáveis globais são definidas em autorecon.sh e acessadas aqui
WORDLISTS_DIR="$HOME/wordlists"
NMAP_SILENCE="-Pn"
declare -A PORT_STATUS_IPV4
declare -A PORT_STATUS_IPV6
declare -A PORT_TESTS_IPV4
declare -A PORT_TESTS_IPV6
RESULTS_DIR="results"

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
    "ffuf -u {URL}/ -H \"Host: FUZZ.{TARGET}\" -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -o $RESULTS_DIR/ffuf_output.csv -of csv"
)
FFUF_WEB_COMMANDS=(
    "ffuf -u {URL}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -o $RESULTS_DIR/ffuf_web_output.csv -of csv"
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
    echo "$cmd" | sed "s/{TARGET}/$TARGET/g; s/{TARGET_IP}/$ip/g; s/{PROTOCOL}/$protocol/g; s|{WORDLIST_SUBDOMAINS}|$wordlist_subdomains|g; s|{WORDLIST_WEB}|$wordlist_web|g"
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
            CHECKLIST+=("Porta $port ($ip_version): ⚠ Filtrada ($open_count aberta & $closed_count fechada & $filtered_count filtrada)")
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

test_ports() {
    local ip="$1" version="$2" ports=("${@:3}")
    for port in "${ports[@]}"; do
        print_status "action" "Testando Porta $port ($version)"
        loading_clock "Testando Porta $port ($version)" 2 &
        pid=$!
        if nc -zv -w 2 "$ip" $port &>/dev/null; then
            CHECKLIST+=("Porta $port ($version): ✓ Aberta")
        else
            CHECKLIST+=("Porta $port ($version): ✗ Fechada")
        fi
        kill -0 $pid 2>/dev/null && kill $pid
        wait $pid 2>/dev/null
    done
}

test_http() {
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
    else
        CHECKLIST+=("HTTP: ✗ Teste requer domínio")
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
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

Ativo_complexo() {
    print_status "info" "Executando testes ATIVOS COMPLEXOS em $TARGET"
    if [ -n "$TARGET_IPv4" ]; then
        for cmd in "${NMAP_COMMANDS_IPV4[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4")
            local output_file="$RESULTS_DIR/nmap_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv4" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            analyze_nmap_results "$output_file" "IPv4"
        done
        consolidar_portas "IPv4"
    fi
    if [ -n "$TARGET_IPv6" ]; then
        for cmd in "${NMAP_COMMANDS_IPV6[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv6")
            local output_file="$RESULTS_DIR/nmap_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv6" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            analyze_nmap_results "$output_file" "IPv6"
        done
        consolidar_portas "IPv6"
    fi
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4")
            executar_comando "$cmd_substituido" "FFUF Subdomínios" "$RESULTS_DIR/ffuf_output.csv" "Subdomínios encontrados" "Nenhum subdomínio encontrado"
        done
        for cmd in "${FFUF_WEB_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4")
            executar_comando "$cmd_substituido" "FFUF Web" "$RESULTS_DIR/ffuf_web_output.csv" "Recursos web encontrados" "Nenhum recurso web encontrado"
        done
    fi
}