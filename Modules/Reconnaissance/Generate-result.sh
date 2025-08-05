#!/bin/bash

# Generate-result.sh
# Função: Processar resultados de autorecon.sh e gerar relatório final em Markdown
# Dependências: utils.sh, ativo.sh

source ./utils.sh
source ./ativo.sh

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
sanitize_string() {
    local input="$1"
    echo -n "$input" | tr -d '\n\r\t\0' | sed 's/[^[:print:]]//g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | sed 's/\\/\\\\/g'
}

get_metadata() {
    local metadata="# Relatório de Análise\n\n"
    metadata+="## Metadados\n"
    [ -z "$TARGET" ] && { print_status "error" "TARGET não definido"; echo "TARGET não definido" >>"$RESULTS_DIR/error.log"; return 1; }
    [ -z "$TYPE_TARGET" ] && { print_status "error" "TYPE_TARGET não definido"; echo "TYPE_TARGET não definido" >>"$RESULTS_DIR/error.log"; return 1; }
    [ -z "$START_TIME" ] && START_TIME=$(date +%s)
    metadata+="- **Script**: AutoRecon Script (Versão 1.2.4)\n"
    metadata+="- **Sistema Operacional**: $(sanitize_string "$(uname -a)")\n"
    metadata+="- **Hora de Início**: $(date -d @$START_TIME '+%Y-%m-%d %H:%M:%S')\n"
    metadata+="- **Usuário**: $(sanitize_string "$(whoami)")\n"
    metadata+="- **Alvo**: $(sanitize_string "$TARGET")\n"
    metadata+="- **IPv4 Resolvido**: $(sanitize_string "${TARGET_IPv4:-Não resolvido}")\n"
    metadata+="- **IPv6 Resolvido**: $(sanitize_string "${TARGET_IPv6:-Não resolvido}")\n"
    metadata+="- **Tipo de Alvo**: $(sanitize_string "$TYPE_TARGET")\n"
    metadata+="- **Protocolo**: $(sanitize_string "$(determinar_protocolo)")\n"
    metadata+="- **Hora de Resolução**: $(date +'%Y-%m-%d %H:%M:%S')\n\n"
    echo -e "$metadata"
}

get_tool_config() {
    local config="## Configurações das Ferramentas\n\n"
    config+="### Nmap\n"
    for cmd in "${NMAP_COMMANDS_IPV4[@]}"; do
        config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv4")")\n"
    done
    for cmd in "${NMAP_COMMANDS_IPV6[@]}"; do
        config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv6")")\n"
    done
    config+="\n### FFUF\n"
    for cmd in "${FFUF_COMMANDS[@]}"; do
        config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv4")")\n"
    done
    for cmd in "${FFUF_WEB_COMMANDS[@]}"; do
        config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv4")")\n"
    done
    for cmd in "${FFUF_EXT_COMMANDS[@]}"; do
        config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv4")")\n"
    done
    config+="\n"
    echo -e "$config"
}

