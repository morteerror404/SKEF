#!/bin/bash

# Função para sanitizar strings para JSON
sanitize_string() {
    local input="$1"
    echo -n "$input" | tr -d '\n\r\t' | sed 's/[^[:print:]]//g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | sed 's/\\/\\\\/g'
}

# Função para determinar o protocolo HTTP/HTTPS
determine_protocol() {
    local protocol="http"
    { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
    echo "$protocol"
}

# Função para coletar metadados
get_metadata() {
    local metadata="\"script\": {\"name\": \"AutoRecon Script\", \"version\": \"1.2.4\", \"os\": \"$(sanitize_string "$(uname -a)")\", \"start_time\": \"$(date -d @$START_TIME '+%Y-%m-%dT%H:%M:%S')\", \"user\": \"$(sanitize_string "$(whoami)")\"},"
    metadata+="\"target\": {\"input\": \"$(sanitize_string "$TARGET")\", \"resolved_ipv4\": \"$(sanitize_string "$TARGET_IPv4")\", \"resolved_ipv6\": \"$(sanitize_string "$TARGET_IPv6")\", \"type\": \"$(sanitize_string "$TYPE_TARGET")\", \"protocol\": \"$(sanitize_string "$(determine_protocol)")\", \"resolution_time\": \"$(date +'%Y-%m-%dT%H:%M:%S')\"}"
    echo "$metadata"
}

# Função para obter configurações das ferramentas
get_tool_config() {
    local config="\"tools_config\": {"
    config+="\"nmap\": {\"ipv4_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV4[@]}" | jq -R . | jq -s .), \"ipv6_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV6[@]}" | jq -R . | jq -s .), \"silence\": \"$(sanitize_string "$NMAP_SILENCE")\"},"
    config+="\"ffuf\": {\"subdomain_commands\": $(printf '%s\n' "${FFUF_COMMANDS[@]}" | jq -R . | jq -s .), \"web_commands\": $(printf '%s\n' "${FFUF_WEB_COMMANDS[@]}" | jq -R . | jq -s .)},"
    config+="\"sherlock\": \"$(sanitize_string "$SHERLOCK_COMMAND")\","
    config+="\"fierce\": \"$(sanitize_string "$FIERCE_COMMAND")\"}"
    echo "$config"
}

# Função para verificar dependências
get_dependencies() {
    local deps="\"dependencies\": {"
    deps+="\"jq\": \"$(command -v jq &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    deps+="\"nmap\": \"$(command -v nmap &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    deps+="\"ffuf\": \"$(command -v ffuf &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    deps+="\"python3\": \"$(command -v python3 &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    deps+="\"sherlock\": \"$(python3 -m pip show sherlock-project &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    deps+="\"fierce\": \"$(command -v fierce &>/dev/null && echo 'Instalado' || echo 'Não instalado')\"}"
    echo "$deps"
}

