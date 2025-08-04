#!/bin/bash

# Generate-result.sh
# Função: Processar resultados de autorecon.sh e gerar relatório final em Markdown

# Carregar determinar_protocolo de ativo.sh
source ./ativo.sh

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
sanitize_string() {
    local input="$1"
    echo -n "$input" | tr -d '\n\r\t' | sed 's/[^[:print:]]//g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | sed 's/\\/\\\\/g'
}

get_metadata() {
    local metadata="# Relatório de Análise\n\n"
    metadata+="## Metadados\n"
    metadata+="- **Script**: AutoRecon Script (Versão 1.2.4)\n"
    metadata+="- **Sistema Operacional**: $(sanitize_string "$(uname -a)")\n"
    metadata+="- **Hora de Início**: $(date -d @$START_TIME '+%Y-%m-%d %H:%M:%S')\n"
    metadata+="- **Usuário**: $(sanitize_string "$(whoami)")\n"
    metadata+="- **Alvo**: $(sanitize_string "$TARGET")\n"
    metadata+="- **IPv4 Resolvido**: $(sanitize_string "$TARGET_IPv4")\n"
    metadata+="- **IPv6 Resolvido**: $(sanitize_string "$TARGET_IPv6")\n"
    metadata+="- **Tipo de Alvo**: $(sanitize_string "$TYPE_TARGET")\n"
    metadata+="- **Protocolo**: $(sanitize_string "$(determinar_protocolo)")\n"
    metadata+="- **Hora de Resolução**: $(date +'%Y-%m-%d %H:%M:%S')\n\n"
    echo -e "$metadata"
}

get_tool_config() {
    local config="## Configurações das Ferramentas\n\n"
    config+="### Nmap\n"
    config+="- **Comandos IPv4**: $(printf '%s, ' "${NMAP_COMMANDS_IPV4[@]}" | sed 's/, $//')\n"
    config+="- **Comandos IPv6**: $(printf '%s, ' "${NMAP_COMMANDS_IPV6[@]}" | sed 's/, $//')\n\n"
    config+="### FFuf\n"
    config+="- **Comandos de Subdomínios**: $(printf '%s, ' "${FFUF_SUBDOMAIN[@]}" | sed 's/, $//')\n"
    config+="- **Comandos Web**: $(printf '%s, ' "${FFUF_DOMAINS[@]}" | sed 's/, $//')\n"
    config+="- **Comandos Extensões**: $(printf '%s, ' "${FFUF_EXTENSIONS[@]}" | sed 's/, $//')\n\n"
    echo -e "$config"
}

get_dependencies() {
    local deps="## Dependências\n\n"
    deps+="- **jq**: $(command -v jq &>/dev/null && echo 'Instalado' || echo 'Não instalado')\n"
    deps+="- **nmap**: $(command -v nmap &>/dev/null && echo 'Instalado' || echo 'Não instalado')\n"
    deps+="- **ffuf**: $(command -v ffuf &>/dev/null && echo 'Instalado' || echo 'Não instalado')\n"
    deps+="- **dig**: $(command -v dig &>/dev/null && echo 'Instalado' || echo 'Não instalado')\n"
    deps+="- **traceroute**: $(command -v traceroute &>/dev/null && echo 'Instalado' || echo 'Não instalado')\n"
    deps+="- **curl**: $(command -v curl &>/dev/null && echo 'Instalado' || echo 'Não instalado')\n\n"
    echo -e "$deps"
}

save_test_result() {
    local test_name="$1" status="$2" message="$3" details="$4"
    local report_file="$RESULTS_DIR/relatorio.md"
    local test_entry="### Teste: $(sanitize_string "$test_name")\n"
    test_entry+="- **Status**: $([[ "$status" == *"✓"* ]] && echo 'Sucesso' || echo 'Falha')\n"
    test_entry+="- **Mensagem**: $(sanitize_string "$message")\n"
    test_entry+="- **Timestamp**: $(date +'%Y-%m-%d %H:%M:%S')\n"
    test_entry+="- **Detalhes**:\n$details\n\n"

    if [[ ! -f "$report_file" ]]; then
        mkdir -p "$RESULTS_DIR"
        echo -e "$(get_metadata)$(get_tool_config)$(get_dependencies)## Resultados dos Testes\n\n" > "$report_file"
    fi

    echo -e "$test_entry" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
        echo "Falha ao salvar resultado do teste em $report_file (verifique $RESULTS_DIR/error.log)" >&2
        return 1
    }
}