get_dependencies() {
    local deps="## Dependências\n\n"
    for cmd in jq nmap ffuf dig traceroute curl nc xmllint; do
        deps+="- **$cmd**: $(command -v $cmd &>/dev/null && echo "Instalado ($(sanitize_string "$($cmd --version 2>&1 | head -n1)")") || echo 'Não instalado')\n"
    done
    deps+="\n"
    echo -e "$deps"
}

clean_intermediate_files() {
    print_status "info" "Removendo arquivos intermediários em $RESULTS_DIR..."
    local temp_error_log=$(mktemp)
    if [ -f "$RESULTS_DIR/error.log" ]; then
        mv "$RESULTS_DIR/error.log" "$temp_error_log" 2>/dev/null || {
            print_status "error" "Falha ao mover error.log para temporário"
            echo "Falha ao mover error.log para temporário" >>"$temp_error_log"
            return 1
        }
    fi
    local files_removed=0
    for file in "$RESULTS_DIR"/*.{txt,csv,xml}; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "relatorio.md" ]; then
            rm -f "$file" 2>>"$temp_error_log" && ((files_removed++))
            print_status "success" "Arquivo $(basename "$file") removido."
        fi
    done
    if [ -f "$temp_error_log" ]; then
        mv "$temp_error_log" "$RESULTS_DIR/error.log" 2>/dev/null || {
            print_status "error" "Falha ao restaurar error.log"
            echo "Falha ao restaurar error.log" >>"$RESULTS_DIR/error.log"
            return 1
        }
    fi
    [ $files_removed -eq 0 ] && print_status "info" "Nenhum arquivo intermediário encontrado para remoção."
}

save_test_result() {
    # Verificar permissões do diretório
    if ! [ -d "$RESULTS_DIR" ] || ! [ -w "$RESULTS_DIR" ]; then
        mkdir -p "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao criar diretório $RESULTS_DIR"
            return 1
        }
        chmod u+w "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao definir permissões no diretório $RESULTS_DIR"
            return 1
        }
    fi

    # Verificar permissões do diretório
    if ! [ -d "$RESULTS_DIR" ] || ! [ -w "$RESULTS_DIR" ]; then
        print_status "error" "Diretório $RESULTS_DIR não existe ou não tem permissões de escrita"
        echo "Erro: Diretório $RESULTS_DIR não existe ou não tem permissões de escrita" >>"$RESULTS_DIR/error.log"
        return 1
    fi

    # Inicializar relatório se não existir
    if [[ ! -f "$report_file" ]]; then
        mkdir -p "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao criar diretório $RESULTS_DIR"
            echo "Falha ao criar diretório $RESULTS_DIR" >>"$RESULTS_DIR/error.log"
            return 1
        }
        chmod u+w "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao definir permissões no diretório $RESULTS_DIR"
            echo "Falha ao definir permissões no diretório $RESULTS_DIR" >>"$RESULTS_DIR/error.log"
            return 1
        }
        echo -e "$(get_metadata)$(get_tool_config)$(get_dependencies)## Resultados dos Testes\n\n" > "$report_file" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao inicializar $report_file"
            echo "Falha ao inicializar $report_file" >>"$RESULTS_DIR/error.log"
            return 1
        }
    fi

    # Escrever no relatório
    echo -e "$test_entry" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
        print_status "error" "Falha ao salvar resultado do teste em $report_file"
        echo "Falha ao salvar resultado do teste em $report_file: $test_name" >>"$RESULTS_DIR/error.log"
        return 1
    }
}

process_test_results() {
    # Adicionado tratamento para Nmap
    case $test_name in
        "Nmap IPv4"*)
            local scan_type=$(echo "$test_name" | sed 's/Nmap IPv4 //')
            local cmd="" results_file=""
            case "$scan_type" in
                "TCP Connect Scan") 
                    cmd=$(substituir_variaveis "${NMAP_COMMANDS_IPV4[0]}" "$TARGET_IPv4")
                    results_file="$RESULTS_DIR/nmap_ipv4_tcp_connect.xml"
                    ;;
                "OS Detection Scan")
                    cmd=$(substituir_variaveis "${NMAP_COMMANDS_IPV4[1]}" "$TARGET_IPv4")
                    results_file="$RESULTS_DIR/nmap_ipv4_os_detection.xml"
                    ;;
                "Service Version Scan")
                    cmd=$(substituir_variaveis "${NMAP_COMMANDS_IPV4[2]}" "$TARGET_IPv4")
                    results_file="$RESULTS_DIR/nmap_ipv4_service_version.xml"
                    ;;
            esac
            details="  - Tipo: $scan_type\n  - Comando: $cmd\n  - Arquivo: ${results_file##*/}"
            ;;
        # Tratamento similar para IPv6...
    esac
}
    local success_count=0 failure_count=0
    [ ${#CHECKLIST[@]} -eq 0 ] && {
        print_status "error" "CHECKLIST vazia, nenhum teste para processar"
        echo "CHECKLIST vazia, nenhum teste para processar" >>"$RESULTS_DIR/error.log"
        return 1
    }
    for item in "${CHECKLIST[@]}"; do
        local item_sanitized=$(sanitize_string "$item")
        [ -z "$item_sanitized" ] && {
            print_status "error" "Item vazio em CHECKLIST"
            echo "Item vazio em CHECKLIST" >>"$RESULTS_DIR/error.log"
            continue
        }
        IFS=':' read -ra parts <<< "$item_sanitized"
        local test_name=$(echo "${parts[0]}" | xargs)
        local status=$(echo "${parts[1]}" | xargs)
        local message=$(echo "${parts[1]}" | cut -d' ' -f2- | xargs)
        local details=""
        local file_content=""

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
            "Nmap IPv4"*)
                local scan_type=$(echo "$test_name" | sed 's/Nmap IPv4 //')
                local cmd=""
                local results_file=""
                case "$scan_type" in
                    "TCP Connect Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV4[0]}" "$TARGET_IPv4")"); results_file="$RESULTS_DIR/nmap_ipv4_nmap_TARGET_IP_-sT_-vv_-Pn.xml" ;;
                    "OS Detection Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV4[1]}" "$TARGET_IPv4")"); results_file="$RESULTS_DIR/nmap_ipv4_nmap_TARGET_IP_-vv_-O_-Pn.xml" ;;
                    "Service Version Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV4[2]}" "$TARGET_IPv4")"); results_file="$RESULTS_DIR/nmap_ipv4_nmap_TARGET_IP_-sV_-O_-vv_-Pn.xml" ;;
                esac
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ${results_file:-N/A}"
                if [ -f "$results_file" ]; then
                    if command -v xmllint &>/dev/null; then
                        file_content="$(xmllint --format "$results_file" 2>/dev/null | sed 's/^/    /')"
                    else
                        file_content="    xmllint não instalado, conteúdo XML não formatado:\n$(cat "$results_file" | sed 's/^/    /')"
                    fi
                else
                    file_content="    Arquivo $results_file não encontrado"
                    echo "Arquivo $results_file não encontrado para $test_name" >>"$RESULTS_DIR/error.log"
                fi
                ;;
            "Nmap IPv6"*)
                local scan_type=$(echo "$test_name" | sed 's/Nmap IPv6 //')
                local cmd=""
                local results_file=""
                case "$scan_type" in
                    "TCP Connect Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV6[0]}" "$TARGET_IPv6")"); results_file="$RESULTS_DIR/nmap_ipv6_nmap_-6_TARGET_IP_-sT_-vv_-Pn.xml" ;;
                    "OS Detection Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV6[1]}" "$TARGET_IPv6")"); results_file="$RESULTS_DIR/nmap_ipv6_nmap_-6_TARGET_IP_-vv_-O_-Pn.xml" ;;
                    "Service Version Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV6[2]}" "$TARGET_IPv6")"); results_file="$RESULTS_DIR/nmap_ipv6_nmap_-6_TARGET_IP_-sV_-O_-vv_-Pn.xml" ;;
                esac
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ${results_file:-N/A}"
                if [ -f "$results_file" ]; then
                    if command -v xmllint &>/dev/null; then
                        file_content="$(xmllint --format "$results_file" 2>/dev/null | sed 's/^/    /')"
                    else
                        file_content="    xmllint não instalado, conteúdo XML não formatado:\n$(cat "$results_file" | sed 's/^/    /')"
                    fi
                else
                    file_content="    Arquivo $results_file não encontrado"
                    echo "Arquivo $results_file não encontrado para $test_name" >>"$RESULTS_DIR/error.log"
                fi
                ;;
            "FFUF Subdomínios")
                local cmd=$(sanitize_string "$(substituir_variaveis "${FFUF_COMMANDS[*]}" "$TARGET_IPv4")")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ffuf_subdomains.csv"
                ;;
            "FFUF Web")
                local cmd=$(sanitize_string "$(substituir_variaveis "${FFUF_WEB_COMMANDS[*]}" "$TARGET_IPv4")"))
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ffuf_web.csv"
                ;;
            "FFUF Extensões")
                local cmd=$(sanitize_string "$(substituir_variaveis "${FFUF_EXT_COMMANDS[*]}" "$TARGET_IPv4")"))
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ffuf_extensions.csv"
                ;;
            "HTTP"*)
                local cmd=$(sanitize_string "curl -sI $(determinar_protocolo)://$TARGET")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: http_test.txt"
                ;;
            "Traceroute"*)
                local cmd=$(sanitize_string "traceroute $TARGET_IPv4")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: traceroute_output.txt"
                ;;
            *)
                details="  - Comando: N/A\n  - Arquivo de Resultados: N/A"
                ;;
        esac

        save_test_result "$test_name" "$status" "$message" "$details" "$file_content"
        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done
    echo "$success_count $failure_count"
}

