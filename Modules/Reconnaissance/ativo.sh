#!/bin/bash

# ativo.sh - Versão 1.4.0
# Script de testes ativos para reconhecimento de redes
# Dependências: nmap, ffuf, dig, curl, nc, ping, ping6

source "$(dirname "$0")/utils.sh"
export -f determinar_protocolo

#------------#------------# CONFIGURAÇÕES #------------#------------#
WORDLISTS_DIR="/usr/share/wordlists/SecLists"
WORDLISTS_EXT="$WORDLISTS_DIR/Discovery/Web-Content/web-extensions.txt"
WORDLIST_SUBDOMAINS="$WORDLISTS_DIR/Discovery/DNS/subdomains-top1million-110000.txt"
WORDLIST_WEB="$WORDLISTS_DIR/Discovery/Web-Content/directory-list-lowercase-2.3-big.txt"
RESULTS_DIR="results"
LOG_FILE="$RESULTS_DIR/ativo.log"
MAX_RETRIES=2
TIMEOUT=10

declare -A PORT_STATUS_IPV4
declare -A PORT_STATUS_IPV6
declare -A PORT_TESTS_IPV4
declare -A PORT_TESTS_IPV6

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
verificar_dependencias() {
    local dependencias=("nmap" "ffuf" "dig" "curl" "nc" "ping" "ping6")
    local faltando=()

    for cmd in "${dependencias[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            faltando+=("$cmd")
        fi
    done

    if [ ${#faltando[@]} -gt 0 ]; then
        print_status "error" "Dependências faltando: ${faltando[*]}"
        return 1
    fi

    if [ ! -d "$WORDLISTS_DIR" ]; then
        print_status "warning" "Diretório de wordlists não encontrado: $WORDLISTS_DIR"
    fi

    mkdir -p "$RESULTS_DIR" || {
        print_status "error" "Falha ao criar diretório $RESULTS_DIR"
        return 1
    }

    return 0
}

determinar_protocolo() {
    local protocol="http"
    
    # Verificar se o alvo é um IP ou domínio
    if [[ $TARGET =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || 
       [[ $TARGET =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
        # Para IPs, verificar apenas a porta 443
        if command -v nc &>/dev/null; then
            if nc -zv -w 2 "$TARGET" 443 &>/dev/null; then
                protocol="https"
            fi
        elif curl -s --connect-timeout 2 "https://$TARGET" >/dev/null 2>&1; then
            protocol="https"
        fi
    else
        # Para domínios, verificar com curl
        if curl -s --connect-timeout 2 "https://$TARGET" >/dev/null 2>&1; then
            protocol="https"
        elif command -v nc &>/dev/null; then
            if nc -zv -w 2 "$TARGET" 443 &>/dev/null; then
                protocol="https"
            fi
        fi
    fi
    
    echo "$protocol"
}

substituir_variaveis() {
    local cmd="$1" ip="$2"
    
    [ -z "$cmd" ] && { print_status "error" "Comando vazio"; return 1; }
    [ -z "$ip" ] && { print_status "error" "IP vazio"; return 1; }

    # Verificar e baixar wordlists se necessário
    local wordlist_subdomains="$WORDLIST_SUBDOMAINS"
    local wordlist_web="$WORDLIST_WEB"
    
    if [ ! -f "$wordlist_subdomains" ]; then
        wordlist_subdomains="/tmp/subdomains.txt"
        if ! curl -s --fail --retry 2 --connect-timeout $TIMEOUT \
             "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt" -o "$wordlist_subdomains"; then
            print_status "error" "Falha ao baixar wordlist de subdomínios"
            return 1
        fi
    fi

    if [ ! -f "$wordlist_web" ]; then
        wordlist_web="/tmp/common.txt"
        if ! curl -s --fail --retry 2 --connect-timeout $TIMEOUT \
             "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt" -o "$wordlist_web"; then
            print_status "error" "Falha ao baixar wordlist web"
            return 1
        fi
    fi

    local protocol=$(determinar_protocolo)
    local url="$protocol://$ip"
    
    # Sanitização de variáveis
    local safe_target=$(printf '%q' "$TARGET")
    local safe_ip=$(printf '%q' "$ip")
    local safe_url=$(printf '%q' "$url")
    local safe_wordlist_subdomains=$(printf '%q' "$wordlist_subdomains")
    local safe_wordlist_web=$(printf '%q' "$wordlist_web")
    local safe_url_dominio=$(printf '%q' "${URL_DOMINIO:-$TARGET}")

    # Substituição de variáveis com delimitador alternativo
    echo "$cmd" | sed \
        -e "s#{DOMINIO}#$safe_url_dominio#g" \
        -e "s#{TARGET_IP}#$safe_ip#g" \
        -e "s#{URL}#$safe_url#g" \
        -e "s#{WORDLIST_SUBDOMAINS}#$safe_wordlist_subdomains#g" \
        -e "s#{WORDLIST_WEB}#$safe_wordlist_web#g"
}

executar_comando() {
    local cmd="$1" name="$2" output_file="$3" success_msg="$4" fail_msg="$5"
    local attempts=0
    local exit_code=1
    local output
    
    [ -z "$cmd" ] && { print_status "error" "Comando vazio"; return 1; }

    local start_time=$(date +%s)
    local start_time_display=$(date +"%H:%M:%S")
    print_status "action" "Executando $name (iniciado às $start_time_display)"

    while [ $attempts -lt $MAX_RETRIES ]; do
        attempts=$((attempts + 1))
        output=$(eval "$cmd" 2>&1)
        exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            break
        fi
        
        print_status "warning" "Tentativa $attempts falhou, aguardando para retry..."
        sleep 1
    done

    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    if [ $exit_code -eq 0 ]; then
        local results=$(echo "$output" | wc -l)
        [ "$results" -gt 0 ] && CHECKLIST+=("$name: ✓ $success_msg ($results linhas, ${elapsed}s)") || 
                               CHECKLIST+=("$name: ✓ $fail_msg (${elapsed}s)")
        echo "$output" > "$output_file"
    else
        CHECKLIST+=("$name: ✗ Falha (${elapsed}s)")
        echo "Falha no comando: $cmd" >> "$LOG_FILE"
        echo "Saída do erro: $output" >> "$LOG_FILE"
    fi

    return $exit_code
}

#------------#------------# COMANDOS DE TESTE #------------#------------#
NMAP_COMMANDS_IPV4=(
    "nmap {TARGET_IP} -sT -vv -Pn --max-retries $MAX_RETRIES --host-timeout ${TIMEOUT}s"
    "nmap {TARGET_IP} -vv -O -Pn --max-retries $MAX_RETRIES --host-timeout ${TIMEOUT}s"
    "nmap {TARGET_IP} -sV -O -vv -Pn --max-retries $MAX_RETRIES --host-timeout ${TIMEOUT}s"
)

NMAP_COMMANDS_IPV6=(
    "nmap -6 {TARGET_IP} -sT -vv -Pn --max-retries $MAX_RETRIES --host-timeout ${TIMEOUT}s"
    "nmap -6 {TARGET_IP} -vv -O -Pn --max-retries $MAX_RETRIES --host-timeout ${TIMEOUT}s"
    "nmap -6 {TARGET_IP} -sV -O -vv -Pn --max-retries $MAX_RETRIES --host-timeout ${TIMEOUT}s"
)

FFUF_COMMANDS=(
    "ffuf -u {URL}/ -H 'Host: FUZZ.{DOMINIO}' -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -fc 404 -timeout $TIMEOUT -o $RESULTS_DIR/ffuf_subdomains.csv -of csv"
)

FFUF_WEB_COMMANDS=(
    "ffuf -u {URL}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -recursion -recursion-depth 2 -fc 404 -timeout $TIMEOUT -o $RESULTS_DIR/ffuf_web.csv -of csv"
)

FFUF_EXT_COMMANDS=(
    "ffuf -u {URL}/index.FUZZ -w {WORDLISTS_EXT} -mc 200,301,302 -fc 404 -timeout $TIMEOUT -o $RESULTS_DIR/ffuf_extensions.csv -of csv"
)

#------------#------------# FUNÇÕES DE TESTE #------------#------------#
test_ping() {
    local ip="$1" version="$2"
    [ -z "$ip" ] && { print_status "error" "IP não definido para ping"; return 1; }

    local start_time=$(date +%s)
    local start_time_display=$(date +"%H:%M:%S")
    print_status "action" "Testando PING $version (iniciado às $start_time_display)"
    
    loading_clock "Testando PING $version" 3 &
    pid=$!
    
    local ping_cmd="ping -c 4 -W 2 $ip"
    [ "$version" = "IPv6" ] && ping_cmd="ping6 -c 4 -W 2 $ip"
    
    local ping_result=$($ping_cmd 2>&1)
    local exit_code=$?
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null

    if [ $exit_code -eq 0 ]; then
        local packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)' || echo "0")
        local avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1 || echo "N/A")
        CHECKLIST+=("Ping $version: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms, ${elapsed}s)")
    else
        CHECKLIST+=("Ping $version: ✗ Falha (${elapsed}s)")
        echo "Falha no ping $version para $ip: $ping_result" >> "$LOG_FILE"
    fi
}

test_http() {
    [ "$TYPE_TARGET" != "DOMAIN" ] && {
        CHECKLIST+=("HTTP: ✗ Teste requer domínio")
        return 1
    }

    local start_time=$(date +%s)
    local start_time_display=$(date +"%H:%M:%S")
    print_status "action" "Testando HTTP (iniciado às $start_time_display)"
    
    local protocol=$(determinar_protocolo)
    local output_file="$RESULTS_DIR/http_test.txt"
    local http_status
    
    loading_clock "Testando HTTP" 3 &
    pid=$!
    
    http_status=$(curl -sI -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT "$protocol://$TARGET" 2>>"$LOG_FILE")
    local exit_code=$?
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null

    if [ $exit_code -eq 0 ] && [[ "$http_status" =~ ^[23] ]]; then
        CHECKLIST+=("HTTP ($protocol): ✓ Servidor ativo (${http_status}, ${elapsed}s)")
        curl -sI --connect-timeout $TIMEOUT "$protocol://$TARGET" > "$output_file"
    else
        CHECKLIST+=("HTTP ($protocol): ✗ Servidor inativo ou erro (${elapsed}s)")
        echo "Falha no teste HTTP para $TARGET" >> "$LOG_FILE"
    fi
}

test_ffuf_subdomains() {
    [ "$TYPE_TARGET" != "DOMAIN" ] && {
        CHECKLIST+=("FFUF Subdomínios: ✗ Teste requer domínio")
        return 1
    }

    for cmd in "${FFUF_COMMANDS[@]}"; do
        local start_time=$(date +%s)
        local start_time_display=$(date +"%H:%M:%S")
        local cmd_substituido
        
        if ! cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4"); then
            CHECKLIST+=("FFUF Subdomínios: ✗ Falha na preparação")
            continue
        fi

        executar_comando "$cmd_substituido" "FFUF Subdomínios (iniciado às $start_time_display)" \
                         "$RESULTS_DIR/ffuf_subdomains.csv" "Subdomínios encontrados" "Nenhum subdomínio encontrado"
    done
}

test_ffuf_directories() {
    [ "$TYPE_TARGET" != "DOMAIN" ] && {
        CHECKLIST+=("FFUF Web: ✗ Teste requer domínio")
        return 1
    }

    local protocol=$(determinar_protocolo)
    local target_url="$protocol://$TARGET"

    for cmd in "${FFUF_WEB_COMMANDS[@]}"; do
        local start_time=$(date +%s)
        local start_time_display=$(date +"%H:%M:%S")
        local cmd_substituido=$(echo "$cmd" | sed "s|{URL}|$target_url|g")

        executar_comando "$cmd_substituido" "FFUF Web (iniciado às $start_time_display)" \
                         "$RESULTS_DIR/ffuf_web.csv" "Recursos web encontrados" "Nenhum recurso web encontrado"
    done
}

test_ffuf_extensions() {
    [ "$TYPE_TARGET" != "DOMAIN" ] && {
        CHECKLIST+=("FFUF Extensões: ✗ Teste requer domínio")
        return 1
    }

    for cmd in "${FFUF_EXT_COMMANDS[@]}"; do
        local start_time=$(date +%s)
        local start_time_display=$(date +"%H:%M:%S")
        local cmd_substituido
        
        if ! cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4"); then
            CHECKLIST+=("FFUF Extensões: ✗ Falha na preparação")
            continue
        fi

        executar_comando "$cmd_substituido" "FFUF Extensões (iniciado às $start_time_display)" \
                         "$RESULTS_DIR/ffuf_extensions.csv" "Extensões encontradas" "Nenhuma extensão encontrada"
    done
}

analyze_nmap_results() {
    local xml_file="$1" ip_version="$2"
    
    [ ! -f "$xml_file" ] && {
        print_status "error" "Arquivo $xml_file não encontrado"
        return 1
    }

    local -n port_status="PORT_STATUS_$ip_version"
    local -n port_tests="PORT_TESTS_$ip_version"
    local ports=($(grep -oP 'portid="\d+"' "$xml_file" | cut -d'"' -f2 | sort -u))
    
    [ ${#ports[@]} -eq 0 ] && {
        print_status "warning" "Nenhuma porta encontrada no scan $ip_version"
        return 0
    }

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
    
    [ ${#port_status[@]} -eq 0 ] && return 0

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

#------------#------------# FUNÇÕES PRINCIPAIS #------------#------------#
Ativo_basico() {
    if ! verificar_dependencias; then
        print_status "error" "Dependências faltando, abortando testes básicos"
        return 1
    fi

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
    if ! verificar_dependencias; then
        print_status "error" "Dependências faltando, abortando testes complexos"
        return 1
    fi

    print_status "info" "Executando testes ATIVOS COMPLEXOS em $TARGET"
    
    mkdir -p "$RESULTS_DIR" || {
        print_status "error" "Falha ao criar diretório $RESULTS_DIR"
        return 1
    }

    loading_clock "Testes Ativos Complexos" 3 &
    pid=$!

    # Testes Nmap IPv4
    if [ -n "$TARGET_IPv4" ]; then
        for cmd in "${NMAP_COMMANDS_IPV4[@]}"; do
            local start_time_display=$(date +"%H:%M:%S")
            local cmd_substituido
            
            if ! cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4"); then
                CHECKLIST+=("Nmap IPv4: ✗ Falha na substituição de variáveis")
                continue
            fi

            local output_file="$RESULTS_DIR/nmap_ipv4_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv4 (iniciado às $start_time_display)" \
                            "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            
            [ -f "$output_file" ] && analyze_nmap_results "$output_file" "IPv4"
        done
        consolidar_portas "IPv4"
    fi

    # Testes Nmap IPv6
    if [ -n "$TARGET_IPv6" ]; then
        for cmd in "${NMAP_COMMANDS_IPV6[@]}"; do
            local start_time_display=$(date +"%H:%M:%S")
            local cmd_substituido
            
            if ! cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv6"); then
                CHECKLIST+=("Nmap IPv6: ✗ Falha na substituição de variáveis")
                continue
            fi

            local output_file="$RESULTS_DIR/nmap_ipv6_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv6 (iniciado às $start_time_display)" \
                            "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            
            [ -f "$output_file" ] && analyze_nmap_results "$output_file" "IPv6"
        done
        consolidar_portas "IPv6"
    fi

    # Testes FFUF
    [ "$TYPE_TARGET" = "DOMAIN" ] && {
        test_ffuf_subdomains
        test_ffuf_directories
        test_ffuf_extensions
    }

    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}