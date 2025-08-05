#!/bin/bash

# ativo.sh
# Função: Executar testes ativos (ping, portas, Nmap, FFUF) e retornar resultados para autorecon.sh
# Dependências: utils.sh

source "$(dirname "$0")/utils.sh"
export -f determinar_protocolo

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
WORDLISTS_DIR="/home/wordlists/SecLists"
WORDLISTS_EXT="$WORDLISTS_DIR/Discovery/Web-Content/web-extensions.txt"
WORDLIST_SUBDOMAINS="$WORDLISTS_DIR/Discovery/DNS/subdomains-top1million-110000.txt"
WORDLIST_WEB="$WORDLISTS_DIR/Discovery/Web-Content/directory-list-lowercase-2.3-big.txt"
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
FFUF_COMMANDS=(
    "ffuf -u {URL}/ -H Host: FUZZ.{DOMINIO} -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -fc 404 -timeout 10 -o $RESULTS_DIR/ffuf_subdomains.csv -of csv"
)
FFUF_WEB_COMMANDS=(
    "ffuf -u {URL}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -recursion -recursion-depth 3 -fc 404 -timeout 10 -o $RESULTS_DIR/ffuf_web.csv -of csv"
)
FFUF_EXT_COMMANDS=(
    "ffuf -u {URL}/index.FUZZ -w {WORDLISTS_EXT} -mc 200,301,302 -timeout 10 -fc 404 -o $RESULTS_DIR/ffuf_extensions.csv -of csv"
)

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
determinar_protocolo() {
    local protocol="http"
    if ! command -v nc &>/dev/null; then
        print_status "error" "Netcat (nc) não encontrado, tentando curl como fallback"
        if curl -s --connect-timeout 2 "$TARGET:443" >/dev/null 2>&1; then
            protocol="https"
        fi
    else
        { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
    fi
    echo "$protocol"
}

substituir_variaveis() {
    local cmd="$1" ip="$2"
    local wordlist_subdomains="$WORDLISTS_DIR/Discovery/DNS/subdomains-top1million-5000.txt"
    local wordlist_web="$WORDLISTS_DIR/Discovery/Web-Content/common.txt"
    [ ! -f "$wordlist_subdomains" ] && { 
        wordlist_subdomains="/tmp/subdomains.txt"
        curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o "$wordlist_subdomains" || {
            print_status "error" "Falha ao baixar wordlist de subdomínios"
            return 1
        }
    }
    [ ! -f "$wordlist_web" ] && { 
        wordlist_web="/tmp/common.txt"
        curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o "$wordlist_web" || {
            print_status "error" "Falha ao baixar wordlist web"
            return 1
        }
    }
    local protocol=$(determinar_protocolo)
    local url="$protocol://$ip"
    # Sanitizar variáveis usando printf para escapar caracteres especiais
    local safe_target=$(printf '%q' "$TARGET")
    local safe_ip=$(printf '%q' "$ip")
    local safe_url=$(printf '%q' "$url")
    local safe_wordlist_subdomains=$(printf '%q' "$wordlist_subdomains")
    local safe_wordlist_web=$(printf '%q' "$wordlist_web")
    local safe_url_dominio=$(printf '%q' "${URL_DOMINIO:-$TARGET}")
    # Usar delimitador alternativo (#) para evitar conflitos com / ou :
    echo "$cmd" | sed \
        -e "s#{DOMINIO}#$safe_url_dominio#g" \
        -e "s#{TARGET_IP}#$safe_ip#g" \
        -e "s#{URL}#$safe_url#g" \
        -e "s#{WORDLIST_SUBDOMAINS}#$safe_wordlist_subdomains#g" \
        -e "s#{WORDLIST_WEB}#$safe_wordlist_web#g"
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
    if [ ! -f "$xml_file" ]; then
        print_status "error" "Arquivo $xml_file não encontrado"
        return 1
    fi
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
        local total_tests=${port_tests["$port"]}
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
        packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)' || echo "0")
        avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1 || echo "N/A")
        CHECKLIST+=("Ping $version: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
    else
        CHECKLIST+=("Ping $version: ✗ Falha")
    fi
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

test_http() {
    if [ "$TYPE_TARGET" != "DOMAIN" ]; then
        CHECKLIST+=("HTTP: ✗ Teste requer domínio")
        return
    fi
    print_status "action" "Testando HTTP"
    local protocol=$(determinar_protocolo)
    local output_file="$RESULTS_DIR/http_test.txt"
    # Usar -I para pegar apenas headers
    if curl -sI -o "$output_file" -w "%{http_code}" "$protocol://$TARGET" | grep -qE '200|301|302'; then
        CHECKLIST+=("HTTP ($protocol): ✓ Servidor ativo")
    else
        CHECKLIST+=("HTTP ($protocol): ✗ Servidor inativo ou erro")
    fi
    # Limitar o conteúdo do arquivo apenas aos headers
    sed -i '/^\r$/q' "$output_file"  # Remove o corpo da resposta se houver
}

test_ffuf_subdomains() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || return 1
            executar_comando "$cmd_substituido" "FFUF Subdomínios" "$RESULTS_DIR/ffuf_subdomains.csv" "Subdomínios encontrados" "Nenhum subdomínio encontrado"
        done
    else
        CHECKLIST+=("FFUF Subdomínios: ✗ Teste requer domínio")
    fi
}