process_result_files() {
    local report_file="$RESULTS_DIR/relatorio.md"
    local files_processed=false

    if [ -d "$RESULTS_DIR" ]; then
        echo -e "\n## Arquivos de Resultados\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao escrever seção de arquivos em $report_file"
            echo "Falha ao escrever seção de arquivos em $report_file" >>"$RESULTS_DIR/error.log"
            return 1
        }
        for file in "$RESULTS_DIR"/*.{txt,csv}; do
            if [ -f "$file" ] && [ "$(basename "$file")" != "relatorio.md" ]; then
                files_processed=true
                local file_name=$(basename "$file")
                local file_type="${file_name##*.}"
                local content=""
                case $file_type in
                    "txt") content=$(cat "$file" 2>/dev/null | sed 's/^/    /') ;;
                    "csv") content=$(awk -F',' 'NR>1 {print "    " $0}' "$file" 2>/dev/null) ;;
                esac
                if [ -n "$content" ]; then
                    echo -e "### Arquivo: $file_name\n\`\`\`$file_type\n$content\n\`\`\`\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
                        print_status "error" "Falha ao incorporar $file_name no relatório"
                        echo "Falha ao incorporar $file_name no relatório" >>"$RESULTS_DIR/error.log"
                        continue
                    }
                    print_status "success" "Arquivo $file_name incorporado no relatório."
                else
                    print_status "error" "Falha ao ler conteúdo de $file_name"
                    echo "Falha ao ler $file_name" >>"$RESULTS_DIR/error.log"
                fi
            fi
        done
        [ "$files_processed" = false ] && echo -e "Nenhum arquivo de resultado (txt, csv) encontrado na pasta $RESULTS_DIR.\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log"
    else
        echo -e "Nenhum arquivo de resultado encontrado, pois a pasta $RESULTS_DIR não existe.\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log"
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
        print_status "error" "Falha ao salvar estatísticas no relatório"
        echo "Falha ao salvar estatísticas no relatório" >>"$RESULTS_DIR/error.log"
        return 1
    }
}

save_report() {
    # Manipulador de interrupção para limpar arquivos
    trap 'print_status "error" "Execução interrompida, limpando arquivos intermediários..."; clean_intermediate_files; exit 1' SIGINT

    print_status "info" "Iniciando geração do relatório..."
    mkdir -p "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
        print_status "error" "Falha ao criar diretório $RESULTS_DIR"
        echo "Falha ao criar diretório $RESULTS_DIR" >>"$RESULTS_DIR/error.log"
        return 1
    }
    chmod u+w "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
        print_status "error" "Falha ao definir permissões no diretório $RESULTS_DIR"
        echo "Falha ao definir permissões no diretório $RESULTS_DIR" >>"$RESULTS_DIR/error.log"
        return 1
    }

    echo "DEBUG: Iniciando process_test_results" >>"$RESULTS_DIR/error.log"
    IFS=' ' read -r success_count failure_count <<< "$(process_test_results)"
    if [ $? -ne 0 ]; then
        print_status "error" "Falha ao processar resultados dos testes"
        echo "Falha ao processar resultados dos testes" >>"$RESULTS_DIR/error.log"
        return 1
    fi
    echo "DEBUG: process_test_results concluído, success_count=$success_count, failure_count=$failure_count" >>"$RESULTS_DIR/error.log"
    echo "DEBUG: Iniciando process_result_files" >>"$RESULTS_DIR/error.log"
    process_result_files
    if [ $? -ne 0 ]; then
        print_status "error" "Falha ao processar arquivos de resultados"
        echo "Falha ao processar arquivos de resultados" >>"$RESULTS_DIR/error.log"
        return 1
    fi
    echo "DEBUG: process_result_files concluído" >>"$RESULTS_DIR/error.log"
    echo "DEBUG: Iniciando generate_statistics" >>"$RESULTS_DIR/error.log"
    generate_statistics "$success_count" "$failure_count"
    if [ $? -ne 0 ]; then
        print_status "error" "Falha ao gerar estatísticas"
        echo "Falha ao gerar estatísticas" >>"$RESULTS_DIR/error.log"
        return 1
    fi
    echo "DEBUG: generate_statistics concluído" >>"$RESULTS_DIR/error.log"
    echo "DEBUG: Iniciando clean_intermediate_files" >>"$RESULTS_DIR/error.log"
    clean_intermediate_files
    if [ $? -ne 0 ]; then
        print_status "error" "Falha ao limpar arquivos intermediários"
        echo "Falha ao limpar arquivos intermediários" >>"$RESULTS_DIR/error.log"
        return 1
    fi
    echo "DEBUG: clean_intermediate_files concluído" >>"$RESULTS_DIR/error.log"
    print_status "success" "Relatório final salvo em $RESULTS_DIR/relatorio.md"
}
