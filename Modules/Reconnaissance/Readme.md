

# Script AutoRecon

Este é um script em Bash baseado na ferramenta AutoRecon, projetado para automatizar tarefas de reconhecimento ativo e passivo em sistemas Linux. **O script está atualmente em produção**, com foco no recon ativo como a única funcionalidade totalmente funcional. Recursos passivos e outras funcionalidades estão em desenvolvimento ou simulados.

## Pré-requisitos

- Um sistema operacional baseado em Linux (ex.: Ubuntu, Debian, Kali).
- Python 3 e `pip` instalados.
- Ferramentas como `nmap`, `ffuf`, `autorecon`, `gitleaks`, `sherlock`, `xray`, `fierce`, `finalrecon`, `firewalk` e `clusterd` instaladas (consulte `requirements.txt` ou instale manualmente).
- Privilégios de `sudo` para execução de comandos de rede.
- Dependências adicionais: `jq` (para salvar resultados em JSON) e `dnsutils` (para DNS).
- Conexão com a internet para acessar alvos e wordlists.

## Instalação

1. **Clone o Repositório** (se aplicável):
   ```bash
   git clone <url-do-repositório>
   cd <diretório-do-repositório>
   ```

2. **Instale as Dependências**:
   - Instale as ferramentas listadas em `requirements.txt` ou manualmente:
     ```bash
     sudo apt-get update
     sudo apt-get install -y nmap jq dnsutils
     pip install autorecon attacksurfacemapper sherlock-project fierce finalrecon clusterd
     go install github.com/ffuf/ffuf/v2@latest
     go install github.com/zricethezav/gitleaks/v8@latest
     ```
   - Wordlists serão baixadas automaticamente (ex.: SecLists).

3. **Torne o Script Executável**:
   ```bash
   chmod +x autorecon.sh
   ```

4. **Execute o Script**:
   ```bash
   sudo ./autorecon.sh
   ```

## Funcionalidades

- **Recon Ativo**: Realiza varreduras ativas como ping, testes de portas (22, 80, 443), Nmap (IPv4/IPv6), FFuf (web), AutoRecon, XRay, Firewalk e Clusterd. **Esta é a funcionalidade principal em produção.**
- **Recon Passivo**: Inclui WHOIS e testes complexos (AttackSurfaceMapper, FFuf Subdomains, Gitleaks, Sherlock, Fierce, FinalRecon), mas muitos estão simulados ou requerem interação manual.
- **Relatórios**: Gera um arquivo JSON (`scan_results_<timestamp>.json`) com resultados detalhados.
- **Interface**: Oferece um menu interativo com opções personalizadas e estratégias predefinidas.

## Uso

### Execução Inicial
- Ao iniciar, o script exibe um menu com as seguintes opções:
  1. **PASSIVO + ATIVO**: Executa recon passivo seguido de ativo.
  2. **ATIVO + PASSIVO**: Executa recon ativo seguido de passivo.
  3. **PASSIVO**: Apenas recon passivo.
  4. **ATIVO**: Apenas recon ativo (recomendado, pois está em produção).
  5. **PERSONALIZADO**: Permite selecionar testes específicos (ping, DNS, portas, HTTP, WHOIS).
  6. **SAIR**: Encerra o script.

### Exemplos
- **Teste Ativo Completo**:
  ```bash
  sudo ./autorecon.sh
  ```
  Escolha a opção 4 (ATIVO) e siga as prompts.

- **Teste Personalizado de Portas**:
  Escolha a opção 5, selecione "3. Teste de Portas" e insira portas (ex.: `22,80,443`).

### Notas
- **Atenção**: Use apenas em ambientes autorizados, pois o recon ativo pode ser considerado invasivo.
- **Interatividade**: Algumas ferramentas (ex.: FFuf, AutoRecon) requerem confirmação manual para execução.

## Configuração

- **Wordlists**: Armazenadas em `$HOME/wordlists`. O script baixa SecLists automaticamente se não estiver presente.
- **Saída**: Resultados salvos em arquivos de texto (ex.: `nmap_output.txt`) e um JSON consolidado.
- **Personalização**: Ajuste os comandos em `NMAP_COMMANDS_IPV4`, `FFUF_COMMANDS`, etc., no script para necessidades específicas.

## Limitações

- **Em Produção Parcial**: Apenas o recon ativo está totalmente funcional. Recursos passivos como Threat Intel e DNS Histórico são simulados.
- **Dependências**: Algumas ferramentas (ex.: xray, firewalk) requerem instalação manual.
- **Interatividade**: O script depende de entrada do usuário para certas execuções.

## Contribuição

Contribuições são bem-vindas! Abra issues ou envie pull requests para melhorar o recon passivo, adicionar relatórios ou otimizar o código.