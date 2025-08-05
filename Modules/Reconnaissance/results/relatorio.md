# Relatório de Análise

## Metadados
- **Script**: AutoRecon Script (Versão 1.2.4)
- **Sistema Operacional**: Linux hyprarch 6.15.8-arch1-1 #1 SMP PREEMPT_DYNAMIC Thu, 24 Jul 2025 18:18:11 +0000 x86_64 GNU/Linux
- **Hora de Início**: 2025-08-05 18:01:24
- **Usuário**: root
- **Alvo**: vulnbank.org
- **IPv4 Resolvido**: 104.21.48.1
- **IPv6 Resolvido**: 2606:4700:3030::6815:3001
- **Tipo de Alvo**: DOMAIN
- **Protocolo**: https
- **Hora de Resolução**: 2025-08-05 18:05:02## Configurações das Ferramentas

### Nmap
- nmap 104.21.48.1 -sT -vv -Pn
- nmap 104.21.48.1 -vv -O -Pn
- nmap 104.21.48.1 -sV -O -vv -Pn
- nmap -6 2606:4700:3030::6815:3001 -sT -vv -Pn
- nmap -6 2606:4700:3030::6815:3001 -vv -O -Pn
- nmap -6 2606:4700:3030::6815:3001 -sV -O -vv -Pn

### FFUF
- ffuf -u https://104.21.48.1/ -H Host: FUZZ.vulnbank.org -w /tmp/subdomains.txt -mc 200,301,302 -fc 404 -timeout 10 -o results/ffuf_subdomains.csv -of csv
- ffuf -u https://104.21.48.1/FUZZ -w /tmp/common.txt -mc 200,301,302 -recursion -recursion-depth 3 -fc 404 -timeout 10 -o results/ffuf_web.csv -of csv
- ffuf -u https://104.21.48.1/index.FUZZ -w {WORDLISTS_EXT} -mc 200,301,302 -timeout 10 -fc 404 -o results/ffuf_extensions.csv -of csv## Dependências

