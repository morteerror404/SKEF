#!/bin/bash

# Função para sanitizar strings para JSON
sanitize_json_string() {
    local input="$1"
    # Remove caracteres de controle, aspas não escapadas, e sanitiza para JSON
    echo -n "$input" | tr -d '\n\r\t' | sed 's/[^[:print:]]//g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | sed 's/\\/\\\\/g'
}

# Função para salvar resultados em JSON
salvar_json() {
    # Definir o nome do arquivo JSON com base na data e hora atuais
    local json_file="$RESULTS_DIR/Analise $(date +'%d-%m-%Y %H.%M.%S').json"

    # Iniciar a estrutura JSON
    local json_data="{"
    
    # Metadados do script
    json_data+="\"script\": {\"name\": \"AutoRecon Script\", \"version\": \"1.2.4\", \"os\": \"$(sanitize_json_string "$(uname -a)")\", \"start_time\": \"$(date -d @$START_TIME '+%Y-%m-%dT%H:%M:%S')\", \"user\": \"$(sanitize_json_string "$(whoami)")\"},"
    
    # Informações do alvo
    json_data+="\"target\": {\"input\": \"$(sanitize_json_string "$TARGET")\", \"resolved_ipv4\": \"$(sanitize_json_string "$TARGET_IPv4")\", \"resolved_ipv6\": \"$(sanitize_json_string "$TARGET_IPv6")\", \"type\": \"$(sanitize_json_string "$TYPE_TARGET")\", \"protocol\": \"$(sanitize_json_string "$(determinar_protocolo)")\", \"resolution_time\": \"$(date +'%Y-%m-%dT%H:%M:%S')\"},"
    
    # Configurações das ferramentas
    json_data+="\"tools_config\": {"
    json_data+="\"nmap\": {\"ipv4_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV4[@]}" | jq -R . | jq -s .), \"ipv6_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV6[@]}" | jq -R . | jq -s .), \"silence\": \"$(sanitize_json_string "$NMAP_SILENCE")\"},"
    json_data+="\"ffuf\": {\"subdomain_commands\": $(printf '%s\n' "${FFUF_COMMANDS[@]}" | jq -R . | jq -s .), \"web_commands\": $(printf '%s\n' "${FFUF_WEB_COMMANDS[@]}" | jq -R . | jq -s .)},"
    json_data+="\"sherlock\": \"$(sanitize_json_string "$SHERLOCK_COMMAND")\","
    json_data+="\"fierce\": \"$(sanitize_json_string "$FIERCE_COMMAND")\""
    json_data+="},"
    
    # Dependências
    json_data+="\"dependencies\": {"
    json_data+="\"jq\": \"$(command -v jq &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    json_data+="\"nmap\": \"$(command -v nmap &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    json_data+="\"ffuf\": \"$(command -v ffuf &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    json_data+="\"python3\": \"$(command -v python3 &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    json_data+="\"sherlock\": \"$(python3 -m pip show sherlock-project &>/dev/null && echo 'Instalado' || echo 'Não instalado')\","
    json_data+="\"fierce\": \"$(command -v fierce &>/dev/null && echo 'Instalado' || echo 'Não instalado')\""
    json_data+="},"
    
    # Resultados dos testes
    json_data+="\"tests\": ["
    local success_count=0 failure_count=0
    for item in "${CHECKLIST[@]}"; do
        item_sanitized=$(sanitize_json_string "$item")
        IFS=':' read -ra parts <<< "$item_sanitized"
        test_name=$(echo "${parts[0]}" | xargs)
        status=$(echo "${parts[1]}" | xargs)
        message=$(echo "${parts[1]}" | cut -d' ' -f2- | xargs)
        json_data+="{\"name\": \"$(sanitize_json_string "$test_name")\", \"status\": $([[ "$status" == *"✓"* ]] && echo "true" || echo "false"), \"message\": \"$(sanitize_json_string "$message")\", \"timestamp\": \"$(date +'%Y-%m-%dT%H:%M:%S')\", \"details\": {"
        case $test_name in
            "Ping"|"Ping Personalizado")
                json_data+="\"command\": \"$(sanitize_json_string "ping -c 4 $TARGET_IPv4")\", \"packet_loss\": \"${packet_loss:-N/A}\", \"avg_latency\": \"${avg_latency:-N/A}\", \"ipv6_command\": \"$(sanitize_json_string "ping6 -c 4 $TARGET_IPv6")\"}"
                ;;
            "DNS"|"DNS Personalizado")
                json_data+="\"command\": \"$(sanitize_json_string "dig $TARGET +short")\", \"resolved_ips\": \"$(sanitize_json_string "${ips:-N/A}")\"}"
                ;;
            "Porta "*)
                json_data+="\"port\": \"$(echo $test_name | grep -oP '\d+')\", \"ipv4_command\": \"$(sanitize_json_string "nc -zv -w 2 $TARGET_IPv4 $(echo $test_name | grep -oP '\d+')")\", \"ipv6_command\": \"$(sanitize_json_string "nc -zv -w 2 $TARGET_IPv6 $(echo $test_name | grep -oP '\d+')")\", \"filtered_details\": \"$(sanitize_json_string "${filtered_details:-N/A}")\"}"
                ;;
            "Nmap"*)
                json_data+="\"command\": \"$(sanitize_json_string "${nmap_cmd:-N/A}")\", \"open_ports\": \"$(sanitize_json_string "${open_ports:-N/A}")\", \"results_file\": \"$(sanitize_json_string "$(basename "$RESULTS_DIR/nmap_$(echo $test_name | tr ' ' '_' | tr -d ':').xml")\")\"}"
                ;;
            "FFUF"*)
                json_data+="\"command\": \"$(sanitize_json_string "${cmd_substituido:-N/A}")\", \"results_file\": \"$(sanitize_json_string "$(basename "$RESULTS_DIR/ffuf_$(echo $test_name | tr ' ' '_' | tr -d ':').csv")\")\"}"
                ;;
            "WHOIS"|"WHOIS Personalizado")
                json_data+="\"command\": \"$(sanitize_json_string "${WHOIS_COMMAND:-N/A}")\", \"results_file\": \"$(sanitize_json_string "whois_output.txt")\"}"
                ;;
            "Sherlock")
                json_data+="\"command\": \"$(sanitize_json_string "${SHERLOCK_COMMAND:-N/A}")\", \"results_file\": \"$(sanitize_json_string "sherlock_output.txt")\"}"
                ;;
            "Fierce")
                json_data+="\"command\": \"$(sanitize_json_string "${FIERCE_COMMAND:-N/A}")\", \"results_file\": \"$(sanitize_json_string "fierce_output.txt")\"}"
                ;;
            *)
                json_data+="\"command\": \"N/A\", \"results_file\": \"N/A\"}"
                ;;
        esac
        json_data+="}, \"raw_output_file\": \"$(sanitize_json_string "$(basename "$RESULTS_DIR/$(echo $test_name | tr ' ' '_' | tr -d ':').txt")")\"},"
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    json_data="${json_data%,]}"
    
    # Processar arquivos da pasta results (apenas .txt, .csv, .xml)
    json_data+="],\"results_files\": ["
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
                [ -n "$content" ] && json_data+="{\"file\": \"$(sanitize_json_string "$file_name")\", \"type\": \"$file_type\", \"content\": $content},"
            fi
        done
        json_data="${json_data%,}"
    fi
    json_data+="],"
    
    # Estatísticas
    json_data+="\"statistics\": {\"total_tests\": ${#CHECKLIST[@]}, \"success_count\": $success_count, \"failure_count\": $failure_count, \"total_execution_time\": \"$(( $(date +%s) - START_TIME )) seconds\"}"
    json_data+="}"
    
    # Salvar o JSON
    mkdir -p "$RESULTS_DIR"
    echo "$json_data" | jq '.' > "$json_file" 2>>"$RESULTS_DIR/error.log" || { print_status "error" "Falha ao salvar JSON (verifique $RESULTS_DIR/error.log)"; return 1; }
    print_status "success" "Resultados salvos em $json_file"
}

# Função auxiliar para determinar o protocolo (usada nos metadados do alvo)
determinar_protocolo() {
    local protocol="http"
    { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
    echo "$protocol"
}