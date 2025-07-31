from flask import Blueprint, jsonify, request
from flask_cors import cross_origin
import subprocess
import json
import os
from datetime import datetime

security_tools_bp = Blueprint('security_tools', __name__)

@security_tools_bp.route('/tools/nmap', methods=['POST'])
@cross_origin()
def run_nmap():
    """Execute NMAP scan"""
    try:
        data = request.get_json()
        target = data.get('target', '')
        scan_type = data.get('scan_type', 'basic')
        
        if not target:
            return jsonify({'error': 'Target is required'}), 400
        
        # Basic NMAP commands based on scan type
        nmap_commands = {
            'basic': f'nmap -sV {target}',
            'stealth': f'nmap -sS {target}',
            'aggressive': f'nmap -A {target}',
            'ping_sweep': f'nmap -sn {target}',
            'port_scan': f'nmap -p- {target}'
        }
        
        command = nmap_commands.get(scan_type, nmap_commands['basic'])
        
        # Execute NMAP command
        result = subprocess.run(command.split(), capture_output=True, text=True, timeout=300)
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr,
            'command': command,
            'timestamp': datetime.now().isoformat()
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Scan timeout after 5 minutes'}), 408
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@security_tools_bp.route('/tools/whois', methods=['POST'])
@cross_origin()
def run_whois():
    """Execute WHOIS lookup"""
    try:
        data = request.get_json()
        domain = data.get('domain', '')
        
        if not domain:
            return jsonify({'error': 'Domain is required'}), 400
        
        result = subprocess.run(['whois', domain], capture_output=True, text=True, timeout=30)
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr,
            'domain': domain,
            'timestamp': datetime.now().isoformat()
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'WHOIS lookup timeout'}), 408
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@security_tools_bp.route('/tools/dig', methods=['POST'])
@cross_origin()
def run_dig():
    """Execute DNS lookup with dig"""
    try:
        data = request.get_json()
        domain = data.get('domain', '')
        record_type = data.get('record_type', 'A')
        
        if not domain:
            return jsonify({'error': 'Domain is required'}), 400
        
        result = subprocess.run(['dig', domain, record_type], capture_output=True, text=True, timeout=30)
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr,
            'domain': domain,
            'record_type': record_type,
            'timestamp': datetime.now().isoformat()
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'DNS lookup timeout'}), 408
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@security_tools_bp.route('/reports/generate', methods=['POST'])
@cross_origin()
def generate_report():
    """Generate security report"""
    try:
        data = request.get_json()
        report_type = data.get('type', 'basic')
        target = data.get('target', '')
        
        # Create a basic report structure
        report = {
            'id': f"report_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            'type': report_type,
            'target': target,
            'timestamp': datetime.now().isoformat(),
            'status': 'completed',
            'findings': [
                {
                    'category': 'Network Scan',
                    'severity': 'info',
                    'description': f'Target {target} scanned successfully',
                    'details': 'Basic network reconnaissance completed'
                }
            ],
            'summary': {
                'total_findings': 1,
                'high_severity': 0,
                'medium_severity': 0,
                'low_severity': 1
            }
        }
        
        return jsonify({
            'success': True,
            'report': report
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@security_tools_bp.route('/reports/list', methods=['GET'])
@cross_origin()
def list_reports():
    """List all generated reports"""
    try:
        # Mock data for demonstration
        reports = [
            {
                'id': 'report_20250721_001',
                'type': 'network_scan',
                'target': '192.168.1.1',
                'timestamp': '2025-07-21T20:00:00',
                'status': 'completed',
                'findings_count': 5
            },
            {
                'id': 'report_20250721_002',
                'type': 'vulnerability_scan',
                'target': 'example.com',
                'timestamp': '2025-07-21T21:00:00',
                'status': 'completed',
                'findings_count': 3
            }
        ]
        
        return jsonify({
            'success': True,
            'reports': reports
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@security_tools_bp.route('/dashboard/stats', methods=['GET'])
@cross_origin()
def get_dashboard_stats():
    """Get dashboard statistics"""
    try:
        stats = {
            'total_scans': 15,
            'active_scans': 2,
            'completed_scans': 13,
            'total_findings': 47,
            'high_severity': 8,
            'medium_severity': 15,
            'low_severity': 24,
            'recent_activity': [
                {
                    'type': 'scan_completed',
                    'target': 'example.com',
                    'timestamp': '2025-07-21T22:30:00',
                    'findings': 3
                },
                {
                    'type': 'report_generated',
                    'target': '192.168.1.0/24',
                    'timestamp': '2025-07-21T22:15:00',
                    'findings': 7
                }
            ]
        }
        
        return jsonify({
            'success': True,
            'stats': stats
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

