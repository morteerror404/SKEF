#!/bin/bash

# Generate-result.sh
# Função: Processar resultados de autorecon.sh e gerar relatório final em Markdown
# Dependências: utils.sh, ativo.sh

source ./utils.sh
source ./ativo.sh

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
declare -A TEST_FILES=(
    ["DNS"]="dig_output.txt"
    ["Traceroute"]="traceroute_output.txt"
    ["HTTP"]="http_test.txt"
    ["FFUF Subdomínios"]="ffuf_subdomains.csv"
    ["FFUF Web"]="ffuf_web.csv"
    ["FFUF Extensões"]="ffuf_extensions.csv"
    ["Nmap IPv4 TCP Connect Scan"]="nmap_ipv4_nmap_${TARGET_IPv4}_-sT_-vv_-Pn.xml"
    ["Nmap IPv4 OS Detection Scan"]="nmap_ipv4_nmap_${TARGET_IPv4}_-vv_-O_-Pn.xml"
    ["Nmap IPv4 Service Version Scan"]="nmap_ipv4_nmap_${TARGET_IPv4}_-sV_-O_-vv_-Pn.xml"
    ["Nmap IPv6 TCP Connect Scan"]="nmap_ipv6_nmap_${TARGET_IPv6}_-sT_-vv_-Pn.xml"
    ["Nmap IPv6 OS Detection Scan"]="nmap_ipv6_nmap_${TARGET_IPv6}_-vv_-O_-Pn.xml"
    ["Nmap IPv6 Service Version Scan"]="nmap_ipv6_nmap_${TARGET_IPv6}_-sV_-O_-vv_-Pn.xml"
)

declare -a BASIC_TESTS=("Ping" "DNS" "Porta" "HTTP" "Traceroute")
declare -a COMPLEX_TESTS=("Nmap IPv4" "Nmap IPv6" "FFUF Subdomínios" "FFUF Web" "FFUF Extensões")

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
        [ -n "$TARGET_IPv4" ] && config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv4")")\n"
    done
    for cmd in "${NMAP_COMMANDS_IPV6[@]}"; do
        [ -n "$TARGET_IPv6" ] && config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv6")")\n"
    done
    config+="\n### FFUF\n"
    for cmd in "${FFUF_COMMANDS[@]}"; do
        [ -n "$TARGET_IPv4" ] && config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv4")")\n"
    done
    for cmd in "${FFUF_WEB_COMMANDS[@]}"; do
        [ -n "$TARGET_IPv4" ] && config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv4")")\n"
    done
    for cmd in "${FFUF_EXT_COMMANDS[@]}"; do
        [ -n "$TARGET_IPv4" ] && config+="- $(sanitize_string "$(substituir_variaveis "$cmd" "$TARGET_IPv4")")\n"
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
    mv "$temp_error_log" "$RESULTS_DIR/error.log" 2>/dev/null || {
        print_status "error" "Falha ao restaurar error.log"
        return 1
    }
    [ $files_removed -eq 0 ] && print_status "info" "Nenhum arquivo intermediário encontrado."
}

save_test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    local details="$4"
    local file_content="$5"
    local report_file="$RESULTS_DIR/relatorio.md"

    # Verificar permissões do diretório
    if ! [ -d "$RESULTS_DIR" ]; then
        mkdir -p "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao criar diretório $RESULTS_DIR"
            return 1
        }
    fi
    if ! [ -w "$RESULTS_DIR" ]; then
        chmod u+w "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Sem permissão para escrever em $RESULTS_DIR"
            return 1
        }
    fi

    # Montar entrada do teste
    local test_entry="### $test_name\n\n"
    test_entry+="- **Status**: $status\n"
    test_entry+="- **Mensagem**: $message\n"
    test_entry+="- **Timestamp**: $(date +'%Y-%m-%d %H:%M:%S')\n"
    test_entry+="$details\n"
    [ -n "$file_content" ] && test_entry+="\n#### Conteúdo do Arquivo\n\`\`\`\n$file_content\n\`\`\`\n\n"

    # Escrever no relatório
    echo -e "$test_entry" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
        print_status "error" "Falha ao escrever teste '$test_name' em $report_file"
        return 1
    }
}

