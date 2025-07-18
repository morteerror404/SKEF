#!/bin/bash

# Variáveis globais
TARGET=""
CHECKLIST=()
JSON_FILE="scan_results.json"

# Funções básicas
definir_alvo() {
    read -p "Digite o IP/host alvo: " TARGET
    CHECKLIST+=("Alvo definido: ✓ $TARGET")
    salvar_json
}

salvar_json() {
    local json_data="{"
    json_data+="\"target\":\"$TARGET\","
    json_data+="\"timestamp\":\"$(date +"%Y-%m-%dT%H:%M:%S")\","
    json_data+="\"tests\":["
    
    for item in "${CHECKLIST[@]}"; do
        IFS=':' read -ra parts <<< "$item"
        test_name=$(echo "${parts[0]}" | xargs)
        status=$(echo "${parts[1]}" | xargs)
        
        json_data+="{\"name\":\"$test_name\","
        
        if [[ "$status" == *"✓"* ]]; then
            json_data+="\"status\":true,"
            json_data+="\"message\":\"${status#*✓}\""
        else
            json_data+="\"status\":false,"
            json_data+="\"message\":\"${status#*✗}\""
        fi
        
        json_data+="},"
    done
    
    json_data="${json_data%,}]}"
    echo "$json_data" | jq '.' > "$JSON_FILE"
}

# Função do relógio animado
loading_clock() {
    local task="$1"
    local duration=${2:-3}
    local end_time=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end_time ]; do
        clear
        hora=$(date +"%H:%M:%S")
        
        # Frame 1
        echo -e "\n   ___"
        echo " /_____\\"
        echo " |$hora|"
        echo " |_____|"
        echo " |.....|"
        echo " |.....|"
        echo " \\ ___ /"
        echo -e "\nExecutando: $task"
        
        # Mostra checklist
        echo -e "\nChecklist:"
        for item in "${CHECKLIST[@]}"; do
            echo " - $item"
        done
        
        sleep 0.5
        
        # Frame 2
        clear
        echo -e "\n   ___"
        echo " /_____\\"
        echo " |$hora|"
        echo " |_____|"
        echo " |     |"
        echo " |     |"
        echo " \\ ___ /"
        echo -e "\nExecutando: $task"
        
        # Mostra checklist
        echo -e "\nChecklist:"
        for item in "${CHECKLIST[@]}"; do
            echo " - $item"
        done
        
        sleep 0.5
    done
}