test_ffuf_directories() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        local protocol=$(determinar_protocolo)
        local target_url="$protocol://$TARGET"
        for cmd in "${FFUF_WEB_COMMANDS[@]}"; do
            local cmd_substituido=$(echo "$cmd" | sed "s|{URL}|$target_url|g")
            executar_comando "$cmd_substituido" "FFUF Web" "$RESULTS_DIR/ffuf_web.csv" "Recursos web encontrados" "Nenhum recurso web encontrado"
        done
    else
        CHECKLIST+=("FFUF Web: ✗ Teste requer domínio")
    fi
}

test_ffuf_extensions() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_EXT_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || return 1
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
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_http
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

Ativo_complexo() {
    print_status "info" "Executando testes ATIVOS COMPLEXOS em $TARGET"
    mkdir -p "$RESULTS_DIR"
    if [ -n "$TARGET_IPv4" ]; then
        for cmd in "${NMAP_COMMANDS_IPV4[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || {
                print_status "error" "Falha ao substituir variáveis no comando Nmap IPv4: $cmd"
                CHECKLIST+=("Nmap IPv4: ✗ Falha na substituição de variáveis")
                continue
            }
            local output_file="$RESULTS_DIR/nmap_ipv4_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv4" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            [ -f "$output_file" ] && analyze_nmap_results "$output_file" "IPv4"
        done
        consolidar_portas "IPv4"
    fi
    if [ -n "$TARGET_IPv6" ]; then
        for cmd in "${NMAP_COMMANDS_IPV6[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv6") || {
                print_status "error" "Falha ao substituir variáveis no comando Nmap IPv6: $cmd"
                CHECKLIST+=("Nmap IPv6: ✗ Falha na substituição de variáveis")
                continue
            }
            local output_file="$RESULTS_DIR/nmap_ipv6_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv6" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            [ -f "$output_file" ] && analyze_nmap_results "$output_file" "IPv6"
        done
        consolidar_portas "IPv6"
    fi
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_subdomains
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_directories
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_extensions
}#!/bin/bash

# ativo.sh
# Função: Executar testes ativos (ping, portas, Nmap, FFUF) e retornar resultados para autorecon.sh
# Dependências: utils.sh