process_test_results() {
    local success_count=0 failure_count=0
    local report_file="$RESULTS_DIR/relatorio.md"
    local basic_tests_written=0 complex_tests_written=0

    # Inicializar relatório
    if ! [ -d "$RESULTS_DIR" ]; then
        mkdir -p "$RESULTS_DIR" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao criar diretório $RESULTS_DIR"
            return 1
        }
    fi
    echo -e "$(get_metadata)$(get_tool_config)$(get_dependencies)" > "$report_file" 2>>"$RESULTS_DIR/error.log" || {
        print_status "error" "Falha ao inicializar $report_file"
        return 1
    }

    # Verificar se CHECKLIST está vazia
    if [ ${#CHECKLIST[@]} -eq 0 ]; then
        print_status "warning" "CHECKLIST vazia, inicializando relatório básico"
        echo -e "## Testes Básicos\n\nNenhum teste básico executado.\n\n## Testes Complexos\n\nNenhum teste complexo executado.\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
            print_status "error" "Falha ao inicializar seções do relatório"
            return 1
        }
        return 0
    fi

    # Inicializar seções
    echo -e "## Testes Básicos\n" >> "$report_file"
    local basic_content=""
    local complex_content=""

    # Processar cada item da CHECKLIST
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

        # Determinar tipo de teste
        local is_basic=0
        for basic_test in "${BASIC_TESTS[@]}"; do
            if [[ "$test_name" == "$basic_test"* ]]; then
                is_basic=1
                break
            fi
        done

        # Definir detalhes e conteúdo por tipo de teste
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
                details="  - Comando: $cmd\n  - IPs Resolvidos: $resolved_ips\n  - Arquivo: ${TEST_FILES["DNS"]}"
                [ -f "$RESULTS_DIR/${TEST_FILES["DNS"]}" ] && file_content=$(cat "$RESULTS_DIR/${TEST_FILES["DNS"]}" | sed 's/^/    /')
                ;;
            "Porta"*)
                local port=$(echo "$test_name" | grep -oP '\d+')
                local cmd_ipv4=$(sanitize_string "nc -zv -w 2 $TARGET_IPv4 $port")
                local cmd_ipv6=$(sanitize_string "nc -zv -w 2 $TARGET_IPv6 $port")
                details="  - Porta: $port\n  - Comando IPv4: $cmd_ipv4\n  - Comando IPv6: $cmd_ipv6"
                ;;
            "HTTP"*)
                local cmd=$(sanitize_string "curl -sI $(determinar_protocolo)://$TARGET")
                details="  - Comando: $cmd\n  - Arquivo: ${TEST_FILES["HTTP"]}"
                [ -f "$RESULTS_DIR/${TEST_FILES["HTTP"]}" ] && file_content=$(cat "$RESULTS_DIR/${TEST_FILES["HTTP"]}" | sed 's/^/    /')
                ;;
            "Traceroute"*)
                local cmd=$(sanitize_string "traceroute $TARGET_IPv4")
                details="  - Comando: $cmd\n  - Arquivo: ${TEST_FILES["Traceroute"]}"
                [ -f "$RESULTS_DIR/${TEST_FILES["Traceroute"]}" ] && file_content=$(cat "$RESULTS_DIR/${TEST_FILES["Traceroute"]}" | sed 's/^/    /')
                ;;
            "Nmap IPv4"*)
                local scan_type=$(echo "$test_name" | sed 's/Nmap IPv4 //')
                local cmd=""
                case "$scan_type" in
                    "TCP Connect Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV4[0]}" "$TARGET_IPv4")") ;;
                    "OS Detection Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV4[1]}" "$TARGET_IPv4")") ;;
                    "Service Version Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV4[2]}" "$TARGET_IPv4")") ;;
                esac
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ${TEST_FILES["Nmap IPv4 $scan_type"]}"
                if [ -f "$RESULTS_DIR/${TEST_FILES["Nmap IPv4 $scan_type"]}" ]; then
                    file_content=$(command -v xmllint &>/dev/null && xmllint --format "$RESULTS_DIR/${TEST_FILES["Nmap IPv4 $scan_type"]}" 2>/dev/null | head -n 50 | sed 's/^/    /' || cat "$RESULTS_DIR/${TEST_FILES["Nmap IPv4 $scan_type"]}" | head -n 50 | sed 's/^/    /')
                fi
                ;;
            "Nmap IPv6"*)
                local scan_type=$(echo "$test_name" | sed 's/Nmap IPv6 //')
                local cmd=""
                case "$scan_type" in
                    "TCP Connect Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV6[0]}" "$TARGET_IPv6")") ;;
                    "OS Detection Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV6[1]}" "$TARGET_IPv6")") ;;
                    "Service Version Scan") cmd=$(sanitize_string "$(substituir_variaveis "${NMAP_COMMANDS_IPV6[2]}" "$TARGET_IPv6")") ;;
                esac
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ${TEST_FILES["Nmap IPv6 $scan_type"]}"
                if [ -f "$RESULTS_DIR/${TEST_FILES["Nmap IPv6 $scan_type"]}" ]; then
                    file_content=$(command -v xmllint &>/dev/null && xmllint --format "$RESULTS_DIR/${TEST_FILES["Nmap IPv6 $scan_type"]}" 2>/dev/null | head -n 50 | sed 's/^/    /' || cat "$RESULTS_DIR/${TEST_FILES["Nmap IPv6 $scan_type"]}" | head -n 50 | sed 's/^/    /')
                fi
                ;;
            "FFUF Subdomínios")
                local cmd=$(sanitize_string "$(substituir_variaveis "${FFUF_COMMANDS[0]}" "$TARGET_IPv4")")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ${TEST_FILES["FFUF Subdomínios"]}"
                if [ -f "$RESULTS_DIR/${TEST_FILES["FFUF Subdomínios"]}" ]; then
                    file_content=$(awk -F',' 'NR==1 {print "| " $0 " |"} NR==1 {gsub(/,/," | "); print "|---" $0 "---|"} NR>1 {print "| " $0 " |"}' "$RESULTS_DIR/${TEST_FILES["FFUF Subdomínios"]}" 2>/dev/null)
                fi
                ;;
            "FFUF Web")
                local cmd=$(sanitize_string "$(substituir_variaveis "${FFUF_WEB_COMMANDS[0]}" "$TARGET_IPv4")")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ${TEST_FILES["FFUF Web"]}"
                if [ -f "$RESULTS_DIR/${TEST_FILES["FFUF Web"]}" ]; then
                    file_content=$(awk -F',' 'NR==1 {print "| " $0 " |"} NR==1 {gsub(/,/," | "); print "|---" $0 "---|"} NR>1 {print "| " $0 " |"}' "$RESULTS_DIR/${TEST_FILES["FFUF Web"]}" 2>/dev/null)
                fi
                ;;
            "FFUF Extensões")
                local cmd=$(sanitize_string "$(substituir_variaveis "${FFUF_EXT_COMMANDS[0]}" "$TARGET_IPv4")")
                details="  - Comando: $cmd\n  - Arquivo de Resultados: ${TEST_FILES["FFUF Extensões"]}"
                if [ -f "$RESULTS_DIR/${TEST_FILES["FFUF Extensões"]}" ]; then
                    file_content=$(awk -F',' 'NR==1 {print "| " $0 " |"} NR==1 {gsub(/,/," | "); print "|---" $0 "---|"} NR>1 {print "| " $0 " |"}' "$RESULTS_DIR/${TEST_FILES["FFUF Extensões"]}" 2>/dev/null)
                fi
                ;;
            *)
                details="  - Comando: N/A\n  - Arquivo de Resultados: N/A"
                ;;
        esac

        # Adicionar ao conteúdo correto
        if [ $is_basic -eq 1 ]; then
            if [ $basic_tests_written -eq 0 ]; then
                basic_content="## Testes Básicos\n\n"
                basic_tests_written=1
            fi
            basic_content+=$(save_test_result "$test_name" "$status" "$message" "$details" "$file_content")
        else
            if [ $complex_tests_written -eq 0 ]; then
                complex_content="\n## Testes Complexos\n\n"
                complex_tests_written=1
            fi
            complex_content+=$(save_test_result "$test_name" "$status" "$message" "$details" "$file_content")
        fi

        [[ "$status" == *"✓"* ]] && ((success_count++)) || ((failure_count++))
    done

    # Escrever seções no relatório
    [ $basic_tests_written -eq 0 ] && echo -e "## Testes Básicos\n\nNenhum teste básico executado.\n" >> "$report_file"
    [ -n "$basic_content" ] && echo -e "$basic_content" >> "$report_file"
    [ $complex_tests_written -eq 0 ] && echo -e "\n## Testes Complexos\n\nNenhum teste complexo executado.\n" >> "$report_file"
    [ -n "$complex_content" ] && echo -e "$complex_content" >> "$report_file"

    echo "$success_count $failure_count"
}