process_test_results() {
    local success_count=0 failure_count=0
    for item in "${CHECKLIST[@]}"; do
        local item_sanitized=$(sanitize_string "$item")
        IFS=':' read -ra parts <<< "$item_sanitized"
        local test_name=$(echo "${parts[0]}" | xargs)
        local status=$(echo "${parts[1]}" | xargs)
        local message=$(echo "${parts[1]}" | cut -d' ' -f2- | xargs)
        local details=""

        case $test_name in
            "Ping"*)
                local cmd_ipv4=$(sanitize_string "ping -c 4 $TARGET_IPv4")
                local cmd_ipv6=$(sanitize_string "ping6 -c 4 $TARGET_IPv6")
                local packet_loss=$(echo "$message" | grep -oP '\d+(?=% packet loss)' || echo "N/A")
                local avg_latency=$(echo "$message" | grep -oP '[\d.]+(?=ms)' || echo "N/A")
                details="  - Comando IPv4: $cmd_ipv4\n  - Comando IPv6: $cmd_ipv6\n  - Perda de Pacotes: $packet_loss\n  - Latência Média: $avg_latency"
                ;;
            "DNS"*)
                local cmd=$(sanitize_string "dig $TARGET ANY +short")
                local resolved_ips=$(echo "$message" | grep -oP '[\d.,:a-fA-F]+$' || echo "N/A")
                details="  - Comando: $cmd\n  - IPs Resolvidos: $resolved_ips\n  - Arquivo: dig_output.txt"
                ;;
            "Porta"*)
                local port=$(echo "$test_name" | grep -oP '\d+')
                local cmd_ipv4=$(sanitize_string "nc -zv -w 2 $TARGET_IPv4 $port")
                local cmd_ipv6=$(sanitize_string "nc -zv -w 2 $TARGET_IPv6 $port")
                details="  - Porta: $port\n  - Comando IPv4: $cmd_ipv4\n  - Comando IPv6: $cmd_ipv6"
                ;;
            "Nmap"*)
                local cmd=$(sanitize_string "${NMAP_COMMANDS_IPV4[*]}" || echo "N/A")
                local results_file=$(ls "$RESULTS_DIR"/nmap_*.xml 2>/dev/null | xargs -n1 basename | tr '\n' ',' | sed 's/,$//')
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ${results_file:-N/A}"
                ;;
            "FFUF Subdomínios"*)
                local cmd=$(sanitize_string "${FFUF_SUBDOMAIN[*]}")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ffuf_subdomains.csv"
                ;;
            "FFUF Web"*)
                local cmd=$(sanitize_string "${FFUF_DOMAINS[*]}")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ffuf_web.csv"
                ;;
            "FFUF Extensões"*)
                local cmd=$(sanitize_string "${FFUF_EXTENSIONS[*]}")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ffuf_extensions.csv"
                ;;
            "HTTP"*)
                local cmd=$(sanitize_string "curl -sI $(determinar_protocolo)://$TARGET")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: curl_headers.txt"
                ;;
            "Traceroute"*)
                local cmd=$(sanitize_string "traceroute $TARGET_IPv4")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: traceroute_output.txt"
                ;;
            *)
                details="  - Comando: N/A\n  - Arquivo de Resultados: N/A"
                ;;
        esac

        save_test_result "$test_name" "$status" "$message" "$details"
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    echo "$success_count $failure_count"
}

process_result_files() {
    local report_file="$RESULTS_DIR/relatorio.md"
    local files_processed=false

    if [ -d "$RESULTS_DIR" ]; then
        echo -e "\n## Arquivos de Resultados\n" >> "$report_file"
        for file in "$RESULTS_DIR"/*.{txt,csv,xml}; do
            if [ -f "$file" ]; then
                files_processed=true
                local file_name=$(basename "$file")
                local file_type="${file_name##*.}"
                local content=""
                case $file_type in
                    "txt") content=$(cat "$file" 2>/dev/null | sed 's/^/    /') ;;
                    "csv") content=$(awk -F',' 'NR>1 {print "    " $0}' "$file" 2>/dev/null) ;;
                    "xml") content=$(xmllint --format "$file" 2>/dev/null | sed 's/^/    /') ;;
                esac
                if [ -n "$content" ]; then
                    echo -e "### Arquivo: $file_name\n\`\`\`$file_type\n$content\n\`\`\`\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
                        echo "Falha ao incorporar $file_name no relatório (verifique $RESULTS_DIR/error.log)" >&2
                        continue
                    }
                    rm "$file" 2>>"$RESULTS_DIR/error.log" && echo "Arquivo $file_name incorporado e excluído."
                fi
            fi
        done
        [ "$files_processed" = false ] && echo -e "Nenhum arquivo de resultado (txt, csv, xml) encontrado na pasta $RESULTS_DIR.\n" >> "$report_file"
    else
        echo -e "Nenhum arquivo de resultado encontrado, pois a pasta $RESULTS_DIR não existe.\n" >> "$report_file"
    fi
}

generate_statistics() {
    local success_count="$1" failure_count="$2"
    local stats="## Estatísticas\n\n"
    stats+="- **Total de Testes**: ${#CHECKLIST[@]}\n"
    stats+="- **Testes Bem-sucedidos**: $success_count\n"
    stats+="- **Testes com Falha**: $failure_count\n"
    stats+="- **Tempo Total de Execução**: $(( $(date +%s) - START_TIME )) segundos\n\n"
    echo -e "$stats" >> "$RESULTS_DIR/relatorio.md" 2>>"$RESULTS_DIR/error.log" || {
        echo "Falha ao salvar estatísticas no relatório (verifique $RESULTS_DIR/error.log)" >&2
        return 1
    }
}

save_report() {
    IFS=' ' read -r success_count failure_count <<< "$(process_test_results)"
    process_result_files
    generate_statistics "$success_count" "$failure_count"
    echo "Relatório final salvo em $RESULTS_DIR/relatorio.md"
}