source "$(dirname "$0")/utils.sh"
export -f determinar_protocolo

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
WORDLISTS_DIR="/home/wordlists/SecLists"
WORDLISTS_EXT="$WORDLISTS_DIR/Discovery/Web-Content/web-extensions.txt"
WORDLIST_SUBDOMAINS="$WORDLISTS_DIR/Discovery/DNS/subdomains-top1million-110000.txt"
WORDLIST_WEB="$WORDLISTS_DIR/Discovery/Web-Content/directory-list-lowercase-2.3-big.txt"
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
FFUF_COMMANDS=(
    "ffuf -u {URL}/ -H Host: FUZZ.{DOMINIO} -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -fc 404 -timeout 10 -o $RESULTS_DIR/ffuf_subdomains.csv -of csv"
)
FFUF_WEB_COMMANDS=(
    "ffuf -u {URL}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -recursion -recursion-depth 3 -fc 404 -timeout 10 -o $RESULTS_DIR/ffuf_web.csv -of csv"
)
FFUF_EXT_COMMANDS=(
    "ffuf -u {URL}/index.FUZZ -w {WORDLISTS_EXT} -mc 200,301,302 -timeout 10 -fc 404 -o $RESULTS_DIR/ffuf_extensions.csv -of csv"
)

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
determinar_protocolo() {
    local protocol="http"
    if ! command -v nc &>/dev/null; then
        print_status "error" "Netcat (nc) não encontrado, tentando curl como fallback"
        if curl -s --connect-timeout 2 "$TARGET:443" >/dev/null 2>&1; then
            protocol="https"
        fi
    else
        { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
    fi
    echo "$protocol"
}

substituir_variaveis() {
    local cmd="$1" ip="$2"
    local wordlist_subdomains="$WORDLISTS_DIR/Discovery/DNS/subdomains-top1million-5000.txt"
    local wordlist_web="$WORDLISTS_DIR/Discovery/Web-Content/common.txt"
    [ ! -f "$wordlist_subdomains" ] && { 
        wordlist_subdomains="/tmp/subdomains.txt"
        curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o "$wordlist_subdomains" || {
            print_status "error" "Falha ao baixar wordlist de subdomínios"
            return 1
        }
    }
    [ ! -f "$wordlist_web" ] && { 
        wordlist_web="/tmp/common.txt"
        curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o "$wordlist_web" || {
            print_status "error" "Falha ao baixar wordlist web"
            return 1
        }
    }
    local protocol=$(determinar_protocolo)
    local url="$protocol://$ip"
    # Sanitizar variáveis usando printf para escapar caracteres especiais
    local safe_target=$(printf '%q' "$TARGET")
    local safe_ip=$(printf '%q' "$ip")
    local safe_url=$(printf '%q' "$url")
    local safe_wordlist_subdomains=$(printf '%q' "$wordlist_subdomains")
    local safe_wordlist_web=$(printf '%q' "$wordlist_web")
    local safe_url_dominio=$(printf '%q' "${URL_DOMINIO:-$TARGET}")
    # Usar delimitador alternativo (#) para evitar conflitos com / ou :
    echo "$cmd" | sed \
        -e "s#{DOMINIO}#$safe_url_dominio#g" \
        -e "s#{TARGET_IP}#$safe_ip#g" \
        -e "s#{URL}#$safe_url#g" \
        -e "s#{WORDLIST_SUBDOMAINS}#$safe_wordlist_subdomains#g" \
        -e "s#{WORDLIST_WEB}#$safe_wordlist_web#g"
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
    if [ ! -f "$xml_file" ]; then
        print_status "error" "Arquivo $xml_file não encontrado"
        return 1
    fi
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
        local total_tests=${port_tests["$port"]}
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
        packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)' || echo "0")
        avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1 || echo "N/A")
        CHECKLIST+=("Ping $version: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
    else
        CHECKLIST+=("Ping $version: ✗ Falha")
    fi
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

test_http() {
    if [ "$TYPE_TARGET" != "DOMAIN" ]; then
        CHECKLIST+=("HTTP: ✗ Teste requer domínio")
        return
    fi
    print_status "action" "Testando HTTP"
    local protocol=$(determinar_protocolo)
    local output_file="$RESULTS_DIR/http_test.txt"
    # Usar -I para pegar apenas headers
    if curl -sI -o "$output_file" -w "%{http_code}" "$protocol://$TARGET" | grep -qE '200|301|302'; then
        CHECKLIST+=("HTTP ($protocol): ✓ Servidor ativo")
    else
        CHECKLIST+=("HTTP ($protocol): ✗ Servidor inativo ou erro")
    fi
    # Limitar o conteúdo do arquivo apenas aos headers
    sed -i '/^\r$/q' "$output_file"  # Remove o corpo da resposta se houver
}

test_ffuf_subdomains() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || return 1
            executar_comando "$cmd_substituido" "FFUF Subdomínios" "$RESULTS_DIR/ffuf_subdomains.csv" "Subdomínios encontrados" "Nenhum subdomínio encontrado"
        done
    else
        CHECKLIST+=("FFUF Subdomínios: ✗ Teste requer domínio")
    fi
}

test_ffuf_directories() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        local protocol=$(determinar_protocolo)
        local target_url="$protocol://$TARGET"
        for cmd in "${FFUF_WEB_COMMANDS[@]}"; do
            local cmd_substituido=$(echo "$cmd" | sed "s|{URL}|$target_url|g")
            executar_comando "$cmd_substituido" "FFUF Web" "$RESULTS_DIR/ffuf_web.csv" "Recursos web encontrados" "Nenhum recurso web encontrado"
        done
    else
        CHECKLIST+=("FFUF Web: ✗ Teste requer domínio")
    fi
}

test_ffuf_extensions() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_EXT_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || return 1
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
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_http
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

Ativo_complexo() {
    print_status "info" "Executando testes ATIVOS COMPLEXOS em $TARGET"
    mkdir -p "$RESULTS_DIR"
    if [ -n "$TARGET_IPv4" ]; then
        for cmd in "${NMAP_COMMANDS_IPV4[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || {
                print_status "error" "Falha ao substituir variáveis no comando Nmap IPv4: $cmd"
                CHECKLIST+=("Nmap IPv4: ✗ Falha na substituição de variáveis")
                continue
            }
            local output_file="$RESULTS_DIR/nmap_ipv4_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv4" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            [ -f "$output_file" ] && analyze_nmap_results "$output_file" "IPv4"
        done
        consolidar_portas "IPv4"
    fi
    if [ -n "$TARGET_IPv6" ]; then
        for cmd in "${NMAP_COMMANDS_IPV6[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv6") || {
                print_status "error" "Falha ao substituir variáveis no comando Nmap IPv6: $cmd"
                CHECKLIST+=("Nmap IPv6: ✗ Falha na substituição de variáveis")
                continue
            }
            local output_file="$RESULTS_DIR/nmap_ipv6_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv6" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            [ -f "$output_file" ] && analyze_nmap_results "$output_file" "IPv6"
        done
        consolidar_portas "IPv6"
    fi
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_subdomains
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_directories
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_extensions
}