const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const app = express();

// Configuração de CORS
app.use(cors({ origin: 'http://localhost:5173' }));
app.use(express.json());

// Validação de entradas para evitar injeção de comandos
const validScanTypes = ['-sV', '-sS', '-A', '-sn', '-p-'];
const sanitizeInput = (input) => {
  // Remove caracteres perigosos (exemplo simples)
  return input.replace(/[;&|`$]/g, '');
};

app.get('/api/dashboard', (req, res) => {
  res.json({ status: "API funcionando", timestamp: new Date() });
});

// Endpoint para payloads salvos (exemplo)
app.get('/api/exploitation/saved-payloads', (req, res) => {
  res.json({ success: true, payloads: [] });
});

// Endpoint para executar Nmap
app.post('/api/tools/nmap', (req, res) => {
  const { target, scan_type } = req.body;
  if (!target || !scan_type) {
    return res.status(400).json({ success: false, error: 'Target e scan_type são obrigatórios' });
  }
  if (!validScanTypes.includes(scan_type)) {
    return res.status(400).json({ success: false, error: 'Tipo de scan inválido' });
  }
  const sanitizedTarget = sanitizeInput(target);
  exec(`nmap ${scan_type} ${sanitizedTarget}`, (error, stdout, stderr) => {
    if (error) {
      return res.status(500).json({ success: false, error: stderr });
    }
    res.json({ success: true, output: stdout });
  });
});

// Endpoint para WHOIS
app.post('/api/tools/whois', (req, res) => {
  const { domain } = req.body;
  if (!domain) {
    return res.status(400).json({ success: false, error: 'Domínio é obrigatório' });
  }
  const sanitizedDomain = sanitizeInput(domain);
  exec(`whois ${sanitizedDomain}`, (error, stdout, stderr) => {
    if (error) {
      return res.status(500).json({ success: false, error: stderr });
    }
    res.json({ success: true, output: stdout });
  });
});

// Endpoint para DIG
app.post('/api/tools/dig', (req, res) => {
  const { domain } = req.body;
  if (!domain) {
    return res.status(400).json({ success: false, error: 'Domínio é obrigatório' });
  }
  const sanitizedDomain = sanitizeInput(domain);
  exec(`dig ${sanitizedDomain} A`, (error, stdout, stderr) => {
    if (error) {
      return res.status(500).json({ success: false, error: stderr });
    }
    res.json({ success: true, output: stdout });
  });
});

// Endpoints adicionais para outras funcionalidades
app.post('/api/exploitation/search-dorks', (req, res) => {
  const { query, type } = req.body;
  res.json({ success: true, dork_queries: [`inurl:${query} ${type}`] });
});

app.post('/api/exploitation/cve-search', (req, res) => {
  const { cve_id } = req.body;
  res.json({ success: true, results: { cve_id, details: 'Exemplo de resultado' } });
});

app.post('/api/exploitation/saved-payloads', (req, res) => {
  const { name, payload, category, os } = req.body;
  res.json({ success: true, payload: { name, payload, category, os } });
});

app.get('/api/reports/list', (req, res) => {
  res.json({ success: true, reports: [] });
});

app.get('/api/dashboard/stats', (req, res) => {
  res.json({
    success: true,
    stats: {
      total_scans: 10,
      active_scans: 2,
      total_findings: 25,
      high_severity: 5,
      completed_scans: 8,
      recent_activity: []
    }
  });
});

app.post('/api/reports/generate', (req, res) => {
  const { type, target, description } = req.body;
  res.json({ success: true, report: { type, target, description } });
});

app.get('/api/auto-recon/list', (req, res) => {
  res.json({ success: true, scans: [] });
});

app.post('/api/auto-recon/start', (req, res) => {
  const { target } = req.body;
  res.json({ success: true, scan: { target, scan_id: Date.now() } });
});

app.get('/api/auto-recon/status/:scanId', (req, res) => {
  const { scanId } = req.params;
  res.json({
    success: true,
    results: {
      scan_id: scanId,
      target: 'example.com',
      status: 'running',
      summary: { open_ports: 3, services_found: 2, vulnerabilities: 1 },
      phases: {
        host_discovery: { status: 'completed', results: [] },
        port_scan: { status: 'running', results: [] }
      }
    }
  });
});

app.listen(5001, () => console.log('Backend rodando na porta 5001'));