# Testes Passivos
Passivo_basico() {
    loading_clock "Testes Passivos" 3 &
    pid=$!
    
    # WHOIS
    if whois $TARGET &>/dev/null; then
        CHECKLIST+=("WHOIS: ✓ Informações obtidas")
    else
        CHECKLIST+=("WHOIS: ✗ Falha")
    fi
    
    # DNS histórico (simulado)
    CHECKLIST+=("DNS Histórico: ⚠ Simulado")
    
    # Consulta Threat Intelligence (simulado)
    CHECKLIST+=("Threat Intel: ⚠ Simulado")
    
    kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

# Testes Ativos
Ativo_basico() {
    # Ping
    loading_clock "Teste de Ping" 3 &
    pid=$!
    
    local ping_result=$(ping -c 4 $TARGET 2>&1)
    if [ $? -eq 0 ]; then
        local packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
        local avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1)
        CHECKLIST+=("Ping: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
    else
        CHECKLIST+=("Ping: ✗ Falha")
    fi
    
    kill $pid
    wait $pid 2>/dev/null
    
    # DNS
    loading_clock "Teste DNS" 3 &
    pid=$!
    
    local dns_result=$(dig $TARGET +short 2>&1)
    if [ -n "$dns_result" ]; then
        local ips=$(echo "$dns_result" | grep -oP '(\d+\.){3}\d+' | tr '\n' ',' | sed 's/,$//')
        CHECKLIST+=("DNS: ✓ Resolvido (IPs: $ips)")
    else
        CHECKLIST+=("DNS: ✗ Falha")
    fi
    
    kill $pid
    wait $pid 2>/dev/null
    
    # Portas
    loading_clock "Teste de Portas" 5 &
    pid=$!
    
    for porta in 22 80 443; do
        if nc -zv -w 2 $TARGET $porta &>/dev/null; then
            CHECKLIST+=("Porta $porta: ✓ Aberta")
        else
            CHECKLIST+=("Porta $porta: ✗ Fechada")
        fi
    done
    
    kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

# Menu Personalizado
menu_personalizado() {
    while true; do
        clear
        echo -e "\nMenu de Ferramentas de Rede (PERSONALIZADO):"
        echo "1. Teste de Ping"
        echo "2. Teste DNS"
        echo "3. Teste de Portas"
        echo "4. Teste HTTP"
        echo "5. Teste WHOIS"
        echo "6. Voltar ao menu principal"
        
        read -p "Escolha uma opção (1-6): " opcao
        
        case $opcao in
            1) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste de Ping" 3 &
                pid=$!
                if ping -c 4 $TARGET &>/dev/null; then
                    CHECKLIST+=("Ping Personalizado: ✓ Sucesso")
                else
                    CHECKLIST+=("Ping Personalizado: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            2) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste DNS" 3 &
                pid=$!
                if host $TARGET &>/dev/null; then
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
                loading_clock "Teste de Portas" 5 &
                pid=$!
                for porta in $(seq 1 1024); do
                    if nc -zv -w 1 $TARGET $porta &>/dev/null; then
                        CHECKLIST+=("Porta $porta: ✓ Aberta")
                        salvar_json
                    fi
                done
                kill $pid
                wait $pid 2>/dev/null
                ;;
            4) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste HTTP" 3 &
                pid=$!
                http_code=$(curl -sI "http://$TARGET" | head -1 | cut -d' ' -f2)
                if [ -n "$http_code" ]; then
                    CHECKLIST+=("HTTP: ✓ Código $http_code")
                else
                    CHECKLIST+=("HTTP: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            5) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste WHOIS" 3 &
                pid=$!
                if whois $TARGET &>/dev/null; then
                    CHECKLIST+=("WHOIS Personalizado: ✓ Informações obtidas")
                else
                    CHECKLIST+=("WHOIS Personalizado: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            6) break ;;
            *) echo "Opção inválida. Tente novamente." ;;
        esac
    done
}

# Menu principal
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
                Passivo_basico
                Ativo_basico
                ;;
            2) 
                definir_alvo
                Ativo_basico
                Passivo_basico
                ;;
            3) 
                definir_alvo
                Passivo_basico
                ;;
            4) 
                definir_alvo
                Ativo_basico
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

# Inicia o script
menu_inicial#!/bin/bash

# Variáveis globais
TARGET=""
CHECKLIST=()
JSON_FILE="scan_results.json"

# Funções básicas
definir_alvo() {
    read -p "Digite o IP/host alvo: " TARGET
    CHECKLIST+=("Alvo definido: ✓ $TARGET")
    salvar_json
}

salvar_json() {
    local json_data="{"
    json_data+="\"target\":\"$TARGET\","
    json_data+="\"timestamp\":\"$(date +"%Y-%m-%dT%H:%M:%S")\","
    json_data+="\"tests\":["
    
    for item in "${CHECKLIST[@]}"; do
        IFS=':' read -ra parts <<< "$item"
        test_name=$(echo "${parts[0]}" | xargs)
        status=$(echo "${parts[1]}" | xargs)
        
        json_data+="{\"name\":\"$test_name\","
        
        if [[ "$status" == *"✓"* ]]; then
            json_data+="\"status\":true,"
            json_data+="\"message\":\"${status#*✓}\""
        else
            json_data+="\"status\":false,"
            json_data+="\"message\":\"${status#*✗}\""
        fi
        
        json_data+="},"
    done
    
    json_data="${json_data%,}]}"
    echo "$json_data" | jq '.' > "$JSON_FILE"
}

