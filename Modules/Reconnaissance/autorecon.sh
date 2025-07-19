#!/bin/bash

#------------#------------# VARIAVEIS GLOBAIS #------------#------------#
ASK=""
TARGET=""
TARGET_IPv4=""
TARGET_IPv6=""
TYPE_TARGET=""
CHECKLIST=()
JSON_FILE="scan_results.json"
OPCAO=""
WORDLISTS_DIR="$HOME/wordlists"
NMAP_SILENCE="" # Inicialmente vazio, será definido pelo usuário

#------------#------------# VARIAVEIS COMANDOS #------------#------------#
# NMAP
NMAP1="nmap {TARGET_IP} -vv -O $NMAP_SILENCE"
NMAP2="nmap {TARGET_IP} -sT -O -vv $NMAP_SILENCE"
NMAP3="nmap {TARGET_IP} -sV -O -vv $NMAP_SILENCE"
NMAP1_IPv6="nmap -6 {TARGET_IP} -vv -O $NMAP_SILENCE"
NMAP2_IPv6="nmap -6 {TARGET_IP} -sT -O -vv $NMAP_SILENCE"
NMAP3_IPv6="nmap -6 {TARGET_IP} -sV -O -vv $NMAP_SILENCE"

# FFUF (Atualizado para usar {TARGET} diretamente)
FFUF1="ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w $WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt -mc 200,301,302 -o ffuf_output.csv -of csv"
FFUF2="ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w $WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-20000.txt -mc 200,301,302 -fc 404 -o ffuf_output.csv -of csv"
FFUF3="ffuf -u {PROTOCOL}://{TARGET}/ -H \"Host: FUZZ.{TARGET}\" -w $WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-20000.txt -mc 200,301,302 -t 50 -recursion -recursion-depth 1 -o ffuf_output.csv -of csv"
FFUF_WEB1="ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w $WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt -mc 200,301,302 -o ffuf_web_output.csv -of csv"
FFUF_WEB2="ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w $WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt -mc 200,301,302 -e .php,.txt,.html -o ffuf_web_output.csv -of csv"
FFUF_WEB3="ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w $WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt -mc 200,301,302 -recursion -recursion-depth 2 -o ffuf_web_output.csv -of csv"

# ATTACK SURFACE MAPPER
ASM1="python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -sth"
ASM2="python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -exp"
ASM3="python3 -m attacksurfacemapper -t {TARGET} -o asm_output.txt -sth -api"

# AUTO RECON
AR1="autorecon {TARGET_IP} --dir autorecon_output --only-scans"
AR2="autorecon {TARGET_IP} --dir autorecon_output"
AR3="autorecon {TARGET_IP} --dir autorecon_output --web"

# GITLEAKS
GL1="gitleaks detect --source . --no-git -c {TARGET} -o gitleaks_output.json"

# SHERLOCK
SH1="python3 -m sherlock {TARGET} --output sherlock_output.txt"

# XRAY
XRAY1="xray ws --url {PROTOCOL}://{TARGET} --json-output xray_output.json"

# FIERCE
FIERCE1="fierce --domain {TARGET} --subdomain-file $WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt --output fierce_output.txt"

# FINALRECON
FR1="python3 -m finalrecon --full {PROTOCOL}://{TARGET} --out finalrecon_output.txt"

# FIREWALK
FW1="firewalk -S1-1024 -i eth0 -n {TARGET_IP} -o firewalk_output.txt"

# CLUSTERD
CL1="python3 -m clusterd -t {TARGET} -o clusterd_output.txt"

