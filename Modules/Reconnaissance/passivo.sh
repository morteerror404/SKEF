#!/bin/bash

#------------#------------# VARIÁVEIS COMANDOS #------------#------------#
WHOIS_COMMAND="whois {TARGET} > $RESULTS_DIR/whois_output.txt"
SHERLOCK_COMMAND="python3 -m sherlock {TARGET} --output $RESULTS_DIR/sherlock_output.txt"
FIERCE_COMMAND="fierce --domain {TARGET} --subdomain-file {WORDLIST_SUBDOMAINS} --output $RESULTS_DIR/fierce_output.txt"

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
substituir_variaveis_passivo() {
    local cmd="$1"
    local wordlist_subdomains="$WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
    [ ! -f "$wordlist_subdomains" ] && { wordlist_subdomains="/tmp/subdomains.txt"; curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o "$wordlist_subdomains"; }
    echo "$cmd" | sed "s/{TARGET}/$TARGET/g; s|{WORDLIST_SUBDOMAINS}|$wordlist_subdomains|g"
}

executar_comando_passivo() {
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

#------------#------------# FUNÇÕES DE TESTE PASSIVO #------------#------------#
test_whois() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        loading_clock "Teste WHOIS" 3 &
        pid=$!
        local cmd_substituido=$(substituir_variaveis_passivo "$WHOIS_COMMAND")
        executar_comando_passivo "$cmd_substituido" "WHOIS" "$RESULTS_DIR/whois_output.txt" "Informações obtidas" "Nenhuma informação obtida"
        kill -0 $pid 2>/dev/null && kill $pid
        wait $pid 2>/dev/null
    else
        CHECKLIST+=("WHOIS: ✗ Teste requer domínio")
    fi
}

test_dns() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
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
    else
        CHECKLIST+=("DNS: ✗ Teste requer domínio")
    fi
}

Passivo_basico() {
    print_status "info" "Executando testes PASSIVOS BÁSICOS em $TARGET"
    loading_clock "Testes Passivos Básicos" 3 &
    pid=$!
    test_whois
    test_dns
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

Passivo_complexo() {
    print_status "info" "Executando testes PASSIVOS COMPLEXOS em $TARGET"
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        local cmd_substituido=$(substituir_variaveis_passivo "$SHERLOCK_COMMAND")
        executar_comando_passivo "$cmd_substituido" "Sherlock" "$RESULTS_DIR/sherlock_output.txt" "Perfis encontrados" "Nenhum perfil encontrado"
        cmd_substituido=$(substituir_variaveis_passivo "$FIERCE_COMMAND")
        executar_comando_passivo "$cmd_substituido" "Fierce" "$RESULTS_DIR/fierce_output.txt" "Subdomínios encontrados" "Nenhum subdomínio encontrado"
        CHECKLIST+=("DNS Histórico: ⚠ Simulado")
        CHECKLIST+=("Threat Intel: ⚠ Simulado")
    else
        CHECKLIST+=("Sherlock: ✗ Teste requer domínio")
        CHECKLIST+=("Fierce: ✗ Teste requer domínio")
    fi
}