# Função do relógio animado
loading_clock() {
    local task="$1"
    local duration=${2:-3}
    local end_time=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end_time ]; do
        clear
        hora=$(date +"%H:%M:%S")
        
        # Frame 1
        echo -e "\n   ___"
        echo " /_____\\"
        echo " |$hora|"
        echo " |_____|"
        echo " |.....|"
        echo " |.....|"
        echo " \\ ___ /"
        echo -e "\nExecutando: $task"
        
        # Mostra checklist
        echo -e "\nChecklist:"
        for item in "${CHECKLIST[@]}"; do
            echo " - $item"
        done
        
        sleep 0.5
        
        # Frame 2
        clear
        echo -e "\n   ___"
        echo " /_____\\"
        echo " |$hora|"
        echo " |_____|"
        echo " |     |"
        echo " |     |"
        echo " \\ ___ /"
        echo -e "\nExecutando: $task"
        
        # Mostra checklist
        echo -e "\nChecklist:"
        for item in "${CHECKLIST[@]}"; do
            echo " - $item"
        done
        
        sleep 0.5
    done
}

# Testes Passivos
Passivo_basico() {
    loading_clock "Testes Passivos" 3 &
    pid=$!
    
    # WHOIS
    if whois $TARGET &>/dev/null; then
        CHECKLIST+=("WHOIS: ✓ Informações obtidas")
    else
        CHECKLIST+=("WHOIS: ✗ Falha")
    fi
    
    # DNS histórico (simulado)
    CHECKLIST+=("DNS Histórico: ⚠ Simulado")
    
    # Consulta Threat Intelligence (simulado)
    CHECKLIST+=("Threat Intel: ⚠ Simulado")
    
    kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

# Testes Ativos
Ativo_basico() {
    # Ping
    loading_clock "Teste de Ping" 3 &
    pid=$!
    
    local ping_result=$(ping -c 4 $TARGET 2>&1)
    if [ $? -eq 0 ]; then
        local packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
        local avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1)
        CHECKLIST+=("Ping: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
    else
        CHECKLIST+=("Ping: ✗ Falha")
    fi
    
    kill $pid
    wait $pid 2>/dev/null
    
    # DNS
    loading_clock "Teste DNS" 3 &
    pid=$!
    
    local dns_result=$(dig $TARGET +short 2>&1)
    if [ -n "$dns_result" ]; then
        local ips=$(echo "$dns_result" | grep -oP '(\d+\.){3}\d+' | tr '\n' ',' | sed 's/,$//')
        CHECKLIST+=("DNS: ✓ Resolvido (IPs: $ips)")
    else
        CHECKLIST+=("DNS: ✗ Falha")
    fi
    
    kill $pid
    wait $pid 2>/dev/null
    
    # Portas
    loading_clock "Teste de Portas" 5 &
    pid=$!
    
    for porta in 22 80 443; do
        if nc -zv -w 2 $TARGET $porta &>/dev/null; then
            CHECKLIST+=("Porta $porta: ✓ Aberta")
        else
            CHECKLIST+=("Porta $porta: ✗ Fechada")
        fi
    done
    
    kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

# Menu Personalizado
menu_personalizado() {
    while true; do
        clear
        echo -e "\nMenu de Ferramentas de Rede (PERSONALIZADO):"
        echo "1. Teste de Ping"
        echo "2. Teste DNS"
        echo "3. Teste de Portas"
        echo "4. Teste HTTP"
        echo "5. Teste WHOIS"
        echo "6. Voltar ao menu principal"
        
        read -p "Escolha uma opção (1-6): " opcao
        
        case $opcao in
            1) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste de Ping" 3 &
                pid=$!
                if ping -c 4 $TARGET &>/dev/null; then
                    CHECKLIST+=("Ping Personalizado: ✓ Sucesso")
                else
                    CHECKLIST+=("Ping Personalizado: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            2) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste DNS" 3 &
                pid=$!
                if host $TARGET &>/dev/null; then
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
                loading_clock "Teste de Portas" 5 &
                pid=$!
                for porta in $(seq 1 1024); do
                    if nc -zv -w 1 $TARGET $porta &>/dev/null; then
                        CHECKLIST+=("Porta $porta: ✓ Aberta")
                        salvar_json
                    fi
                done
                kill $pid
                wait $pid 2>/dev/null
                ;;
            4) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste HTTP" 3 &
                pid=$!
                http_code=$(curl -sI "http://$TARGET" | head -1 | cut -d' ' -f2)
                if [ -n "$http_code" ]; then
                    CHECKLIST+=("HTTP: ✓ Código $http_code")
                else
                    CHECKLIST+=("HTTP: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            5) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste WHOIS" 3 &
                pid=$!
                if whois $TARGET &>/dev/null; then
                    CHECKLIST+=("WHOIS Personalizado: ✓ Informações obtidas")
                else
                    CHECKLIST+=("WHOIS Personalizado: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            6) break ;;
            *) echo "Opção inválida. Tente novamente." ;;
        esac
    done
}

# Menu principal
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
                Passivo_basico
                Ativo_basico
                ;;
            2) 
                definir_alvo
                Ativo_basico
                Passivo_basico
                ;;
            3) 
                definir_alvo
                Passivo_basico
                ;;
            4) 
                definir_alvo
                Ativo_basico
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