process_result_files() {
    local report_file="$RESULTS_DIR/relatorio.md"
    local files_processed=0
    declare -A processed_files

    # Adicionar seção de arquivos de resultados
    echo -e "\n## Arquivos de Resultados\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
        print_status "error" "Falha ao escrever seção de arquivos em $report_file"
        return 1
    }

    # Processar arquivos mapeados por TEST_FILES
    for test_name in "${!TEST_FILES[@]}"; do
        local file="$RESULTS_DIR/${TEST_FILES[$test_name]}"
        if [ -f "$file" ] && [ -z "${processed_files[$file]}" ]; then
            local file_name=$(basename "$file")
            local file_type="${file_name##*.}"
            local content=""
            case $file_type in
                "txt")
                    content=$(cat "$file" 2>/dev/null | sed 's/^/    /')
                    ;;
                "csv")
                    content=$(awk -F',' 'NR==1 {print "| " $0 " |"} NR==1 {gsub(/,/," | "); print "|---" $0 "---|"} NR>1 {print "| " $0 " |"}' "$file" 2>/dev/null)
                    ;;
                "xml")
                    content=$(command -v xmllint &>/dev/null && xmllint --format "$file" 2>/dev/null | head -n 50 | sed 's/^/    /' || cat "$file" | head -n 50 | sed 's/^/    /')
                    ;;
            esac
            if [ -n "$content" ]; then
                echo -e "### Arquivo: $file_name\n\`\`\`$file_type\n$content\n\`\`\`\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
                    print_status "error" "Falha ao incorporar $file_name no relatório"
                    return 1
                }
                print_status "success" "Arquivo $file_name incorporado no relatório."
                processed_files["$file"]=1
                ((files_processed++))
            else
                print_status "error" "Falha ao ler conteúdo de $file_name"
                echo "Falha ao ler $file_name" >>"$RESULTS_DIR/error.log"
            fi
        fi
    done

    # Processar arquivos adicionais não mapeados
    for file in "$RESULTS_DIR"/*.{txt,csv,xml}; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "relatorio.md" ] && [ -z "${processed_files[$file]}" ]; then
            local file_name=$(basename "$file")
            local file_type="${file_name##*.}"
            local content=""
            case $file_type in
                "txt") content=$(cat "$file" 2>/dev/null | sed 's/^/    /') ;;
                "csv") content=$(awk -F',' 'NR==1 {print "| " $0 " |"} NR==1 {gsub(/,/," | "); print "|---" $0 "---|"} NR>1 {print "| " $0 " |"}' "$file" 2>/dev/null) ;;
                "xml") content=$(command -v xmllint &>/dev/null && xmllint --format "$file" 2>/dev/null | head -n 50 | sed 's/^/    /' || cat "$file" | head -n 50 | sed 's/^/    /') ;;
            esac
            if [ -n "$content" ]; then
                echo -e "### Arquivo: $file_name\n\`\`\`$file_type\n$content\n\`\`\`\n" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
                    print_status "error" "Falha ao incorporar $file_name no relatório"
                    return 1
                }
                print_status "success" "Arquivo $file_name incorporado no relatório."
                processed_files["$file"]=1
                ((files_processed++))
            else
                print_status "error" "Falha ao ler conteúdo de $file_name"
                echo "Falha ao ler $file_name" >>"$RESULTS_DIR/error.log"
            fi
        fi
    done

    [ $files_processed -eq 0 ] && echo -e "Nenhum arquivo de resultado (txt, csv, xml) encontrado.\n" >> "$report_file"
}

generate_statistics() {
    local success_count="$1"
    local failure_count="$2"
    local report_file="$RESULTS_DIR/relatorio.md"
    local stats="## Estatísticas\n\n"
    stats+="- **Total de Testes**: ${#CHECKLIST[@]}\n"
    stats+="- **Testes Bem-sucedidos**: $success_count\n"
    stats+="- **Testes com Falha**: $failure_count\n"
    stats+="- **Tempo Total de Execução**: $(( $(date +%s) - START_TIME )) segundos\n\n"
    echo -e "$stats" >> "$report_file" 2>>"$RESULTS_DIR/error.log" || {
        print_status "error" "Falha ao salvar estatísticas no relatório"
        return 1
    }
}

save_report() {
    trap 'print_status "error" "Execução interrompida, limpando arquivos..."; clean_intermediate_files; exit 1' SIGINT

    print_status "info" "Iniciando geração do relatório..."
    # Verificar permissões do diretório
    if ! mkdir -p "$RESULTS_DIR" || ! touch "$RESULTS_DIR/test_write" 2>/dev/null; then
        print_status "error" "Sem permissão para criar ou escrever em $RESULTS_DIR"
        exit 1
    fi
    rm -f "$RESULTS_DIR/test_write" 2>/dev/null

    # Processar resultados e gerar relatório
    IFS=' ' read -r success_count failure_count <<< "$(process_test_results)"
    [ $? -ne 0 ] && { print_status "error" "Falha ao processar resultados"; return 1; }

    process_result_files
    [ $? -ne 0 ] && { print_status "error" "Falha ao processar arquivos de resultados"; return 1; }

    generate_statistics "$success_count" "$failure_count"
    [ $? -ne 0 ] && { print_status "error" "Falha ao gerar estatísticas"; return 1; }

    clean_intermediate_files
    [ $? -ne 0 ] && { print_status "error" "Falha ao limpar arquivos intermediários"; return 1; }

    print_status "success" "Relatório final salvo em $RESULTS_DIR/relatorio.md"
}