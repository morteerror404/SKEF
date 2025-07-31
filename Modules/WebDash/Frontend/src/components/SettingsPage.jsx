import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card.jsx'
import { Button } from '@/components/ui/button.jsx'
import { Input } from '@/components/ui/input.jsx'
import { Textarea } from '@/components/ui/textarea.jsx'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select.jsx'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs.jsx'
import { Badge } from '@/components/ui/badge.jsx'
import { Switch } from '@/components/ui/switch.jsx'
import { 
  Settings, 
  Palette, 
  Monitor, 
  Globe, 
  Tool, 
  FileText,
  Download,
  Upload,
  Save,
  RotateCcw,
  Plus,
  Trash2,
  Edit,
  ExternalLink,
  Folder,
  Database
} from 'lucide-react'

const SettingsPage = () => {
  const [theme, setTheme] = useState('dark')
  const [background, setBackground] = useState('default')
  const [customTools, setCustomTools] = useState([])
  const [referenceUrls, setReferenceUrls] = useState([])
  const [projectSettings, setProjectSettings] = useState({
    name: 'Security Toolkit Project',
    description: 'Projeto de ferramentas de segurança',
    author: 'Security Team',
    version: '1.0.0'
  })

  useEffect(() => {
    loadSettings()
  }, [])

  const loadSettings = () => {
    // Carregar configurações salvas
    const savedSettings = localStorage.getItem('security-toolkit-settings')
    if (savedSettings) {
      const settings = JSON.parse(savedSettings)
      setTheme(settings.theme || 'dark')
      setBackground(settings.background || 'default')
      setCustomTools(settings.customTools || [])
      setReferenceUrls(settings.referenceUrls || [])
      setProjectSettings(settings.projectSettings || projectSettings)
    }
  }

  const saveSettings = () => {
    const settings = {
      theme,
      background,
      customTools,
      referenceUrls,
      projectSettings
    }
    localStorage.setItem('security-toolkit-settings', JSON.stringify(settings))
    alert('Configurações salvas com sucesso!')
  }

  const addCustomTool = () => {
    const newTool = {
      id: Date.now(),
      name: 'Nova Ferramenta',
      command: '',
      description: '',
      category: 'custom'
    }
    setCustomTools([...customTools, newTool])
  }

  const updateCustomTool = (id, field, value) => {
    setCustomTools(customTools.map(tool => 
      tool.id === id ? { ...tool, [field]: value } : tool
    ))
  }

  const removeCustomTool = (id) => {
    setCustomTools(customTools.filter(tool => tool.id !== id))
  }

  const addReferenceUrl = () => {
    const newUrl = {
      id: Date.now(),
      name: 'Nova Referência',
      url: '',
      category: 'general'
    }
    setReferenceUrls([...referenceUrls, newUrl])
  }

  const updateReferenceUrl = (id, field, value) => {
    setReferenceUrls(referenceUrls.map(ref => 
      ref.id === id ? { ...ref, [field]: value } : ref
    ))
  }

  const removeReferenceUrl = (id) => {
    setReferenceUrls(referenceUrls.filter(ref => ref.id !== id))
  }

  const exportSettings = () => {
    const settings = {
      theme,
      background,
      customTools,
      referenceUrls,
      projectSettings,
      exportDate: new Date().toISOString()
    }
    
    const blob = new Blob([JSON.stringify(settings, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `security-toolkit-config-${new Date().toISOString().split('T')[0]}.json`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  const importSettings = (event) => {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        try {
          const settings = JSON.parse(e.target.result)
          setTheme(settings.theme || 'dark')
          setBackground(settings.background || 'default')
          setCustomTools(settings.customTools || [])
          setReferenceUrls(settings.referenceUrls || [])
          setProjectSettings(settings.projectSettings || projectSettings)
          alert('Configurações importadas com sucesso!')
        } catch (error) {
          alert('Erro ao importar configurações: ' + error.message)
        }
      }
      reader.readAsText(file)
    }
  }

  const resetSettings = () => {
    if (confirm('Tem certeza que deseja resetar todas as configurações?')) {
      setTheme('dark')
      setBackground('default')
      setCustomTools([])
      setReferenceUrls([])
      setProjectSettings({
        name: 'Security Toolkit Project',
        description: 'Projeto de ferramentas de segurança',
        author: 'Security Team',
        version: '1.0.0'
      })
      localStorage.removeItem('security-toolkit-settings')
      alert('Configurações resetadas!')
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold">Configurações</h1>
        <Badge variant="outline" className="flex items-center gap-2">
          <Settings className="w-4 h-4" />
          Personalização
        </Badge>
      </div>

      <Tabs defaultValue="appearance" className="space-y-6">
        <TabsList>
          <TabsTrigger value="appearance">Aparência</TabsTrigger>
          <TabsTrigger value="tools">Ferramentas</TabsTrigger>
          <TabsTrigger value="references">Referências</TabsTrigger>
          <TabsTrigger value="project">Projeto</TabsTrigger>
          <TabsTrigger value="backup">Backup</TabsTrigger>
        </TabsList>

        <TabsContent value="appearance" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Tema</CardTitle>
                <CardDescription>Personalize a aparência da aplicação</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Esquema de Cores</label>
                  <Select value={theme} onValueChange={setTheme}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="light">Claro</SelectItem>
                      <SelectItem value="dark">Escuro</SelectItem>
                      <SelectItem value="green">Verde (Hacker)</SelectItem>
                      <SelectItem value="blue">Azul (Profissional)</SelectItem>
                      <SelectItem value="red">Vermelho (Alerta)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="grid grid-cols-3 gap-2">
                  {[
                    { name: 'Claro', value: 'light', bg: 'bg-white', text: 'text-black' },
                    { name: 'Escuro', value: 'dark', bg: 'bg-gray-900', text: 'text-white' },
                    { name: 'Verde', value: 'green', bg: 'bg-green-900', text: 'text-green-100' }
                  ].map((themeOption) => (
                    <div
                      key={themeOption.value}
                      className={`p-3 rounded border cursor-pointer ${
                        theme === themeOption.value ? 'ring-2 ring-blue-500' : ''
                      } ${themeOption.bg} ${themeOption.text}`}
                      onClick={() => setTheme(themeOption.value)}
                    >
                      <div className="text-xs font-medium">{themeOption.name}</div>
                      <div className="text-xs opacity-70">Aa</div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Fundo</CardTitle>
                <CardDescription>Personalize o fundo da aplicação</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Tipo de Fundo</label>
                  <Select value={background} onValueChange={setBackground}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="default">Padrão</SelectItem>
                      <SelectItem value="gradient">Gradiente</SelectItem>
                      <SelectItem value="pattern">Padrão</SelectItem>
                      <SelectItem value="matrix">Matrix</SelectItem>
                      <SelectItem value="custom">Personalizado</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {background === 'custom' && (
                  <div className="space-y-2">
                    <label className="text-sm font-medium">URL da Imagem</label>
                    <Input placeholder="https://example.com/background.jpg" />
                  </div>
                )}

                <div className="space-y-2">
                  <label className="text-sm font-medium">Opacidade</label>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    defaultValue="80"
                    className="w-full"
                  />
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Layout</CardTitle>
              <CardDescription>Configurações de layout e navegação</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <label className="text-sm font-medium">Menu Lateral Compacto</label>
                    <Switch />
                  </div>
                  <div className="flex items-center justify-between">
                    <label className="text-sm font-medium">Menu Superior</label>
                    <Switch />
                  </div>
                  <div className="flex items-center justify-between">
                    <label className="text-sm font-medium">Breadcrumbs</label>
                    <Switch defaultChecked />
                  </div>
                </div>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <label className="text-sm font-medium">Animações</label>
                    <Switch defaultChecked />
                  </div>
                  <div className="flex items-center justify-between">
                    <label className="text-sm font-medium">Sons</label>
                    <Switch />
                  </div>
                  <div className="flex items-center justify-between">
                    <label className="text-sm font-medium">Notificações</label>
                    <Switch defaultChecked />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="tools" className="space-y-6">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Ferramentas Personalizadas</CardTitle>
                  <CardDescription>Adicione suas próprias ferramentas e comandos</CardDescription>
                </div>
                <Button onClick={addCustomTool}>
                  <Plus className="w-4 h-4 mr-2" />
                  Adicionar Ferramenta
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {customTools.length === 0 ? (
                <p className="text-muted-foreground text-center py-8">
                  Nenhuma ferramenta personalizada adicionada
                </p>
              ) : (
                <div className="space-y-4">
                  {customTools.map((tool) => (
                    <div key={tool.id} className="border rounded-lg p-4">
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <label className="text-sm font-medium">Nome da Ferramenta</label>
                          <Input
                            value={tool.name}
                            onChange={(e) => updateCustomTool(tool.id, 'name', e.target.value)}
                            placeholder="Nome da ferramenta"
                          />
                        </div>
                        <div className="space-y-2">
                          <label className="text-sm font-medium">Categoria</label>
                          <Select
                            value={tool.category}
                            onValueChange={(value) => updateCustomTool(tool.id, 'category', value)}
                          >
                            <SelectTrigger>
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="recon">Reconhecimento</SelectItem>
                              <SelectItem value="scan">Scanning</SelectItem>
                              <SelectItem value="exploit">Exploração</SelectItem>
                              <SelectItem value="post">Pós-exploração</SelectItem>
                              <SelectItem value="custom">Personalizada</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>
                      </div>

                      <div className="space-y-2 mt-4">
                        <label className="text-sm font-medium">Comando</label>
                        <Input
                          value={tool.command}
                          onChange={(e) => updateCustomTool(tool.id, 'command', e.target.value)}
                          placeholder="nmap -sV -T4 {target}"
                        />
                      </div>

                      <div className="space-y-2 mt-4">
                        <label className="text-sm font-medium">Descrição</label>
                        <Textarea
                          value={tool.description}
                          onChange={(e) => updateCustomTool(tool.id, 'description', e.target.value)}
                          placeholder="Descrição da ferramenta..."
                          rows={2}
                        />
                      </div>

                      <div className="flex justify-end mt-4">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => removeCustomTool(tool.id)}
                          className="text-red-600 hover:text-red-700"
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Remover
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="references" className="space-y-6">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Sites de Referência</CardTitle>
                  <CardDescription>Adicione links úteis para consulta rápida</CardDescription>
                </div>
                <Button onClick={addReferenceUrl}>
                  <Plus className="w-4 h-4 mr-2" />
                  Adicionar Referência
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {referenceUrls.length === 0 ? (
                <p className="text-muted-foreground text-center py-8">
                  Nenhuma referência adicionada
                </p>
              ) : (
                <div className="space-y-4">
                  {referenceUrls.map((ref) => (
                    <div key={ref.id} className="border rounded-lg p-4">
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div className="space-y-2">
                          <label className="text-sm font-medium">Nome</label>
                          <Input
                            value={ref.name}
                            onChange={(e) => updateReferenceUrl(ref.id, 'name', e.target.value)}
                            placeholder="Nome da referência"
                          />
                        </div>
                        <div className="space-y-2">
                          <label className="text-sm font-medium">URL</label>
                          <Input
                            value={ref.url}
                            onChange={(e) => updateReferenceUrl(ref.id, 'url', e.target.value)}
                            placeholder="https://example.com"
                          />
                        </div>
                        <div className="space-y-2">
                          <label className="text-sm font-medium">Categoria</label>
                          <Select
                            value={ref.category}
                            onValueChange={(value) => updateReferenceUrl(ref.id, 'category', value)}
                          >
                            <SelectTrigger>
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="general">Geral</SelectItem>
                              <SelectItem value="exploits">Exploits</SelectItem>
                              <SelectItem value="tools">Ferramentas</SelectItem>
                              <SelectItem value="learning">Aprendizado</SelectItem>
                              <SelectItem value="news">Notícias</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>
                      </div>

                      <div className="flex justify-between mt-4">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => window.open(ref.url, '_blank')}
                          disabled={!ref.url}
                        >
                          <ExternalLink className="w-4 h-4 mr-2" />
                          Abrir
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => removeReferenceUrl(ref.id)}
                          className="text-red-600 hover:text-red-700"
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Remover
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="project" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Configurações do Projeto</CardTitle>
              <CardDescription>Gerencie informações do projeto atual</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Nome do Projeto</label>
                  <Input
                    value={projectSettings.name}
                    onChange={(e) => setProjectSettings({...projectSettings, name: e.target.value})}
                    placeholder="Nome do projeto"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Versão</label>
                  <Input
                    value={projectSettings.version}
                    onChange={(e) => setProjectSettings({...projectSettings, version: e.target.value})}
                    placeholder="1.0.0"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Autor</label>
                <Input
                  value={projectSettings.author}
                  onChange={(e) => setProjectSettings({...projectSettings, author: e.target.value})}
                  placeholder="Nome do autor"
                />
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Descrição</label>
                <Textarea
                  value={projectSettings.description}
                  onChange={(e) => setProjectSettings({...projectSettings, description: e.target.value})}
                  placeholder="Descrição do projeto..."
                  rows={3}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg">Estatísticas do Projeto</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-sm">Ferramentas Configuradas:</span>
                      <span className="text-sm font-medium">{customTools.length}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm">Referências Salvas:</span>
                      <span className="text-sm font-medium">{referenceUrls.length}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm">Tema Atual:</span>
                      <span className="text-sm font-medium capitalize">{theme}</span>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg">Ações Rápidas</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-2">
                    <Button variant="outline" className="w-full justify-start">
                      <Folder className="w-4 h-4 mr-2" />
                      Criar Novo Projeto
                    </Button>
                    <Button variant="outline" className="w-full justify-start">
                      <Database className="w-4 h-4 mr-2" />
                      Limpar Cache
                    </Button>
                    <Button variant="outline" className="w-full justify-start">
                      <Monitor className="w-4 h-4 mr-2" />
                      Verificar Sistema
                    </Button>
                  </CardContent>
                </Card>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="backup" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Backup e Restauração</CardTitle>
              <CardDescription>Exporte e importe suas configurações</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg">Exportar Configurações</CardTitle>
                    <CardDescription>Salve suas configurações em um arquivo</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <Button onClick={exportSettings} className="w-full">
                      <Download className="w-4 h-4 mr-2" />
                      Exportar Template
                    </Button>
                    <p className="text-xs text-muted-foreground">
                      Inclui: tema, ferramentas personalizadas, referências e configurações do projeto
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg">Importar Configurações</CardTitle>
                    <CardDescription>Restaure configurações de um arquivo</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div>
                      <input
                        type="file"
                        accept=".json"
                        onChange={importSettings}
                        className="hidden"
                        id="import-settings"
                      />
                      <Button asChild className="w-full">
                        <label htmlFor="import-settings" className="cursor-pointer">
                          <Upload className="w-4 h-4 mr-2" />
                          Importar Template
                        </label>
                      </Button>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      Selecione um arquivo JSON de configurações exportado anteriormente
                    </p>
                  </CardContent>
                </Card>
              </div>

              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Ações de Sistema</CardTitle>
                  <CardDescription>Operações de manutenção e reset</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex gap-4">
                    <Button onClick={saveSettings} className="flex-1">
                      <Save className="w-4 h-4 mr-2" />
                      Salvar Configurações
                    </Button>
                    <Button onClick={resetSettings} variant="outline" className="flex-1">
                      <RotateCcw className="w-4 h-4 mr-2" />
                      Resetar Tudo
                    </Button>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Salve suas alterações ou reset para as configurações padrão
                  </p>
                </CardContent>
              </Card>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

export default SettingsPage

