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
    local test_name="$1" status="$2" message="$3" details="$4" file_content="$5"
    local report_file="$RESULTS_DIR/relatorio.md"
    local test_entry="### Teste: $(sanitize_string "$test_name")\n"
    test_entry+="- **Status**: $([[ "$status" == *"✓"* ]] && echo 'Sucesso' || echo 'Falha')\n"
    test_entry+="- **Mensagem**: $(sanitize_string "$message")\n"
    test_entry+="- **Timestamp**: $(date +'%Y-%m-%d %H:%M:%S')\n"
    test_entry+="- **Detalhes**:\n$details\n"
    if [ -n "$file_content" ]; then
        test_entry+="\n#### Conteúdo do Arquivo\n\`\`\`xml\n$file_content\n\`\`\`\n"
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
```

**Alterações**:
- **Verificação de Permissões**: Adicionada uma verificação explícita em `save_test_result` para garantir que o diretório `results/` existe e tem permissões de escrita.
- **Logs Detalhados**: Adicionados logs em `error.log` para cada etapa de `save_report` e `save_test_result`, incluindo falhas específicas.
- **CHECKLIST Vazia**: Verificação em `process_test_results` para evitar processamento se `CHECKLIST` estiver vazia.
- **Nmap Testes Distintos**: Atualizada a lógica para `Nmap IPv4` e `Nmap IPv6` para associar cada teste ao arquivo XML correto, usando nomes como "TCP Connect Scan", "OS Detection Scan", e "Service Version Scan".
- **Retorno de Erros**: Cada função (`process_test_results`, `process_result_files`, `generate_statistics`, `clean_intermediate_files`) agora retorna códigos de erro explícitos para interromper a execução se necessário.

#### **ativo.sh**
As alterações garantem que os testes Nmap sejam registrados com nomes distintos e que os arquivos sejam gerados corretamente.

<xaiArtifact artifact_id="45678f12-7e69-4229-b9f2-76b044f71f49" artifact_version_id="353b6276-fbe4-4ffb-bead-c4e72ab8b48c" title="ativo.sh" contentType="text/x-shellscript">
```bash
#!/bin/bash

# ativo.sh
# Função: Executar testes ativos (ping, portas, Nmap, FFUF) e retornar resultados para autorecon.sh
# Dependências: utils.sh

source "$(dirname "$0")/utils.sh"
export -f determinar_protocolo

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
WORDLISTS_EXT="/home/wordlists/SecLists/Discovery/Web-Content/web-extensions.txt"
WORDLIST_SUBDOMAINS="/home/wordlists/SecLists/Discovery/DNS/subdomains-top1million-110000.txt"
WORDLIST_WEB="/home/wordlists/SecLists/Discovery/Web-Content/directory-list-lowercase-2.3-big.txt"
declare -A PORT_STATUS_IPV4
declare -A PORT_STATUS_IPV6
declare -A PORT_TESTS_IPV4
declare -A PORT_TESTS_IPV6
RESULTS_DIR="results"

#------------#------------# VARIÁVEIS COMANDOS #------------#------------#
NMAP_COMMANDS_IPV4=(
    "nmap {TARGET_IP} -sT -vv -Pn"
    "nmap {TARGET_IP} -vv -O -Pn"
    "nmap {TARGET_IP} -sV -O -vv -Pn"
)
NMAP_COMMANDS_IPV6=(
    "nmap -6 {TARGET_IP} -sT -vv -Pn"
    "nmap -6 {TARGET_IP} -vv -O -Pn"
    "nmap -6 {TARGET_IP} -sV -O -vv -Pn"
)
FFUF_COMMANDS=(
    "ffuf -u {URL}/ -H 'Host: FUZZ.{DOMINIO}' -w {WORDLIST_SUBDOMAINS} -mc 200,301,302 -fc 404 -timeout 10 -t 50 -o $RESULTS_DIR/ffuf_subdomains.csv -of csv"
)
FFUF_WEB_COMMANDS=(
    "ffuf -u {URL}/FUZZ -w {WORDLIST_WEB} -mc 200,301,302 -recursion -recursion-depth 3 -fc 404 -timeout 10 -t 50 -o $RESULTS_DIR/ffuf_web.csv -of csv"
)
FFUF_EXT_COMMANDS=(
    "ffuf -u {URL}/index.FUZZ -w {WORDLISTS_EXT} -mc 200,301,302 -timeout 10 -fc 404 -t 50 -o $RESULTS_DIR/ffuf_extensions.csv -of csv"
)

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#
determinar_protocolo() {
    local protocol="http"
    { nc -zv -w 2 "$TARGET_IPv4" 443 &>/dev/null || nc -zv -w 2 "$TARGET_IPv6" 443 &>/dev/null; } && protocol="https"
    echo "$protocol"
}