# Inicia o script
menu_inicial#!/bin/bash

# Variáveis globais
TARGET=""
CHECKLIST=()
JSON_FILE="scan_results.json"

# Funções básicas
definir_alvo() {
    read -p "Digite o IP/host alvo: " TARGET
    CHECKLIST+=("Alvo definido: ✓ $TARGET")
    salvar_json
}

salvar_json() {
    local json_data="{"
    json_data+="\"target\":\"$TARGET\","
    json_data+="\"timestamp\":\"$(date +"%Y-%m-%dT%H:%M:%S")\","
    json_data+="\"tests\":["
    
    for item in "${CHECKLIST[@]}"; do
        IFS=':' read -ra parts <<< "$item"
        test_name=$(echo "${parts[0]}" | xargs)
        status=$(echo "${parts[1]}" | xargs)
        
        json_data+="{\"name\":\"$test_name\","
        
        if [[ "$status" == *"✓"* ]]; then
            json_data+="\"status\":true,"
            json_data+="\"message\":\"${status#*✓}\""
        else
            json_data+="\"status\":false,"
            json_data+="\"message\":\"${status#*✗}\""
        fi
        
        json_data+="},"
    done
    
    json_data="${json_data%,}]}"
    echo "$json_data" | jq '.' > "$JSON_FILE"
}

# Função do relógio animado
loading_clock() {
    local task="$1"
    local duration=${2:-3}
    local end_time=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end_time ]; do
        clear
        hora=$(date +"%H:%M:%S")
        
        # Frame 1
        echo -e "\n   ___"
        echo " /_____\\"
        echo " |$hora|"
        echo " |_____|"
        echo " |.....|"
        echo " |.....|"
        echo " \\ ___ /"
        echo -e "\nExecutando: $task"
        
        # Mostra checklist
        echo -e "\nChecklist:"
        for item in "${CHECKLIST[@]}"; do
            echo " - $item"
        done
        
        sleep 0.5
        
        # Frame 2
        clear
        echo -e "\n   ___"
        echo " /_____\\"
        echo " |$hora|"
        echo " |_____|"
        echo " |     |"
        echo " |     |"
        echo " \\ ___ /"
        echo -e "\nExecutando: $task"
        
        # Mostra checklist
        echo -e "\nChecklist:"
        for item in "${CHECKLIST[@]}"; do
            echo " - $item"
        done
        
        sleep 0.5
    done
}

