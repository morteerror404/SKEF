# Script de Ferramenta de Instalação

Este é um script em Bash projetado para automatizar a configuração de ferramentas de segurança, listas de palavras (wordlists) e configurações de mirrors em um sistema Linux. Ele detecta o gerenciador de pacotes, instala dependências com base em um arquivo `requirements.txt`, configura mirrors e organiza diretórios de wordlists.

## Pré-requisitos

- Um sistema operacional baseado em Linux (ex.: Ubuntu, Fedora, Arch).
- Privilégios de `sudo` para instalação de pacotes.
- Conexão com a internet para baixar ferramentas e repositórios.

## Instalação

1. **Clone o Repositório** (se aplicável):
   ```bash
   git clone <url-do-repositório>
   cd <diretório-do-repositório>
   ```

2. **Torne o Script Executável**:
   ```bash
   chmod +x install_tools.sh
   ```

3. **Execute o Script**:
   ```bash
   ./install_tools.sh
   ```

## Funcionalidades

- **Detecção de Gerenciador de Pacotes**: Detecta automaticamente e configura gerenciadores de pacotes suportados (apt, pacman, dnf, yum, zypper) ou permite configuração manual.
- **Instalação Dinâmica de Dependências**: Lê as dependências do arquivo `requirements.txt` e as instala usando o método apropriado (gerenciador de pacotes, pip, go ou manual).
- **Configuração de Mirrors**: Configura arquivos de mirror (`tools.conf` e `mirrors_multi.conf`) para acessar repositórios de ferramentas.
- **Configuração de Wordlists**: Clona e organiza repositórios de wordlists (ex.: SecLists) no diretório `$HOME/wordlists` com links simbólicos para arquivos comuns.
- **Animação de Carregamento**: Oferece feedback visual durante tarefas demoradas.
- **Logs**: Gera arquivos de log para solução de problemas (ex.: `install_tools_<timestamp>.log`).

## Configuração

- **requirements.txt**: Contém a lista de ferramentas a serem instaladas. Se não estiver presente, um arquivo padrão será criado. Exemplo:
  ```
  python3
  pip
  nmap
  ffuf
  attacksurfacemapper
  autorecon
  gitleaks
  sherlock-project
  xray
  fierce
  finalrecon
  firewalk
  clusterd
  git
  go
  ```
  - As ferramentas são instaladas com base em métodos predefinidos (package, pip, go, manual).

- **Mirrors**: Configurados nos arquivos `tools.conf` (diretório atual) e `mirrors_multi.conf` (diretório de configuração do gerenciador de pacotes). Os mirrors podem ser expandidos conforme necessário.

## Logs

- Os logs são salvos automaticamente em `$HOME/install_tools_<timestamp>.log` e `$HOME/wordlists/wordlist_setup_<timestamp>.log` para rastrear o progresso e erros.

## Contribuição

Sinta-se à vontade para contribuir! Envie pull requests ou abra issues para sugestões e melhorias.


