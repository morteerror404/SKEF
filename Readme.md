# SKEF - Speed Kill Execution Framework

**SKEF** é um framework de teste de penetração projetado para validação rápida e eliminatória de vulnerabilidades. Focado em eficiência e objetividade, o SKEF segue um fluxo de trabalho modular para identificar e explorar vulnerabilidades conhecidas em tempo reduzido.

---

## 🔍 Visão Geral

O SKEF é estruturado em etapas claras e concisas:

1. **Definição do alvo base**
2. **Reconhecimento ativo**
3. **Exploração de vulnerabilidades conhecidas**
4. **Organização das informações**
5. **Filtro do viável vs. inviável**
6. **Mudança de abordagem (se necessário)**
7. **Reteste com nova estratégia**

---

## ⚡ Funcionalidades
- **Reconhecimento Rápido**: Varredura automatizada de subdomínios, portas e serviços.
- **Exploração Direta**: Foco em vulnerabilidades críticas (CVSS >= 7.0).
- **Relatórios Concertos**: Geração automática de relatórios em Markdown/HTML.
- **Modular**: Facilidade para adicionar novos scripts ou ferramentas.

---

## 🛠️ Pré-requisitos


---

## 🚀 Instalação
1. Clone o repositório:
   ```bash
   git clone https://github.com/morteerror404/SKEF
   cd SKEF
   ```
2. Instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```

---

## 🏁 Uso Básico
### Exemplo 1: Reconhecimento Inicial
```bash
python3 modules/reconnaissance/amass_scan.py -t alvo.com
```

### Exemplo 2: Exploração de Vulnerabilidade
```bash
python3 modules/exploitation/cve_2023_1234.py -i 192.168.1.1
```

---

## 📂 Estrutura do Projeto
```
SKEF/
├── docs/          # Documentação
├── modules/       # Módulos principais
├── templates/     # Modelos de relatórios
├── scripts/       # Utilitários
└── tests/         # Testes automatizados
```

---

## 📄 Documentação
Detalhes avançados estão em [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) e [docs/EXAMPLES.md](docs/EXAMPLES.md).

---

## 🤝 Como Contribuir
1. Abra uma **issue** para discutir mudanças.
2. Faça um **fork** do projeto.
3. Envie um **PR** com sua contribuição.

---

## 📬 Contato
Para dúvidas ou sugestões, abra uma **issue** .