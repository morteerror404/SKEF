#!/bin/bash

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#

loading_animation() {
    local pid=$1
    local text="${2:-Processando...}"
    local delay=0.1
    local spin='-\|/'
    local i=0
    
    echo -n "$text...  "
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\b${spin:$i:1}"
        sleep "$delay"
    done
    
    printf "\b \n"
}

tem_certeza() {
    local resposta
    read -rp "Deseja continuar? [S/n] " resposta
    valida_resposta_simples "$resposta"
    return $?
}

valida_resposta_simples() {
    local resposta=$(echo "${1,,}" | tr -d '[:space:]')
    if [[ -z "$resposta" ]]; then
        return 0
    elif [[ "$resposta" == "y" || "$resposta" == "s" ]]; then
        return 0
    elif [[ "$resposta" == "n" ]]; then
        return 1
    else
        echo -e "\033[31mResposta inválida! Por favor, use uma opção válida. [S/n]\033[0m"
        return 2
    fi
}

#------------#------------# FUNÇÕES DE VERIFICAÇÃO #------------#------------#

detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32mapt\033[0m"
        CMD_PACK_MANAGER_INSTALL="sudo apt install -y"
        CMD_PACK_MANAGER_NAME="apt"
        CONFIG_DIR="/etc/apt"
        return 0
    elif command -v pacman &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32mpacman\033[0m"
        CMD_PACK_MANAGER_INSTALL="sudo pacman -S --noconfirm"
        CMD_PACK_MANAGER_NAME="pacman"
        CONFIG_DIR="/etc/pacman.d"
        return 0
    elif command -v dnf &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32mdnf\033[0m"
        CMD_PACK_MANAGER_INSTALL="sudo dnf install -y"
        CMD_PACK_MANAGER_NAME="dnf"
        CONFIG_DIR="/etc/yum"
        return 0
    elif command -v yum &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32myum\033[0m"
        CMD_PACK_MANAGER_INSTALL="sudo yum install -y"
        CMD_PACK_MANAGER_NAME="yum"
        CONFIG_DIR="/etc/yum"
        return 0
    elif command -v zypper &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32mzypper\033[0m"
        CMD_PACK_MANAGER_INSTALL="sudo zypper install -y"
        CMD_PACK_MANAGER_NAME="zypper"
        CONFIG_DIR="/etc/zypp"
        return 0
    else
        echo -e "\033[31mQue pena. Não conseguimos encontrar seu instalador. :(\033[0m"
        while true; do
            read -rp "Deseja informar manualmente? [S/n] " resposta
            if valida_resposta_simples "$resposta"; then
                while true; do
                    read -rp "Qual é o seu instalador? (ex: apt, dnf, pacman): " resposta_discritiva
                    CMD_PACK_MANAGER_NAME="$resposta_discritiva"
                    read -rp "Qual é o parâmetro de instalação? (ex: install, -S): " resposta_discritiva
                    CMD_PACK_MANAGER_INSTALL="sudo $CMD_PACK_MANAGER_NAME $resposta_discritiva"
                    read -rp "Qual é o diretório de configuração? (ex: /etc/apt): " CONFIG_DIR
                    echo -e "\n\033[33mValide as informações:\033[0m"
                    echo -e "Comando: \033[36m$CMD_PACK_MANAGER_INSTALL pacote\033[0m"
                    echo -e "Diretório de configuração: \033[36m$CONFIG_DIR\033[0m"
                    if tem_certeza; then
                        return 0
                    else
                        break
                    fi
                done
            else
                return 1
            fi
        done
    fi
}

#------------#------------# Mirrors #------------#------------#

editar_config_mirrors() {
    local config_file="tools.conf"
    local mirrors=(
        "# Git mirrors"
        "git_mirror=https://mirrors.edge.kernel.org/pub/software/scm/git/"
        "git_alt_mirror=https://github.com/git/git"
        "# Nmap mirrors"
        "nmap_mirror=https://nmap.org/dist/"
        "nmap_alt_mirror=https://github.com/nmap/nmap"
        "# FFuf mirrors (Web Fuzzer)"
        "ffuf_mirror=https://github.com/ffuf/ffuf"
        "ffuf_releases=https://github.com/ffuf/ffuf/releases"
        "ffuf_pkg=github.com/ffuf/ffuf/v2@latest"
    )

    if [[ ! -w "$(pwd)" ]]; then
        echo -e "\033[31mErro: Sem permissão para escrever em $(pwd).\033[0m"
        return 1
    fi

    echo -e "\033[34mConfigurando mirrors no arquivo $config_file...\033[0m"
    
    if [[ ! -f "$config_file" ]]; then
        touch "$config_file" || {
            echo -e "\033[31mErro: Não foi possível criar o arquivo $config_file.\033[0m"
            return 1
        }
        echo -e "\033[33mArquivo $config_file criado.\033[0m"
        echo "# Security Tools Mirror Configuration" >> "$config_file"
        echo "# Generated on $(date)" >> "$config_file"
        echo "# DO NOT EDIT MANUALLY - Use the mirror configuration tool" >> "$config_file"
        echo "" >> "$config_file"
    fi

    for mirror in "${mirrors[@]}"; do
        if [[ "$mirror" == \#* ]]; then
            if ! grep -Fx "$mirror" "$config_file" > /dev/null; then
                echo "" >> "$config_file"
                echo "$mirror" >> "$config_file"
            fi
        else
            if ! grep -Fx "^${mirror%%=*}" "$config_file" > /dev/null; then
                echo "$mirror" >> "$config_file"
                echo -e "  \033[32m✓\033[0m Adicionado: ${mirror%%=*}"
            else
                echo -e "  \033[33mⓘ\033[0m Já existe: ${mirror%%=*}"
            fi
        fi
    done

    echo -e "\n\033[32mMirror configuration complete!\033[0m"
    echo -e "Total tools configured: \033[36m$(grep -c '^[^#]' "$config_file")\033[0m"
    echo -e "Config file location: \033[35m$(pwd)/$config_file\033[0m"
}

configure_multi_package_mirrors() {
    local config_file="$CONFIG_DIR/mirrors_multi.conf"
    local mirrors=(
        "# Git mirrors"
        "git_mirror=https://mirrors.edge.kernel.org/pub/software/scm/git/"
        "git_alt_mirror=https://github.com/git/git"
        "# Nmap mirrors"
        "nmap_mirror=https://nmap.org/dist/"
        "nmap_alt_mirror=https://github.com/nmap/nmap"
        "# FFuf mirrors (Web Fuzzer)"
        "ffuf_mirror=https://github.com/ffuf/ffuf"
        "ffuf_releases=https://github.com/ffuf/ffuf/releases"
        "ffuf_pkg=github.com/ffuf/ffuf/v2@latest"
    )

    if [[ ! -d "$CONFIG_DIR" ]]; then
        echo -e "\033[31mErro: Diretório $CONFIG_DIR não encontrado.\033[0m"
        return 1
    fi

    if [[ ! -w "$CONFIG_DIR" ]]; then
        echo -e "\033[31mErro: Sem permissão para escrever em $CONFIG_DIR. Execute com sudo.\033[0m"
        return 1
    fi

    echo -e "\033[34mConfigurando mirrors no arquivo $config_file...\033[0m"
    
    if [[ ! -f "$config_file" ]]; then
        touch "$config_file" || {
            echo -e "\033[31mErro: Não foi possível criar o arquivo $config_file.\033[0m"
            return 1
        }
        echo -e "\033[33mArquivo $config_file criado.\033[0m"
        echo "# Mirrors Configuration for Multiple Package Managers" >> "$config_file"
        echo "# Compatible with apt, yum/dnf, pacman, and others" >> "$config_file"
        echo "# Generated on $(date)" >> "$config_file"
        echo "# Format: key=value (parseable by shell and package managers)" >> "$config_file"
        echo "" >> "$config_file"
    else
        echo -e "\033[33mArquivo $config_file já existe, adicionando novos mirrors sem sobrescrever.\033[0m"
    fi

    for mirror in "${mirrors[@]}"; do
        if [[ "$mirror" == \#* ]]; then
            if ! grep -Fx "$mirror" "$config_file" > /dev/null; then
                echo "" >> "$config_file"
                echo "$mirror" >> "$config_file"
            fi
        else
            if ! grep -Fx "^${mirror%%=*}" "$config_file" > /dev/null; then
                echo "$mirror" >> "$config_file"
                echo -e "  \033[32m✓\033[0m Adicionado: ${mirror%%=*}"
            else
                echo -e "  \033[33mⓘ\033[0m Já existe: ${mirror%%=*}"
            fi
        fi
    done

    echo -e "\n\033[32mConfiguração de mirrors concluída!\033[0m"
    echo -e "Total de ferramentas configuradas: \033[36m$(grep -c '^[^#]' "$config_file")\033[0m"
    echo -e "Localização do arquivo de configuração: \033[35m$config_file\033[0m"
    echo -e "\033[34mEste arquivo é compatível com apt, yum/dnf, pacman e outros gerenciadores de pacotes.\033[0m"
}

setup_wordlists() {
    local wordlists_dir="$HOME/wordlists"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="$wordlists_dir/wordlist_setup_${timestamp}.log"
    
    if ! command -v git &> /dev/null; then
        echo -e "\033[31mErro: 'git' não está instalado.\033[0m"
        echo -e "\033[34mTentando instalar o 'git' com '$CMD_PACK_MANAGER_INSTALL git'...\033[0m"
        if $CMD_PACK_MANAGER_INSTALL git &>> "$log_file"; then
            echo -e "\033[32m[√] 'git' instalado com sucesso!\033[0m"
        else
            echo -e "\033[31mErro: Falha ao instalar o 'git'. Instale manualmente com '$CMD_PACK_MANAGER_INSTALL git'.\033[0m"
            return 1
        fi
    fi

    if [[ ! -w "$HOME" ]]; then
        echo -e "\033[31mErro: Sem permissão para escrever em $HOME.\033[0m"
        return 1
    fi

    declare -A wordlist_repos=(
        ["SecLists"]="https://github.com/danielmiessler/SecLists"
        ["dadoware"]="https://github.com/thoughtworks/dadoware"
        ["awesome-wordlists"]="https://github.com/gmelodie/awesome-wordlists"
    )
    
    echo -e "\033[34m[+] Configurando wordlists no diretório home...\033[0m"
    
    if [[ ! -d "$wordlists_dir" ]]; then
        mkdir -p "$wordlists_dir" || {
            echo -e "\033[31m[-] Falha ao criar o diretório de wordlists em $wordlists_dir\033[0m" | tee -a "$log_file"
            return 1
        }
        echo -e "\033[32m[+] Diretório criado: $wordlists_dir\033[0m" | tee -a "$log_file"
    else
        echo -e "\033[33m[!] Diretório de wordlists já existe em $wordlists_dir\033[0m" | tee -a "$log_file"
    fi
    
    for repo in "${!wordlist_repos[@]}"; do
        local repo_dir="${wordlists_dir}/${repo}"
        local repo_url="${wordlist_repos[$repo]}"
        
        echo -e "\n\033[36mProcessando ${repo}...\033[0m" | tee -a "$log_file"
        
        if [[ -d "$repo_dir" ]]; then
            cd "$repo_dir" || continue
            git pull --quiet 2>> "$log_file" && {
                echo -e "\033[32m[√] ${repo} atualizado com sucesso\033[0m" | tee -a "$log_file"
                cd - > /dev/null || return 1
            } || {
                echo -e "\033[31m[!] Falha ao atualizar ${repo}\033[0m" | tee -a "$log_file"
                cd - > /dev/null || return 1
            }
        else
            git clone --depth 1 "$repo_url" "$repo_dir" --quiet 2>> "$log_file" && {
                echo -e "\033[32m[√] ${repo} clonado com sucesso\033[0m" | tee -a "$log_file"
            } || {
                echo -e "\033[31m[!] Falha ao clonar ${repo}\033[0m" | tee -a "$log_file"
            }
        fi
        
        if [[ "$repo" == "SecLists" && -f "${repo_dir}/Discovery/Web-Content/raft-large-directories.txt" ]]; then
            ln -sf "${repo_dir}/Discovery/Web-Content/raft-large-directories.txt" "${wordlists_dir}/web_directories.txt" 2>/dev/null
            ln -sf "${repo_dir}/Passwords/Common-Credentials/top-20-common-SSH-passwords.txt" "${wordlists_dir}/ssh_passwords.txt" 2>/dev/null
            ln -sf "${repo_dir}/Discovery/DNS/subdomains-top1million-5000.txt" "${wordlists_dir}/subdomains.txt" 2>/dev/null
        fi
    done
    
    mkdir -p "${wordlists_dir}/custom" "${wordlists_dir}/merged" 2>/dev/null
    
    echo -e "\n\033[32m[+] Configuração de wordlists concluída!\033[0m" | tee -a "$log_file"
    echo -e "Diretório de wordlists: \033[35m${wordlists_dir}\033[0m"
    echo -e "Arquivo de log: \033[35m${log_file}\033[0m"
    echo -e "\n\033[33mRecomendação: Execute esta função periodicamente para atualizar as wordlists\033[0m"
    
    if [[ ":$PATH:" != *":$wordlists_dir:"* ]]; then
        echo -e "\n\033[36mConsidere adicionar ao seu PATH:\033[0m"
        echo "echo 'export PATH=\"\$PATH:$wordlists_dir\"' >> ~/.bashrc"
    fi

    # Atualizar config-SKEF.json com o diretório de wordlists
    update_config_json "wordlists_dir" "$wordlists_dir"
}

# Nova função para gerenciar config-SKEF.json
update_config_json() {
    local key="$1"
    local value="$2"
    local config_file="config-SKEF.json"
    local temp_file="config-SKEF.json.tmp"
    local timestamp=$(date +%Y-%m-%dT%H:%M:%S)

    if [[ ! -w "$(pwd)" ]]; then
        echo -e "\033[31mErro: Sem permissão para escrever em $(pwd).\033[0m"
        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        echo -e "\033[33mCriando novo arquivo $config_file...\033[0m"
        cat > "$config_file" <<EOL
{
  "wordlists_dir": "",
  "installed_tools": [],
  "user_options": [],
  "last_updated": "$timestamp"
}
EOL
    fi

    # Ler o conteúdo atual do JSON
    if ! command -v jq &> /dev/null; then
        echo -e "\033[31mErro: 'jq' não está instalado. Instale-o para manipular JSON.\033[0m"
        echo -e "\033[34mTentando instalar 'jq' com '$CMD_PACK_MANAGER_INSTALL jq'...\033[0m"
        if $CMD_PACK_MANAGER_INSTALL jq &>> "$log_file"; then
            echo -e "\033[32m[√] 'jq' instalado com sucesso!\033[0m"
        else
            echo -e "\033[31mErro: Falha ao instalar 'jq'. Instale manualmente.\033[0m"
            return 1
        fi
    fi

    if [[ "$key" == "wordlists_dir" ]]; then
        jq --arg key "$key" --arg value "$value" --arg ts "$timestamp" \
           '. + {($key): $value, "last_updated": $ts}' "$config_file" > "$temp_file"
    elif [[ "$key" == "installed_tools" ]]; then
        jq --arg tool "$value" --arg ts "$timestamp" \
           '.installed_tools += [$tool] | .last_updated = $ts' "$config_file" > "$temp_file"
    elif [[ "$key" == "user_options" ]]; then
        jq --arg opt "$value" --arg ts "$timestamp" \
           '.user_options += [$opt] | .last_updated = $ts' "$config_file" > "$temp_file"
    fi

    mv "$temp_file" "$config_file" && {
        echo -e "\033[32m[√] Arquivo $config_file atualizado com $key.\033[0m"
    } || {
        echo -e "\033[31m[!] Falha ao atualizar $config_file.\033[0m"
        return 1
    }
}

install_tools() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="$HOME/install_tools_${timestamp}.log"
    local requirements_file="requirements.txt"
    
    # Adicionar opção do usuário ao config-SKEF.json
    update_config_json "user_options" "Usuário escolheu instalar ferramentas de recon ativo"
    
    echo -e "\033[34m[+] Instalando ferramentas de segurança a partir de $requirements_file...\033[0m" | tee -a "$log_file"

    if [[ ! -f "$requirements_file" ]]; then
        echo -e "\033[31mErro: O arquivo $requirements_file não foi encontrado. Criando um padrão.\033[0m" | tee -a "$log_file"
        cat > "$requirements_file" <<EOL
python3
pip
nmap
ffuf
attacksurfacemapper
autorecon
gitleaks
sherlock-project
fierce
finalrecon
git
go
EOL
        echo -e "\033[33mArquivo $requirements_file criado com dependências padrão.\033[0m" | tee -a "$log_file"
    }

    mapfile -t tools < "$requirements_file"
    declare -A tool_methods=(
        ["nmap"]="package"
        ["ffuf"]="go:github.com/ffuf/ffuf/v2@latest"
        ["attacksurfacemapper"]="pip:attacksurfacemapper"
        ["autorecon"]="pip:autorecon"
        ["gitleaks"]="go:github.com/zricethezav/gitleaks/v8@latest"
        ["sherlock-project"]="pip:sherlock-project"
        ["finalrecon"]="pip:finalrecon"
        ["git"]="package"
        ["go"]="package"
        ["python3"]="package"
        ["pip"]="package"
    )

    for tool in "${tools[@]}"; do
        [[ -z "$tool" || "$tool" =~ ^# ]] && continue
        echo -e "\n\033[36mProcessando $tool...\033[0m" | tee -a "$log_file"

        if [[ "${tool_methods[$tool]}" == "package" || "${tool_methods[$tool]}" == "pip" || "${tool_methods[$tool]}" == "go" || "${tool_methods[$tool]}" == "manual"* ]]; then
            install_method="${tool_methods[$tool]%%:*}"
            install_source="${tool_methods[$tool]#*:}"
            [ "$install_method" == "$tool" ] && install_source=""
        else
            echo -e "\033[33m[!] Método de instalação para $tool não definido. Usando 'package' como padrão.\033[0m" | tee -a "$log_file"
            install_method="package"
            install_source=""
        fi

        if [ "$install_method" = "pip" ]; then
            if python3 -m pip show "$tool" &>/dev/null; then
                echo -e "\033[33m[!] $tool já está instalado.\033[0m" | tee -a "$log_file"
                continue
            fi
        elif [[ "$tool" = "gitleaks" || "$tool" = "ffuf" || "$tool" = "go" || "$tool" = "git" || "$tool" = "python3" || "$tool" = "pip" || "$tool" = "nmap" ]]; then
            if command -v "$tool" &>/dev/null; then
                echo -e "\033[33m[!] $tool já está instalado.\033[0m" | tee -a "$log_file"
                continue
            fi
        elif [[ "$tool" = "xray" || "$tool" = "firewalk" ]]; then
            if command -v "$tool" &>/dev/null; then
                echo -e "\033[33m[!] $tool já está instalado.\033[0m" | tee -a "$log_file"
                continue
            fi
        fi

        case $install_method in
            package)
                echo -e "\033[34mTentando instalar $tool com $CMD_PACK_MANAGER_INSTALL...\033[0m" | tee -a "$log_file"
                ( $CMD_PACK_MANAGER_INSTALL "$tool" &>> "$log_file" ) &
                loading_animation $! "Instalando $tool"
                if command -v "$tool" &>/dev/null; then
                    echo -e "\033[32m[√] $tool instalado com sucesso!\033[0m" | tee -a "$log_file"
                    update_config_json "installed_tools" "$tool"
                else
                    echo -e "\033[31m[!] Falha ao instalar $tool com $CMD_PACK_MANAGER_NAME.\033[0m" | tee -a "$log_file"
                fi
                ;;
            pip)
                echo -e "\033[34mTentando instalar $tool com pip3...\033[0m" | tee -a "$log_file"
                ( python3 -m pip install "$install_source" &>> "$log_file" ) &
                loading_animation $! "Instalando $tool"
                if python3 -m pip show "$tool" &>/dev/null; then
                    echo -e "\033[32m[√] $tool instalado com sucesso!\033[0m" | tee -a "$log_file"
                    update_config_json "installed_tools" "$tool"
                else
                    echo -e "\033[31m[!] Falha ao instalar $tool com pip.\033[0m" | tee -a "$log_file"
                fi
                ;;
            go)
                echo -e "\033[34mTentando instalar $tool com go install...\033[0m" | tee -a "$log_file"
                if ! command -v go &>/dev/null; then
                    echo -e "\033[34mGo não está instalado. Tentando instalar com $CMD_PACK_MANAGER_INSTALL...\033[0m" | tee -a "$log_file"
                    ( $CMD_PACK_MANAGER_INSTALL go &>> "$log_file" ) &
                    loading_animation $! "Instalando Go"
                fi
                ( go install "$install_source" &>> "$log_file" ) &
                loading_animation $! "Instalando $tool"
                if command -v "$tool" &>/dev/null; then
                    echo -e "\033[32m[√] $tool instalado com sucesso!\033[0m" | tee -a "$log_file"
                    update_config_json "installed_tools" "$tool"
                else
                    echo -e "\033[31m[!] Falha ao instalar $tool com go install.\033[0m" | tee -a "$log_file"
                fi
                ;;
            manual)
                echo -e "\033[33m[!] $tool requer instalação manual. Visite: $install_source\033[0m" | tee -a "$log_file"
                ;;
        esac
    done

    echo -e "\n\033[32m[+] Instalação de ferramentas concluída!\033[0m" | tee -a "$log_file"
    echo -e "Arquivo de log: \033[35m$log_file\033[0m"
}

main() {
    echo -e "\n\033[34mBem-vindo à ferramenta de instalação\033[0m\n"
    sleep 1

    (sleep 3) &
    loading_animation $! "Aguarde enquanto encontramos seu gerenciador de pacotes"
    
    if detect_package_manager; then
        echo -e "\n\033[32mConfiguração do gerenciador concluída com sucesso!\033[0m"
        echo -e "Gerenciador: \033[36m$CMD_PACK_MANAGER_NAME\033[0m"
        echo -e "Comando de instalação: \033[36m$CMD_PACK_MANAGER_INSTALL\033[0m"
        echo -e "Diretório de configuração: \033[36m$CONFIG_DIR\033[0m"
        
        (sleep 3) &
        loading_animation $! "Aguarde enquanto configuramos os mirrors"
        configure_multi_package_mirrors
        
        (sleep 3) &
        loading_animation $! "Aguarde enquanto configuramos as wordlists"
        setup_wordlists
        
        (sleep 3) &
        loading_animation $! "Aguarde enquanto instalamos as ferramentas"
        install_tools
    else
        echo -e "\n\033[33mNenhum gerenciador de pacotes foi configurado.\033[0m"
    fi
    
    (sleep 3) &
    loading_animation $! "Aguarde enquanto configuramos tools.conf"
    editar_config_mirrors
}

main