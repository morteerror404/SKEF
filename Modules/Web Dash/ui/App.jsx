import { useState } from 'react'
import { Button } from '@/components/ui/button.jsx'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card.jsx'
import { Badge } from '@/components/ui/badge.jsx'
import { 
  Shield, 
  Search, 
  FileText, 
  Target, 
  TestTube, 
  Zap, 
  Settings, 
  Menu,
  X,
  Home,
  Activity
} from 'lucide-react'
import ReportsPage from '../components/ReportsPage.jsx'
import ReconPage from './components/ReconPage.jsx'
import TestingPage from './components/TestingPage.jsx'
import ExploitationPage from '../components/ExploitationPage.jsx'
import PayloadPage from './components/PayloadPage.jsx'
import SettingsPage from './components/SettingsPage.jsx'
import './App.css'

function App() {
  const [activeSection, setActiveSection] = useState('dashboard')
  const [sidebarOpen, setSidebarOpen] = useState(true)

  const menuItems = [
    { id: 'dashboard', label: 'Dashboard', icon: Home },
    { id: 'recon', label: 'Recon / OSINT', icon: Search },
    { id: 'reports', label: 'Relatórios', icon: FileText },
    { id: 'testing', label: 'Testes e Validação', icon: TestTube },
    { id: 'exploitation', label: 'Exploração', icon: Target },
    { id: 'payload', label: 'Envio de Payload', icon: Zap },
    { id: 'settings', label: 'Configurações', icon: Settings },
  ]

  const renderContent = () => {
    switch (activeSection) {
      case 'dashboard':
        return (
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <h1 className="text-3xl font-bold">Dashboard</h1>
              <Badge variant="outline" className="flex items-center gap-2">
                <Activity className="w-4 h-4" />
                Sistema Ativo
              </Badge>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Search className="w-5 h-5" />
                    Reconhecimento
                  </CardTitle>
                  <CardDescription>
                    Ferramentas de OSINT e reconhecimento automatizado
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Button 
                    onClick={() => setActiveSection('recon')}
                    className="w-full"
                  >
                    Acessar Recon
                  </Button>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <FileText className="w-5 h-5" />
                    Relatórios
                  </CardTitle>
                  <CardDescription>
                    Geração de relatórios e dashboards em tempo real
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Button 
                    onClick={() => setActiveSection('reports')}
                    className="w-full"
                  >
                    Ver Relatórios
                  </Button>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <TestTube className="w-5 h-5" />
                    Testes
                  </CardTitle>
                  <CardDescription>
                    Validação e testes de segurança automatizados
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Button 
                    onClick={() => setActiveSection('testing')}
                    className="w-full"
                  >
                    Executar Testes
                  </Button>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Target className="w-5 h-5" />
                    Exploração
                  </CardTitle>
                  <CardDescription>
                    Ferramentas de exploração e análise de vulnerabilidades
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Button 
                    onClick={() => setActiveSection('exploitation')}
                    className="w-full"
                  >
                    Explorar
                  </Button>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Zap className="w-5 h-5" />
                    Payloads
                  </CardTitle>
                  <CardDescription>
                    Geração e envio de payloads personalizados
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Button 
                    onClick={() => setActiveSection('payload')}
                    className="w-full"
                  >
                    Gerenciar Payloads
                  </Button>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Settings className="w-5 h-5" />
                    Configurações
                  </CardTitle>
                  <CardDescription>
                    Personalização e configuração do sistema
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Button 
                    onClick={() => setActiveSection('settings')}
                    className="w-full"
                  >
                    Configurar
                  </Button>
                </CardContent>
              </Card>
            </div>
          </div>
        )
      case 'recon':
        return <ReconPage />
      case 'reports':
        return <ReportsPage />
      case 'testing':
        return <TestingPage />
      case 'exploitation':
        return <ExploitationPage />
      case 'payloads':
        return <PayloadPage />
      case 'settings':
        return <SettingsPage />
      default:
        return <div>Seção não encontrada</div>
    }
  }

  return (
    <div className="flex h-screen bg-background">
      {/* Sidebar */}
      <div className={`${sidebarOpen ? 'w-64' : 'w-16'} transition-all duration-300 bg-sidebar border-r border-sidebar-border`}>
        <div className="flex items-center justify-between p-4 border-b border-sidebar-border">
          {sidebarOpen && (
            <div className="flex items-center gap-2">
              <Shield className="w-6 h-6 text-sidebar-primary" />
              <span className="font-bold text-sidebar-foreground">Security Toolkit</span>
            </div>
          )}
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="text-sidebar-foreground hover:bg-sidebar-accent"
          >
            {sidebarOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
          </Button>
        </div>
        
        <nav className="p-2">
          {menuItems.map((item) => {
            const Icon = item.icon
            return (
              <Button
                key={item.id}
                variant={activeSection === item.id ? "default" : "ghost"}
                className={`w-full justify-start mb-1 ${
                  sidebarOpen ? 'px-3' : 'px-2'
                } ${
                  activeSection === item.id 
                    ? 'bg-sidebar-primary text-sidebar-primary-foreground' 
                    : 'text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground'
                }`}
                onClick={() => setActiveSection(item.id)}
              >
                <Icon className={`w-4 h-4 ${sidebarOpen ? 'mr-2' : ''}`} />
                {sidebarOpen && item.label}
              </Button>
            )
          })}
        </nav>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        <div className="p-6">
          {renderContent()}
        </div>
      </div>
    </div>
  )
}

export default App