#------------#------------# FUNÇÕES BÁSICAS #------------#------------#
definir_alvo() {
    read -p "Digite o IP, domínio ou URL alvo: " TARGET
    TYPE_TARGET=$(verificar_tipo_alvo "$TARGET")

    if [ "$TYPE_TARGET" = "INVÁLIDO" ]; then
        echo "Entrada inválida. Digite um IP, domínio ou URL válido."
        CHECKLIST+=("Alvo definido: ✗ Entrada inválida")
        salvar_json
        return 1
    fi

    # Extrair domínio de URL, se aplicável
    TARGET_CLEAN=$(echo "$TARGET" | sed -E 's|^https?://||; s|/.*$||; s|:[0-9]+$||')
    TARGET="$TARGET_CLEAN"

    # Resolver IPs (IPv4 e IPv6)
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        TARGET_IPv4=$(dig +short A "$TARGET" | grep -oP '^\d+\.\d+\.\d+\.\d+$' | head -1)
        TARGET_IPv6=$(dig +short AAAA "$TARGET" | grep -oP '^[0-9a-fA-F:]+$' | head -1)
        
        if [ -z "$TARGET_IPv4" ] && [ -z "$TARGET_IPv6" ]; then
            CHECKLIST+=("Resolução de IP: ✗ Não foi possível resolver IP para $TARGET")
            salvar_json
            return 1
        fi
        
        if [ -n "$TARGET_IPv4" ]; then
            CHECKLIST+=("Resolução IPv4: ✓ $TARGET_IPv4")
        fi
        if [ -n "$TARGET_IPv6" ]; then
            CHECKLIST+=("Resolução IPv6: ✓ $TARGET_IPv6")
        fi
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

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
verificar_tipo_alvo() {
    local entrada="$1"

    # Remove protocolo e caminhos de URLs
    entrada=$(echo "$entrada" | sed -E 's|^https?://||; s|/.*$||; s|:[0-9]+$||')

    # Regex para IP IPv4
    if [[ $entrada =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "IP"
        return 0
    fi

    # Regex para IP IPv6
    if [[ $entrada =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
        echo "IP"
        return 0
    fi

    # Regex para domínio
    if [[ $entrada =~ ^([a-zA-Z0-9][-a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$ ]]; then
        echo "DOMAIN"
        return 0
    fi

    echo "INVÁLIDO"
    return 1
}

salvar_json() {
    local start_time=$(date +%s)
    local json_data="{"

    # Metadados do script
    json_data+="\"script\": {"
    json_data+="\"name\": \"Network Recon Script\","
    json_data+="\"version\": \"1.1.0\","
    json_data+="\"os\": \"$(uname -a)\","
    json_data+="\"start_time\": \"$(date -d @$start_time '+%Y-%m-%dT%H:%M:%S')\","
    json_data+="\"user\": \"$(whoami)\""
    json_data+="},"

    # Informações do alvo
    json_data+="\"target\": {"
    json_data+="\"input\": \"$TARGET\","
    json_data+="\"resolved_ipv4\": \"$TARGET_IPv4\","
    json_data+="\"resolved_ipv6\": \"$TARGET_IPv6\","
    json_data+="\"type\": \"$TYPE_TARGET\","
    json_data+="\"protocol\": \"$(nc -zv -w 2 \"$TARGET_IPv4\" 443 &>/dev/null && echo 'https' || echo 'http')\","
    json_data+="\"resolution_time\": \"$(date +'%Y-%m-%dT%H:%M:%S')\""
    json_data+="},"

    # Configurações das ferramentas
    json_data+="\"tools_config\": {"
    json_data+="\"nmap\": {"
    json_data+="\"ipv4_commands\": [\"$NMAP1\", \"$NMAP2\", \"$NMAP3\"],"
    json_data+="\"ipv6_commands\": [\"$NMAP1_IPv6\", \"$NMAP2_IPv6\", \"$NMAP3_IPv6\"],"
    json_data+="\"silence\": \"$NMAP_SILENCE\""
    json_data+="},"
    json_data+="\"ffuf\": {"
    json_data+="\"subdomain_commands\": [\"$FFUF1\", \"$FFUF2\", \"$FFUF3\"],"
    json_data+="\"web_commands\": [\"$FFUF_WEB1\", \"$FFUF_WEB2\", \"$FFUF_WEB3\"]"
    json_data+="},"
    json_data+="\"attacksurfacemapper\": [\"$ASM1\", \"$ASM2\", \"$ASM3\"],"
    json_data+="\"autorecon\": [\"$AR1\", \"$AR2\", \"$AR3\"],"
    json_data+="\"gitleaks\": \"$GL1\","
    json_data+="\"sherlock\": \"$SH1\","
    json_data+="\"xray\": \"$XRAY1\","
    json_data+="\"fierce\": \"$FIERCE1\","
    json_data+="\"finalrecon\": \"$FR1\","
    json_data+="\"firewalk\": \"$FW1\","
    json_data+="\"clusterd\": \"$CL1\""
    json_data+="},"

    # Dependências
    json_data+="\"dependencies\": {"
    json_data+="\"jq\": \"$(command -v jq &>/dev/null && jq --version || echo 'Não instalado')\","
    json_data+="\"nmap\": \"$(command -v nmap &>/dev/null && nmap --version | head -1 || echo 'Não instalado')\","
    json_data+="\"ffuf\": \"$(command -v ffuf &>/dev/null && ffuf --version || echo 'Não instalado')\","
    json_data+="\"python3\": \"$(command -v python3 &>/dev/null && python3 --version || echo 'Não instalado')\","
    json_data+="\"attacksurfacemapper\": \"$(python3 -m pip show attacksurfacemapper &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    json_data+="\"autorecon\": \"$(command -v autorecon &>/dev/null && autorecon --version || echo 'Não instalado')\","
    json_data+="\"gitleaks\": \"$(command -v gitleaks &>/dev/null && gitleaks --version || echo 'Não instalado')\","
    json_data+="\"sherlock\": \"$(python3 -m pip show sherlock-project &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    json_data+="\"xray\": \"$(command -v xray &>/dev/null && xray --version || echo 'Não instalado')\","
    json_data+="\"fierce\": \"$(command -v fierce &>/dev/null && fierce --version || echo 'Não instalado')\","
    json_data+="\"finalrecon\": \"$(python3 -m pip show finalrecon &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    json_data+="\"firewalk\": \"$(command -v firewalk &>/dev/null && firewalk --version || echo 'Não instalado')\","
    json_data+="\"clusterd\": \"$(python3 -m pip show clusterd &>/dev/null && echo 'Instalado' || echo 'Não instalado')\""
    json_data+="},"

    # Resultados dos testes
    json_data+="\"tests\": ["
    local success_count=0
    local failure_count=0
    for item in "${CHECKLIST[@]}"; do
        IFS=':' read -ra parts <<< "$item"
        test_name=$(echo "${parts[0]}" | xargs)
        status=$(echo "${parts[1]}" | xargs)
        message=$(echo "${parts[1]}" | cut -d' ' -f2- | xargs)

        json_data+="{\"name\": \"$test_name\","
        json_data+="\"status\": $([[ "$status" == *"✓"* ]] && echo "true" || echo "false"),"
        json_data+="\"message\": \"$message\","
        json_data+="\"timestamp\": \"$(date +'%Y-%m-%dT%H:%M:%S')\","
        json_data+="\"details\": {"
        case $test_name in
            "Ping"|"Ping Personalizado")
                json_data+="\"command\": \"ping -c 4 $TARGET_IPv4\","
                json_data+="\"packet_loss\": \"$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)' || echo 'N/A')\","
                json_data+="\"avg_latency\": \"$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1 || echo 'N/A')\","
                json_data+="\"ipv6_command\": \"ping6 -c 4 $TARGET_IPv6\""
                ;;
            "DNS"|"DNS Personalizado")
                json_data+="\"command\": \"dig $TARGET +short\","
                json_data+="\"resolved_ips\": \"$(echo "$dns_result" | grep -oP '(\d+\.){3}\d+|[0-9a-fA-F:]+' | tr '\n' ',' | sed 's/,$//' || echo 'N/A')\""
                ;;
            "Porta "*)
                json_data+="\"port\": \"$(echo $test_name | grep -oP '\d+')\","
                json_data+="\"ipv4_command\": \"nc -zv -w 2 $TARGET_IPv4 $(echo $test_name | grep -oP '\d+')\","
                json_data+="\"ipv6_command\": \"nc -zv -w 2 $TARGET_IPv6 $(echo $test_name | grep -oP '\d+')\""
                ;;
            "Nmap Avançado")
                json_data+="\"command\": \"$nmap_cmd\","
                json_data+="\"open_ports\": \"$(grep -oP 'portid=\"\d+\"' "$nmap_output" 2>/dev/null | cut -d'\"' -f2 | tr '\n' ',' | sed 's/,$//' || echo 'N/A')\""
                ;;
            *) json_data+="\"command\": \"N/A\"" ;;
        esac
        json_data+="},"
        json_data+="\"raw_output_file\": \"$(echo $test_name | tr ' ' '_' | tr -d ':').txt\"},"

        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    json_data="${json_data%,]}"

    # Estatísticas
    json_data+="],"
    json_data+="\"statistics\": {"
    json_data+="\"total_tests\": ${#CHECKLIST[@]},"
    json_data+="\"success_count\": $success_count,"
    json_data+="\"failure_count\": $failure_count,"
    json_data+="\"total_execution_time\": \"$(( $(date +%s) - start_time )) seconds\""
    json_data+="}"

    json_data+="}"
    echo "$json_data" | jq '.' > "$JSON_FILE"
}

#------------#------------# FUNÇÕES PARA ANIMAÇÃO #------------#------------#
print_clock_frame() {
    local frame=$1
    local task=$2
    local hora=$(date +"%H:%M:%S")

    echo -e "\n   ______"
    echo " /________\\"
    echo " |$hora|"
    echo " |________|"

    if [ "$frame" -eq 1 ]; then
        echo " |........|"
        echo " |........|"
    else
        echo " |        |"
        echo " |        |"
    fi

    echo " \\ ______ /"
    echo -e "\nExecutando: $task em: $TARGET"

    echo -e "\nChecklist:"
    for item in "${CHECKLIST[@]}"; do
        echo " - $item"
    done
}

loading_clock() {
    local task="$1"
    local duration=${2:-3}
    local end_time=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end_time ]; do
        clear
        print_clock_frame 1 "$task"
        sleep 0.5
        
        clear
        print_clock_frame 2 "$task"
        sleep 0.5
    done
}

#------------#------------# TESTES PASSIVOS #------------#------------#
Passivo_basico() {
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
    [ "$TYPE_TARGET" != "DOMAIN" ] && { CHECKLIST+=("Passivo Complexo: ✗ Requer domínio"); salvar_json; return 1; }

    # Verifica dependências
    if ! command -v python3 &>/dev/null; then
        CHECKLIST+=("Python3: ✗ Não instalado")
        salvar_json
        return 1
    fi

    python_version=$(python3 --version | grep -oP '\d+\.\d+\.\d+')
    python_major=$(echo $python_version | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d'.' -f2)
    if [ $python_major -lt 3 ] || { [ $python_major -eq 3 ] && [ $python_minor -lt 7 ]; }; then
        CHECKLIST+=("Python: ✗ Versão 3.7+ necessária para ferramentas")
        salvar_json
        return 1
    fi

    # AttackSurfaceMapper
    read -p "Deseja executar testes de subdomínios com AttackSurfaceMapper para $TARGET? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        loading_clock "AttackSurfaceMapper (Subdomínios)" 15 &
        pid=$!
        local asm_output=$(mktemp)
        if python3 -m pip show attacksurfacemapper &>/dev/null; then
            local asm_cmd=$(echo "$ASM1" | sed "s/{TARGET}/$TARGET/g")
            if $asm_cmd &>/dev/null; then
                local asm_results=$(grep -oP 'Found \d+ subdomains' "$asm_output" | tr '\n' ',' | sed 's/,$//')
                [ -n "$asm_results" ] && CHECKLIST+=("AttackSurfaceMapper: ✓ $asm_results") || CHECKLIST+=("AttackSurfaceMapper: ✗ Nenhum subdomínio encontrado")
            else
                CHECKLIST+=("AttackSurfaceMapper: ✗ Falha")
            fi
        else
            CHECKLIST+=("AttackSurfaceMapper: ✗ Não instalado. Execute o script de instalação.")
        fi
        rm -f "$asm_output"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    fi

    # FFuf (Brute Force de Subdomínios)
    read -p "Deseja executar brute force de subdomínios com FFuf para $TARGET? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! command -v ffuf &>/dev/null; then
            CHECKLIST+=("FFuf: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi

        local protocol="http"
        { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
        local wordlist="$WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
        if [ ! -f "$wordlist" ]; then
            wordlist="/tmp/subdomains.txt"
            curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o "$wordlist"
        fi

        loading_clock "FFuf (Brute Force de Subdomínios)" 10 &
        pid=$!
        local ffuf_output=$(mktemp)
        local ffuf_cmd=$(echo "$FFUF1" | sed "s/{TARGET}/$TARGET/g; s/{PROTOCOL}/$protocol/g")
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
        salvar_json
    fi

    # Gitleaks
    read -p "Deseja executar Gitleaks para $TARGET? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! command -v gitleaks &>/dev/null; then
            CHECKLIST+=("Gitleaks: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
        loading_clock "Gitleaks (Detecção de Vazamentos)" 10 &
        pid=$!
        local gl_output=$(mktemp)
        local gl_cmd=$(echo "$GL1" | sed "s/{TARGET}/$TARGET/g")
        if $gl_cmd &>/dev/null; then
            local gl_results=$(jq '. | length' "$gl_output")
            [ "$gl_results" -gt 0 ] && CHECKLIST+=("Gitleaks: ✓ $gl_results vazamentos encontrados") || CHECKLIST+=("Gitleaks: ✓ Nenhum vazamento encontrado")
        else
            CHECKLIST+=("Gitleaks: ✗ Falha")
        fi
        rm -f "$gl_output"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    fi

    # Sherlock
    read -p "Deseja executar Sherlock para $TARGET? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! python3 -m pip show sherlock-project &>/dev/null; then
            CHECKLIST+=("Sherlock: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
        loading_clock "Sherlock (OSINT)" 15 &
        pid=$!
        local sh_output=$(mktemp)
        local sh_cmd=$(echo "$SH1" | sed "s/{TARGET}/$TARGET/g")
        if $sh_cmd &>/dev/null; then
            local sh_results=$(wc -l < "$sh_output")
            [ "$sh_results" -gt 0 ] && CHECKLIST+=("Sherlock: ✓ $sh_results perfis encontrados") || CHECKLIST+=("Sherlock: ✓ Nenhum perfil encontrado")
        else
            CHECKLIST+=("Sherlock: ✗ Falha")
        fi
        rm -f "$sh_output"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    fi

    # Fierce
    read -p "Deseja executar Fierce para $TARGET? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! command -v fierce &>/dev/null; then
            CHECKLIST+=("Fierce: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
        local wordlist="$WORDLISTS_DIR/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
        if [ ! -f "$wordlist" ]; then
            wordlist="/tmp/subdomains.txt"
            curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -o "$wordlist"
        fi
        loading_clock "Fierce (Subdomínios)" 10 &
        pid=$!
        local fierce_output=$(mktemp)
        local fierce_cmd=$(echo "$FIERCE1" | sed "s/{TARGET}/$TARGET/g")
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
        salvar_json
    fi

    # FinalRecon
    read -p "Deseja executar FinalRecon para $TARGET? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! python3 -m pip show finalrecon &>/dev/null; then
            CHECKLIST+=("FinalRecon: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
        local protocol="http"
        { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
        loading_clock "FinalRecon (OSINT)" 15 &
        pid=$!
        local fr_output=$(mktemp)
        local fr_cmd=$(echo "$FR1" | sed "s/{TARGET}/$TARGET/g; s/{PROTOCOL}/$protocol/g")
        if $fr_cmd &>/dev/null; then
            local fr_results=$(wc -l < "$fr_output")
            [ "$fr_results" -gt 0 ] && CHECKLIST+=("FinalRecon: ✓ $fr_results linhas de resultados") || CHECKLIST+=("FinalRecon: ✓ Nenhum resultado encontrado")
        else
            CHECKLIST+=("FinalRecon: ✗ Falha")
        fi
        rm -f "$fr_output"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    fi
}

#------------#------------# TESTES ATIVOS #------------#------------#
Ativo_basico() {
    loading_clock "Testes Ativos Básicos" 3 &
    pid=$!

    # Ping para IPv4
    if [ -n "$TARGET_IPv4" ]; then
        local ping_target="$TARGET_IPv4"
        local ping_result=$(ping -c 4 "$ping_target" 2>&1)
        if [ $? -eq 0 ]; then
            local packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
            local avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1)
            CHECKLIST+=("Ping IPv4: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
        else
            CHECKLIST+=("Ping IPv4: ✗ Falha")
        fi
    fi

    # Ping para IPv6
    if [ -n "$TARGET_IPv6" ]; then
        local ping_target="$TARGET_IPv6"
        local ping_result=$(ping6 -c 4 "$ping_target" 2>&1)
        if [ $? -eq 0 ]; then
            local packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
            local avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1)
            CHECKLIST+=("Ping IPv6: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
        else
            CHECKLIST+=("Ping IPv6: ✗ Falha")
        fi
    fi

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

    for porta in 22 80 443; do
        if [ -n "$TARGET_IPv4" ]; then
            if nc -zv -w 2 "$TARGET_IPv4" $porta &>/dev/null; then
                CHECKLIST+=("Porta $porta (IPv4): ✓ Aberta")
            else
                CHECKLIST+=("Porta $porta (IPv4): ✗ Fechada")
            fi
        fi
        if [ -n "$TARGET_IPv6" ]; then
            if nc -zv -w 2 "$TARGET_IPv6" $porta &>/dev/null; then
                CHECKLIST+=("Porta $porta (IPv6): ✓ Aberta")
            else
                CHECKLIST+=("Porta $porta (IPv6): ✗ Fechada")
            fi
        fi
    done

    kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

Ativo_complexo() {
    [ -z "$TARGET" ] && definir_alvo
    [ "$TYPE_TARGET" = "INVÁLIDO" ] && return 1

    # Verifica dependências
    for cmd in nmap ffuf python3; do
        if ! command -v $cmd &>/dev/null; then
            CHECKLIST+=("$cmd: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
    done

    python_version=$(python3 --version | grep -oP '\d+\.\d+\.\d+')
    python_major=$(echo $python_version | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d'.' -f2)
    if [ $python_major -lt 3 ] || { [ $python_major -eq 3 ] && [ $python_minor -lt 7 ]; }; then
        CHECKLIST+=("Python: ✗ Versão 3.7+ necessária para ferramentas")
        salvar_json
        return 1
    fi

    # Perguntar sobre modo silencioso do Nmap
    read -p "Deseja executar o Nmap em modo silencioso (-Pn)? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        NMAP_SILENCE="-Pn"
    else
        NMAP_SILENCE=""
    fi

    # Nmap para IPv4
    if [ -n "$TARGET_IPv4" ]; then
        loading_clock "Nmap Escaneamento Avançado (IPv4)" 10 &
        pid=$!
        local nmap_output=$(mktemp)
        local nmap_cmd=$(echo "$NMAP3" | sed "s/{TARGET_IP}/$TARGET_IPv4/g")
        if $nmap_cmd -oX "$nmap_output" &>/dev/null; then
            local open_ports=$(grep -oP 'portid="\d+"' "$nmap_output" | cut -d'"' -f2 | tr '\n' ',' | sed 's/,$//')
            [ -n "$open_ports" ] && CHECKLIST+=("Nmap Avançado (IPv4): ✓ Portas abertas: $open_ports") || CHECKLIST+=("Nmap Avançado (IPv4): ✗ Nenhuma porta aberta")
        else
            CHECKLIST+=("Nmap Avançado (IPv4): ✗ Falha")
        fi
        rm -f "$nmap_output"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    fi

    # Nmap para IPv6
    if [ -n "$TARGET_IPv6" ]; then
        loading_clock "Nmap Escaneamento Avançado (IPv6)" 10 &
        pid=$!
        local nmap_output=$(mktemp)
        local nmap_cmd=$(echo "$NMAP3_IPv6" | sed "s/{TARGET_IP}/$TARGET_IPv6/g")
        if $nmap_cmd -oX "$nmap_output" &>/dev/null; then
            local open_ports=$(grep -oP 'portid="\d+"' "$nmap_output" | cut -d'"' -f2 | tr '\n' ',' | sed 's/,$//')
            [ -n "$open_ports" ] && CHECKLIST+=("Nmap Avançado (IPv6): ✓ Portas abertas: $open_ports") || CHECKLIST+=("Nmap Avançado (IPv6): ✗ Nenhuma porta aberta")
        else
            CHECKLIST+=("Nmap Avançado (IPv6): ✗ Falha")
        fi
        rm -f "$nmap_output"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    fi

    # FFuf (Fuzzing Web)
    if [ "$TYPE_TARGET" = "DOMAIN" ] && { nc -zv -w 2 "$TARGET_IPv4" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; }; then
        local protocol="http"
        { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
        local wordlist="$WORDLISTS_DIR/SecLists/Discovery/Web-Content/common.txt"
        if [ ! -f "$wordlist" ]; then
            wordlist="/tmp/common.txt"
            curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o "$wordlist"
        fi

        loading_clock "FFuf Fuzzing Web ($protocol)" 10 &
        pid=$!
        local ffuf_output=$(mktemp)
        local ffuf_cmd=$(echo "$FFUF_WEB1" | sed "s/{TARGET}/$TARGET/g; s/{PROTOCOL}/$protocol/g")
        if $ffuf_cmd &>/dev/null; then
            local found_dirs=$(awk -F',' 'NR>1 {print $2}' "$ffuf_output" | tr '\n' ',' | sed 's/,$//')
            [ -n "$found_dirs" ] && CHECKLIST+=("FFuf Web: ✓ Diretórios encontrados: $found_dirs") || CHECKLIST+=("FFuf Web: ✗ Nenhum diretório encontrado")
        else
            CHECKLIST+=("FFuf Web: ✗ Falha")
        fi
        rm -f "$ffuf_output"
        [ "$wordlist" = "/tmp/common.txt" ] && rm -f "$wordlist"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    else
        CHECKLIST+=("FFuf Web: ✗ Portas HTTP/HTTPS não abertas")
        salvar_json
    fi

    # AutoRecon
    read -p "Deseja executar AutoRecon para $TARGET_IPv4 ou $TARGET_IPv6? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! command -v autorecon &>/dev/null; then
            CHECKLIST+=("AutoRecon: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
        loading_clock "AutoRecon" 20 &
        pid=$!
        local autorecon_output_dir=$(mktemp -d)
        local ar_cmd=""
        if [ -n "$TARGET_IPv4" ]; then
            ar_cmd=$(echo "$AR1" | sed "s/{TARGET_IP}/$TARGET_IPv4/g")
        elif [ -n "$TARGET_IPv6" ]; then
            ar_cmd=$(echo "$AR1" | sed "s/{TARGET_IP}/$TARGET_IPv6/g")
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
        salvar_json
    fi

    # XRay
    read -p "Deseja executar XRay para $TARGET? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! command -v xray &>/dev/null; then
            CHECKLIST+=("XRay: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
        if [ "$TYPE_TARGET" = "DOMAIN" ] && { nc -zv -w 2 "$TARGET_IPv4" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 80 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; }; then
            local protocol="http"
            { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
            loading_clock "XRay (Varredura de Vulnerabilidades)" 15 &
            pid=$!
            local xray_output=$(mktemp)
            local xray_cmd=$(echo "$XRAY1" | sed "s/{TARGET}/$TARGET/g; s/{PROTOCOL}/$protocol/g")
            if $xray_cmd &>/dev/null; then
                local xray_results=$(jq '. | length' "$xray_output")
                [ "$xray_results" -gt 0 ] && CHECKLIST+=("XRay: ✓ $xray_results vulnerabilidades encontradas") || CHECKLIST+=("XRay: ✓ Nenhuma vulnerabilidade encontrada")
            else
                CHECKLIST+=("XRay: ✗ Falha")
            fi
            rm -f "$xray_output"
            kill $pid
            wait $pid 2>/dev/null
            salvar_json
        else
            CHECKLIST+=("XRay: ✗ Portas HTTP/HTTPS não abertas")
            salvar_json
        fi
    fi

    # Firewalk
    read -p "Deseja executar Firewalk para $TARGET_IPv4 ou $TARGET_IPv6? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! command -v firewalk &>/dev/null; then
            CHECKLIST+=("Firewalk: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
        loading_clock "Firewalk (Mapeamento de Firewall)" 15 &
        pid=$!
        local fw_output=$(mktemp)
        local fw_cmd=""
        if [ -n "$TARGET_IPv4" ]; then
            fw_cmd=$(echo "$FW1" | sed "s/{TARGET_IP}/$TARGET_IPv4/g")
        elif [ -n "$TARGET_IPv6" ]; then
            fw_cmd=$(echo "$FW1" | sed "s/{TARGET_IP}/$TARGET_IPv6/g")
        fi
        if $fw_cmd &>/dev/null; then
            local fw_results=$(wc -l < "$fw_output")
            [ "$fw_results" -gt 0 ] && CHECKLIST+=("Firewalk: ✓ $fw_results regras de firewall mapeadas") || CHECKLIST+=("Firewalk: ✓ Nenhuma regra encontrada")
        else
            CHECKLIST+=("Firewalk: ✗ Falha")
        fi
        rm -f "$fw_output"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    fi

    # Clusterd
    read -p "Deseja executar Clusterd para $TARGET? (s/n): " ASK
    if [ "$ASK" = "s" ] || [ "$ASK" = "S" ]; then
        if ! python3 -m pip show clusterd &>/dev/null; then
            CHECKLIST+=("Clusterd: ✗ Não instalado. Execute o script de instalação.")
            salvar_json
            return 1
        fi
        loading_clock "Clusterd (Exploração de Servidores)" 15 &
        pid=$!
        local cl_output=$(mktemp)
        local cl_cmd=$(echo "$CL1" | sed "s/{TARGET}/$TARGET/g")
        if $cl_cmd &>/dev/null; then
            local cl_results=$(wc -l < "$cl_output")
            [ "$cl_results" -gt 0 ] && CHECKLIST+=("Clusterd: ✓ $cl_results resultados encontrados") || CHECKLIST+=("Clusterd: ✓ Nenhum resultado encontrado")
        else
            CHECKLIST+=("Clusterd: ✗ Falha")
        fi
        rm -f "$cl_output"
        kill $pid
        wait $pid 2>/dev/null
        salvar_json
    fi
}

#------------#------------# MENUS #------------#------------#
menu_personalizado() {
    while true; do
        clear
        echo -e "\nMenu de Ferramentas de Rede (PERSONALIZADO):"
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
                if [ -n "$TARGET_IPv4" ]; then
                    if ping -c 4 "$TARGET_IPv4" &>/dev/null; then
                        CHECKLIST+=("Ping Personalizado (IPv4): ✓ Sucesso")
                    else
                        CHECKLIST+=("Ping Personalizado (IPv4): ✗ Falha")
                    fi
                fi
                if [ -n "$TARGET_IPv6" ]; then
                    if ping6 -c 4 "$TARGET_IPv6" &>/dev/null; then
                        CHECKLIST+=("Ping Personalizado (IPv6): ✓ Sucesso")
                    else
                        CHECKLIST+=("Ping Personalizado (IPv6): ✗ Falha")
                    fi
                fi
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
                loading_clock "Teste de Portas" 5 &
                pid=$!
                for porta in $(seq 1 1024); do
                    if [ -n "$TARGET_IPv4" ]; then
                        if nc -zv -w 1 "$TARGET_IPv4" $porta &>/dev/null; then
                            CHECKLIST+=("Porta $porta (IPv4): ✓ Aberta")
                            salvar_json
                        fi
                    fi
                    if [ -n "$TARGET_IPv6" ]; then
                        if nc -zv -w 1 "$TARGET_IPv6" $porta &>/dev/null; then
                            CHECKLIST+=("Porta $porta (IPv6): ✓ Aberta")
                            salvar_json
                        fi
                    fi
                done
                kill $pid
                wait $pid 2>/dev/null
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
            *) echo "Opção inválida. Tente novamente." ;;
        esac
    done
}

menu_inicial() {
    while true; do
        echo -e "\n=== MENU INICIAL ==="
        echo "1. PASSIVO + ATIVO"
        echo "2. ATIVO + PASSIVO"
        echo "3. PASSIVO"
        echo "4. ATIVO"
        echo "5. PERSONALIZADO"
        echo "6. SAIR"
        
        read -p "Escolha uma estratégia (1-6): " estrategia
        
        case $estrategia in
            1) 
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Passivo_basico
                Passivo_complexo
                Ativo_basico
                Ativo_complexo
                ;;
            2) 
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Ativo_basico
                Ativo_complexo
                Passivo_basico
                Passivo_complexo
                ;;
            3) 
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Passivo_basico
                Passivo_complexo
                ;;
            4) 
                definir_alvo
                [ "$TYPE_TARGET" = "INVÁLIDO" ] && continue
                Ativo_basico
                Ativo_complexo
                ;;
            5) 
                menu_personalizado
                ;;
            6) 
                echo "Saindo..."
                exit 0
                ;;
            *) 
                echo "Opção inválida. Tente novamente."
                ;;
        esac
    done
}

# Verifica dependências
if ! command -v jq &>/dev/null; then
    echo "Instalando jq para formatação JSON..."
    sudo apt-get install -y jq >/dev/null || sudo yum install -y jq >/dev/null
fi
if ! command -v dig &>/dev/null; then
    echo "Instalando dnsutils para resolução de IP..."
    sudo apt-get install -y dnsutils >/dev/null || sudo yum install -y bind-utils >/dev/null
fi

# Inicia o script
menu_inicial