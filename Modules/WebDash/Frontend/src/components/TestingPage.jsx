import React from 'react';
import { Card, Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui';
import { Button } from '@/components/ui/button';
import { Copy } from 'lucide-react';

function TestingPage() {
  // Dados de exemplo para as categorias de teste
  const testCategories = [
    {
      name: "Testes de Injeção",
      tests: [
        { name: "SQL Injection", command: "test-sql-injection" },
        { name: "XSS", command: "test-xss" }
      ]
    },
    {
      name: "Testes de Autenticação",
      tests: [
        { name: "Brute Force", command: "test-brute-force" },
        { name: "Quebra de Senha", command: "test-password-crack" }
      ]
    }
  ];

  return (
    <div className="space-y-4">
      <Tabs defaultValue="tests">
        <TabsList>
          <TabsTrigger value="tests">Testes Automatizados</TabsTrigger>
          <TabsTrigger value="manual">Testes Manuais</TabsTrigger>
        </TabsList>
        
        <TabsContent value="tests">
          <Card>
            <CardContent className="pt-6">
              <div className="space-y-6">
                {testCategories.map((category) => (
                  <div key={category.name} className="space-y-2">
                    <h3 className="font-medium">{category.name}</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                      {category.tests.map((test) => (
                        <div key={test.command} className="flex items-center justify-between p-3 border rounded-lg">
                          <span>{test.name}</span>
                          <Button variant="ghost" size="sm">
                            <Copy className="w-3 h-3" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

export default TestingPage;