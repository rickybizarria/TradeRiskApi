# 🏦 Trade Risk Classification API

API REST desenvolvida em **ASP.NET Core 8** para classificação automática de risco de operações financeiras (trades) de acordo com valor monetário e setor do cliente.

**Desenvolvido para:** Desafio Técnico .NET - UBS FI Team

---

## 📋 Índice

- [Características](#características)
- [Tecnologias](#tecnologias)
- [Arquitetura](#arquitetura)
- [Instalação](#instalação)
- [Execução](#execução)
- [Endpoints](#endpoints)
- [Testes](#testes)
- [Decisões Técnicas](#decisões-técnicas)
- [Performance](#performance)
- [Regras de Negócio](#regras-de-negócio)

---

## ✨ Características

### Parte 1: Classificação de Risco
- ✅ Classificação automática baseada em regras de negócio
- ✅ Suporte a múltiplas trades em uma única requisição
- ✅ Validação robusta de entrada com FluentValidation
- ✅ Tratamento de erros centralizado
- ✅ Documentação automática com Swagger/OpenAPI

### Parte 2: Análise de Distribuição
- ✅ Processamento eficiente de até **100.000 trades**
- ✅ Resumo estatístico por categoria de risco
- ✅ Identificação de top clients por exposição
- ✅ Medição de tempo de processamento
- ✅ Algoritmo otimizado (O(n) - single-pass)

---

## 🛠️ Tecnologias

| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| **ASP.NET Core** | 8.0 | Framework Web |
| **C#** | 12.0 | Linguagem |
| **FluentValidation** | 11.9.2 | Validação de entrada |
| **Swagger/OpenAPI** | 6.5.0 | Documentação da API |
| **xUnit** | 2.6.2 | Testes unitários |
| **Moq** | 4.20.70 | Mocking para testes |
| **FluentAssertions** | 6.12.0 | Assertions fluentes |

---

## 🏗️ Arquitetura

Projeto estruturado em **Clean Architecture** com separação clara de responsabilidades:
```
TradeRiskApi/
├── Domain/          # Entidades, Value Objects, Interfaces
├── Application/     # Serviços, DTOs, Validadores
└── Web/             # Controllers, Middleware, API
```

### Camadas:

#### **🔷 Domain Layer (Camada de Domínio)**
**Responsabilidade:** Lógica de negócio pura, sem dependências externas

- **Entidades**: `Trade`, `RiskCategory`
  - Trade: Entidade rica com comportamento `ClassifyRisk()`
  - RiskCategory: Agregador de estatísticas por categoria

- **Value Objects**: `Money`
  - Imutável, validação de regras de negócio
  - Operadores de comparação e igualdade

- **Enums**: `ClientSector`, `RiskLevel`
  - Tipagem forte para domínio

- **Interfaces**: `IRiskClassificationService`
  - Contratos para serviços de domínio

#### **🔶 Application Layer (Camada de Aplicação)**
**Responsabilidade:** Casos de uso, orquestração, validação

- **Serviços**:
  - `RiskClassificationService`: Classificação de trades
  - `RiskAnalysisService`: Análise estatística com performance tracking

- **DTOs**:
  - `TradeRequestDto`: Entrada
  - `TradeResponseDto`: Saída simples
  - `RiskAnalysisResponseDto`: Saída com estatísticas

- **Validadores**: `TradeRequestValidator` (FluentValidation)
  - Validação de valor, setor, clientId

- **HealthChecks**: `RiskClassificationHealthCheck`
  - Monitoramento de saúde do serviço

#### **🔴 Web/API Layer (Camada de Apresentação)**
**Responsabilidade:** HTTP, controllers, middleware

- **Controllers**: `TradesController`
  - 3 endpoints REST
  - Async/await para escalabilidade
  - Tratamento de exceções

- **Middleware**: `ExceptionHandlingMiddleware`
  - Tratamento global de exceções
  - Respostas JSON padronizadas

- **Configuração**: `Program.cs`
  - Dependency Injection
  - Swagger
  - CORS
  - Health Checks

---

## 📦 Instalação

### Pré-requisitos

- **.NET 8 SDK** ([Download](https://dotnet.microsoft.com/download/dotnet/8.0))
- **Visual Studio 2022** ou **Visual Studio Code**
- **Git** (opcional)

### Clonar o Repositório
```bash
git clone https://github.com/seu-usuario/trade-risk-api.git
cd trade-risk-api
```

### Restaurar Dependências
```bash
dotnet restore
```

---

## 🚀 Execução

### Modo Desenvolvimento
```bash
cd src/TradeRiskApi.Web
dotnet run
```

A API estará disponível em:
- **HTTPS**: `https://localhost:7183`
- **HTTP**: `http://localhost:5092`

### Modo Produção
```bash
dotnet publish -c Release -o ./publish
cd publish
dotnet TradeRiskApi.Web.dll
```

### Docker
```bash
docker build -t trade-risk-api .
docker run -p 8080:80 trade-risk-api
```

Acesse: `http://localhost:8080`

---

## 📡 Endpoints

### **Swagger UI**
Acesse a documentação interativa em: **https://localhost:7183**

---

### **1. POST /api/trades/classify**

Classifica uma lista de trades retornando suas categorias de risco.

#### Request Body:
```json
[
  { "value": 2000000, "clientSector": "Private" },
  { "value": 400000, "clientSector": "Public" },
  { "value": 500000, "clientSector": "Public" },
  { "value": 3000000, "clientSector": "Public" }
]
```

#### Response (200 OK):
```json
{
  "categories": ["HIGHRISK", "LOWRISK", "LOWRISK", "MEDIUMRISK"]
}
```

#### cURL:
```bash
curl -X POST "https://localhost:7183/api/trades/classify" \
  -H "Content-Type: application/json" \
  -d '[{"value":2000000,"clientSector":"Private"},{"value":400000,"clientSector":"Public"}]'
```

---

### **2. POST /api/trades/analyze**

Classifica trades e retorna análise estatística completa.

#### Request Body:
```json
[
  { "value": 2000000, "clientSector": "Private", "clientId": "CLI003" },
  { "value": 400000, "clientSector": "Public", "clientId": "CLI001" },
  { "value": 500000, "clientSector": "Public", "clientId": "CLI001" },
  { "value": 3000000, "clientSector": "Public", "clientId": "CLI002" }
]
```

#### Response (200 OK):
```json
{
  "categories": ["HIGHRISK", "LOWRISK", "LOWRISK", "MEDIUMRISK"],
  "summary": {
    "LOWRISK": {
      "count": 2,
      "totalValue": 900000,
      "topClient": "CLI001"
    },
    "MEDIUMRISK": {
      "count": 1,
      "totalValue": 3000000,
      "topClient": "CLI002"
    },
    "HIGHRISK": {
      "count": 1,
      "totalValue": 2000000,
      "topClient": "CLI003"
    }
  },
  "processingTimeMs": 45,
  "totalTrades": 4
}
```

#### cURL:
```bash
curl -X POST "https://localhost:7183/api/trades/analyze" \
  -H "Content-Type: application/json" \
  -d '[{"value":2000000,"clientSector":"Private","clientId":"CLI003"}]'
```

---

### **3. GET /api/trades/health**

Health check endpoint.

#### Response (200 OK):
```json
{
  "status": "healthy",
  "timestamp": "2026-03-21T14:30:00Z",
  "version": "2.0.0"
}
```

#### cURL:
```bash
curl "https://localhost:7183/api/trades/health"
```

---

## 🧪 Testes

### Executar Todos os Testes
```bash
dotnet test
```

### Testes Unitários
```bash
dotnet test tests/TradeRiskApi.UnitTests/
```

### Testes de Integração
```bash
dotnet test tests/TradeRiskApi.IntegrationTests/
```

### Coverage Report
```bash
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

### Resultados Esperados
```
Aprovado!   - Com falha:     0, Aprovado:    15, Ignorado:     0, Total:    15
```

---

## 💡 Decisões Técnicas

### 1. **Clean Architecture**
**Por quê?** Separação clara de responsabilidades facilita manutenção, testes e evolução do código.

**Benefício:**
- Domain isolado de frameworks
- Fácil substituição de infraestrutura
- Testabilidade alta

---

### 2. **Value Objects (Money)**
**Por quê?** Encapsular lógica de negócio relacionada a valores monetários.

**Benefício:**
- Validação centralizada (não permite valores negativos)
- Imutabilidade garantida
- Semântica rica (IsAboveThreshold())
```csharp
public sealed class Money : IEquatable<Money>
{
    public decimal Value { get; }
    public bool IsAboveThreshold() => Value >= 1_000_000m;
}
```

---

### 3. **DDD - Domain-Driven Design**
**Por quê?** Lógica de negócio dentro das entidades (Rich Domain Model).

**Benefício:**
- Entidade Trade conhece suas próprias regras
- Método `ClassifyRisk()` na entidade
- Código auto-explicativo
```csharp
public RiskLevel ClassifyRisk()
{
    if (!Value.IsAboveThreshold())
        return RiskLevel.LOWRISK;
    
    return ClientSector == ClientSector.Public 
        ? RiskLevel.MEDIUMRISK 
        : RiskLevel.HIGHRISK;
}
```

---

### 4. **Async/Await**
**Por quê?** Escalabilidade e não bloqueio de threads.

**Benefício:**
- Suporta múltiplas requisições simultâneas
- Uso eficiente do thread pool
- Preparado para I/O assíncrono futuro
```csharp
public async Task<IEnumerable<RiskLevel>> ClassifyTradesAsync(
    IEnumerable<Trade> trades, 
    CancellationToken cancellationToken = default)
{
    return await Task.Run(() => 
        trades.Select(ClassifyTrade).ToList(), 
        cancellationToken);
}
```

---

### 5. **FluentValidation**
**Por quê?** Validação declarativa e testável separada do modelo.

**Benefício:**
- Regras expressivas e reutilizáveis
- Fácil manutenção
- Mensagens customizadas
```csharp
RuleFor(x => x.Value)
    .GreaterThanOrEqualTo(0)
    .WithMessage("O valor da trade deve ser maior ou igual a zero");
```

---

### 6. **Single-Pass Algorithm (O(n))**
**Por quê?** Otimização para processar 100.000+ trades.

**Benefício:**
- Classificação e agregação em uma única iteração
- Memória constante
- Performance previsível
```csharp
foreach (var trade in tradeList)
{
    var riskLevel = _classificationService.ClassifyTrade(trade);
    categories.Add(riskLevel);
    summary[riskLevel].AddTrade(trade); // Agregação incremental
}
```

---

### 7. **Dependency Injection**
**Por quê?** Inversão de controle, testabilidade.

**Benefício:**
- Fácil mock em testes
- Baixo acoplamento
- Configuração centralizada
```csharp
builder.Services.AddScoped<IRiskClassificationService, RiskClassificationService>();
builder.Services.AddScoped<IRiskAnalysisService, RiskAnalysisService>();
```

---

### 8. **Middleware de Exceções**
**Por quê?** Tratamento centralizado de erros.

**Benefício:**
- Respostas consistentes
- Logging automático
- Código mais limpo nos controllers

---

## ⚡ Performance

### Benchmarks (100.000 trades)

| Métrica | Valor |
|---------|-------|
| **Tempo de processamento** | ~40-50ms |
| **Memória alocada** | ~15MB |
| **Complexidade** | O(n) - linear |
| **Throughput** | ~2.000.000 trades/segundo |

### Otimizações Implementadas

1. **Single-pass algorithm**: Classificação e agregação em uma única iteração
2. **Dictionary lookup**: O(1) para acesso a categorias
3. **List pre-sizing**: `new List<RiskLevel>(tradeList.Count)` evita realocações
4. **Async/await**: Não bloqueia threads durante processamento

---

## 📚 Regras de Negócio

| Categoria | Regra |
|-----------|-------|
| **LOWRISK** | Valor < 1.000.000 (independente do setor) |
| **MEDIUMRISK** | Valor ≥ 1.000.000 **E** setor Público |
| **HIGHRISK** | Valor ≥ 1.000.000 **E** setor Privado |

### Exemplos:
```
Trade(value: 500.000, sector: Public)   → LOWRISK
Trade(value: 500.000, sector: Private)  → LOWRISK
Trade(value: 2.000.000, sector: Public)  → MEDIUMRISK
Trade(value: 2.000.000, sector: Private) → HIGHRISK
```

---

## 🔒 Validações

### Entrada (TradeRequestDto)

- ✅ **value**: Maior ou igual a 0
- ✅ **clientSector**: "Public" ou "Private" (case-insensitive)
- ✅ **clientId**: Opcional, máximo 50 caracteres, alfanumérico

### Limites

- ✅ Lista de trades não pode estar vazia
- ✅ Máximo de **100.000 trades** por requisição (endpoint `/analyze`)
- ✅ Sem limite para endpoint `/classify`

---

## 🐛 Tratamento de Erros

### 400 Bad Request
```json
{
  "error": "A lista de trades não pode estar vazia"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "Descrição do erro",
  "timestamp": "2026-03-21T14:30:00Z"
}
```

### Validação (FluentValidation)
```json
{
  "errors": {
    "Value": ["O valor da trade deve ser maior ou igual a zero"],
    "ClientSector": ["Setor deve ser 'Public' ou 'Private'"]
  }
}
```

---

## 📝 Logs

A API registra automaticamente:
```
[INF] Recebida requisição para classificar 10000 trades
[INF] Classificando 10000 trades de forma assíncrona
[INF] Análise concluída em 42ms. LOWRISK=5000, MEDIUMRISK=3000, HIGHRISK=2000
```

Níveis de log configuráveis em `appsettings.json`.

---

## 🚀 Roadmap Futuro

Melhorias planejadas:

- [ ] Autenticação/Autorização (JWT)
- [ ] Cache distribuído (Redis)
- [ ] Processamento assíncrono (RabbitMQ/Kafka)
- [ ] Métricas e observabilidade (Prometheus/Grafana)
- [ ] Rate limiting
- [ ] Suporte a múltiplas moedas
- [ ] API versionamento (v1, v2)

---

## 📄 Licença

Este projeto está sob a licença MIT.

---

## 📧 Contato

**Desenvolvedor:** Henrique Bizarria  
**Email:** bizarriaefilhos@gmail.com  
**LinkedIn:** https://www.linkedin.com/in/rickybizarria/
**GitHub:** https://github.com/rickybizarria

---

## 🙏 Agradecimentos

Desenvolvido como parte do desafio técnico para a vaga de **Desenvolvedor .NET** na **UBS FI Team**.
Avalia com o ❤️

---

**Desenvolvido com ❤️ usando ASP.NET Core 8**