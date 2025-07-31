import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card.jsx'
import { Button } from '@/components/ui/button.jsx'
import { Input } from '@/components/ui/input.jsx'
import { Textarea } from '@/components/ui/textarea.jsx'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select.jsx'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs.jsx'
import { Badge } from '@/components/ui/badge.jsx'
import { 
  Search, 
  Target, 
  Globe, 
  Shield, 
  Terminal,
  Play,
  Download,
  Eye,
  Network,
  Database,
  FileText,
  Zap
} from 'lucide-react'
import AutoReconPage from './AutoReconPage.jsx'

const ReconPage = () => {
  const [scanTarget, setScanTarget] = useState('')
  const [scanType, setScanType] = useState('')
  const [scanResults, setScanResults] = useState('')
  const [loading, setLoading] = useState(false)
  const [markdownContent, setMarkdownContent] = useState(`# Relatório de Reconhecimento

## Alvo: [TARGET]

### Informações Básicas
- **Data**: ${new Date().toLocaleDateString('pt-BR')}
- **Tipo de Scan**: [SCAN_TYPE]
- **Status**: Em andamento

### Metodologia
1. Reconhecimento passivo
2. Enumeração de serviços
3. Análise de vulnerabilidades
4. Documentação dos achados

### Resultados

#### Portas Abertas
- [ ] Porta 22 (SSH)
- [ ] Porta 80 (HTTP)
- [ ] Porta 443 (HTTPS)

#### Serviços Identificados
- [ ] Servidor Web
- [ ] Banco de Dados
- [ ] Serviços de Email

### Observações
[Adicione suas observações aqui]

### Próximos Passos
- [ ] Análise detalhada dos serviços
- [ ] Teste de vulnerabilidades
- [ ] Documentação final
`)

  const runNmapScan = async () => {
    if (!scanTarget || !scanType) {
      alert('Por favor, preencha o alvo e o tipo de scan')
      return
    }

    setLoading(true)
    setScanResults('Iniciando scan...\n')

    try {
      const response = await fetch('http://localhost:5001/api/tools/nmap', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          target: scanTarget,
          scan_type: scanType
        })
      })

      const data = await response.json()
      if (data.success) {
        setScanResults(data.output || data.error || 'Scan concluído')
      } else {
        setScanResults(`Erro: ${data.error}`)
      }
    } catch (error) {
      setScanResults(`Erro de conexão: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  const runWhoisLookup = async () => {
    if (!scanTarget) {
      alert('Por favor, preencha o domínio')
      return
    }

    setLoading(true)
    setScanResults('Executando WHOIS lookup...\n')

    try {
      const response = await fetch('http://localhost:5001/api/tools/whois', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          domain: scanTarget
        })
      })

      const data = await response.json()
      if (data.success) {
        setScanResults(data.output || 'WHOIS lookup concluído')
      } else {
        setScanResults(`Erro: ${data.error}`)
      }
    } catch (error) {
      setScanResults(`Erro de conexão: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  const runDnsLookup = async () => {
    if (!scanTarget) {
      alert('Por favor, preencha o domínio')
      return
    }

    setLoading(true)
    setScanResults('Executando DNS lookup...\n')

    try {
      const response = await fetch('http://localhost:5001/api/tools/dig', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          domain: scanTarget,
          record_type: 'A'
        })
      })

      const data = await response.json()
      if (data.success) {
        setScanResults(data.output || 'DNS lookup concluído')
      } else {
        setScanResults(`Erro: ${data.error}`)
      }
    } catch (error) {
      setScanResults(`Erro de conexão: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  const toolCategories = [
    {
      title: 'Reconhecimento Passivo',
      tools: [
        { name: 'WHOIS Lookup', description: 'Informações de registro do domínio', action: runWhoisLookup },
        { name: 'DNS Lookup', description: 'Resolução de nomes DNS', action: runDnsLookup },
        { name: 'Shodan Search', description: 'Busca em bancos de dados públicos', disabled: true },
        { name: 'Google Dorking', description: 'Busca avançada no Google', disabled: true }
      ]
    },
    {
      title: 'Reconhecimento Ativo',
      tools: [
        { name: 'NMAP Scan', description: 'Scan de portas e serviços', action: runNmapScan },
        { name: 'Ping Sweep', description: 'Descoberta de hosts ativos', disabled: true },
        { name: 'Service Detection', description: 'Detecção de versões de serviços', disabled: true },
        { name: 'OS Fingerprinting', description: 'Identificação do sistema operacional', disabled: true }
      ]
    },
    {
      title: 'Análise Web',
      tools: [
        { name: 'Dirb/Gobuster', description: 'Descoberta de diretórios', disabled: true },
        { name: 'Nikto', description: 'Scanner de vulnerabilidades web', disabled: true },
        { name: 'Whatweb', description: 'Identificação de tecnologias web', disabled: true },
        { name: 'SSL Analysis', description: 'Análise de certificados SSL', disabled: true }
      ]
    }
  ]

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Reconhecimento / OSINT</h1>
        <Badge variant="outline" className="flex items-center gap-2">
          <Search className="w-4 h-4" />
          Ferramentas Ativas
        </Badge>
      </div>

      <Tabs defaultValue="auto-recon" className="space-y-6">
        <TabsList>
          <TabsTrigger value="auto-recon">Auto Recon</TabsTrigger>
          <TabsTrigger value="tools">Ferramentas</TabsTrigger>
          <TabsTrigger value="scanner">Scanner</TabsTrigger>
          <TabsTrigger value="results">Resultados</TabsTrigger>
          <TabsTrigger value="notes">Anotações</TabsTrigger>
        </TabsList>

        <TabsContent value="auto-recon">
          <AutoReconPage />
        </TabsContent>

        <TabsContent value="tools" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {toolCategories.map((category, categoryIndex) => (
              <Card key={categoryIndex}>
                <CardHeader>
                  <CardTitle className="text-lg">{category.title}</CardTitle>
                  <CardDescription>
                    Ferramentas para {category.title.toLowerCase()}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  {category.tools.map((tool, toolIndex) => (
                    <div key={toolIndex} className="flex items-center justify-between p-3 border rounded-lg">
                      <div>
                        <p className="font-medium">{tool.name}</p>
                        <p className="text-sm text-muted-foreground">{tool.description}</p>
                      </div>
                      <Button 
                        size="sm" 
                        disabled={tool.disabled || loading}
                        onClick={tool.action}
                      >
                        <Play className="w-4 h-4" />
                      </Button>
                    </div>
                  ))}
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="scanner" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Configuração do Scan</CardTitle>
                <CardDescription>Configure os parâmetros para o reconhecimento</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Alvo</label>
                  <Input
                    placeholder="IP, domínio ou range (ex: 192.168.1.1, example.com)"
                    value={scanTarget}
                    onChange={(e) => setScanTarget(e.target.value)}
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">Tipo de Scan</label>
                  <Select value={scanType} onValueChange={setScanType}>
                    <SelectTrigger>
                      <SelectValue placeholder="Selecione o tipo de scan" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="basic">Básico (-sV)</SelectItem>
                      <SelectItem value="stealth">Stealth (-sS)</SelectItem>
                      <SelectItem value="aggressive">Agressivo (-A)</SelectItem>
                      <SelectItem value="ping_sweep">Ping Sweep (-sn)</SelectItem>
                      <SelectItem value="port_scan">Scan de Portas (-p-)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="flex gap-2">
                  <Button onClick={runNmapScan} disabled={loading} className="flex-1">
                    <Terminal className="w-4 h-4 mr-2" />
                    {loading ? 'Executando...' : 'Executar NMAP'}
                  </Button>
                  <Button onClick={runWhoisLookup} disabled={loading} variant="outline">
                    <Globe className="w-4 h-4 mr-2" />
                    WHOIS
                  </Button>
                  <Button onClick={runDnsLookup} disabled={loading} variant="outline">
                    <Network className="w-4 h-4 mr-2" />
                    DNS
                  </Button>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Ferramentas Instaladas</CardTitle>
                <CardDescription>Status das ferramentas de reconhecimento</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {[
                    { name: 'NMAP', status: 'installed', description: 'Network Mapper' },
                    { name: 'WHOIS', status: 'installed', description: 'Domain information lookup' },
                    { name: 'DIG', status: 'installed', description: 'DNS lookup utility' },
                    { name: 'Nikto', status: 'not_installed', description: 'Web vulnerability scanner' },
                    { name: 'Dirb', status: 'not_installed', description: 'Directory brute forcer' },
                    { name: 'Gobuster', status: 'not_installed', description: 'Directory/file brute forcer' }
                  ].map((tool, index) => (
                    <div key={index} className="flex items-center justify-between p-2 border rounded">
                      <div>
                        <p className="font-medium">{tool.name}</p>
                        <p className="text-xs text-muted-foreground">{tool.description}</p>
                      </div>
                      <Badge variant={tool.status === 'installed' ? 'default' : 'secondary'}>
                        {tool.status === 'installed' ? 'Instalado' : 'Não Instalado'}
                      </Badge>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="results" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Resultados do Scan</CardTitle>
              <CardDescription>Output das ferramentas de reconhecimento</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex gap-2">
                  <Button size="sm" variant="outline">
                    <Download className="w-4 h-4 mr-2" />
                    Exportar
                  </Button>
                  <Button size="sm" variant="outline">
                    <Eye className="w-4 h-4 mr-2" />
                    Visualizar
                  </Button>
                </div>
                <Textarea
                  className="h-96 font-mono text-sm"
                  value={scanResults}
                  readOnly
                  placeholder="Os resultados dos scans aparecerão aqui..."
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notes" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Anotações em Markdown</CardTitle>
              <CardDescription>Documente seus achados e observações</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 h-96">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Editor</label>
                  <Textarea
                    className="h-full resize-none font-mono text-sm"
                    value={markdownContent}
                    onChange={(e) => setMarkdownContent(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Visualização</label>
                  <div className="h-full p-4 border rounded-md bg-muted/50 overflow-auto">
                    <div className="prose prose-sm max-w-none">
                      <p className="text-sm text-muted-foreground">
                        Visualização do Markdown apareceria aqui...
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="flex gap-2 mt-4">
                <Button size="sm">
                  <FileText className="w-4 h-4 mr-2" />
                  Salvar Anotações
                </Button>
                <Button size="sm" variant="outline">
                  <Download className="w-4 h-4 mr-2" />
                  Exportar MD
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

export default ReconPage