# Função para processar resultados dos testes
process_test_results() {
    local tests="\"tests\": ["
    local success_count=0
    local failure_count=0
    for item in "${CHECKLIST[@]}"; do
        local item_sanitized=$(sanitize_string "$item")
        IFS=':' read -ra parts <<< "$item_sanitized"
        local test_name=$(echo "${parts[0]}" | xargs)
        local status=$(echo "${parts[1]}" | xargs)
        local message=$(echo "${parts[1]}" | cut -d' ' -f2- | xargs)
        local details=""

        case $test_name in
            "Ping"|"Ping Personalizado")
                local cmd_ipv4=$(sanitize_string "ping -c 4 $TARGET_IPv4")
                local packet_loss=$(sanitize_string "${packet_loss:-N/A}")
                local avg_latency=$(sanitize_string "${avg_latency:-N/A}")
                local cmd_ipv6=$(sanitize_string "ping6 -c 4 $TARGET_IPv6")
                details="\"command\": \"$cmd_ipv4\", \"packet_loss\": \"$packet_loss\", \"avg_latency\": \"$avg_latency\", \"ipv6_command\": \"$cmd_ipv6\""
                ;;
            "DNS"|"DNS Personalizado")
                local cmd=$(sanitize_string "dig $TARGET +short")
                local resolved_ips=$(sanitize_string "${ips:-N/A}")
                details="\"command\": \"$cmd\", \"resolved_ips\": \"$resolved_ips\""
                ;;
            "Porta "*)
                local port=$(echo $test_name | grep -oP '\d+')
                local cmd_ipv4=$(sanitize_string "nc -zv -w 2 $TARGET_IPv4 $port")
                local cmd_ipv6=$(sanitize_string "nc -zv -w 2 $TARGET_IPv6 $port")
                local filtered_details=$(sanitize_string "${filtered_details:-N/A}")
                details="\"port\": \"$port\", \"ipv4_command\": \"$cmd_ipv4\", \"ipv6_command\": \"$cmd_ipv6\", \"filtered_details\": \"$filtered_details\""
                ;;
            "Nmap"*)
                local cmd=$(sanitize_string "${nmap_cmd:-N/A}")
                local open_ports=$(sanitize_string "${open_ports:-N/A}")
                local results_file=$(sanitize_string "$(basename "$RESULTS_DIR/nmap_$(echo $test_name | tr ' ' '_' | tr -d ':').xml")")
                details="\"command\": \"$cmd\", \"open_ports\": \"$open_ports\", \"results_file\": \"$results_file\""
                ;;
            "FFUF"*)
                local cmd=$(sanitize_string "${cmd_substituido:-N/A}")
                local results_file=$(sanitize_string "$(basename "$RESULTS_DIR/ffuf_$(echo $test_name | tr ' ' '_' | tr -d ':').csv")")
                details="\"command\": \"$cmd\", \"results_file\": \"$results_file\""
                ;;
            "WHOIS"|"WHOIS Personalizado")
                local cmd=$(sanitize_string "${WHOIS_COMMAND:-N/A}")
                local results_file=$(sanitize_string "whois_output.txt")
                details="\"command\": \"$cmd\", \"results_file\": \"$results_file\""
                ;;
            "Sherlock")
                local cmd=$(sanitize_string "${SHERLOCK_COMMAND:-N/A}")
                local results_file=$(sanitize_string "sherlock_output.txt")
                details="\"command\": \"$cmd\", \"results_file\": \"$results_file\""
                ;;
            "Fierce")
                local cmd=$(sanitize_string "${FIERCE_COMMAND:-N/A}")
                local results_file=$(sanitize_string "fierce_output.txt")
                details="\"command\": \"$cmd\", \"results_file\": \"$results_file\""
                ;;
            *)
                local cmd="N/A"
                local results_file="N/A"
                details="\"command\": \"$cmd\", \"results_file\": \"$results_file\""
                ;;
        esac

        tests+="{\"name\": \"$(sanitize_string "$test_name")\", \"status\": $([[ "$status" == *"✓"* ]] && echo "true" || echo "false"), \"message\": \"$(sanitize_string "$message")\", \"timestamp\": \"$(date +'%Y-%m-%dT%H:%M:%S')\", \"details\": { $details }},"
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    tests="${tests%,]}"
    echo "$tests" "success_count:$success_count" "failure_count:$failure_count"
}

# Função para processar arquivos da pasta results
process_result_files() {
    local files="\"results_files\": ["
    if [ -d "$RESULTS_DIR" ]; then
        for file in "$RESULTS_DIR"/*.{txt,csv,xml}; do
            if [ -f "$file" ]; then
                local file_name=$(basename "$file")
                local file_type="${file_name##*.}"
                local content=""
                case $file_type in
                    "txt")
                        content=$(cat "$file" 2>/dev/null | tr -d '\n\r\t' | sed 's/[^[:print:]]//g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | jq -R .)
                        ;;
                    "csv")
                        content=$(awk -F',' 'NR>1 {print $0}' "$file" 2>/dev/null | tr -d '\n\r\t' | sed 's/[^[:print:]]//g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | jq -R . | jq -s .)
                        ;;
                    "xml")
                        content=$(xmllint --format "$file" 2>/dev/null | tr -d '\n\r\t' | sed 's/[^[:print:]]//g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | jq -R .)
                        ;;
                esac
                [ -n "$content" ] && files+="{\"file\": \"$(sanitize_string "$file_name")\", \"type\": \"$file_type\", \"content\": $content},"
            fi
        done
        files="${files%,}"
    fi
    echo "$files"
}

# Função para gerar estatísticas
generate_statistics() {
    local stats="\"statistics\": {\"total_tests\": ${#CHECKLIST[@]}, \"success_count\": $1, \"failure_count\": $2, \"total_execution_time\": \"$(( $(date +%s) - START_TIME )) seconds\"}"
    echo "$stats"
}

# Função principal para salvar o JSON
save_json() {
    local json_data="{"
    json_data+="$(get_metadata),"
    json_data+="$(get_tool_config),"
    json_data+="$(get_dependencies),"
    local test_results=$(process_test_results)
    IFS=' ' read -r tests success_count failure_count <<< "$test_results"
    json_data+="$tests,"
    json_data+="$(process_result_files),"
    json_data+="$(generate_statistics "$success_count" "$failure_count")"
    json_data+="}"

    mkdir -p "$RESULTS_DIR"
    echo "$json_data" | jq '.' > "$RESULTS_DIR/Analise $(date +'%d-%m-%Y %H.%M.%S').json" 2>>"$RESULTS_DIR/error.log" || { echo "Falha ao salvar JSON (verifique $RESULTS_DIR/error.log)" >&2; return 1; }
    echo "Resultados salvos em $RESULTS_DIR/Analise $(date +'%d-%m-%Y %H.%M.%S').json"
}