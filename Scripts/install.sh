#!/bin/bash

#------------#------------# VARIÁVEIS GLOBAIS #------------#------------#
CMD_PACK_MANAGER_INSTALL=""
CMD_PACK_MANAGER_NAME=""
CONFIG_DIR=""
VERBOSE=false
LOG_FILE="install_$(date +%Y%m%d_%H%M%S).log"

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#

# Função para log de mensagens
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO") color="\033[34m" ;;
        "SUCCESS") color="\033[32m" ;;
        "WARNING") color="\033[33m" ;;
        "ERROR") color="\033[31m" ;;
        *) color="\033[0m" ;;
    esac
    
    echo -e "${color}[${timestamp}] ${level}: ${message}\033[0m" | tee -a "$LOG_FILE"
}

# Função para validar resposta do usuário
valida_resposta_simples() {
    local resposta=$(echo "${1,,}" | tr -d '[:space:]')
    case "$resposta" in
        ""|"y"|"s") return 0 ;;
        "n") return 1 ;;
        *) 
            log_message "ERROR" "Resposta inválida! Por favor, use S/n"
            return 2 
        ;;
    esac
}

#------------#------------# FUNÇÕES DE INSTALAÇÃO #------------#------------#

# Função para detectar gerenciador de pacotes
detect_package_manager() {
    if command -v apt &>/dev/null; then
        CMD_PACK_MANAGER_INSTALL="sudo apt install -y"
        CMD_PACK_MANAGER_NAME="apt"
        CONFIG_DIR="/etc/apt"
    elif command -v pacman &>/dev/null; then
        CMD_PACK_MANAGER_INSTALL="sudo pacman -S --noconfirm"
        CMD_PACK_MANAGER_NAME="pacman"
        CONFIG_DIR="/etc/pacman.d"
    elif command -v dnf &>/dev/null; then
        CMD_PACK_MANAGER_INSTALL="sudo dnf install -y"
        CMD_PACK_MANAGER_NAME="dnf"
        CONFIG_DIR="/etc/yum.repos.d"
    elif command -v yum &>/dev/null; then
        CMD_PACK_MANAGER_INSTALL="sudo yum install -y"
        CMD_PACK_MANAGER_NAME="yum"
        CONFIG_DIR="/etc/yum.repos.d"
    else
        log_message "ERROR" "Não foi possível detectar o gerenciador de pacotes"
        return 1
    fi
    
    log_message "SUCCESS" "Gerenciador de pacotes detectado: $CMD_PACK_MANAGER_NAME"
    return 0
}

# Função para instalar dependências básicas
install_dependencies() {
    local dependencies=("git" "curl" "wget" "jq")
    local missing_deps=()
    
    # Verificar dependências faltantes
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        log_message "INFO" "Todas as dependências já estão instaladas"
        return 0
    fi
    
    log_message "INFO" "Instalando dependências: ${missing_deps[*]}"
    
    if ! $CMD_PACK_MANAGER_INSTALL "${missing_deps[@]}" >> "$LOG_FILE" 2>&1; then
        log_message "ERROR" "Falha ao instalar dependências"
        return 1
    fi
    
    log_message "SUCCESS" "Dependências instaladas com sucesso"
    return 0
}

#------------#------------# FUNÇÕES DE CONFIGURAÇÃO #------------#------------#

# Função para configurar mirrors
configure_mirrors() {
    local config_file="$CONFIG_DIR/mirrors.conf"
    
    log_message "INFO" "Configurando mirrors em $config_file"
    
    # Criar arquivo de configuração se não existir
    if [ ! -f "$config_file" ]; then
        if ! sudo touch "$config_file"; then
            log_message "ERROR" "Falha ao criar arquivo de configuração"
            return 1
        fi
    fi
    
    # Adicionar mirrors padrão
    declare -A default_mirrors=(
        ["git"]="https://mirrors.edge.kernel.org/pub/software/scm/git/"
        ["nmap"]="https://nmap.org/dist/"
        ["ffuf"]="https://github.com/ffuf/ffuf"
    )
    
    for tool in "${!default_mirrors[@]}"; do
        if ! grep -q "^\[$tool\]" "$config_file"; then
            echo -e "[$tool]\nmirror = ${default_mirrors[$tool]}" | sudo tee -a "$config_file" >/dev/null
        fi
    done
    
    log_message "SUCCESS" "Mirrors configurados com sucesso"
    return 0
}

#------------#------------# FUNÇÃO PRINCIPAL #------------#------------#

main() {
    # Verificar se é root
    if [ "$(id -u)" -ne 0 ]; then
        log_message "ERROR" "Este script precisa ser executado como root"
        exit 1
    fi
    
    # Detectar gerenciador de pacotes
    if ! detect_package_manager; then
        exit 1
    fi
    
    # Instalar dependências
    if ! install_dependencies; then
        exit 1
    fi
    
    # Configurar mirrors
    if ! configure_mirrors; then
        exit 1
    fi
    
    log_message "SUCCESS" "Instalação concluída com sucesso!"
    exit 0
}

# Executar função principal
main