substituir_variaveis() {
    local cmd="$1" ip="$2"
    local wordlist_subdomains="$WORDLIST_SUBDOMAINS"
    local wordlist_web="$WORDLIST_WEB"
    
    # Verificar e baixar wordlist de subdomínios
    if [ ! -f "$wordlist_subdomains" ]; then
        wordlist_subdomains="/tmp/subdomains.txt"
        print_status "info" "Wordlist de subdomínios não encontrada. Baixando..."
        curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-110000.txt -o "$wordlist_subdomains" || {
            print_status "error" "Falha ao baixar wordlist de subdomínios"
            echo "Falha ao baixar $wordlist_subdomains" >>"$RESULTS_DIR/error.log"
            return 1
        }
        if [ ! -s "$wordlist_subdomains" ]; then
            print_status "error" "Wordlist de subdomínios baixada está vazia ou inválida"
            echo "Wordlist $wordlist_subdomains vazia ou inválida" >>"$RESULTS_DIR/error.log"
            return 1
        }
    fi
    
    # Verificar e baixar wordlist web
    if [ ! -f "$wordlist_web" ]; then
        wordlist_web="/tmp/directory-list.txt"
        print_status "info" "Wordlist web não encontrada. Baixando..."
        curl -s https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-lowercase-2.3-big.txt -o "$wordlist_web" || {
            print_status "error" "Falha ao baixar wordlist web"
            echo "Falha ao baixar $wordlist_web" >>"$RESULTS_DIR/error.log"
            return 1
        }
        if [ ! -s "$wordlist_web" ]; then
            print_status "error" "Wordlist web baixada está vazia ou inválida"
            echo "Wordlist $wordlist_web vazia ou inválida" >>"$RESULTS_DIR/error.log"
            return 1
        }
    fi
    
    local protocol=$(determinar_protocolo)
    local url="$protocol://$ip"
    local safe_target=$(echo "$TARGET" | sed 's/[^a-zA-Z0-9.:-]/_/g')
    local safe_ip=$(echo "$ip" | sed 's/[^a-zA-Z0-9.:-]/_/g')
    local safe_url=$(echo "$url" | sed 's/[^a-zA-Z0-9.:/=-]/_/g')
    local safe_wordlist_subdomains=$(echo "$wordlist_subdomains" | sed 's/[^a-zA-Z0-9./-]/_/g')
    local safe_wordlist_web=$(echo "$wordlist_web" | sed 's/[^a-zA-Z0-9./-]/_/g')
    local safe_dominio=$(echo "$URL_DOMINIO" | sed 's/[^a-zA-Z0-9.:-]/_/g')
    echo "$cmd" | sed \
        -e "s#{DOMINIO}#$safe_dominio#g" \
        -e "s#{TARGET_IP}#$safe_ip#g" \
        -e "s#{URL}#$safe_url#g" \
        -e "s#{WORDLIST_SUBDOMAINS}#$safe_wordlist_subdomains#g" \
        -e "s#{WORDLIST_WEB}#$safe_wordlist_web#g"
}

executar_comando() {
    local cmd="$1" name="$2" output_file="$3" success_msg="$4" fail_msg="$5"
    print_status "action" "Executando $name"
    local temp_output=$(mktemp)
    if $cmd >"$temp_output" 2>&1; then
        local results=$(wc -l < "$temp_output")
        [ "$results" -gt 0 ] && CHECKLIST+=("$name: ✓ $success_msg ($results linhas)") || CHECKLIST+=("$name: ✓ $fail_msg")
    else
        CHECKLIST+=("$name: ✗ Falha")
        echo "Erro ao executar comando: $cmd" >>"$RESULTS_DIR/error.log"
    fi
    mv "$temp_output" "$output_file" 2>>"$RESULTS_DIR/error.log" || {
        print_status "error" "Falha ao mover $temp_output para $output_file"
        echo "Falha ao mover $temp_output para $output_file" >>"$RESULTS_DIR/error.log"
    }
}

analyze_nmap_results() {
    local xml_file="$1" ip_version="$2"
    if [ ! -f "$xml_file" ]; then
        print_status "error" "Arquivo $xml_file não encontrado"
        echo "Arquivo $xml_file não encontrado" >>"$RESULTS_DIR/error.log"
        return 1
    fi
    local -n port_status="PORT_STATUS_$ip_version"
    local -n port_tests="PORT_TESTS_$ip_version"
    local ports=($(grep -oP 'portid="\d+"' "$xml_file" | cut -d'"' -f2 | sort -u))
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

#------------#------------# FUNÇÕES DE TESTE ATIVO #------------#------------#
test_ping() {
    local ip="$1" version="$2"
    local ping_cmd="ping -c 4 $ip" && [ "$version" = "IPv6" ] && ping_cmd="ping6 -c 4 $ip"
    print_status "action" "Testando PING $version"
    loading_clock "Testando PING $version" 3 &
    pid=$!
    local ping_result=$($ping_cmd 2>&1)
    if [ $? -eq 0 ]; then
        packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)' || echo "0")
        avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1 || echo "N/A")
        CHECKLIST+=("Ping $version: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
    else
        CHECKLIST+=("Ping $version: ✗ Falha")
        echo "Erro ao executar ping $version: $ping_cmd" >>"$RESULTS_DIR/error.log"
    fi
    kill -0 $pid 2>/dev/null && kill $pid
    wait $pid 2>/dev/null
}

