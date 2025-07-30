#!/bin/bash

# Função para salvar resultados em JSON
salvar_json() {
    # Definir o nome do arquivo JSON com base na data e hora atuais
    local json_file="$RESULTS_DIR/Analise $(date +'%d-%m-%Y %H.%M.%S').json"

    # Iniciar a estrutura JSON
    local json_data="{"
    
    # Metadados do script
    json_data+="\"script\": {\"name\": \"AutoRecon Script\", \"version\": \"1.2.4\", \"os\": \"$(uname -a | tr -d '\n' | sed 's/[^[:print:]]//g')\", \"start_time\": \"$(date -d @$START_TIME '+%Y-%m-%dT%H:%M:%S')\", \"user\": \"$(whoami | tr -d '\n' | sed 's/[^[:print:]]//g')\"},"
    
    # Informações do alvo
    json_data+="\"target\": {\"input\": \"$TARGET\", \"resolved_ipv4\": \"$TARGET_IPv4\", \"resolved_ipv6\": \"$TARGET_IPv6\", \"type\": \"$TYPE_TARGET\", \"protocol\": \"$(determinar_protocolo)\", \"resolution_time\": \"$(date +'%Y-%m-%dT%H:%M:%S')\"},"
    
    # Configurações das ferramentas
    json_data+="\"tools_config\": {"
    json_data+="\"nmap\": {\"ipv4_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV4[@]}" | jq -R . | jq -s .), \"ipv6_commands\": $(printf '%s\n' "${NMAP_COMMANDS_IPV6[@]}" | jq -R . | jq -s .), \"silence\": \"$NMAP_SILENCE\"},"
    json_data+="\"ffuf\": {\"subdomain_commands\": $(printf '%s\n' "${FFUF_COMMANDS[@]}" | jq -R . | jq -s .), \"web_commands\": $(printf '%s\n' "${FFUF_WEB_COMMANDS[@]}" | jq -R . | jq -s .)},"
    json_data+="\"sherlock\": \"$(echo "$SHERLOCK_COMMAND" | jq -R .)\","
    json_data+="\"fierce\": \"$(echo "$FIERCE_COMMAND" | jq -R .)\""
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
        item_sanitized=$(echo "$item" | sed 's/[^[:print:]]//g')
        IFS=':' read -ra parts <<< "$item_sanitized"
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
                json_data+="\"port\": \"$(echo $test_name | grep -oP '\d+')\", \"ipv4_command\": \"nc -zv -w 2 $TARGET_IPv4 $(echo $test_name | grep -oP '\d+')\", \"ipv6_command\": \"nc -zv -w 2 $TARGET_IPv6 $(echo $test_name | grep -oP '\d+')\", \"filtered_details\": \"${filtered_details:-N/A}\"}"
                ;;
            "Nmap"*)
                json_data+="\"command\": \"${nmap_cmd:-N/A}\", \"open_ports\": \"${open_ports:-N/A}\", \"results_file\": \"$(basename "$RESULTS_DIR/nmap_$(echo $test_name | tr ' ' '_' | tr -d ':').xml\")\"}"
                ;;
            "FFUF"*)
                json_data+="\"command\": \"${cmd_substituido:-N/A}\", \"results_file\": \"$(basename "$RESULTS_DIR/ffuf_$(echo $test_name | tr ' ' '_' | tr -d ':').csv\")\"}"
                ;;
            "WHOIS"|"WHOIS Personalizado")
                json_data+="\"command\": \"${WHOIS_COMMAND:-N/A}\", \"results_file\": \"whois_output.txt\"}"
                ;;
            "Sherlock")
                json_data+="\"command\": \"${SHERLOCK_COMMAND:-N/A}\", \"results_file\": \"sherlock_output.txt\"}"
                ;;
            "Fierce")
                json_data+="\"command\": \"${FIERCE_COMMAND:-N/A}\", \"results_file\": \"fierce_output.txt\"}"
                ;;
            *) json_data+="\"command\": \"N/A\", \"results_file\": \"N/A\"}" ;;
        esac
        json_data+="}, \"raw_output_file\": \"$(basename "$RESULTS_DIR/$(echo $test_name | tr ' ' '_' | tr -d ':').txt\")\"},"
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    json_data="${json_data%,]}"
    
    # Processar arquivos da pasta results
    json_data+="],\"results_files\": ["
    if [ -d "$RESULTS_DIR" ]; then
        for file in "$RESULTS_DIR"/*; do
            if [ -f "$file" ] && [ "$file" != "$json_file" ]; then
                local file_name=$(basename "$file")
                local file_type="${file_name##*.}"
                local content=""
                case $file_type in
                    "txt")
                        content=$(cat "$file" 2>/dev/null | tr -d '\n' | sed 's/[^[:print:]]//g' | jq -R .)
                        ;;
                    "csv")
                        content=$(awk -F',' 'NR>1 {print $0}' "$file" 2>/dev/null | tr -d '\n' | sed 's/[^[:print:]]//g' | jq -R . | jq -s .)
                        ;;
                    "xml")
                        content=$(xmllint --format "$file" 2>/dev/null | tr -d '\n' | sed 's/[^[:print:]]//g' | jq -R .)
                        ;;
                    *)
                        content=$(cat "$file" 2>/dev/null | tr -d '\n' | sed 's/[^[:print:]]//g' | jq -R .)
                        ;;
                esac
                [ -n "$content" ] && json_data+="{\"file\": \"$file_name\", \"type\": \"$file_type\", \"content\": $content},"
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