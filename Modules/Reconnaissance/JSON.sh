#!/bin/bash

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
ASK=""
TARGET=""
TARGET_IPv4=""
TARGET_IPv6=""
TYPE_TARGET=""
CHECKLIST=()
JSON_FILE="results/scan_results_ativo_$(date +%s).json"
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

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
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
    local wordlist_web="$HOME/wordlists/SecLists/Discovery/Web-Content/common.txt"
    [ ! -f "$wordlist_web" ] && { wordlist_web="/tmp/common.txt"; curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o "$wordlist_web"; }
    local protocol=$(determinar_protocolo)
    echo "$cmd" | sed "s/{TARGET}/$TARGET/g; s/{TARGET_IP}/$ip/g; s/{PROTOCOL}/$protocol/g; s|{WORDLIST_WEB}|$wordlist_web|g"
}

salvar_json() {
    packet_loss="${packet_loss:-"N/A"}"
    avg_latency="${avg_latency:-"N/A"}"
    filtered_details="${filtered_details:-"N/A"}"
    nmap_cmd="${nmap_cmd:-"N/A"}"
    open_ports="${open_ports:-"N/A"}"

    # Criar pasta results se não existir
    mkdir -p results

    local json_base=$(cat <<EOF
{
  "script": {
    "name": "Ativo Recon Script",
    "version": "1.0",
    "os": "$(uname -a | tr -d '\n' | sed 's/[^[:print:]]//g')",
    "start_time": "$(date -d @$START_TIME '+%Y-%m-%dT%H:%M:%S')",
    "user": "$(whoami | tr -d '\n' | sed 's/[^[:print:]]//g')"
  },
  "target": {
    "input": "$TARGET",
    "resolved_ipv4": "$TARGET_IPv4",
    "resolved_ipv6": "$TARGET_IPv6",
    "type": "$TYPE_TARGET",
    "protocol": "$(determinar_protocolo)",
    "resolution_time": "$(date +'%Y-%m-%dT%H:%M:%S')"
  },
  "tools_config": {
    "nmap": {
      "ipv4_commands": $(printf '%s\n' "${NMAP_COMMANDS_IPV4[@]}" | jq -R . | jq -s .),
      "ipv6_commands": $(printf '%s\n' "${NMAP_COMMANDS_IPV6[@]}" | jq -R . | jq -s .),
      "silence": "$NMAP_SILENCE"
    },
    "ffuf": {
      "web_commands": $(printf '%s\n' "${FFUF_WEB_COMMANDS[@]}" | jq -R . | jq -s .)
    },
    "autorecon": $(printf '%s\n' "${AR_COMMANDS[@]}" | jq -R . | jq -s .),
    "xray": "$XRAY_COMMAND",
    "firewalk": "$FW_COMMAND",
    "clusterd": "$CL_COMMAND"
  },
  "dependencies": {
    "jq": "$(command -v jq &>/dev/null && echo 'Instalado' || echo 'Não instalado')",
    "nmap": "$(command -v nmap &>/dev/null && echo 'Instalado' || echo 'Não instalado')",
    "ffuf": "$(command -v ffuf &>/dev/null && echo 'Instalado' || echo 'Não instalado')",
    "python3": "$(command -v python3 &>/dev/null && echo 'Instalado' || echo 'Não instalado')",
    "autorecon": "$(command -v autorecon &>/dev/null && echo 'Instalado' || echo 'Não instalado')",
    "xray": "$(command -v xray &>/dev/null && echo 'Instalado' || echo 'Não instalado')",
    "firewalk": "$(command -v firewalk &>/dev/null && echo 'Instalado' || echo 'Não instalado')",
    "clusterd": "$(python3 -m pip show clusterd &>/dev/null && echo 'Instalado' || echo 'Não instalado')"
  },
  "tests": [
EOF
)

    local tests_array=""
    local success_count=0
    local failure_count=0
    for item in "${CHECKLIST[@]}"; do
        # Sanitização aprimorada: remove caracteres de controle e escapa caracteres especiais
        item_sanitized=$(echo "$item" | sed 's/[\x00-\x1F\x7F]//g' | sed 's/"/\\"/g' | sed 's/:/\\:/g')
        IFS=':' read -ra parts <<< "$item_sanitized"
        test_name=$(echo "${parts[0]}" | xargs)
        status=$(echo "${parts[1]}" | xargs)
        message=$(echo "${parts[1]}" | cut -d' ' -f2- | xargs)

        local status_bool=$( [[ "$status" == *"✓"* ]] && echo "true" || echo "false" )
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))

        tests_array+=$(cat <<EOF
    {
      "name": "$test_name",
      "status": $status_bool,
      "message": "$message",
      "timestamp": "$(date +'%Y-%m-%dT%H:%M:%S')",
      "details": {
EOF
)
        case $test_name in
            "Ping"|"Ping Personalizado")
                tests_array+="\"command\": \"ping -c 4 $TARGET_IPv4\", \"packet_loss\": \"$packet_loss\", \"avg_latency\": \"$avg_latency\", \"ipv6_command\": \"ping6 -c 4 $TARGET_IPv6\"}"
                ;;
            "Porta "*)
                tests_array+="\"port\": \"$(echo $test_name | grep -oP '\d+')\", \"ipv4_command\": \"nc -zv -w 2 $TARGET_IPv4 $(echo $test_name | grep -oP '\d+')\", \"ipv6_command\": \"nc -zv -w 2 $TARGET_IPv6 $(echo $test_name | grep -oP '\d+')\", \"filtered_details\": \"$filtered_details\"}"
                ;;
            "Nmap"*)
                tests_array+="\"command\": \"$nmap_cmd\", \"open_ports\": \"$open_ports\"}"
                ;;
            *) tests_array+="\"command\": \"N/A\"" ;;
        esac
        tests_array+=$(cat <<EOF
      },
      "raw_output_file": "$(echo $test_name | tr ' ' '_' | tr -d ':').txt"
    },