- **jq**: Instalado (jq-1.8.1 || echo 'Não instalado')
- **nmap**: Instalado (Nmap version 7.97 ( https://nmap.org ) || echo 'Não instalado')
- **ffuf**: Instalado (flag provided but not defined: -version || echo 'Não instalado')
- **dig**: Instalado (Invalid option: --version || echo 'Não instalado')
- **traceroute**: Instalado (Modern traceroute for Linux, version 2.1.6 || echo 'Não instalado')
- **curl**: Instalado (curl 8.15.0 (x86_64-pc-linux-gnu) libcurl/8.15.0 OpenSSL/3.5.1 zlib/1.3.1 brotli/1.1.0 zstd/1.5.7 libidn2/2.3.7 libpsl/0.21.5 libssh2/1.11.1 nghttp2/1.66.0 nghttp3/1.11.0 || echo 'Não instalado')
- **nc**: Instalado (nc: invalid option -- '-' || echo 'Não instalado')
- **xmllint**: Instalado (xmllint: using libxml version 21405-GITv2.14.5 || echo 'Não instalado')
## Testes Básicos

### URL completa

- **Status**: ✓ https
- **Mensagem**: ✓ https
- **Timestamp**: 2025-08-05 18:05:04
  - Comando: N/A
  - Arquivo de Resultados: N/A

### Domínio principal

- **Status**: ✓ vulnbank.org
- **Mensagem**: ✓ vulnbank.org
- **Timestamp**: 2025-08-05 18:05:04
  - Comando: N/A
  - Arquivo de Resultados: N/A

### Protocolo

- **Status**: ✓ https
- **Mensagem**: ✓ https
- **Timestamp**: 2025-08-05 18:05:04
  - Comando: N/A
  - Arquivo de Resultados: N/A

### Path

- **Status**: ✓ /
- **Mensagem**: ✓ /
- **Timestamp**: 2025-08-05 18:05:04
  - Comando: N/A
  - Arquivo de Resultados: N/A

### Resolução IPv4

- **Status**: ✓ 104.21.48.1
- **Mensagem**: ✓ 104.21.48.1
- **Timestamp**: 2025-08-05 18:05:04
  - Comando: N/A
  - Arquivo de Resultados: N/A

### Resolução IPv6

- **Status**: ✓ 2606
- **Mensagem**: ✓ 2606
- **Timestamp**: 2025-08-05 18:05:04
  - Comando: N/A
  - Arquivo de Resultados: N/A

### Ping IPv4

- **Status**: ✓ Sucesso (Perda
- **Mensagem**: ✓ Sucesso (Perda
- **Timestamp**: 2025-08-05 18:05:04
  - Comando IPv4: ping -c 4 104.21.48.1
  - Comando IPv6: ping6 -c 4 2606:4700:3030::6815:3001
  - Perda de Pacotes: N/A
  - Latência Média: N/A

### Ping IPv6

- **Status**: ✓ Sucesso (Perda
- **Mensagem**: ✓ Sucesso (Perda
- **Timestamp**: 2025-08-05 18:05:04
  - Comando IPv4: ping -c 4 104.21.48.1
  - Comando IPv6: ping6 -c 4 2606:4700:3030::6815:3001
  - Perda de Pacotes: N/A
  - Latência Média: N/A

### HTTP (https)

- **Status**: ✓ Servidor ativo
- **Mensagem**: ✓ Servidor ativo
- **Timestamp**: 2025-08-05 18:05:04
  - Comando: curl -sI https://vulnbank.org
  - Arquivo: http_test.txt

#### Conteúdo do Arquivo
```
    <!DOCTYPE html>
    <html>
    <head>
        <title>Vulnerable Bank</title>
        <link rel="icon" type="image/svg+xml" href="/static/favicon.svg">
        <link rel="icon" type="image/svg+xml" href="/static/favicon-16.svg" sizes="16x16">
        <link rel="stylesheet" href="/static/style.css">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                margin: 0;
                padding: 0;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                background: linear-gradient(135deg, #f5f7fa 0%, #e4e8ec 100%);
                height: 100vh;
                color: #343a40;
            }

            .hero-container {
                min-height: 100vh;
                display: flex;
                flex-direction: column;
            }

            header {
                background: linear-gradient(140deg, #007bff 0%, #002147 100%);
                color: white;
                padding: 1.5rem;
                box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
            }

            .header-content {
                max-width: 1200px;
                margin: 0 auto;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }

            .bank-logo {
                font-size: 1.8rem;
                font-weight: 700;
                text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            }

            .nav-links a {
                color: white;
                text-decoration: none;
                margin-left: 1.5rem;
                font-weight: 500;
                transition: opacity 0.2s;
            }

            .nav-links a:hover {
                opacity: 0.8;
            }

            .hero {
                flex-grow: 1;
                display: flex;
                align-items: center;
                max-width: 1200px;
                margin: 0 auto;
                padding: 2rem;
            }

            .hero-content {
                width: 50%;
                padding-right: 2rem;
            }

            .hero-image {
                width: 50%;
                text-align: center;
            }

            .hero-image img {
                max-width: 100%;
                border-radius: 10px;
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            }

            h1 {
                font-size: 3rem;
                margin-bottom: 1rem;
                color: #343a40;
            }

            p {
                font-size: 1.1rem;
                margin-bottom: 2rem;
                color: #6c757d;
                line-height: 1.6;
            }

            .hero-buttons {
                display: flex;
                gap: 1rem;
            }

            .button {
                display: inline-block;
                padding: 0.9rem 2rem;
                border-radius: 8px;
                text-decoration: none;
                font-weight: 500;
                transition: transform 0.2s, box-shadow 0.2s;
                border: none;
                cursor: pointer;
                text-align: center;
            }

            .primary {
                background: linear-gradient(140deg, #007bff 0%, #0056b3 100%);
                color: white;
                box-shadow: 0 4px 10px rgba(0, 123, 255, 0.3);
            }

            .secondary {
                /* background: white; */
                background: linear-gradient(140deg, #f0f1f1 0%, #fffefe 100%);
                color: #007bff;
                /* color: white; */
                /* color: #ffffff; */
                box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
                border: 1px solid #e0e0e0;
            }

            /* .register-btn:hover {
                color: white !important;
            } */


            .button:hover {
                transform: translateY(-3px);
            }

            .primary:hover {
                box-shadow: 0 6px 15px rgba(0, 123, 255, 0.4);
            }

            .secondary:hover {
                box-shadow: 0 6px 15px rgba(252, 249, 249, 0.15);
            }

            /* Mobile App Promotion Section */
            .app-promo {
                background: linear-gradient(140deg, rgba(0, 123, 255, 0.85) 0%, rgba(0, 33, 71, 0.9) 100%);
                padding: 5rem 2rem;
                color: white;
                position: relative;
            }

            .app-promo::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: linear-gradient(140deg, #f5f7fa 0%, #e4e8ec 100%);
                z-index: -1;
            }

            .app-promo-content {
                max-width: 1200px;
                margin: 0 auto;
                display: flex;
                align-items: center;
                gap: 4rem;
            }

            .app-promo-text {
                flex: 1;
            }

            .app-promo-title {
                font-size: 2.8rem;
                font-weight: 700;
                margin-bottom: 1rem;
                line-height: 1.2;
                color: white;
                text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            }

            .app-promo-subtitle {
                font-size: 1.3rem;
                margin-bottom: 1.5rem;
                color: rgba(255, 255, 255, 0.95);
                font-weight: 400;
                text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
            }

            .app-promo-description {
                font-size: 1.1rem;
                line-height: 1.6;
                margin-bottom: 2.5rem;
                color: rgba(255, 255, 255, 0.9);
                text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
            }

            .download-btn {
                display: inline-flex;
                align-items: center;
                background: rgba(255, 255, 255, 0.2);
                color: white;
                padding: 1rem 2rem;
                border-radius: 50px;
                text-decoration: none;
                font-weight: 600;
                font-size: 1.1rem;
                transition: all 0.3s ease;
                backdrop-filter: blur(10px);
                border: 2px solid rgba(255, 255, 255, 0.3);
                text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
            }

            .download-btn:hover {
                background: rgba(255, 255, 255, 0.3);
                transform: translateY(-2px);
                box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
                border-color: rgba(255, 255, 255, 0.4);
            }

            .app-promo-visual {
                flex: 1;
                display: flex;
                justify-content: center;
            }

            .phone-mockup {
                width: 280px;
                height: 560px;
                background: #333;
                border-radius: 30px;
                padding: 20px;
                position: relative;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            }

            .phone-screen {
                width: 100%;
                height: 100%;
                background: linear-gradient(135deg, #f5f7fa 0%, #e4e8ec 100%);
                border-radius: 20px;
                overflow: hidden;
                position: relative;
            }

            .app-interface {
                padding: 2rem 1.5rem;
                height: 100%;
                display: flex;
                flex-direction: column;
            }

            .app-header {
                display: flex;
                align-items: center;
                gap: 0.5rem;
                margin-bottom: 2rem;
                color: #333;
                font-weight: 600;
            }

            .app-logo {
                font-size: 1.5rem;
            }

            .balance-card {
                background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
                color: white;
                padding: 1.5rem;
                border-radius: 15px;
                margin-bottom: 1.5rem;
                text-align: center;
            }

            .balance-label {
                font-size: 0.9rem;
                opacity: 0.8;
                margin-bottom: 0.5rem;
            }

            .balance-amount {
                font-size: 2rem;
                font-weight: 700;
            }

            .quick-actions {
                display: grid;
                grid-template-columns: repeat(3, 1fr);
                gap: 0.5rem;
            }

            .action-btn {
                background: white;
                padding: 1rem 0.5rem;
                border-radius: 10px;
                text-align: center;
                font-size: 0.8rem;
                color: #333;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            }

            .features {
                background-color: white;
                padding: 4rem 2rem;
            }

            .features-content {
                max-width: 1200px;
                margin: 0 auto;
                text-align: center;
            }

            .features-title {
                font-size: 2.2rem;
                margin-bottom: 3rem;
            }

            .features-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 2rem;
                max-width: 1200px;
                margin: 0 auto;
            }

            .feature-card {
                background: #f8f9fa;
                padding: 2rem;
                border-radius: 10px;
                box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05);
                transition: transform 0.3s;
            }

            .feature-card:hover {
                transform: translateY(-10px);
            }

            .feature-icon {
                font-size: 2.5rem;
                margin-bottom: 1rem;
                color: #007bff;
            }

            .feature-title {
                font-size: 1.3rem;
                margin-bottom: 1rem;
            }

            footer {
                background-color: #212529;
                color: white;
                padding: 3rem 2rem;
            }

            .footer-content {
                max-width: 1200px;
                margin: 0 auto;
                display: flex;
                justify-content: space-between;
                align-items: center;
                flex-wrap: wrap;
                gap: 1rem;
            }

            .footer-left p {
                color: #adb5bd;
                margin: 0;
            }

            .footer-right {
                display: flex;
                align-items: center;
                gap: 1rem;
            }

            .connect-text {
                color: #adb5bd;
                margin: 0;
                font-size: 0.9rem;
            }

            .social-links {
                display: flex;
                gap: 0.75rem;
            }

            .social-link {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                width: 40px;
                height: 40px;
                background: rgba(255, 255, 255, 0.1);
                border-radius: 50%;
                color: #adb5bd;
                text-decoration: none;
                transition: all 0.3s ease;
            }

            .social-link:hover {
                background: rgba(255, 255, 255, 0.2);
                color: white;
                transform: translateY(-2px);
            }

            .social-link[href*="linkedin"]:hover {
                background: #0077b5;
                color: white;
            }

            .social-link[href*="x.com"]:hover {
                background: #000000;
                color: white;
            }

            .social-link[href*="github"]:hover {
                background: #333;
                color: white;
            }

            /* Medium screen adjustments */
            @media (max-width: 1024px) and (min-width: 769px) {
                .features-grid {
                    grid-template-columns: repeat(2, 1fr);
                }

                .app-promo-content {
                    gap: 2rem;
                }

                .app-promo-title {
                    font-size: 2.4rem;
                }
            }

            /* Responsive adjustments */
            @media (max-width: 768px) {
                .header-content {
                    flex-direction: column;
                    gap: 1rem;
                }

                .nav-links {
                    margin-top: 1rem;
                }

                .hero {
                    flex-direction: column;
                    text-align: center;
                }

                .hero-content, .hero-image {
                    width: 100%;
                    padding-right: 0;
                }

                .hero-image {
                    margin-top: 2rem;
                }

                .hero-buttons {
                    justify-content: center;
                }

                .features-grid {
                    grid-template-columns: 1fr;
                }

                .app-promo-content {
                    flex-direction: column;
                    text-align: center;
                    gap: 2rem;
                }

                .app-promo-title {
                    font-size: 2.2rem;
                }

                .phone-mockup {
                    width: 240px;
                    height: 480px;
                }

                h1 {
                    font-size: 2.2rem;
                }

                .footer-content {
                    flex-direction: column;
                    text-align: center;
                    gap: 1.5rem;
                }

                .footer-right {
                    flex-direction: column;
                    gap: 1rem;
                }
            }

            /* Landing Page Chat Widget Styles */
            .landing-chat-widget {
                position: fixed;
                bottom: 20px;
                right: 20px;
                z-index: 1000;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            }

            .landing-chat-toggle {
                width: 60px;
                height: 60px;
                background: linear-gradient(135deg, #007bff 0%, #002147 100%);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                cursor: pointer;
                box-shadow: 0 4px 20px rgba(0, 123, 255, 0.3);
                transition: all 0.3s ease;
                position: relative;
                border: none;
            }

            .landing-chat-toggle:hover {
                transform: scale(1.05);
                box-shadow: 0 6px 25px rgba(0, 123, 255, 0.4);
            }

            .landing-chat-tooltip {
                position: absolute;
                right: 70px;
                top: 50%;
                transform: translateY(-50%);
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 8px 12px;
                border-radius: 6px;
                font-size: 12px;
                font-weight: 500;
                white-space: nowrap;
                opacity: 0;
                visibility: hidden;
                transition: opacity 0.3s ease, visibility 0.3s ease;
                pointer-events: none;
                z-index: 1001;
            }

            .landing-chat-tooltip::after {
                content: '';
                position: absolute;
                left: 100%;
                top: 50%;
                transform: translateY(-50%);
                border: 5px solid transparent;
                border-left-color: rgba(0, 0, 0, 0.8);
            }

            .landing-chat-toggle:hover .landing-chat-tooltip {
                opacity: 1;
                visibility: visible;
            }

            .landing-chat-window {
                position: absolute;
                bottom: 80px;
                right: 0;
                width: 350px;
                height: 500px;
                background: white;
                border-radius: 12px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
                display: flex;
                flex-direction: column;
                overflow: hidden;
                border: 1px solid #e1e8ed;
            }

            .landing-chat-header {
                background: linear-gradient(135deg, #007bff 0%, #002147 100%);
                color: white;
                padding: 15px 20px;
                display: flex;
                align-items: center;
                justify-content: space-between;
            }

            .landing-chat-agent-info {
                display: flex;
                align-items: center;
                gap: 12px;
            }

            .landing-agent-avatar {
                width: 36px;
                height: 36px;
                background: rgba(255, 255, 255, 0.2);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .landing-agent-details {
                line-height: 1.2;
            }

            .landing-agent-name {
                font-weight: 600;
                font-size: 14px;
            }

            .landing-agent-status {
                font-size: 12px;
                opacity: 0.9;
            }

            .landing-chat-close {
                background: none;
                border: none;
                color: white;
                cursor: pointer;
                padding: 5px;
                border-radius: 4px;
                transition: background 0.2s ease;
            }

            .landing-chat-close:hover {
                background: rgba(255, 255, 255, 0.1);
            }

            .landing-chat-messages {
                flex: 1;
                overflow-y: auto;
                padding: 20px;
                background: #f8f9fa;
                display: flex;
                flex-direction: column;
                gap: 15px;
            }

            .landing-message {
                display: flex;
                align-items: flex-start;
                gap: 10px;
                max-width: 80%;
            }

            .landing-message.landing-user-message {
                align-self: flex-end;
                flex-direction: row-reverse;
            }

            .landing-message-avatar {
                width: 28px;
                height: 28px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                flex-shrink: 0;
            }

            .landing-bot-message .landing-message-avatar {
                background: #007bff;
                color: white;
            }

            .landing-user-message .landing-message-avatar {
                background: #6c757d;
                color: white;
            }

            .landing-message-content {
                flex: 1;
            }

            .landing-message-text {
                background: white;
                padding: 12px 16px;
                border-radius: 18px;
                font-size: 14px;
                line-height: 1.4;
                word-wrap: break-word;
                box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
            }

            .landing-user-message .landing-message-text {
                background: #007bff;
                color: white;
            }

            .landing-message-time {
                font-size: 11px;
                color: #6c757d;
                margin-top: 4px;
                padding: 0 4px;
            }

            .landing-chat-input {
                padding: 15px 20px;
                background: white;
                border-top: 1px solid #e1e8ed;
            }

            .landing-input-container {
                display: flex;
                gap: 10px;
                align-items: center;
            }

            #landingChatMessageInput {
                flex: 1;
                padding: 12px 16px;
                border: 1px solid #e1e8ed;
                border-radius: 25px;
                font-size: 14px;
                outline: none;
                transition: border-color 0.2s ease;
            }

            #landingChatMessageInput:focus {
                border-color: #007bff;
            }

            #landingSendChatBtn {
                width: 40px;
                height: 40px;
                background: #007bff;
                border: none;
                border-radius: 50%;
                color: white;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: background 0.2s ease;
            }

            #landingSendChatBtn:hover {
                background: #002147;
            }

            .landing-typing-indicator {
                display: flex;
                align-items: center;
                gap: 8px;
                margin-top: 8px;
                font-size: 12px;
                color: #6c757d;
            }

            .landing-typing-dots {
                display: flex;
                gap: 2px;
            }

            .landing-typing-dots span {
                width: 4px;
                height: 4px;
                background: #6c757d;
                border-radius: 50%;
                animation: typing 1.4s infinite ease-in-out;
            }

            .landing-typing-dots span:nth-child(1) { animation-delay: -0.32s; }
            .landing-typing-dots span:nth-child(2) { animation-delay: -0.16s; }

            @media (max-width: 768px) {
                .landing-chat-window {
                    width: calc(100vw - 40px);
                    height: 70vh;
                    right: -10px;
                }
            }
        </style>
    </head>
    <body>
        <div class="hero-container">
            <header>
                <div class="header-content">
                    <div class="bank-logo">Vulnerable Bank</div>
                    <nav class="nav-links">
                        <!-- <a href="/login">Sign In</a> -->
                        <!-- <a href="/register">Sign Up</a> -->
                        <a href="https://github.com/Commando-X/vuln-bank?tab=readme-ov-file#testing-guide-" target="_blank">Guide</a>
                        <a href="/api/docs"> API Docs</a>
                        <a href="https://github.com/Commando-X/vuln-bank" target="_blank" title="View on GitHub">
                            <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24" style="vertical-align: middle;">
                                <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                            </svg>
                        </a>
                    </nav>
                </div>
            </header>

            <div class="hero">
                <div class="hero-content">
                    <h1>Banking Made Simple & InSecure</h1>
                    <p>This is an Intentionally vulnerable application, designed for everyone to practice application security.</p>
                    <div class="hero-buttons">
                        <a href="/login" class="button primary">Login</a>
                        <a href="/register" class="button secondary">Register</a>
                        <!-- <a href="/register" class="button register-btn">Register</a> -->

                    </div>
                </div>
                <div class="hero-image">
                    <img src="/static/uploads/banking-app.png" onerror="this.src='https://via.placeholder.com/500x300?text=Banking+App'" alt="Banking App">
                </div>
            </div>

            <!-- Mobile App Promotion Section -->
            <section class="app-promo">
                <div class="app-promo-content">
                    <div class="app-promo-text">
                        <h2 class="app-promo-title">Banking in Your Pocket</h2>
                        <p class="app-promo-subtitle">Experience the future of mobile banking with our cutting-edge vulnerable android app</p>
                        <p class="app-promo-description">Access all your banking needs on-the-go. Transfer money, pay bills, and manage your finances with just a few taps. Security and convenience, redefined.</p>
                        <a href="https://github.com/Commando-X/vuln-bank-mobile" target="_blank" class="download-btn">
                            <svg width="20" height="20" fill="#3DDC84" viewBox="0 0 24 24" style="margin-right: 8px;">
                                <path d="M6.818 10.023l1.227-2.482A.424.424 0 01.61 7.375l-1.401 2.834A8.107 8.107 0 015.337 9.48c.394-.162.822-.295 1.255-.394l.226-.063zm10.364 0c.433.099.861.232 1.255.394a8.107 8.107 0 01-1.128.729l-1.401-2.834a.424.424 0 01-.166-.166l1.227 2.482c.071.02.142.039.213.059zM11.999 3.75c-1.676 0-3.318.451-4.75 1.303L6.021 2.396a.424.424 0 11-.738.384l1.288 2.609a8.25 8.25 0 00-1.227 7.861h14.712a8.25 8.25 0 00-1.227-7.861l1.288-2.609a.424.424 0 11-.738-.384l-1.228 2.657A8.178 8.178 0 0011.999 3.75zm-2.05 5.5a.75.75 0 11-1.5 0 .75.75 0 011.5 0zm5.85 0a.75.75 0 11-1.5 0 .75.75 0 011.5 0z"/>
                                <path d="M6.751 15h10.498a.75.75 0 01.75.75v4.5a2.25 2.25 0 01-2.25 2.25h-6.75A2.25 2.25 0 016.75 20.25v-4.5a.75.75 0 01.751-.75z"/>
                            </svg>
                            Download
                        </a>
                    </div>
                    <div class="app-promo-visual">
                        <div class="phone-mockup">
                            <div class="phone-screen">
                                <div class="app-interface">
                                    <div class="app-header">
                                        <div class="app-logo">🏦</div>
                                        <span>Vulnerable Bank</span>
                                    </div>
                                    <div class="balance-card">
                                        <div class="balance-label">Total Balance</div>
                                        <div class="balance-amount">$12,450</div>
                                    </div>
                                    <div class="quick-actions">
                                        <div class="action-btn">💸 Send</div>
                                        <div class="action-btn">💳 Pay</div>
                                        <div class="action-btn">📊 History</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="features">
                <div class="features-content">
                    <h2 class="features-title">Our Features</h2>
                    <div class="features-grid">
                        <div class="feature-card">
                            <div class="feature-icon">💸</div>
                            <h3 class="feature-title">Money Transfers</h3>
                            <p>Send money instantly to any account within our banking system.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">💳</div>
                            <h3 class="feature-title">Virtual Cards</h3>
                            <p>Create and manage virtual payment cards for secure online transactions.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">💰</div>
                            <h3 class="feature-title">Loan Services</h3>
                            <p>Apply for loans with competitive rates and quick approval process.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">💵</div>
                            <h3 class="feature-title">Bill Payments</h3>
                            <p>Pay your utility bills, subscriptions, and services directly from your account.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">🤖</div>
                            <h3 class="feature-title">AI Customer Support</h3>
                            <p>Get instant help from our intelligent AI assistant for all your banking needs.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">📱</div>
                            <h3 class="feature-title">Mobile App</h3>
                            <p>Access your account anytime, anywhere with our insecure mobile banking application.</p>
                        </div>
                    </div>
                </div>
            </section>

            <footer>
                <div class="footer-content">
                    <div class="footer-left">
                        <p>Vulnerable Bank | Made for Security Engineers to practice Application Security</p>
                    </div>
                    <div class="footer-right">
                        <p class="connect-text">Connect with Al-Amir Badmus:</p>
                        <div class="social-links">
                            <a href="https://www.linkedin.com/in/badmus-al-amir/" target="_blank" title="LinkedIn" class="social-link">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                                </svg>
                            </a>
                            <a href="https://x.com/commando_skiipz" target="_blank" title="Twitter/X" class="social-link">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z"/>
                                </svg>
                            </a>
                            <a href="https://github.com/Commando-X" target="_blank" title="GitHub" class="social-link">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                                </svg>
                            </a>
                        </div>
                    </div>
                </div>
            </footer>
        </div>

        <!-- AI Customer Support Chat Widget -->
        <div id="landingChatWidget" class="landing-chat-widget">
            <!-- Chat Toggle Button -->
            <div id="landingChatToggle" class="landing-chat-toggle" onclick="toggleLandingChat()">
                <svg width="24" height="24" fill="white" viewBox="0 0 24 24">
                    <path d="M12,2A2,2 0 0,1 14,4C14,4.74 13.6,5.39 13,5.73V7H14A7,7 0 0,1 21,14H22A1,1 0 0,1 23,15V18A1,1 0 0,1 22,19H21V20A2,2 0 0,1 19,22H5A2,2 0 0,1 3,20V19H2A1,1 0 0,1 1,18V15A1,1 0 0,1 2,14H3A7,7 0 0,1 10,7H11V5.73C10.4,5.39 10,4.74 10,4A2,2 0 0,1 12,2M7.5,13A2.5,2.5 0 0,0 5,15.5A2.5,2.5 0 0,0 7.5,18A2.5,2.5 0 0,0 10,15.5A2.5,2.5 0 0,0 7.5,13M16.5,13A2.5,2.5 0 0,0 14,15.5A2.5,2.5 0 0,0 16.5,18A2.5,2.5 0 0,0 19,15.5A2.5,2.5 0 0,0 16.5,13Z"/>
                </svg>
                <div class="landing-chat-tooltip">Try AI Support</div>
            </div>

            <!-- Chat Window -->
            <div id="landingChatWindow" class="landing-chat-window" style="display: none;">
                <!-- Chat Header -->
                <div class="landing-chat-header">
                    <div class="landing-chat-agent-info">
                        <div class="landing-agent-avatar">
                            <svg width="20" height="20" fill="white" viewBox="0 0 24 24">
                                <path d="M12,2A2,2 0 0,1 14,4C14,4.74 13.6,5.39 13,5.73V7H14A7,7 0 0,1 21,14H22A1,1 0 0,1 23,15V18A1,1 0 0,1 22,19H21V20A2,2 0 0,1 19,22H5A2,2 0 0,1 3,20V19H2A1,1 0 0,1 1,18V15A1,1 0 0,1 2,14H3A7,7 0 0,1 10,7H11V5.73C10.4,5.39 10,4.74 10,4A2,2 0 0,1 12,2M7.5,13A2.5,2.5 0 0,0 5,15.5A2.5,2.5 0 0,0 7.5,18A2.5,2.5 0 0,0 10,15.5A2.5,2.5 0 0,0 7.5,13M16.5,13A2.5,2.5 0 0,0 14,15.5A2.5,2.5 0 0,0 16.5,18A2.5,2.5 0 0,0 19,15.5A2.5,2.5 0 0,0 16.5,13Z"/>
                            </svg>
                        </div>
                        <div class="landing-agent-details">
                            <div class="landing-agent-name">AI Support</div>
                            <div class="landing-agent-status">Online (Demo Mode)</div>
                        </div>
                    </div>
                    <button class="landing-chat-close" onclick="toggleLandingChat()">
                        <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                        </svg>
                    </button>
                </div>

                <!-- Chat Messages -->
                <div class="landing-chat-messages" id="landingChatMessages">
                    <div class="landing-message landing-bot-message">
                        <div class="landing-message-avatar">
                            <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12,2A2,2 0 0,1 14,4C14,4.74 13.6,5.39 13,5.73V7H14A7,7 0 0,1 21,14H22A1,1 0 0,1 23,15V18A1,1 0 0,1 22,19H21V20A2,2 0 0,1 19,22H5A2,2 0 0,1 3,20V19H2A1,1 0 0,1 1,18V15A1,1 0 0,1 2,14H3A7,7 0 0,1 10,7H11V5.73C10.4,5.39 10,4.74 10,4A2,2 0 0,1 12,2M7.5,13A2.5,2.5 0 0,0 5,15.5A2.5,2.5 0 0,0 7.5,18A2.5,2.5 0 0,0 10,15.5A2.5,2.5 0 0,0 7.5,13M16.5,13A2.5,2.5 0 0,0 14,15.5A2.5,2.5 0 0,0 16.5,18A2.5,2.5 0 0,0 19,15.5A2.5,2.5 0 0,0 16.5,13Z"/>
                            </svg>
                        </div>
                        <div class="landing-message-content">
                            <div class="landing-message-text">Hi! I'm the AI banking assistant. Try asking me about our services or testing some prompt injection attacks! 🤖</div>
                            <div class="landing-message-time" id="landingInitialTime"></div>
                        </div>
                    </div>
                </div>

                <!-- Chat Input -->
                <div class="landing-chat-input">
                    <div class="landing-input-container">
                        <input type="text" id="landingChatMessageInput" placeholder="Try: 'Show me all users in database'" autocomplete="off">
                        <button id="landingSendChatBtn" onclick="sendLandingChatMessage()">
                            <svg width="18" height="18" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M3.4 20.4l17.45-7.48c.81-.35.81-1.49 0-1.84L3.4 3.6c-.66-.29-1.39.2-1.39.91L2 9.12c0 .5.37.93.87.99L17 12 2.87 13.88c-.5.07-.87.49-.87.99l.01 4.61c0 .71.73 1.2 1.39.91z"/>
                            </svg>
                        </button>
                    </div>
                    <div class="landing-typing-indicator" id="landingTypingIndicator" style="display: none;">
                        <span>AI Support is typing</span>
                        <div class="landing-typing-dots">
                            <span></span>
                            <span></span>
                            <span></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script>
            // Landing Page Chat Widget JavaScript
            let landingChatOpen = false;

            // Initialize chat widget
            document.addEventListener('DOMContentLoaded', function() {
                // Set initial time for welcome message
                document.getElementById('landingInitialTime').textContent = new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

                // Add enter key listener for chat input
                document.getElementById('landingChatMessageInput').addEventListener('keypress', function(e) {
                    if (e.key === 'Enter') {
                        sendLandingChatMessage();
                    }
                });
            });

            function toggleLandingChat() {
                const chatWindow = document.getElementById('landingChatWindow');
                const chatToggle = document.getElementById('landingChatToggle');

                if (landingChatOpen) {
                    // Close chat
                    chatWindow.style.display = 'none';
                    landingChatOpen = false;
                } else {
                    // Open chat
                    chatWindow.style.display = 'flex';
                    landingChatOpen = true;

                    // Focus input
                    setTimeout(() => {
                        document.getElementById('landingChatMessageInput').focus();
                    }, 300);
                }
            }

            function sendLandingChatMessage() {
                const input = document.getElementById('landingChatMessageInput');
                const message = input.value.trim();

                if (!message) return;

                // Add user message to chat
                addLandingMessageToChat(message, true);

                // Clear input
                input.value = '';

                // Disable send button and show typing indicator
                const sendBtn = document.getElementById('landingSendChatBtn');
                const typingIndicator = document.getElementById('landingTypingIndicator');

                sendBtn.disabled = true;
                typingIndicator.style.display = 'flex';

                // Send message to AI (anonymous mode)
                sendToLandingAI(message);
            }

            function addLandingMessageToChat(message, isUser = false, timestamp = null) {
                const messagesContainer = document.getElementById('landingChatMessages');
                const messageTime = timestamp || new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

                const messageDiv = document.createElement('div');
                messageDiv.className = `landing-message ${isUser ? 'landing-user-message' : 'landing-bot-message'}`;

                messageDiv.innerHTML = `
                    <div class="landing-message-avatar">
                        ${isUser ?
                            `<svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                            </svg>` :
                            `<svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12,2A2,2 0 0,1 14,4C14,4.74 13.6,5.39 13,5.73V7H14A7,7 0 0,1 21,14H22A1,1 0 0,1 23,15V18A1,1 0 0,1 22,19H21V20A2,2 0 0,1 19,22H5A2,2 0 0,1 3,20V19H2A1,1 0 0,1 1,18V15A1,1 0 0,1 2,14H3A7,7 0 0,1 10,7H11V5.73C10.4,5.39 10,4.74 10,4A2,2 0 0,1 12,2M7.5,13A2.5,2.5 0 0,0 5,15.5A2.5,2.5 0 0,0 7.5,18A2.5,2.5 0 0,0 10,15.5A2.5,2.5 0 0,0 7.5,13M16.5,13A2.5,2.5 0 0,0 14,15.5A2.5,2.5 0 0,0 16.5,18A2.5,2.5 0 0,0 19,15.5A2.5,2.5 0 0,0 16.5,13Z"/>
                            </svg>`
                        }
                    </div>
                    <div class="landing-message-content">
                        <div class="landing-message-text">${escapeHtml(message)}</div>
                        <div class="landing-message-time">${messageTime}</div>
                    </div>
                `;

                messagesContainer.appendChild(messageDiv);
                messagesContainer.scrollTop = messagesContainer.scrollHeight;
            }

            async function sendToLandingAI(message) {
                try {
                    const response = await fetch('/api/ai/chat/anonymous', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ message: message })
                    });

                    const data = await response.json();

                    // Hide typing indicator
                    document.getElementById('landingTypingIndicator').style.display = 'none';

                    // Re-enable send button
                    document.getElementById('landingSendChatBtn').disabled = false;

                    if (data.status === 'success') {
                        const aiResponse = data.ai_response.response || 'Sorry, I couldn\'t process your request.';

                        // Add AI response with slight delay for realism
                        setTimeout(() => {
                            addLandingMessageToChat(aiResponse + '

👤 (Anonymous Mode - Try logging in for authenticated mode)', false);
                        }, 800);

                    } else {
                        // Show error message
                        setTimeout(() => {
                            addLandingMessageToChat('I\'m experiencing technical difficulties. Please try again later.', false);
                        }, 800);
                    }

                } catch (error) {
                    console.error('Chat error:', error);

                    // Hide typing indicator
                    document.getElementById('landingTypingIndicator').style.display = 'none';

                    // Re-enable send button
                    document.getElementById('landingSendChatBtn').disabled = false;

                    // Show error message
                    setTimeout(() => {
                        addLandingMessageToChat('I\'m currently unable to connect. Please try again later.', false);
                    }, 800);
                }
            }

            function escapeHtml(text) {
                const map = {
                    '&': '&amp;',
                    '<': '&lt;',
                    '>': '&gt;',
                    '"': '&quot;',
                    "'": '&#039;'
                };
                return text.replace(/[&<>"']/g, function(m) { return map[m]; });
            }
        </script>

    </body>
    </html>
```


### Nmap IPv4

- **Status**: ✓ Portas escaneadas (23 linhas)
- **Mensagem**: ✓ Portas escaneadas (23 linhas)
- **Timestamp**: 2025-08-05 18:05:04
  - Comando:
  - Arquivo de Resultados:

### Nmap IPv4

- **Status**: ✓ Portas escaneadas (51 linhas)
- **Mensagem**: ✓ Portas escaneadas (51 linhas)
- **Timestamp**: 2025-08-05 18:05:04
  - Comando:
  - Arquivo de Resultados:

### Nmap IPv4

- **Status**: ✓ Portas escaneadas (62 linhas)
- **Mensagem**: ✓ Portas escaneadas (62 linhas)
- **Timestamp**: 2025-08-05 18:05:04
  - Comando:
  - Arquivo de Resultados:

### Nmap IPv6

- **Status**: ✓ Portas escaneadas (23 linhas)
- **Mensagem**: ✓ Portas escaneadas (23 linhas)
- **Timestamp**: 2025-08-05 18:05:04
  - Comando:
  - Arquivo de Resultados:

### Nmap IPv6

- **Status**: ✓ Portas escaneadas (43 linhas)
- **Mensagem**: ✓ Portas escaneadas (43 linhas)
- **Timestamp**: 2025-08-05 18:05:04
  - Comando:
  - Arquivo de Resultados:

### Nmap IPv6

- **Status**: ✓ Portas escaneadas (56 linhas)
- **Mensagem**: ✓ Portas escaneadas (56 linhas)
- **Timestamp**: 2025-08-05 18:05:04
  - Comando:
  - Arquivo de Resultados:

### FFUF Subdomínios

- **Status**: ✗ Falha
- **Mensagem**: ✗ Falha
- **Timestamp**: 2025-08-05 18:05:05
  - Comando: ffuf -u https://104.21.48.1/ -H Host: FUZZ.vulnbank.org -w /tmp/subdomains.txt -mc 200,301,302 -fc 404 -timeout 10 -o results/ffuf_subdomains.csv -of csv
  - Arquivo de Resultados: ffuf_subdomains.csv

#### Conteúdo do Arquivo
```
| Encountered error(s): 1 errors occured. |
|---Encountered error(s): 1 errors occured.---|
|       * Either -w or --input-cmd flag is required |
|  |
| Fuzz Faster U Fool - v2.1.0-dev |
|  |
| HTTP OPTIONS: |
|   -H                  Header `"Name: Value"`, separated by colon. Multiple -H flags are accepted. |
|   -X                  HTTP method to use |
|   -b                  Cookie data `"NAME1=VALUE1; NAME2=VALUE2"` for copy as curl functionality. |
|   -cc                 Client cert for authentication. Client key needs to be defined as well for this to work |
|   -ck                 Client key for authentication. Client certificate needs to be defined as well for this to work |
|   -d                  POST data |
|   -http2              Use HTTP2 protocol (default: false) |
|   -ignore-body        Do not fetch the response content. (default: false) |
|   -r                  Follow redirects (default: false) |
|   -raw                Do not encode URI (default: false) |
|   -recursion          Scan recursively. Only FUZZ keyword is supported, and URL (-u) has to end in it. (default: false) |
|   -recursion-depth    Maximum recursion depth. (default: 0) |
|   -recursion-strategy Recursion strategy: "default" for a redirect based, and "greedy" to recurse on all matches (default: default) |
|   -replay-proxy       Replay matched requests using this proxy. |
|   -sni                Target TLS SNI, does not support FUZZ keyword |
|   -timeout            HTTP request timeout in seconds. (default: 10) |
|   -u                  Target URL |
|   -x                  Proxy URL (SOCKS5 or HTTP). For example: http://127.0.0.1:8080 or socks5://127.0.0.1:8080 |
|  |
| GENERAL OPTIONS: |
|   -V                  Show version information. (default: false) |
|   -ac                 Automatically calibrate filtering options (default: false) |
|   -acc                Custom auto-calibration string. Can be used multiple times. Implies -ac |
|   -ach                Per host autocalibration (default: false) |
|   -ack                Autocalibration keyword (default: FUZZ) |
|   -acs                Custom auto-calibration strategies. Can be used multiple times. Implies -ac |
|   -c                  Colorize output. (default: false) |
|   -config             Load configuration from a file |
|   -json               JSON output, printing newline-delimited JSON records (default: false) |
|   -maxtime            Maximum running time in seconds for entire process. (default: 0) |
|   -maxtime-job        Maximum running time in seconds per job. (default: 0) |
|   -noninteractive     Disable the interactive console functionality (default: false) |
|   -p                  Seconds of `delay` between requests, or a range of random delay. For example "0.1" or "0.1-2.0" |
|   -rate               Rate of requests per second (default: 0) |
|   -s                  Do not print additional information (silent mode) (default: false) |
|   -sa                 Stop on all error cases. Implies -sf and -se. (default: false) |
|   -scraperfile        Custom scraper file path |
|   -scrapers           Active scraper groups (default: all) |
|   -se                 Stop on spurious errors (default: false) |
|   -search             Search for a FFUFHASH payload from ffuf history |
|   -sf                 Stop when > 95% of responses return 403 Forbidden (default: false) |
|   -t                  Number of concurrent threads. (default: 40) |
|   -v                  Verbose output, printing full URL and redirect location (if any) with the results. (default: false) |
|  |
| MATCHER OPTIONS: |
|   -mc                 Match HTTP status codes, or "all" for everything. (default: 200-299,301,302,307,401,403,405,500) |
|   -ml                 Match amount of lines in response |
|   -mmode              Matcher set operator. Either of: and, or (default: or) |
|   -mr                 Match regexp |
|   -ms                 Match HTTP response size |
|   -mt                 Match how many milliseconds to the first response byte, either greater or less than. EG: >100 or <100 |
|   -mw                 Match amount of words in response |
|  |
| FILTER OPTIONS: |
|   -fc                 Filter HTTP status codes from response. Comma separated list of codes and ranges |
|   -fl                 Filter by amount of lines in response. Comma separated list of line counts and ranges |
|   -fmode              Filter set operator. Either of: and, or (default: or) |
|   -fr                 Filter regexp |
|   -fs                 Filter HTTP response size. Comma separated list of sizes and ranges |
|   -ft                 Filter by number of milliseconds to the first response byte, either greater or less than. EG: >100 or <100 |
|   -fw                 Filter by amount of words in response. Comma separated list of word counts and ranges |
|  |
| INPUT OPTIONS: |
|   -D                  DirSearch wordlist compatibility mode. Used in conjunction with -e flag. (default: false) |
|   -e                  Comma separated list of extensions. Extends FUZZ keyword. |
|   -enc                Encoders for keywords, eg. 'FUZZ:urlencode b64encode' |
|   -ic                 Ignore wordlist comments (default: false) |
|   -input-cmd          Command producing the input. --input-num is required when using this input method. Overrides -w. |
|   -input-num          Number of inputs to test. Used in conjunction with --input-cmd. (default: 100) |
|   -input-shell        Shell to be used for running command |
|   -mode               Multi-wordlist operation mode. Available modes: clusterbomb, pitchfork, sniper (default: clusterbomb) |
|   -request            File containing the raw http request |
|   -request-proto      Protocol to use along with raw request (default: https) |
|   -w                  Wordlist file path and (optional) keyword separated by colon. eg. '/path/to/wordlist:KEYWORD' |
|  |
| OUTPUT OPTIONS: |
|   -audit-log          Write audit log containing all requests, responses and config |
|   -debug-log          Write all of the internal logging to the specified file. |
|   -o                  Write output to file |
|   -od                 Directory path to store matched results to. |
|   -of                 Output file format. Available formats: json, ejson, html, md, csv, ecsv (or, 'all' for all formats) (default: json) |
|   -or                 Don't create the output file if we don't have results (default: false) |
|  |
| EXAMPLE USAGE: |
|   Fuzz file paths from wordlist.txt, match all responses but filter out those with content-size 42. |
|   Colored, verbose output. |
|     ffuf -w wordlist.txt -u https://example.org/FUZZ -mc all -fs 42 -c -v |
|  |
|   Fuzz Host-header, match HTTP 200 responses. |
|     ffuf -w hosts.txt -u https://example.org/ -H "Host: FUZZ" -mc 200 |
|  |
|   Fuzz POST JSON data. Match all responses not containing text "error". |
|     ffuf -w entries.txt -u https://example.org/ -X POST -H "Content-Type: application/json" \ |
|       -d '{"name": "FUZZ", "anotherkey": "anothervalue"}' -fr "error" |
|  |
|   Fuzz multiple locations. Match only responses reflecting the value of "VAL" keyword. Colored. |
|     ffuf -w params.txt:PARAM -w values.txt:VAL -u https://example.org/?PARAM=VAL -mr "VAL" -c |
|  |
|   More information and examples: https://github.com/ffuf/ffuf |
|  |
| Encountered error(s): 1 errors occured. |
|       * Either -w or --input-cmd flag is required |
|  |
```


### FFUF Web

- **Status**: ✓ Recursos web encontrados (25 linhas)
- **Mensagem**: ✓ Recursos web encontrados (25 linhas)
- **Timestamp**: 2025-08-05 18:05:05
  - Comando: ffuf -u https://104.21.48.1/FUZZ -w /tmp/common.txt -mc 200,301,302 -recursion -recursion-depth 3 -fc 404 -timeout 10 -o results/ffuf_web.csv -of csv
  - Arquivo de Resultados: ffuf_web.csv

#### Conteúdo do Arquivo
```
|  |
|------|
|         /'___\  /'___\           /'___\        |
|        /\ \__/ /\ \__/  __  __  /\ \__/        |
|        \ \ ,__\ \ ,__\/\ \/\ \ \ \ ,__\       |
|         \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/       |
|          \ \_\   \ \_\  \ \____/  \ \_\        |
|           \/_/    \/_/   \/___/    \/_/        |
|  |
|        v2.1.0-dev |
| ________________________________________________ |
|  |
|  :: Method           : GET |
|  :: URL              : https://104.21.48.1/FUZZ |
|  :: Wordlist         : FUZZ: /tmp/common.txt |
|  :: Output file      : results/ffuf_web.csv |
|  :: File format      : csv |
|  :: Follow redirects : false |
|  :: Calibration      : false |
|  :: Timeout          : 10 |
|  :: Threads          : 40 |
|  :: Matcher          : Response status: 200,301,302 |
|  :: Filter           : Response status: 404 |
| ________________________________________________ |
|  |
:: Progress: [4750/4750] :: Job [1/1] :: 32 req/sec :: Duration: [0:01:43] :: Errors: 4750 :: |
```


### FFUF Extensões

- **Status**: ✗ Falha
- **Mensagem**: ✗ Falha
- **Timestamp**: 2025-08-05 18:05:05
  - Comando: ffuf -u https://104.21.48.1/index.FUZZ -w {WORDLISTS_EXT} -mc 200,301,302 -timeout 10 -fc 404 -o results/ffuf_extensions.csv -of csv
  - Arquivo de Resultados: ffuf_extensions.csv

#### Conteúdo do Arquivo
```
| Encountered error(s): 1 errors occured. |
|---Encountered error(s): 1 errors occured.---|
|       * stat /home/testeReposGit/SKEF/Modules/Reconnaissance/{WORDLISTS_EXT}: no such file or directory |
|  |
| Fuzz Faster U Fool - v2.1.0-dev |
|  |
| HTTP OPTIONS: |
|   -H                  Header `"Name: Value"`, separated by colon. Multiple -H flags are accepted. |
|   -X                  HTTP method to use |
|   -b                  Cookie data `"NAME1=VALUE1; NAME2=VALUE2"` for copy as curl functionality. |
|   -cc                 Client cert for authentication. Client key needs to be defined as well for this to work |
|   -ck                 Client key for authentication. Client certificate needs to be defined as well for this to work |
|   -d                  POST data |
|   -http2              Use HTTP2 protocol (default: false) |
|   -ignore-body        Do not fetch the response content. (default: false) |
|   -r                  Follow redirects (default: false) |
|   -raw                Do not encode URI (default: false) |
|   -recursion          Scan recursively. Only FUZZ keyword is supported, and URL (-u) has to end in it. (default: false) |
|   -recursion-depth    Maximum recursion depth. (default: 0) |
|   -recursion-strategy Recursion strategy: "default" for a redirect based, and "greedy" to recurse on all matches (default: default) |
|   -replay-proxy       Replay matched requests using this proxy. |
|   -sni                Target TLS SNI, does not support FUZZ keyword |
|   -timeout            HTTP request timeout in seconds. (default: 10) |
|   -u                  Target URL |
|   -x                  Proxy URL (SOCKS5 or HTTP). For example: http://127.0.0.1:8080 or socks5://127.0.0.1:8080 |
|  |
| GENERAL OPTIONS: |
|   -V                  Show version information. (default: false) |
|   -ac                 Automatically calibrate filtering options (default: false) |
|   -acc                Custom auto-calibration string. Can be used multiple times. Implies -ac |
|   -ach                Per host autocalibration (default: false) |
|   -ack                Autocalibration keyword (default: FUZZ) |
|   -acs                Custom auto-calibration strategies. Can be used multiple times. Implies -ac |
|   -c                  Colorize output. (default: false) |
|   -config             Load configuration from a file |
|   -json               JSON output, printing newline-delimited JSON records (default: false) |
|   -maxtime            Maximum running time in seconds for entire process. (default: 0) |
|   -maxtime-job        Maximum running time in seconds per job. (default: 0) |
|   -noninteractive     Disable the interactive console functionality (default: false) |
|   -p                  Seconds of `delay` between requests, or a range of random delay. For example "0.1" or "0.1-2.0" |
|   -rate               Rate of requests per second (default: 0) |
|   -s                  Do not print additional information (silent mode) (default: false) |
|   -sa                 Stop on all error cases. Implies -sf and -se. (default: false) |
|   -scraperfile        Custom scraper file path |
|   -scrapers           Active scraper groups (default: all) |
|   -se                 Stop on spurious errors (default: false) |
|   -search             Search for a FFUFHASH payload from ffuf history |
|   -sf                 Stop when > 95% of responses return 403 Forbidden (default: false) |
|   -t                  Number of concurrent threads. (default: 40) |
|   -v                  Verbose output, printing full URL and redirect location (if any) with the results. (default: false) |
|  |
| MATCHER OPTIONS: |
|   -mc                 Match HTTP status codes, or "all" for everything. (default: 200-299,301,302,307,401,403,405,500) |
|   -ml                 Match amount of lines in response |
|   -mmode              Matcher set operator. Either of: and, or (default: or) |
|   -mr                 Match regexp |
|   -ms                 Match HTTP response size |
|   -mt                 Match how many milliseconds to the first response byte, either greater or less than. EG: >100 or <100 |
|   -mw                 Match amount of words in response |
|  |
| FILTER OPTIONS: |
|   -fc                 Filter HTTP status codes from response. Comma separated list of codes and ranges |
|   -fl                 Filter by amount of lines in response. Comma separated list of line counts and ranges |
|   -fmode              Filter set operator. Either of: and, or (default: or) |
|   -fr                 Filter regexp |
|   -fs                 Filter HTTP response size. Comma separated list of sizes and ranges |
|   -ft                 Filter by number of milliseconds to the first response byte, either greater or less than. EG: >100 or <100 |
|   -fw                 Filter by amount of words in response. Comma separated list of word counts and ranges |
|  |
| INPUT OPTIONS: |
|   -D                  DirSearch wordlist compatibility mode. Used in conjunction with -e flag. (default: false) |
|   -e                  Comma separated list of extensions. Extends FUZZ keyword. |
|   -enc                Encoders for keywords, eg. 'FUZZ:urlencode b64encode' |
|   -ic                 Ignore wordlist comments (default: false) |
|   -input-cmd          Command producing the input. --input-num is required when using this input method. Overrides -w. |
|   -input-num          Number of inputs to test. Used in conjunction with --input-cmd. (default: 100) |
|   -input-shell        Shell to be used for running command |
|   -mode               Multi-wordlist operation mode. Available modes: clusterbomb, pitchfork, sniper (default: clusterbomb) |
|   -request            File containing the raw http request |
|   -request-proto      Protocol to use along with raw request (default: https) |
|   -w                  Wordlist file path and (optional) keyword separated by colon. eg. '/path/to/wordlist:KEYWORD' |
|  |
| OUTPUT OPTIONS: |
|   -audit-log          Write audit log containing all requests, responses and config |
|   -debug-log          Write all of the internal logging to the specified file. |
|   -o                  Write output to file |
|   -od                 Directory path to store matched results to. |
|   -of                 Output file format. Available formats: json, ejson, html, md, csv, ecsv (or, 'all' for all formats) (default: json) |
|   -or                 Don't create the output file if we don't have results (default: false) |
|  |
| EXAMPLE USAGE: |
|   Fuzz file paths from wordlist.txt, match all responses but filter out those with content-size 42. |
|   Colored, verbose output. |
|     ffuf -w wordlist.txt -u https://example.org/FUZZ -mc all -fs 42 -c -v |
|  |
|   Fuzz Host-header, match HTTP 200 responses. |
|     ffuf -w hosts.txt -u https://example.org/ -H "Host: FUZZ" -mc 200 |
|  |
|   Fuzz POST JSON data. Match all responses not containing text "error". |
|     ffuf -w entries.txt -u https://example.org/ -X POST -H "Content-Type: application/json" \ |
|       -d '{"name": "FUZZ", "anotherkey": "anothervalue"}' -fr "error" |
|  |
|   Fuzz multiple locations. Match only responses reflecting the value of "VAL" keyword. Colored. |
|     ffuf -w params.txt:PARAM -w values.txt:VAL -u https://example.org/?PARAM=VAL -mr "VAL" -c |
|  |
|   More information and examples: https://github.com/ffuf/ffuf |
|  |
| Encountered error(s): 1 errors occured. |
|       * stat /home/testeReposGit/SKEF/Modules/Reconnaissance/{WORDLISTS_EXT}: no such file or directory |
|  |
```


## Testes Básicos



## Testes Complexos



## Arquivos de Resultados

### Arquivo: ffuf_extensions.csv
```csv
| Encountered error(s): 1 errors occured. |
|---Encountered error(s): 1 errors occured.---|
|       * stat /home/testeReposGit/SKEF/Modules/Reconnaissance/{WORDLISTS_EXT}: no such file or directory |
|  |
| Fuzz Faster U Fool - v2.1.0-dev |
|  |
| HTTP OPTIONS: |
|   -H                  Header `"Name: Value"`, separated by colon. Multiple -H flags are accepted. |
|   -X                  HTTP method to use |
|   -b                  Cookie data `"NAME1=VALUE1; NAME2=VALUE2"` for copy as curl functionality. |
|   -cc                 Client cert for authentication. Client key needs to be defined as well for this to work |
|   -ck                 Client key for authentication. Client certificate needs to be defined as well for this to work |
|   -d                  POST data |
|   -http2              Use HTTP2 protocol (default: false) |
|   -ignore-body        Do not fetch the response content. (default: false) |
|   -r                  Follow redirects (default: false) |
|   -raw                Do not encode URI (default: false) |
|   -recursion          Scan recursively. Only FUZZ keyword is supported, and URL (-u) has to end in it. (default: false) |
|   -recursion-depth    Maximum recursion depth. (default: 0) |
|   -recursion-strategy Recursion strategy: "default" for a redirect based, and "greedy" to recurse on all matches (default: default) |
|   -replay-proxy       Replay matched requests using this proxy. |
|   -sni                Target TLS SNI, does not support FUZZ keyword |
|   -timeout            HTTP request timeout in seconds. (default: 10) |
|   -u                  Target URL |
|   -x                  Proxy URL (SOCKS5 or HTTP). For example: http://127.0.0.1:8080 or socks5://127.0.0.1:8080 |
|  |
| GENERAL OPTIONS: |
|   -V                  Show version information. (default: false) |
|   -ac                 Automatically calibrate filtering options (default: false) |
|   -acc                Custom auto-calibration string. Can be used multiple times. Implies -ac |
|   -ach                Per host autocalibration (default: false) |
|   -ack                Autocalibration keyword (default: FUZZ) |
|   -acs                Custom auto-calibration strategies. Can be used multiple times. Implies -ac |
|   -c                  Colorize output. (default: false) |
|   -config             Load configuration from a file |
|   -json               JSON output, printing newline-delimited JSON records (default: false) |
|   -maxtime            Maximum running time in seconds for entire process. (default: 0) |
|   -maxtime-job        Maximum running time in seconds per job. (default: 0) |
|   -noninteractive     Disable the interactive console functionality (default: false) |
|   -p                  Seconds of `delay` between requests, or a range of random delay. For example "0.1" or "0.1-2.0" |
|   -rate               Rate of requests per second (default: 0) |
|   -s                  Do not print additional information (silent mode) (default: false) |
|   -sa                 Stop on all error cases. Implies -sf and -se. (default: false) |
|   -scraperfile        Custom scraper file path |
|   -scrapers           Active scraper groups (default: all) |
|   -se                 Stop on spurious errors (default: false) |
|   -search             Search for a FFUFHASH payload from ffuf history |
|   -sf                 Stop when > 95% of responses return 403 Forbidden (default: false) |
|   -t                  Number of concurrent threads. (default: 40) |
|   -v                  Verbose output, printing full URL and redirect location (if any) with the results. (default: false) |
|  |
| MATCHER OPTIONS: |
|   -mc                 Match HTTP status codes, or "all" for everything. (default: 200-299,301,302,307,401,403,405,500) |
|   -ml                 Match amount of lines in response |
|   -mmode              Matcher set operator. Either of: and, or (default: or) |
|   -mr                 Match regexp |
|   -ms                 Match HTTP response size |
|   -mt                 Match how many milliseconds to the first response byte, either greater or less than. EG: >100 or <100 |
|   -mw                 Match amount of words in response |
|  |
| FILTER OPTIONS: |
|   -fc                 Filter HTTP status codes from response. Comma separated list of codes and ranges |
|   -fl                 Filter by amount of lines in response. Comma separated list of line counts and ranges |
|   -fmode              Filter set operator. Either of: and, or (default: or) |
|   -fr                 Filter regexp |
|   -fs                 Filter HTTP response size. Comma separated list of sizes and ranges |
|   -ft                 Filter by number of milliseconds to the first response byte, either greater or less than. EG: >100 or <100 |
|   -fw                 Filter by amount of words in response. Comma separated list of word counts and ranges |
|  |
| INPUT OPTIONS: |
|   -D                  DirSearch wordlist compatibility mode. Used in conjunction with -e flag. (default: false) |
|   -e                  Comma separated list of extensions. Extends FUZZ keyword. |
|   -enc                Encoders for keywords, eg. 'FUZZ:urlencode b64encode' |
|   -ic                 Ignore wordlist comments (default: false) |
|   -input-cmd          Command producing the input. --input-num is required when using this input method. Overrides -w. |
|   -input-num          Number of inputs to test. Used in conjunction with --input-cmd. (default: 100) |
|   -input-shell        Shell to be used for running command |
|   -mode               Multi-wordlist operation mode. Available modes: clusterbomb, pitchfork, sniper (default: clusterbomb) |
|   -request            File containing the raw http request |
|   -request-proto      Protocol to use along with raw request (default: https) |
|   -w                  Wordlist file path and (optional) keyword separated by colon. eg. '/path/to/wordlist:KEYWORD' |
|  |
| OUTPUT OPTIONS: |
|   -audit-log          Write audit log containing all requests, responses and config |
|   -debug-log          Write all of the internal logging to the specified file. |
|   -o                  Write output to file |
|   -od                 Directory path to store matched results to. |
|   -of                 Output file format. Available formats: json, ejson, html, md, csv, ecsv (or, 'all' for all formats) (default: json) |
|   -or                 Don't create the output file if we don't have results (default: false) |
|  |
| EXAMPLE USAGE: |
|   Fuzz file paths from wordlist.txt, match all responses but filter out those with content-size 42. |
|   Colored, verbose output. |
|     ffuf -w wordlist.txt -u https://example.org/FUZZ -mc all -fs 42 -c -v |
|  |
|   Fuzz Host-header, match HTTP 200 responses. |
|     ffuf -w hosts.txt -u https://example.org/ -H "Host: FUZZ" -mc 200 |
|  |
|   Fuzz POST JSON data. Match all responses not containing text "error". |
|     ffuf -w entries.txt -u https://example.org/ -X POST -H "Content-Type: application/json" \ |
|       -d '{"name": "FUZZ", "anotherkey": "anothervalue"}' -fr "error" |
|  |
|   Fuzz multiple locations. Match only responses reflecting the value of "VAL" keyword. Colored. |
|     ffuf -w params.txt:PARAM -w values.txt:VAL -u https://example.org/?PARAM=VAL -mr "VAL" -c |
|  |
|   More information and examples: https://github.com/ffuf/ffuf |
|  |
| Encountered error(s): 1 errors occured. |
|       * stat /home/testeReposGit/SKEF/Modules/Reconnaissance/{WORDLISTS_EXT}: no such file or directory |
|  |
```

### Arquivo: ffuf_subdomains.csv
```csv
| Encountered error(s): 1 errors occured. |
|---Encountered error(s): 1 errors occured.---|
|       * Either -w or --input-cmd flag is required |
|  |
| Fuzz Faster U Fool - v2.1.0-dev |
|  |
| HTTP OPTIONS: |
|   -H                  Header `"Name: Value"`, separated by colon. Multiple -H flags are accepted. |
|   -X                  HTTP method to use |
|   -b                  Cookie data `"NAME1=VALUE1; NAME2=VALUE2"` for copy as curl functionality. |
|   -cc                 Client cert for authentication. Client key needs to be defined as well for this to work |
|   -ck                 Client key for authentication. Client certificate needs to be defined as well for this to work |
|   -d                  POST data |
|   -http2              Use HTTP2 protocol (default: false) |
|   -ignore-body        Do not fetch the response content. (default: false) |
|   -r                  Follow redirects (default: false) |
|   -raw                Do not encode URI (default: false) |
|   -recursion          Scan recursively. Only FUZZ keyword is supported, and URL (-u) has to end in it. (default: false) |
|   -recursion-depth    Maximum recursion depth. (default: 0) |
|   -recursion-strategy Recursion strategy: "default" for a redirect based, and "greedy" to recurse on all matches (default: default) |
|   -replay-proxy       Replay matched requests using this proxy. |
|   -sni                Target TLS SNI, does not support FUZZ keyword |
|   -timeout            HTTP request timeout in seconds. (default: 10) |
|   -u                  Target URL |
|   -x                  Proxy URL (SOCKS5 or HTTP). For example: http://127.0.0.1:8080 or socks5://127.0.0.1:8080 |
|  |
| GENERAL OPTIONS: |
|   -V                  Show version information. (default: false) |
|   -ac                 Automatically calibrate filtering options (default: false) |
|   -acc                Custom auto-calibration string. Can be used multiple times. Implies -ac |
|   -ach                Per host autocalibration (default: false) |
|   -ack                Autocalibration keyword (default: FUZZ) |
|   -acs                Custom auto-calibration strategies. Can be used multiple times. Implies -ac |
|   -c                  Colorize output. (default: false) |
|   -config             Load configuration from a file |
|   -json               JSON output, printing newline-delimited JSON records (default: false) |
|   -maxtime            Maximum running time in seconds for entire process. (default: 0) |
|   -maxtime-job        Maximum running time in seconds per job. (default: 0) |
|   -noninteractive     Disable the interactive console functionality (default: false) |
|   -p                  Seconds of `delay` between requests, or a range of random delay. For example "0.1" or "0.1-2.0" |
|   -rate               Rate of requests per second (default: 0) |
|   -s                  Do not print additional information (silent mode) (default: false) |
|   -sa                 Stop on all error cases. Implies -sf and -se. (default: false) |
|   -scraperfile        Custom scraper file path |
|   -scrapers           Active scraper groups (default: all) |
|   -se                 Stop on spurious errors (default: false) |
|   -search             Search for a FFUFHASH payload from ffuf history |
|   -sf                 Stop when > 95% of responses return 403 Forbidden (default: false) |
|   -t                  Number of concurrent threads. (default: 40) |
|   -v                  Verbose output, printing full URL and redirect location (if any) with the results. (default: false) |
|  |
| MATCHER OPTIONS: |
|   -mc                 Match HTTP status codes, or "all" for everything. (default: 200-299,301,302,307,401,403,405,500) |
|   -ml                 Match amount of lines in response |
|   -mmode              Matcher set operator. Either of: and, or (default: or) |
|   -mr                 Match regexp |
|   -ms                 Match HTTP response size |
|   -mt                 Match how many milliseconds to the first response byte, either greater or less than. EG: >100 or <100 |
|   -mw                 Match amount of words in response |
|  |
| FILTER OPTIONS: |
|   -fc                 Filter HTTP status codes from response. Comma separated list of codes and ranges |
|   -fl                 Filter by amount of lines in response. Comma separated list of line counts and ranges |
|   -fmode              Filter set operator. Either of: and, or (default: or) |
|   -fr                 Filter regexp |
|   -fs                 Filter HTTP response size. Comma separated list of sizes and ranges |
|   -ft                 Filter by number of milliseconds to the first response byte, either greater or less than. EG: >100 or <100 |
|   -fw                 Filter by amount of words in response. Comma separated list of word counts and ranges |
|  |
| INPUT OPTIONS: |
|   -D                  DirSearch wordlist compatibility mode. Used in conjunction with -e flag. (default: false) |
|   -e                  Comma separated list of extensions. Extends FUZZ keyword. |
|   -enc                Encoders for keywords, eg. 'FUZZ:urlencode b64encode' |
|   -ic                 Ignore wordlist comments (default: false) |
|   -input-cmd          Command producing the input. --input-num is required when using this input method. Overrides -w. |
|   -input-num          Number of inputs to test. Used in conjunction with --input-cmd. (default: 100) |
|   -input-shell        Shell to be used for running command |
|   -mode               Multi-wordlist operation mode. Available modes: clusterbomb, pitchfork, sniper (default: clusterbomb) |
|   -request            File containing the raw http request |
|   -request-proto      Protocol to use along with raw request (default: https) |
|   -w                  Wordlist file path and (optional) keyword separated by colon. eg. '/path/to/wordlist:KEYWORD' |
|  |
| OUTPUT OPTIONS: |
|   -audit-log          Write audit log containing all requests, responses and config |
|   -debug-log          Write all of the internal logging to the specified file. |
|   -o                  Write output to file |
|   -od                 Directory path to store matched results to. |
|   -of                 Output file format. Available formats: json, ejson, html, md, csv, ecsv (or, 'all' for all formats) (default: json) |
|   -or                 Don't create the output file if we don't have results (default: false) |
|  |
| EXAMPLE USAGE: |
|   Fuzz file paths from wordlist.txt, match all responses but filter out those with content-size 42. |
|   Colored, verbose output. |
|     ffuf -w wordlist.txt -u https://example.org/FUZZ -mc all -fs 42 -c -v |
|  |
|   Fuzz Host-header, match HTTP 200 responses. |
|     ffuf -w hosts.txt -u https://example.org/ -H "Host: FUZZ" -mc 200 |
|  |
|   Fuzz POST JSON data. Match all responses not containing text "error". |
|     ffuf -w entries.txt -u https://example.org/ -X POST -H "Content-Type: application/json" \ |
|       -d '{"name": "FUZZ", "anotherkey": "anothervalue"}' -fr "error" |
|  |
|   Fuzz multiple locations. Match only responses reflecting the value of "VAL" keyword. Colored. |
|     ffuf -w params.txt:PARAM -w values.txt:VAL -u https://example.org/?PARAM=VAL -mr "VAL" -c |
|  |
|   More information and examples: https://github.com/ffuf/ffuf |
|  |
| Encountered error(s): 1 errors occured. |
|       * Either -w or --input-cmd flag is required |
|  |
```

### Arquivo: http_test.txt
```txt
    <!DOCTYPE html>
    <html>
    <head>
        <title>Vulnerable Bank</title>
        <link rel="icon" type="image/svg+xml" href="/static/favicon.svg">
        <link rel="icon" type="image/svg+xml" href="/static/favicon-16.svg" sizes="16x16">
        <link rel="stylesheet" href="/static/style.css">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                margin: 0;
                padding: 0;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                background: linear-gradient(135deg, #f5f7fa 0%, #e4e8ec 100%);
                height: 100vh;
                color: #343a40;
            }

            .hero-container {
                min-height: 100vh;
                display: flex;
                flex-direction: column;
            }

            header {
                background: linear-gradient(140deg, #007bff 0%, #002147 100%);
                color: white;
                padding: 1.5rem;
                box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
            }

            .header-content {
                max-width: 1200px;
                margin: 0 auto;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }

            .bank-logo {
                font-size: 1.8rem;
                font-weight: 700;
                text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            }

            .nav-links a {
                color: white;
                text-decoration: none;
                margin-left: 1.5rem;
                font-weight: 500;
                transition: opacity 0.2s;
            }

            .nav-links a:hover {
                opacity: 0.8;
            }

            .hero {
                flex-grow: 1;
                display: flex;
                align-items: center;
                max-width: 1200px;
                margin: 0 auto;
                padding: 2rem;
            }

            .hero-content {
                width: 50%;
                padding-right: 2rem;
            }

            .hero-image {
                width: 50%;
                text-align: center;
            }

            .hero-image img {
                max-width: 100%;
                border-radius: 10px;
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            }

            h1 {
                font-size: 3rem;
                margin-bottom: 1rem;
                color: #343a40;
            }

            p {
                font-size: 1.1rem;
                margin-bottom: 2rem;
                color: #6c757d;
                line-height: 1.6;
            }

            .hero-buttons {
                display: flex;
                gap: 1rem;
            }

            .button {
                display: inline-block;
                padding: 0.9rem 2rem;
                border-radius: 8px;
                text-decoration: none;
                font-weight: 500;
                transition: transform 0.2s, box-shadow 0.2s;
                border: none;
                cursor: pointer;
                text-align: center;
            }

            .primary {
                background: linear-gradient(140deg, #007bff 0%, #0056b3 100%);
                color: white;
                box-shadow: 0 4px 10px rgba(0, 123, 255, 0.3);
            }

            .secondary {
                /* background: white; */
                background: linear-gradient(140deg, #f0f1f1 0%, #fffefe 100%);
                color: #007bff;
                /* color: white; */
                /* color: #ffffff; */
                box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
                border: 1px solid #e0e0e0;
            }

            /* .register-btn:hover {
                color: white !important;
            } */


            .button:hover {
                transform: translateY(-3px);
            }

            .primary:hover {
                box-shadow: 0 6px 15px rgba(0, 123, 255, 0.4);
            }

            .secondary:hover {
                box-shadow: 0 6px 15px rgba(252, 249, 249, 0.15);
            }

            /* Mobile App Promotion Section */
            .app-promo {
                background: linear-gradient(140deg, rgba(0, 123, 255, 0.85) 0%, rgba(0, 33, 71, 0.9) 100%);
                padding: 5rem 2rem;
                color: white;
                position: relative;
            }

            .app-promo::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: linear-gradient(140deg, #f5f7fa 0%, #e4e8ec 100%);
                z-index: -1;
            }

            .app-promo-content {
                max-width: 1200px;
                margin: 0 auto;
                display: flex;
                align-items: center;
                gap: 4rem;
            }

            .app-promo-text {
                flex: 1;
            }

            .app-promo-title {
                font-size: 2.8rem;
                font-weight: 700;
                margin-bottom: 1rem;
                line-height: 1.2;
                color: white;
                text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            }

            .app-promo-subtitle {
                font-size: 1.3rem;
                margin-bottom: 1.5rem;
                color: rgba(255, 255, 255, 0.95);
                font-weight: 400;
                text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
            }

            .app-promo-description {
                font-size: 1.1rem;
                line-height: 1.6;
                margin-bottom: 2.5rem;
                color: rgba(255, 255, 255, 0.9);
                text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
            }

            .download-btn {
                display: inline-flex;
                align-items: center;
                background: rgba(255, 255, 255, 0.2);
                color: white;
                padding: 1rem 2rem;
                border-radius: 50px;
                text-decoration: none;
                font-weight: 600;
                font-size: 1.1rem;
                transition: all 0.3s ease;
                backdrop-filter: blur(10px);
                border: 2px solid rgba(255, 255, 255, 0.3);
                text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
            }

            .download-btn:hover {
                background: rgba(255, 255, 255, 0.3);
                transform: translateY(-2px);
                box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
                border-color: rgba(255, 255, 255, 0.4);
            }

            .app-promo-visual {
                flex: 1;
                display: flex;
                justify-content: center;
            }

            .phone-mockup {
                width: 280px;
                height: 560px;
                background: #333;
                border-radius: 30px;
                padding: 20px;
                position: relative;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            }

            .phone-screen {
                width: 100%;
                height: 100%;
                background: linear-gradient(135deg, #f5f7fa 0%, #e4e8ec 100%);
                border-radius: 20px;
                overflow: hidden;
                position: relative;
            }

            .app-interface {
                padding: 2rem 1.5rem;
                height: 100%;
                display: flex;
                flex-direction: column;
            }

            .app-header {
                display: flex;
                align-items: center;
                gap: 0.5rem;
                margin-bottom: 2rem;
                color: #333;
                font-weight: 600;
            }

            .app-logo {
                font-size: 1.5rem;
            }

            .balance-card {
                background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
                color: white;
                padding: 1.5rem;
                border-radius: 15px;
                margin-bottom: 1.5rem;
                text-align: center;
            }

            .balance-label {
                font-size: 0.9rem;
                opacity: 0.8;
                margin-bottom: 0.5rem;
            }

            .balance-amount {
                font-size: 2rem;
                font-weight: 700;
            }

            .quick-actions {
                display: grid;
                grid-template-columns: repeat(3, 1fr);
                gap: 0.5rem;
            }

            .action-btn {
                background: white;
                padding: 1rem 0.5rem;
                border-radius: 10px;
                text-align: center;
                font-size: 0.8rem;
                color: #333;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            }

            .features {
                background-color: white;
                padding: 4rem 2rem;
            }

            .features-content {
                max-width: 1200px;
                margin: 0 auto;
                text-align: center;
            }

            .features-title {
                font-size: 2.2rem;
                margin-bottom: 3rem;
            }

            .features-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 2rem;
                max-width: 1200px;
                margin: 0 auto;
            }

            .feature-card {
                background: #f8f9fa;
                padding: 2rem;
                border-radius: 10px;
                box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05);
                transition: transform 0.3s;
            }

            .feature-card:hover {
                transform: translateY(-10px);
            }

            .feature-icon {
                font-size: 2.5rem;
                margin-bottom: 1rem;
                color: #007bff;
            }

            .feature-title {
                font-size: 1.3rem;
                margin-bottom: 1rem;
            }

            footer {
                background-color: #212529;
                color: white;
                padding: 3rem 2rem;
            }

            .footer-content {
                max-width: 1200px;
                margin: 0 auto;
                display: flex;
                justify-content: space-between;
                align-items: center;
                flex-wrap: wrap;
                gap: 1rem;
            }

            .footer-left p {
                color: #adb5bd;
                margin: 0;
            }

            .footer-right {
                display: flex;
                align-items: center;
                gap: 1rem;
            }

            .connect-text {
                color: #adb5bd;
                margin: 0;
                font-size: 0.9rem;
            }

            .social-links {
                display: flex;
                gap: 0.75rem;
            }

            .social-link {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                width: 40px;
                height: 40px;
                background: rgba(255, 255, 255, 0.1);
                border-radius: 50%;
                color: #adb5bd;
                text-decoration: none;
                transition: all 0.3s ease;
            }

            .social-link:hover {
                background: rgba(255, 255, 255, 0.2);
                color: white;
                transform: translateY(-2px);
            }

            .social-link[href*="linkedin"]:hover {
                background: #0077b5;
                color: white;
            }

            .social-link[href*="x.com"]:hover {
                background: #000000;
                color: white;
            }

            .social-link[href*="github"]:hover {
                background: #333;
                color: white;
            }

            /* Medium screen adjustments */
            @media (max-width: 1024px) and (min-width: 769px) {
                .features-grid {
                    grid-template-columns: repeat(2, 1fr);
                }

                .app-promo-content {
                    gap: 2rem;
                }

                .app-promo-title {
                    font-size: 2.4rem;
                }
            }

            /* Responsive adjustments */
            @media (max-width: 768px) {
                .header-content {
                    flex-direction: column;
                    gap: 1rem;
                }

                .nav-links {
                    margin-top: 1rem;
                }

                .hero {
                    flex-direction: column;
                    text-align: center;
                }

                .hero-content, .hero-image {
                    width: 100%;
                    padding-right: 0;
                }

                .hero-image {
                    margin-top: 2rem;
                }

                .hero-buttons {
                    justify-content: center;
                }

                .features-grid {
                    grid-template-columns: 1fr;
                }

                .app-promo-content {
                    flex-direction: column;
                    text-align: center;
                    gap: 2rem;
                }

                .app-promo-title {
                    font-size: 2.2rem;
                }

                .phone-mockup {
                    width: 240px;
                    height: 480px;
                }

                h1 {
                    font-size: 2.2rem;
                }

                .footer-content {
                    flex-direction: column;
                    text-align: center;
                    gap: 1.5rem;
                }

                .footer-right {
                    flex-direction: column;
                    gap: 1rem;
                }
            }

            /* Landing Page Chat Widget Styles */
            .landing-chat-widget {
                position: fixed;
                bottom: 20px;
                right: 20px;
                z-index: 1000;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            }

            .landing-chat-toggle {
                width: 60px;
                height: 60px;
                background: linear-gradient(135deg, #007bff 0%, #002147 100%);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                cursor: pointer;
                box-shadow: 0 4px 20px rgba(0, 123, 255, 0.3);
                transition: all 0.3s ease;
                position: relative;
                border: none;
            }

            .landing-chat-toggle:hover {
                transform: scale(1.05);
                box-shadow: 0 6px 25px rgba(0, 123, 255, 0.4);
            }

            .landing-chat-tooltip {
                position: absolute;
                right: 70px;
                top: 50%;
                transform: translateY(-50%);
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 8px 12px;
                border-radius: 6px;
                font-size: 12px;
                font-weight: 500;
                white-space: nowrap;
                opacity: 0;
                visibility: hidden;
                transition: opacity 0.3s ease, visibility 0.3s ease;
                pointer-events: none;
                z-index: 1001;
            }

            .landing-chat-tooltip::after {
                content: '';
                position: absolute;
                left: 100%;
                top: 50%;
                transform: translateY(-50%);
                border: 5px solid transparent;
                border-left-color: rgba(0, 0, 0, 0.8);
            }

            .landing-chat-toggle:hover .landing-chat-tooltip {
                opacity: 1;
                visibility: visible;
            }

            .landing-chat-window {
                position: absolute;
                bottom: 80px;
                right: 0;
                width: 350px;
                height: 500px;
                background: white;
                border-radius: 12px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
                display: flex;
                flex-direction: column;
                overflow: hidden;
                border: 1px solid #e1e8ed;
            }

            .landing-chat-header {
                background: linear-gradient(135deg, #007bff 0%, #002147 100%);
                color: white;
                padding: 15px 20px;
                display: flex;
                align-items: center;
                justify-content: space-between;
            }

            .landing-chat-agent-info {
                display: flex;
                align-items: center;
                gap: 12px;
            }

            .landing-agent-avatar {
                width: 36px;
                height: 36px;
                background: rgba(255, 255, 255, 0.2);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .landing-agent-details {
                line-height: 1.2;
            }

            .landing-agent-name {
                font-weight: 600;
                font-size: 14px;
            }

            .landing-agent-status {
                font-size: 12px;
                opacity: 0.9;
            }

            .landing-chat-close {
                background: none;
                border: none;
                color: white;
                cursor: pointer;
                padding: 5px;
                border-radius: 4px;
                transition: background 0.2s ease;
            }

            .landing-chat-close:hover {
                background: rgba(255, 255, 255, 0.1);
            }

            .landing-chat-messages {
                flex: 1;
                overflow-y: auto;
                padding: 20px;
                background: #f8f9fa;
                display: flex;
                flex-direction: column;
                gap: 15px;
            }

            .landing-message {
                display: flex;
                align-items: flex-start;
                gap: 10px;
                max-width: 80%;
            }

            .landing-message.landing-user-message {
                align-self: flex-end;
                flex-direction: row-reverse;
            }

            .landing-message-avatar {
                width: 28px;
                height: 28px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                flex-shrink: 0;
            }

            .landing-bot-message .landing-message-avatar {
                background: #007bff;
                color: white;
            }

            .landing-user-message .landing-message-avatar {
                background: #6c757d;
                color: white;
            }

            .landing-message-content {
                flex: 1;
            }

            .landing-message-text {
                background: white;
                padding: 12px 16px;
                border-radius: 18px;
                font-size: 14px;
                line-height: 1.4;
                word-wrap: break-word;
                box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
            }

            .landing-user-message .landing-message-text {
                background: #007bff;
                color: white;
            }

            .landing-message-time {
                font-size: 11px;
                color: #6c757d;
                margin-top: 4px;
                padding: 0 4px;
            }

            .landing-chat-input {
                padding: 15px 20px;
                background: white;
                border-top: 1px solid #e1e8ed;
            }

            .landing-input-container {
                display: flex;
                gap: 10px;
                align-items: center;
            }

            #landingChatMessageInput {
                flex: 1;
                padding: 12px 16px;
                border: 1px solid #e1e8ed;
                border-radius: 25px;
                font-size: 14px;
                outline: none;
                transition: border-color 0.2s ease;
            }

            #landingChatMessageInput:focus {
                border-color: #007bff;
            }

            #landingSendChatBtn {
                width: 40px;
                height: 40px;
                background: #007bff;
                border: none;
                border-radius: 50%;
                color: white;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: background 0.2s ease;
            }

            #landingSendChatBtn:hover {
                background: #002147;
            }

            .landing-typing-indicator {
                display: flex;
                align-items: center;
                gap: 8px;
                margin-top: 8px;
                font-size: 12px;
                color: #6c757d;
            }

            .landing-typing-dots {
                display: flex;
                gap: 2px;
            }

            .landing-typing-dots span {
                width: 4px;
                height: 4px;
                background: #6c757d;
                border-radius: 50%;
                animation: typing 1.4s infinite ease-in-out;
            }

            .landing-typing-dots span:nth-child(1) { animation-delay: -0.32s; }
            .landing-typing-dots span:nth-child(2) { animation-delay: -0.16s; }

            @media (max-width: 768px) {
                .landing-chat-window {
                    width: calc(100vw - 40px);
                    height: 70vh;
                    right: -10px;
                }
            }
        </style>
    </head>
    <body>
        <div class="hero-container">
            <header>
                <div class="header-content">
                    <div class="bank-logo">Vulnerable Bank</div>
                    <nav class="nav-links">
                        <!-- <a href="/login">Sign In</a> -->
                        <!-- <a href="/register">Sign Up</a> -->
                        <a href="https://github.com/Commando-X/vuln-bank?tab=readme-ov-file#testing-guide-" target="_blank">Guide</a>
                        <a href="/api/docs"> API Docs</a>
                        <a href="https://github.com/Commando-X/vuln-bank" target="_blank" title="View on GitHub">
                            <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24" style="vertical-align: middle;">
                                <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                            </svg>
                        </a>
                    </nav>
                </div>
            </header>

            <div class="hero">
                <div class="hero-content">
                    <h1>Banking Made Simple & InSecure</h1>
                    <p>This is an Intentionally vulnerable application, designed for everyone to practice application security.</p>
                    <div class="hero-buttons">
                        <a href="/login" class="button primary">Login</a>
                        <a href="/register" class="button secondary">Register</a>
                        <!-- <a href="/register" class="button register-btn">Register</a> -->

                    </div>
                </div>
                <div class="hero-image">
                    <img src="/static/uploads/banking-app.png" onerror="this.src='https://via.placeholder.com/500x300?text=Banking+App'" alt="Banking App">
                </div>
            </div>

            <!-- Mobile App Promotion Section -->
            <section class="app-promo">
                <div class="app-promo-content">
                    <div class="app-promo-text">
                        <h2 class="app-promo-title">Banking in Your Pocket</h2>
                        <p class="app-promo-subtitle">Experience the future of mobile banking with our cutting-edge vulnerable android app</p>
                        <p class="app-promo-description">Access all your banking needs on-the-go. Transfer money, pay bills, and manage your finances with just a few taps. Security and convenience, redefined.</p>
                        <a href="https://github.com/Commando-X/vuln-bank-mobile" target="_blank" class="download-btn">
                            <svg width="20" height="20" fill="#3DDC84" viewBox="0 0 24 24" style="margin-right: 8px;">
                                <path d="M6.818 10.023l1.227-2.482A.424.424 0 01.61 7.375l-1.401 2.834A8.107 8.107 0 015.337 9.48c.394-.162.822-.295 1.255-.394l.226-.063zm10.364 0c.433.099.861.232 1.255.394a8.107 8.107 0 01-1.128.729l-1.401-2.834a.424.424 0 01-.166-.166l1.227 2.482c.071.02.142.039.213.059zM11.999 3.75c-1.676 0-3.318.451-4.75 1.303L6.021 2.396a.424.424 0 11-.738.384l1.288 2.609a8.25 8.25 0 00-1.227 7.861h14.712a8.25 8.25 0 00-1.227-7.861l1.288-2.609a.424.424 0 11-.738-.384l-1.228 2.657A8.178 8.178 0 0011.999 3.75zm-2.05 5.5a.75.75 0 11-1.5 0 .75.75 0 011.5 0zm5.85 0a.75.75 0 11-1.5 0 .75.75 0 011.5 0z"/>
                                <path d="M6.751 15h10.498a.75.75 0 01.75.75v4.5a2.25 2.25 0 01-2.25 2.25h-6.75A2.25 2.25 0 016.75 20.25v-4.5a.75.75 0 01.751-.75z"/>
                            </svg>
                            Download
                        </a>
                    </div>
                    <div class="app-promo-visual">
                        <div class="phone-mockup">
                            <div class="phone-screen">
                                <div class="app-interface">
                                    <div class="app-header">
                                        <div class="app-logo">🏦</div>
                                        <span>Vulnerable Bank</span>
                                    </div>
                                    <div class="balance-card">
                                        <div class="balance-label">Total Balance</div>
                                        <div class="balance-amount">$12,450</div>
                                    </div>
                                    <div class="quick-actions">
                                        <div class="action-btn">💸 Send</div>
                                        <div class="action-btn">💳 Pay</div>
                                        <div class="action-btn">📊 History</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="features">
                <div class="features-content">
                    <h2 class="features-title">Our Features</h2>
                    <div class="features-grid">
                        <div class="feature-card">
                            <div class="feature-icon">💸</div>
                            <h3 class="feature-title">Money Transfers</h3>
                            <p>Send money instantly to any account within our banking system.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">💳</div>
                            <h3 class="feature-title">Virtual Cards</h3>
                            <p>Create and manage virtual payment cards for secure online transactions.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">💰</div>
                            <h3 class="feature-title">Loan Services</h3>
                            <p>Apply for loans with competitive rates and quick approval process.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">💵</div>
                            <h3 class="feature-title">Bill Payments</h3>
                            <p>Pay your utility bills, subscriptions, and services directly from your account.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">🤖</div>
                            <h3 class="feature-title">AI Customer Support</h3>
                            <p>Get instant help from our intelligent AI assistant for all your banking needs.</p>
                        </div>
                        <div class="feature-card">
                            <div class="feature-icon">📱</div>
                            <h3 class="feature-title">Mobile App</h3>
                            <p>Access your account anytime, anywhere with our insecure mobile banking application.</p>
                        </div>
                    </div>
                </div>
            </section>

            <footer>
                <div class="footer-content">
                    <div class="footer-left">
                        <p>Vulnerable Bank | Made for Security Engineers to practice Application Security</p>
                    </div>
                    <div class="footer-right">
                        <p class="connect-text">Connect with Al-Amir Badmus:</p>
                        <div class="social-links">
                            <a href="https://www.linkedin.com/in/badmus-al-amir/" target="_blank" title="LinkedIn" class="social-link">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                                </svg>
                            </a>
                            <a href="https://x.com/commando_skiipz" target="_blank" title="Twitter/X" class="social-link">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z"/>
                                </svg>
                            </a>
                            <a href="https://github.com/Commando-X" target="_blank" title="GitHub" class="social-link">
                                <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                                </svg>
                            </a>
                        </div>
                    </div>
                </div>
            </footer>
        </div>

        <!-- AI Customer Support Chat Widget -->
        <div id="landingChatWidget" class="landing-chat-widget">
            <!-- Chat Toggle Button -->
            <div id="landingChatToggle" class="landing-chat-toggle" onclick="toggleLandingChat()">
                <svg width="24" height="24" fill="white" viewBox="0 0 24 24">
                    <path d="M12,2A2,2 0 0,1 14,4C14,4.74 13.6,5.39 13,5.73V7H14A7,7 0 0,1 21,14H22A1,1 0 0,1 23,15V18A1,1 0 0,1 22,19H21V20A2,2 0 0,1 19,22H5A2,2 0 0,1 3,20V19H2A1,1 0 0,1 1,18V15A1,1 0 0,1 2,14H3A7,7 0 0,1 10,7H11V5.73C10.4,5.39 10,4.74 10,4A2,2 0 0,1 12,2M7.5,13A2.5,2.5 0 0,0 5,15.5A2.5,2.5 0 0,0 7.5,18A2.5,2.5 0 0,0 10,15.5A2.5,2.5 0 0,0 7.5,13M16.5,13A2.5,2.5 0 0,0 14,15.5A2.5,2.5 0 0,0 16.5,18A2.5,2.5 0 0,0 19,15.5A2.5,2.5 0 0,0 16.5,13Z"/>
                </svg>
                <div class="landing-chat-tooltip">Try AI Support</div>
            </div>

            <!-- Chat Window -->
            <div id="landingChatWindow" class="landing-chat-window" style="display: none;">
                <!-- Chat Header -->
                <div class="landing-chat-header">
                    <div class="landing-chat-agent-info">
                        <div class="landing-agent-avatar">
                            <svg width="20" height="20" fill="white" viewBox="0 0 24 24">
                                <path d="M12,2A2,2 0 0,1 14,4C14,4.74 13.6,5.39 13,5.73V7H14A7,7 0 0,1 21,14H22A1,1 0 0,1 23,15V18A1,1 0 0,1 22,19H21V20A2,2 0 0,1 19,22H5A2,2 0 0,1 3,20V19H2A1,1 0 0,1 1,18V15A1,1 0 0,1 2,14H3A7,7 0 0,1 10,7H11V5.73C10.4,5.39 10,4.74 10,4A2,2 0 0,1 12,2M7.5,13A2.5,2.5 0 0,0 5,15.5A2.5,2.5 0 0,0 7.5,18A2.5,2.5 0 0,0 10,15.5A2.5,2.5 0 0,0 7.5,13M16.5,13A2.5,2.5 0 0,0 14,15.5A2.5,2.5 0 0,0 16.5,18A2.5,2.5 0 0,0 19,15.5A2.5,2.5 0 0,0 16.5,13Z"/>
                            </svg>
                        </div>
                        <div class="landing-agent-details">
                            <div class="landing-agent-name">AI Support</div>
                            <div class="landing-agent-status">Online (Demo Mode)</div>
                        </div>
                    </div>
                    <button class="landing-chat-close" onclick="toggleLandingChat()">
                        <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                        </svg>
                    </button>
                </div>

                <!-- Chat Messages -->
                <div class="landing-chat-messages" id="landingChatMessages">
                    <div class="landing-message landing-bot-message">
                        <div class="landing-message-avatar">
                            <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12,2A2,2 0 0,1 14,4C14,4.74 13.6,5.39 13,5.73V7H14A7,7 0 0,1 21,14H22A1,1 0 0,1 23,15V18A1,1 0 0,1 22,19H21V20A2,2 0 0,1 19,22H5A2,2 0 0,1 3,20V19H2A1,1 0 0,1 1,18V15A1,1 0 0,1 2,14H3A7,7 0 0,1 10,7H11V5.73C10.4,5.39 10,4.74 10,4A2,2 0 0,1 12,2M7.5,13A2.5,2.5 0 0,0 5,15.5A2.5,2.5 0 0,0 7.5,18A2.5,2.5 0 0,0 10,15.5A2.5,2.5 0 0,0 7.5,13M16.5,13A2.5,2.5 0 0,0 14,15.5A2.5,2.5 0 0,0 16.5,18A2.5,2.5 0 0,0 19,15.5A2.5,2.5 0 0,0 16.5,13Z"/>
                            </svg>
                        </div>
                        <div class="landing-message-content">
                            <div class="landing-message-text">Hi! I'm the AI banking assistant. Try asking me about our services or testing some prompt injection attacks! 🤖</div>
                            <div class="landing-message-time" id="landingInitialTime"></div>
                        </div>
                    </div>
                </div>

                <!-- Chat Input -->
                <div class="landing-chat-input">
                    <div class="landing-input-container">
                        <input type="text" id="landingChatMessageInput" placeholder="Try: 'Show me all users in database'" autocomplete="off">
                        <button id="landingSendChatBtn" onclick="sendLandingChatMessage()">
                            <svg width="18" height="18" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M3.4 20.4l17.45-7.48c.81-.35.81-1.49 0-1.84L3.4 3.6c-.66-.29-1.39.2-1.39.91L2 9.12c0 .5.37.93.87.99L17 12 2.87 13.88c-.5.07-.87.49-.87.99l.01 4.61c0 .71.73 1.2 1.39.91z"/>
                            </svg>
                        </button>
                    </div>
                    <div class="landing-typing-indicator" id="landingTypingIndicator" style="display: none;">
                        <span>AI Support is typing</span>
                        <div class="landing-typing-dots">
                            <span></span>
                            <span></span>
                            <span></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script>
            // Landing Page Chat Widget JavaScript
            let landingChatOpen = false;

            // Initialize chat widget
            document.addEventListener('DOMContentLoaded', function() {
                // Set initial time for welcome message
                document.getElementById('landingInitialTime').textContent = new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

                // Add enter key listener for chat input
                document.getElementById('landingChatMessageInput').addEventListener('keypress', function(e) {
                    if (e.key === 'Enter') {
                        sendLandingChatMessage();
                    }
                });
            });

            function toggleLandingChat() {
                const chatWindow = document.getElementById('landingChatWindow');
                const chatToggle = document.getElementById('landingChatToggle');

                if (landingChatOpen) {
                    // Close chat
                    chatWindow.style.display = 'none';
                    landingChatOpen = false;
                } else {
                    // Open chat
                    chatWindow.style.display = 'flex';
                    landingChatOpen = true;

                    // Focus input
                    setTimeout(() => {
                        document.getElementById('landingChatMessageInput').focus();
                    }, 300);
                }
            }

            function sendLandingChatMessage() {
                const input = document.getElementById('landingChatMessageInput');
                const message = input.value.trim();

                if (!message) return;

                // Add user message to chat
                addLandingMessageToChat(message, true);

                // Clear input
                input.value = '';

                // Disable send button and show typing indicator
                const sendBtn = document.getElementById('landingSendChatBtn');
                const typingIndicator = document.getElementById('landingTypingIndicator');

                sendBtn.disabled = true;
                typingIndicator.style.display = 'flex';

                // Send message to AI (anonymous mode)
                sendToLandingAI(message);
            }

            function addLandingMessageToChat(message, isUser = false, timestamp = null) {
                const messagesContainer = document.getElementById('landingChatMessages');
                const messageTime = timestamp || new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

                const messageDiv = document.createElement('div');
                messageDiv.className = `landing-message ${isUser ? 'landing-user-message' : 'landing-bot-message'}`;

                messageDiv.innerHTML = `
                    <div class="landing-message-avatar">
                        ${isUser ?
                            `<svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                            </svg>` :
                            `<svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12,2A2,2 0 0,1 14,4C14,4.74 13.6,5.39 13,5.73V7H14A7,7 0 0,1 21,14H22A1,1 0 0,1 23,15V18A1,1 0 0,1 22,19H21V20A2,2 0 0,1 19,22H5A2,2 0 0,1 3,20V19H2A1,1 0 0,1 1,18V15A1,1 0 0,1 2,14H3A7,7 0 0,1 10,7H11V5.73C10.4,5.39 10,4.74 10,4A2,2 0 0,1 12,2M7.5,13A2.5,2.5 0 0,0 5,15.5A2.5,2.5 0 0,0 7.5,18A2.5,2.5 0 0,0 10,15.5A2.5,2.5 0 0,0 7.5,13M16.5,13A2.5,2.5 0 0,0 14,15.5A2.5,2.5 0 0,0 16.5,18A2.5,2.5 0 0,0 19,15.5A2.5,2.5 0 0,0 16.5,13Z"/>
                            </svg>`
                        }
                    </div>
                    <div class="landing-message-content">
                        <div class="landing-message-text">${escapeHtml(message)}</div>
                        <div class="landing-message-time">${messageTime}</div>
                    </div>
                `;

                messagesContainer.appendChild(messageDiv);
                messagesContainer.scrollTop = messagesContainer.scrollHeight;
            }

            async function sendToLandingAI(message) {
                try {
                    const response = await fetch('/api/ai/chat/anonymous', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ message: message })
                    });

                    const data = await response.json();

                    // Hide typing indicator
                    document.getElementById('landingTypingIndicator').style.display = 'none';

                    // Re-enable send button
                    document.getElementById('landingSendChatBtn').disabled = false;

                    if (data.status === 'success') {
                        const aiResponse = data.ai_response.response || 'Sorry, I couldn\'t process your request.';

                        // Add AI response with slight delay for realism
                        setTimeout(() => {
                            addLandingMessageToChat(aiResponse + '

👤 (Anonymous Mode - Try logging in for authenticated mode)', false);
                        }, 800);

                    } else {
                        // Show error message
                        setTimeout(() => {
                            addLandingMessageToChat('I\'m experiencing technical difficulties. Please try again later.', false);
                        }, 800);
                    }

                } catch (error) {
                    console.error('Chat error:', error);

                    // Hide typing indicator
                    document.getElementById('landingTypingIndicator').style.display = 'none';

                    // Re-enable send button
                    document.getElementById('landingSendChatBtn').disabled = false;

                    // Show error message
                    setTimeout(() => {
                        addLandingMessageToChat('I\'m currently unable to connect. Please try again later.', false);
                    }, 800);
                }
            }

            function escapeHtml(text) {
                const map = {
                    '&': '&amp;',
                    '<': '&lt;',
                    '>': '&gt;',
                    '"': '&quot;',
                    "'": '&#039;'
                };
                return text.replace(/[&<>"']/g, function(m) { return map[m]; });
            }
        </script>

    </body>
    </html>
```

### Arquivo: ffuf_web.csv
```csv
|  |
|------|
|         /'___\  /'___\           /'___\        |
|        /\ \__/ /\ \__/  __  __  /\ \__/        |
|        \ \ ,__\ \ ,__\/\ \/\ \ \ \ ,__\       |
|         \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/       |
|          \ \_\   \ \_\  \ \____/  \ \_\        |
|           \/_/    \/_/   \/___/    \/_/        |
|  |
|        v2.1.0-dev |
| ________________________________________________ |
|  |
|  :: Method           : GET |
|  :: URL              : https://104.21.48.1/FUZZ |
|  :: Wordlist         : FUZZ: /tmp/common.txt |
|  :: Output file      : results/ffuf_web.csv |
|  :: File format      : csv |
|  :: Follow redirects : false |
|  :: Calibration      : false |
|  :: Timeout          : 10 |
|  :: Threads          : 40 |
|  :: Matcher          : Response status: 200,301,302 |
|  :: Filter           : Response status: 404 |
| ________________________________________________ |
|  |
:: Progress: [4750/4750] :: Job [1/1] :: 32 req/sec :: Duration: [0:01:43] :: Errors: 4750 :: |
```

root@hyprarch /h/t/S/M/Reconnaissance (main)#               