test_http() {
    print_status "action" "Testando HTTP"
    local protocol=$(determinar_protocolo)
    local output_file="$RESULTS_DIR/http_test.txt"
    if curl -s -o "$output_file" -w "%{http_code}" "$protocol://$TARGET" | grep -qE '200|301|302'; then
        CHECKLIST+=("HTTP ($protocol): ✓ Servidor ativo")
    else
        CHECKLIST+=("HTTP ($protocol): ✗ Servidor inativo ou erro")
        echo "Erro ao executar curl $protocol://$TARGET" >>"$RESULTS_DIR/error.log"
    fi
}

test_ffuf_subdomains() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || {
                print_status "error" "Falha ao substituir variáveis no comando FFUF Subdomínios"
                CHECKLIST+=("FFUF Subdomínios: ✗ Falha na substituição de variáveis")
                return 1
            }
            executar_comando "$cmd_substituido" "FFUF Subdomínios" "$RESULTS_DIR/ffuf_subdomains.csv" "Subdomínios encontrados" "Nenhum subdomínio encontrado"
        done
    else
        CHECKLIST+=("FFUF Subdomínios: ✗ Teste requer domínio")
    fi
}

test_ffuf_directories() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_WEB_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || {
                print_status "error" "Falha ao substituir variáveis no comando FFUF Web"
                CHECKLIST+=("FFUF Web: ✗ Falha na substituição de variáveis")
                return 1
            }
            executar_comando "$cmd_substituido" "FFUF Web" "$RESULTS_DIR/ffuf_web.csv" "Recursos web encontrados" "Nenhum recurso web encontrado"
        done
    else
        CHECKLIST+=("FFUF Web: ✗ Teste requer domínio")
    fi
}

test_ffuf_extensions() {
    if [ "$TYPE_TARGET" = "DOMAIN" ]; then
        for cmd in "${FFUF_EXT_COMMANDS[@]}"; do
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || {
                print_status "error" "Falha ao substituir variáveis no comando FFUF Extensões"
                CHECKLIST+=("FFUF Extensões: ✗ Falha na substituição de variáveis")
                return 1
            }
            executar_comando "$cmd_substituido" "FFUF Extensões" "$RESULTS_DIR/ffuf_extensions.csv" "Extensões encontradas" "Nenhuma extensão encontrada"
        done
    else
        CHECKLIST+=("FFUF Extensões: ✗ Teste requer domínio")
    fi
}

Ativo_basico() {
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
    print_status "info" "Executando testes ATIVOS COMPLEXOS em $TARGET"
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
    if [ -n "$TARGET_IPv4" ]; then
        local scan_types=("TCP Connect Scan" "OS Detection Scan" "Service Version Scan")
        for i in "${!NMAP_COMMANDS_IPV4[@]}"; do
            local cmd="${NMAP_COMMANDS_IPV4[$i]}"
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv4") || {
                print_status "error" "Falha ao substituir variáveis no comando Nmap IPv4: $cmd"
                CHECKLIST+=("Nmap IPv4 ${scan_types[$i]}: ✗ Falha na substituição de variáveis")
                continue
            }
            local output_file="$RESULTS_DIR/nmap_ipv4_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv4 ${scan_types[$i]}" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            [ -f "$output_file" ] && analyze_nmap_results "$output_file" "IPv4"
        done
        consolidar_portas "IPv4"
    fi
    if [ -n "$TARGET_IPv6" ]; then
        local scan_types=("TCP Connect Scan" "OS Detection Scan" "Service Version Scan")
        for i in "${!NMAP_COMMANDS_IPV6[@]}"; do
            local cmd="${NMAP_COMMANDS_IPV6[$i]}"
            local cmd_substituido=$(substituir_variaveis "$cmd" "$TARGET_IPv6") || {
                print_status "error" "Falha ao substituir variáveis no comando Nmap IPv6: $cmd"
                CHECKLIST+=("Nmap IPv6 ${scan_types[$i]}: ✗ Falha na substituição de variáveis")
                continue
            }
            local output_file="$RESULTS_DIR/nmap_ipv6_$(echo "$cmd" | tr ' ' '_' | tr -d '{}').xml"
            executar_comando "$cmd_substituido -oX $output_file" "Nmap IPv6 ${scan_types[$i]}" "$output_file" "Portas escaneadas" "Nenhuma porta encontrada"
            [ -f "$output_file" ] && analyze_nmap_results "$output_file" "IPv6"
        done
        consolidar_portas "IPv6"
    fi
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_subdomains
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_directories
    [ "$TYPE_TARGET" = "DOMAIN" ] && test_ffuf_extensions
}
