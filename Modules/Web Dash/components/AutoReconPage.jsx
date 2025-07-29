import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card.jsx'
import { Button } from '@/components/ui/button.jsx'
import { Input } from '@/components/ui/input.jsx'
import { Badge } from '@/components/ui/badge.jsx'
import { Progress } from '@/components/ui/progress.jsx'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs.jsx'
import { 
  Play, 
  Pause, 
  RefreshCw, 
  CheckCircle, 
  AlertCircle,
  Clock,
  Target,
  Search,
  Shield,
  Network,
  Eye
} from 'lucide-react'

const AutoReconPage = () => {
  const [target, setTarget] = useState('')
  const [activeScans, setActiveScans] = useState([])
  const [selectedScan, setSelectedScan] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    fetchActiveScans()
    const interval = setInterval(fetchActiveScans, 5000) // Update every 5 seconds
    return () => clearInterval(interval)
  }, [])

  const fetchActiveScans = async () => {
    try {
      const response = await fetch('http://localhost:5001/api/auto-recon/list')
      const data = await response.json()
      if (data.success) {
        setActiveScans(data.scans)
      }
    } catch (error) {
      console.error('Error fetching scans:', error)
    }
  }

  const startAutoRecon = async () => {
    if (!target) {
      alert('Por favor, insira um alvo')
      return
    }

    setLoading(true)
    try {
      const response = await fetch('http://localhost:5001/api/auto-recon/start', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ target })
      })

      const data = await response.json()
      if (data.success) {
        alert('Auto Recon iniciado com sucesso!')
        setTarget('')
        fetchActiveScans()
      } else {
        alert('Erro ao iniciar Auto Recon: ' + data.error)
      }
    } catch (error) {
      alert('Erro de conexão: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  const fetchScanDetails = async (scanId) => {
    try {
      const response = await fetch(`http://localhost:5001/api/auto-recon/status/${scanId}`)
      const data = await response.json()
      if (data.success) {
        setSelectedScan(data.results)
      }
    } catch (error) {
      console.error('Error fetching scan details:', error)
    }
  }

  const getPhaseStatus = (phase) => {
    switch (phase.status) {
      case 'completed': return { icon: CheckCircle, color: 'text-green-600', bg: 'bg-green-100' }
      case 'running': return { icon: RefreshCw, color: 'text-blue-600', bg: 'bg-blue-100' }
      case 'failed': return { icon: AlertCircle, color: 'text-red-600', bg: 'bg-red-100' }
      default: return { icon: Clock, color: 'text-gray-600', bg: 'bg-gray-100' }
    }
  }

  const calculateProgress = (phases) => {
    const totalPhases = Object.keys(phases).length
    const completedPhases = Object.values(phases).filter(p => p.status === 'completed').length
    return (completedPhases / totalPhases) * 100
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Auto Reconnaissance</h1>
        <Badge variant="outline" className="flex items-center gap-2">
          <Target className="w-4 h-4" />
          Reconhecimento Automatizado
        </Badge>
      </div>

      <Tabs defaultValue="scanner" className="space-y-6">
        <TabsList>
          <TabsTrigger value="scanner">Scanner</TabsTrigger>
          <TabsTrigger value="active">Scans Ativos</TabsTrigger>
          <TabsTrigger value="details">Detalhes</TabsTrigger>
        </TabsList>

        <TabsContent value="scanner" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Iniciar Auto Reconnaissance</CardTitle>
              <CardDescription>
                Execute um reconhecimento automatizado completo do alvo
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-4">
                <Input
                  placeholder="IP ou domínio (ex: 192.168.1.1, example.com)"
                  value={target}
                  onChange={(e) => setTarget(e.target.value)}
                  className="flex-1"
                />
                <Button onClick={startAutoRecon} disabled={loading}>
                  <Play className="w-4 h-4 mr-2" />
                  {loading ? 'Iniciando...' : 'Iniciar Scan'}
                </Button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mt-6">
                {[
                  { name: 'Host Discovery', icon: Search, desc: 'Descoberta de hosts ativos' },
                  { name: 'Port Scan', icon: Network, desc: 'Varredura de portas' },
                  { name: 'Service Detection', icon: Eye, desc: 'Detecção de serviços' },
                  { name: 'OS Detection', icon: Shield, desc: 'Identificação do SO' },
                  { name: 'Vulnerability Scan', icon: AlertCircle, desc: 'Busca por vulnerabilidades' }
                ].map((phase, index) => (
                  <Card key={index} className="text-center">
                    <CardContent className="pt-6">
                      <phase.icon className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
                      <h3 className="font-medium text-sm">{phase.name}</h3>
                      <p className="text-xs text-muted-foreground mt-1">{phase.desc}</p>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="active" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Scans Ativos</CardTitle>
              <CardDescription>Acompanhe o progresso dos scans em execução</CardDescription>
            </CardHeader>
            <CardContent>
              {activeScans.length === 0 ? (
                <p className="text-muted-foreground text-center py-8">
                  Nenhum scan ativo no momento
                </p>
              ) : (
                <div className="space-y-4">
                  {activeScans.map((scan) => (
                    <div key={scan.scan_id} className="border rounded-lg p-4">
                      <div className="flex items-center justify-between mb-3">
                        <div>
                          <h3 className="font-medium">{scan.target}</h3>
                          <p className="text-sm text-muted-foreground">
                            ID: {scan.scan_id}
                          </p>
                        </div>
                        <div className="flex items-center gap-2">
                          <Badge variant={scan.status === 'completed' ? 'default' : 'secondary'}>
                            {scan.status}
                          </Badge>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => fetchScanDetails(scan.scan_id)}
                          >
                            Ver Detalhes
                          </Button>
                        </div>
                      </div>

                      <div className="grid grid-cols-3 gap-4 text-sm">
                        <div>
                          <p className="text-muted-foreground">Portas Abertas</p>
                          <p className="font-medium">{scan.summary.open_ports}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Serviços</p>
                          <p className="font-medium">{scan.summary.services_found}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Vulnerabilidades</p>
                          <p className="font-medium">{scan.summary.vulnerabilities}</p>
                        </div>
                      </div>

                      <div className="mt-3">
                        <p className="text-xs text-muted-foreground mb-1">
                          Iniciado em: {new Date(scan.start_time).toLocaleString('pt-BR')}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="details" className="space-y-6">
          {selectedScan ? (
            <>
              <Card>
                <CardHeader>
                  <CardTitle>Detalhes do Scan: {selectedScan.target}</CardTitle>
                  <CardDescription>
                    Status: {selectedScan.status} | ID: {selectedScan.scan_id}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium">Progresso Geral</span>
                        <span className="text-sm text-muted-foreground">
                          {Math.round(calculateProgress(selectedScan.phases))}%
                        </span>
                      </div>
                      <Progress value={calculateProgress(selectedScan.phases)} />
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="text-center p-3 border rounded">
                        <p className="text-2xl font-bold text-blue-600">{selectedScan.summary.open_ports}</p>
                        <p className="text-sm text-muted-foreground">Portas Abertas</p>
                      </div>
                      <div className="text-center p-3 border rounded">
                        <p className="text-2xl font-bold text-green-600">{selectedScan.summary.services_found}</p>
                        <p className="text-sm text-muted-foreground">Serviços</p>
                      </div>
                      <div className="text-center p-3 border rounded">
                        <p className="text-2xl font-bold text-red-600">{selectedScan.summary.vulnerabilities}</p>
                        <p className="text-sm text-muted-foreground">Vulnerabilidades</p>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Fases do Reconhecimento</CardTitle>
                  <CardDescription>Progresso detalhado de cada fase</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {Object.entries(selectedScan.phases).map(([phaseName, phase]) => {
                      const statusInfo = getPhaseStatus(phase)
                      const StatusIcon = statusInfo.icon
                      
                      return (
                        <div key={phaseName} className="flex items-center gap-4 p-3 border rounded-lg">
                          <div className={`p-2 rounded-full ${statusInfo.bg}`}>
                            <StatusIcon className={`w-4 h-4 ${statusInfo.color}`} />
                          </div>
                          <div className="flex-1">
                            <h3 className="font-medium capitalize">
                              {phaseName.replace('_', ' ')}
                            </h3>
                            <p className="text-sm text-muted-foreground">
                              Status: {phase.status} | Resultados: {phase.results?.length || 0}
                            </p>
                          </div>
                          <Badge variant={phase.status === 'completed' ? 'default' : 'secondary'}>
                            {phase.status}
                          </Badge>
                        </div>
                      )
                    })}
                  </div>
                </CardContent>
              </Card>
            </>
          ) : (
            <Card>
              <CardContent className="text-center py-8">
                <p className="text-muted-foreground">
                  Selecione um scan na aba "Scans Ativos" para ver os detalhes
                </p>
              </CardContent>
            </Card>
          )}
        </TabsContent>
      </Tabs>
    </div>
  )
}

export default AutoReconPage