# Testes Passivos
Passivo_basico() {
    loading_clock "Testes Passivos" 3 &
    pid=$!
    
    # WHOIS
    if whois $TARGET &>/dev/null; then
        CHECKLIST+=("WHOIS: ✓ Informações obtidas")
    else
        CHECKLIST+=("WHOIS: ✗ Falha")
    fi
    
    # DNS histórico (simulado)
    CHECKLIST+=("DNS Histórico: ⚠ Simulado")
    
    # Consulta Threat Intelligence (simulado)
    CHECKLIST+=("Threat Intel: ⚠ Simulado")
    
    kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

# Testes Ativos
Ativo_basico() {
    # Ping
    loading_clock "Teste de Ping" 3 &
    pid=$!
    
    local ping_result=$(ping -c 4 $TARGET 2>&1)
    if [ $? -eq 0 ]; then
        local packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
        local avg_latency=$(echo "$ping_result" | grep -oPm1 '[\d.]+(?=\s*ms$)' | tail -1)
        CHECKLIST+=("Ping: ✓ Sucesso (Perda: ${packet_loss}%, Latência: ${avg_latency}ms)")
    else
        CHECKLIST+=("Ping: ✗ Falha")
    fi
    
    kill $pid
    wait $pid 2>/dev/null
    
    # DNS
    loading_clock "Teste DNS" 3 &
    pid=$!
    
    local dns_result=$(dig $TARGET +short 2>&1)
    if [ -n "$dns_result" ]; then
        local ips=$(echo "$dns_result" | grep -oP '(\d+\.){3}\d+' | tr '\n' ',' | sed 's/,$//')
        CHECKLIST+=("DNS: ✓ Resolvido (IPs: $ips)")
    else
        CHECKLIST+=("DNS: ✗ Falha")
    fi
    
    kill $pid
    wait $pid 2>/dev/null
    
    # Portas
    loading_clock "Teste de Portas" 5 &
    pid=$!
    
    for porta in 22 80 443; do
        if nc -zv -w 2 $TARGET $porta &>/dev/null; then
            CHECKLIST+=("Porta $porta: ✓ Aberta")
        else
            CHECKLIST+=("Porta $porta: ✗ Fechada")
        fi
    done
    
    kill $pid
    wait $pid 2>/dev/null
    salvar_json
}

# Menu Personalizado
menu_personalizado() {
    while true; do
        clear
        echo -e "\nMenu de Ferramentas de Rede (PERSONALIZADO):"
        echo "1. Teste de Ping"
        echo "2. Teste DNS"
        echo "3. Teste de Portas"
        echo "4. Teste HTTP"
        echo "5. Teste WHOIS"
        echo "6. Voltar ao menu principal"
        
        read -p "Escolha uma opção (1-6): " opcao
        
        case $opcao in
            1) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste de Ping" 3 &
                pid=$!
                if ping -c 4 $TARGET &>/dev/null; then
                    CHECKLIST+=("Ping Personalizado: ✓ Sucesso")
                else
                    CHECKLIST+=("Ping Personalizado: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            2) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste DNS" 3 &
                pid=$!
                if host $TARGET &>/dev/null; then
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
                loading_clock "Teste de Portas" 5 &
                pid=$!
                for porta in $(seq 1 1024); do
                    if nc -zv -w 1 $TARGET $porta &>/dev/null; then
                        CHECKLIST+=("Porta $porta: ✓ Aberta")
                        salvar_json
                    fi
                done
                kill $pid
                wait $pid 2>/dev/null
                ;;
            4) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste HTTP" 3 &
                pid=$!
                http_code=$(curl -sI "http://$TARGET" | head -1 | cut -d' ' -f2)
                if [ -n "$http_code" ]; then
                    CHECKLIST+=("HTTP: ✓ Código $http_code")
                else
                    CHECKLIST+=("HTTP: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            5) 
                [ -z "$TARGET" ] && definir_alvo
                loading_clock "Teste WHOIS" 3 &
                pid=$!
                if whois $TARGET &>/dev/null; then
                    CHECKLIST+=("WHOIS Personalizado: ✓ Informações obtidas")
                else
                    CHECKLIST+=("WHOIS Personalizado: ✗ Falha")
                fi
                kill $pid
                wait $pid 2>/dev/null
                salvar_json
                ;;
            6) break ;;
            *) echo "Opção inválida. Tente novamente." ;;
        esac
    done
}

# Menu principal
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
                Passivo_basico
                Ativo_basico
                ;;
            2) 
                definir_alvo
                Ativo_basico
                Passivo_basico
                ;;
            3) 
                definir_alvo
                Passivo_basico
                ;;
            4) 
                definir_alvo
                Ativo_basico
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

# Inicia o script
menu_inicial