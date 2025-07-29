import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card.jsx'
import { Button } from '@/components/ui/button.jsx'
import { Badge } from '@/components/ui/badge.jsx'
import { Input } from '@/components/ui/input.jsx'
import { Textarea } from '@/components/ui/textarea.jsx'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select.jsx'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs.jsx'
import { 
  FileText, 
  Download, 
  Plus, 
  Activity, 
  AlertTriangle, 
  CheckCircle,
  Clock,
  Target,
  BarChart3
} from 'lucide-react'

const ReportsPage = () => {
  const [reports, setReports] = useState([])
  const [dashboardStats, setDashboardStats] = useState(null)
  const [loading, setLoading] = useState(false)
  const [newReport, setNewReport] = useState({
    type: '',
    target: '',
    description: ''
  })

  useEffect(() => {
    fetchReports()
    fetchDashboardStats()
  }, [])

  const fetchReports = async () => {
    try {
      const response = await fetch('http://localhost:5001/api/reports/list')
      const data = await response.json()
      if (data.success) {
        setReports(data.reports)
      }
    } catch (error) {
      console.error('Error fetching reports:', error)
    }
  }

  const fetchDashboardStats = async () => {
    try {
      const response = await fetch('http://localhost:5001/api/dashboard/stats')
      const data = await response.json()
      if (data.success) {
        setDashboardStats(data.stats)
      }
    } catch (error) {
      console.error('Error fetching dashboard stats:', error)
    }
  }

  const generateReport = async () => {
    if (!newReport.type || !newReport.target) {
      alert('Por favor, preencha o tipo e o alvo do relatório')
      return
    }

    setLoading(true)
    try {
      const response = await fetch('http://localhost:5001/api/reports/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(newReport)
      })
      
      const data = await response.json()
      if (data.success) {
        alert('Relatório gerado com sucesso!')
        fetchReports()
        setNewReport({ type: '', target: '', description: '' })
      }
    } catch (error) {
      console.error('Error generating report:', error)
      alert('Erro ao gerar relatório')
    } finally {
      setLoading(false)
    }
  }

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString('pt-BR')
  }

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'high': return 'destructive'
      case 'medium': return 'default'
      case 'low': return 'secondary'
      default: return 'outline'
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Relatórios</h1>
        <Badge variant="outline" className="flex items-center gap-2">
          <Activity className="w-4 h-4" />
          Dashboard Ativo
        </Badge>
      </div>

      <Tabs defaultValue="dashboard" className="space-y-6">
        <TabsList>
          <TabsTrigger value="dashboard">Dashboard</TabsTrigger>
          <TabsTrigger value="reports">Relatórios</TabsTrigger>
          <TabsTrigger value="generate">Gerar Relatório</TabsTrigger>
          <TabsTrigger value="editor">Editor Markdown</TabsTrigger>
        </TabsList>

        <TabsContent value="dashboard" className="space-y-6">
          {dashboardStats && (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total de Scans</CardTitle>
                    <Target className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{dashboardStats.total_scans}</div>
                    <p className="text-xs text-muted-foreground">
                      {dashboardStats.active_scans} ativos
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total de Achados</CardTitle>
                    <BarChart3 className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{dashboardStats.total_findings}</div>
                    <p className="text-xs text-muted-foreground">
                      Últimas 24 horas
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Alta Severidade</CardTitle>
                    <AlertTriangle className="h-4 w-4 text-destructive" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold text-destructive">{dashboardStats.high_severity}</div>
                    <p className="text-xs text-muted-foreground">
                      Requer atenção imediata
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Scans Completos</CardTitle>
                    <CheckCircle className="h-4 w-4 text-green-600" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold text-green-600">{dashboardStats.completed_scans}</div>
                    <p className="text-xs text-muted-foreground">
                      Taxa de sucesso: 95%
                    </p>
                  </CardContent>
                </Card>
              </div>

              <Card>
                <CardHeader>
                  <CardTitle>Atividade Recente</CardTitle>
                  <CardDescription>Últimas atividades do sistema</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {dashboardStats.recent_activity.map((activity, index) => (
                      <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                        <div className="flex items-center gap-3">
                          <Clock className="w-4 h-4 text-muted-foreground" />
                          <div>
                            <p className="font-medium">
                              {activity.type === 'scan_completed' ? 'Scan Completo' : 'Relatório Gerado'}
                            </p>
                            <p className="text-sm text-muted-foreground">
                              Alvo: {activity.target}
                            </p>
                          </div>
                        </div>
                        <div className="text-right">
                          <Badge variant="outline">{activity.findings} achados</Badge>
                          <p className="text-xs text-muted-foreground mt-1">
                            {formatDate(activity.timestamp)}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </>
          )}
        </TabsContent>

        <TabsContent value="reports" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Relatórios Gerados</CardTitle>
              <CardDescription>Lista de todos os relatórios de segurança</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {reports.map((report) => (
                  <div key={report.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-3">
                      <FileText className="w-5 h-5 text-muted-foreground" />
                      <div>
                        <p className="font-medium">{report.id}</p>
                        <p className="text-sm text-muted-foreground">
                          {report.type} - {report.target}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {formatDate(report.timestamp)}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={report.status === 'completed' ? 'default' : 'secondary'}>
                        {report.status}
                      </Badge>
                      <Badge variant="outline">
                        {report.findings_count} achados
                      </Badge>
                      <Button size="sm" variant="outline">
                        <Download className="w-4 h-4 mr-2" />
                        Download
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="generate" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Gerar Novo Relatório</CardTitle>
              <CardDescription>Crie um relatório de segurança personalizado</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Tipo de Relatório</label>
                  <Select value={newReport.type} onValueChange={(value) => setNewReport({...newReport, type: value})}>
                    <SelectTrigger>
                      <SelectValue placeholder="Selecione o tipo" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="network_scan">Scan de Rede</SelectItem>
                      <SelectItem value="vulnerability_scan">Scan de Vulnerabilidades</SelectItem>
                      <SelectItem value="penetration_test">Teste de Penetração</SelectItem>
                      <SelectItem value="compliance_audit">Auditoria de Compliance</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">Alvo</label>
                  <Input
                    placeholder="IP, domínio ou range de rede"
                    value={newReport.target}
                    onChange={(e) => setNewReport({...newReport, target: e.target.value})}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Descrição (Opcional)</label>
                <Textarea
                  placeholder="Descrição adicional do relatório..."
                  value={newReport.description}
                  onChange={(e) => setNewReport({...newReport, description: e.target.value})}
                />
              </div>

              <Button onClick={generateReport} disabled={loading} className="w-full">
                <Plus className="w-4 h-4 mr-2" />
                {loading ? 'Gerando...' : 'Gerar Relatório'}
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="editor" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Editor Markdown</CardTitle>
              <CardDescription>Edite e visualize conteúdo em Markdown</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 h-96">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Editor</label>
                  <Textarea
                    className="h-full resize-none font-mono"
                    placeholder="# Título do Relatório

## Resumo Executivo

Este relatório apresenta os resultados da análise de segurança...

## Metodologia

- Reconhecimento
- Enumeração
- Exploração
- Pós-exploração

## Achados

### Vulnerabilidade Crítica
- **Severidade**: Alta
- **Descrição**: ...
- **Impacto**: ...
- **Recomendação**: ...

## Conclusão

..."
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Visualização</label>
                  <div className="h-full p-4 border rounded-md bg-muted/50 overflow-auto">
                    <p className="text-sm text-muted-foreground">
                      A visualização do Markdown apareceria aqui...
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

export default ReportsPage

