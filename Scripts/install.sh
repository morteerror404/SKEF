#!/bin/bash

#------------#------------# FUNÇÕES AUXILIARES #------------#------------#

# Função com animação de loading
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
    local resposta="${1,,}" # Converte para minúscula

    # Validação Positiva Enter 
    if [[ -z "$resposta" ]]; then
        return 0
        
    # Validação Positiva 
    elif [[ "$resposta" == "y" || "$resposta" == "s" ]]; then
        return 0

    # Validação Negativa
    elif [[ "$resposta" == "n" ]]; then
        return 1

    # Validação Erro
    else
        echo -e "\033[31mResposta inválida! Por favor, use uma opção válida. [S/n]\033[0m"
        return 2 
    fi
}

#------------#------------# FUNÇÕES DE VERIFICAÇÃO #------------#------------#

detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32mapt\033[0m"  # Debian/Ubuntu
        CMD_PACK_MANAGER_INSTALL="sudo apt install -y"
        CMD_PACK_MANAGER_NAME="apt"
        return 0
    elif command -v pacman &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32mpacman\033[0m"  # Arch
        CMD_PACK_MANAGER_INSTALL="sudo pacman -S --noconfirm"
        CMD_PACK_MANAGER_NAME="pacman"
        return 0
    elif command -v dnf &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32mdnf\033[0m"  # Fedora
        CMD_PACK_MANAGER_INSTALL="sudo dnf install -y"
        CMD_PACK_MANAGER_NAME="dnf"
        return 0
    elif command -v yum &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32myum\033[0m"  # RHEL/CentOS
        CMD_PACK_MANAGER_INSTALL="sudo yum install -y"
        CMD_PACK_MANAGER_NAME="yum"
        return 0
    elif command -v zypper &> /dev/null; then
        echo -e "Encontramos seu Gerenciador! Você usa o \033[32mzypper\033[0m"  # openSUSE
        CMD_PACK_MANAGER_INSTALL="sudo zypper install -y"
        CMD_PACK_MANAGER_NAME="zypper"
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
                    
                    echo -e "\n\033[33mValide as informações:\033[0m"
                    echo -e "Comando: \033[36m$CMD_PACK_MANAGER_INSTALL pacote\033[0m"
                    
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

#------------#------------# DECLARAÇÕES DE VARIAVEIS GLOBAIS #------------#------------#

CMD_PACK_MANAGER_INSTALL=""
CMD_PACK_MANAGER_NAME=""
resposta_discritiva=""
resposta=""
pergunta=""

#------------#------------# FUNÇÃO PRINCIPAL #------------#------------#

main() {
    echo -e "\n\033[34mBem-vindo à ferramenta de instalação\033[0m\n"
    sleep 1

    # Simula um processo demorado
    (sleep 3) &
    loading_animation $! "Aguarde enquanto encontramos seu gerenciador de pacotes"
    
    if detect_package_manager; then
        echo -e "\n\033[32mConfiguração concluída com sucesso!\033[0m"
        echo -e "Gerenciador: \033[36m$CMD_PACK_MANAGER_NAME\033[0m"
        echo -e "Comando de instalação: \033[36m$CMD_PACK_MANAGER_INSTALL\033[0m"
    else
        echo -e "\n\033[33mNenhum gerenciador de pacotes foi configurado.\033[0m"
    fi
}

# Executa a função principal
main