EOF
)
    done
    tests_array="${tests_array%,}"

    local json_end=$(cat <<EOF
  ],
  "statistics": {
    "total_tests": ${#CHECKLIST[@]},
    "success_count": $success_count,
    "failure_count": $failure_count,
    "total_execution_time": "$(( $(date +%s) - START_TIME )) seconds"
  }
}
EOF
)

    local json_data="$json_base$tests_array$json_end"
    echo "DEBUG: JSON gerado: $json_data" > debug.log
    echo "$json_data" > temp.json 2>>error.log
    if jq '.' temp.json > "$JSON_FILE" 2>>error.log; then
        rm -f temp.json
        print_status "success" "Resultados salvos em $JSON_FILE"
    else
        cat error.log >&2
        print_status "error" "Falha ao salvar JSON (veja error.log para detalhes)"
        rm -f temp.json
        return 1
    fi
}

#------------#------------# VARIÁVEIS COMANDOS #------------#------------#
NMAP_SILENCE=""
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
FFUF_WEB_COMMANDS=(
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -o ffuf_web_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -e .php,.txt,.html -o ffuf_web_output.csv -of csv"
    "ffuf -u {PROTOCOL}://{TARGET}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -recursion -recursion-depth 2 -o ffuf_web_output.csv -of csv"
)
AR_COMMANDS=(
    "autorecon {TARGET_IP} -o autorecon_output --only-scans"
    "autorecon {TARGET_IP} -o autorecon_output"
    "autorecon {TARGET_IP} -o autorecon_output --web"
)
XRAY_COMMAND="xray ws -domain {TARGET} --json-output xray_output.json"
FW_COMMAND="firewalk -S1-1024 -i eth0 -n {TARGET_IP} -o firewalk_output.txt"
CL_COMMAND="./clusterd.py -t {TARGET} -o clusterd_output.txt"