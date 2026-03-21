# 🏗️ Arquitetura - Trade Risk Classification API

## Visão Geral

Este documento descreve as decisões arquiteturais, padrões de design e estrutura do projeto Trade Risk Classification API.

---

## 📐 Arquitetura em Camadas (Clean Architecture)
```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│        (TradeRiskApi.Web)               │
│  Controllers, Middleware, Program.cs    │
└─────────────┬───────────────────────────┘
              │ HTTP/REST
              ↓
┌─────────────────────────────────────────┐
│        Application Layer                │
│      (TradeRiskApi.Application)         │
│   Services, DTOs, Validators, UseCases  │
└─────────────┬───────────────────────────┘
              │ Interfaces
              ↓
┌─────────────────────────────────────────┐
│          Domain Layer                   │
│        (TradeRiskApi.Domain)            │
│  Entities, ValueObjects, Enums, Rules   │
└─────────────────────────────────────────┘
```

### Princípios Aplicados

1. **Dependency Rule**: Dependências apontam para dentro (Domain não conhece Application/Web)
2. **Separation of Concerns**: Cada camada tem responsabilidade única
3. **Dependency Inversion**: Abstrações (interfaces) no Domain, implementações na Application
4. **Single Responsibility**: Classes e métodos com propósito único

---

## 🎯 Domain Layer (Núcleo do Negócio)

### Estrutura
```
TradeRiskApi.Domain/
├── Entities/
│   ├── Trade.cs              # Entidade rica com comportamento
│   └── RiskCategory.cs       # Agregador de estatísticas
├── ValueObjects/
│   └── Money.cs              # Valor monetário imutável
├── Enums/
│   ├── ClientSector.cs       # Public/Private
│   └── RiskLevel.cs          # LOWRISK/MEDIUMRISK/HIGHRISK
└── Interfaces/
    └── IRiskClassificationService.cs
```

### Padrões de Design

#### **1. Rich Domain Model (DDD)**

A lógica de negócio está **dentro** das entidades, não em serviços anêmicos.
```csharp
// ✅ BOM - Lógica na entidade
public sealed class Trade
{
    public RiskLevel ClassifyRisk()
    {
        if (!Value.IsAboveThreshold())
            return RiskLevel.LOWRISK;
        
        return ClientSector == ClientSector.Public 
            ? RiskLevel.MEDIUMRISK 
            : RiskLevel.HIGHRISK;
    }
}

// ❌ RUIM - Entidade anêmica
public class Trade
{
    public decimal Value { get; set; }
    public string Sector { get; set; }
    // Sem comportamento
}
```

#### **2. Value Objects**

Conceitos do domínio que são **imutáveis** e **comparáveis por valor**.
```csharp
public sealed class Money : IEquatable<Money>
{
    private const decimal HIGH_RISK_THRESHOLD = 1_000_000m;
    
    public decimal Value { get; } // Imutável
    
    public Money(decimal value)
    {
        if (value < 0)
            throw new ArgumentException("Valor não pode ser negativo");
        Value = value;
    }
    
    public bool IsAboveThreshold() => Value >= HIGH_RISK_THRESHOLD;
}
```

**Por que Value Object?**
- ✅ Validação centralizada
- ✅ Regras de negócio encapsuladas
- ✅ Imutabilidade garante consistência
- ✅ Semântica rica (`IsAboveThreshold()`)

#### **3. Aggregates (Agregadores)**

`RiskCategory` agrega informações de múltiplas `Trades`.
```csharp
public sealed class RiskCategory
{
    public RiskLevel Level { get; }
    public int Count { get; private set; }
    public decimal TotalValue { get; private set; }
    
    private readonly Dictionary<string, decimal> _clientExposure = new();
    
    public void AddTrade(Trade trade)
    {
        Count++;
        TotalValue += trade.Value.Value;
        // Atualiza exposição por cliente
    }
}
```

**Responsabilidades:**
- ✅ Manter consistência interna
- ✅ Aplicar regras de agregação
- ✅ Proteger invariantes

---

## 🔧 Application Layer (Casos de Uso)

### Estrutura
```
TradeRiskApi.Application/
├── DTOs/
│   ├── TradeRequestDto.cs        # Input
│   ├── TradeResponseDto.cs       # Output simples
│   └── RiskSummaryDto.cs         # Output com estatísticas
├── Services/
│   ├── RiskClassificationService.cs
│   └── RiskAnalysisService.cs
├── Validators/
│   └── TradeRequestValidator.cs  # FluentValidation
└── HealthChecks/
    └── RiskClassificationHealthCheck.cs
```

### Padrões de Design

#### **1. DTO Pattern (Data Transfer Object)**

Separação entre modelos de domínio e modelos de API.
```csharp
// DTO - Para transporte HTTP
public sealed class TradeRequestDto
{
    public decimal Value { get; set; }
    public string ClientSector { get; set; }
    public string? ClientId { get; set; }
}

// Entidade de Domínio
public sealed class Trade
{
    public Money Value { get; }
    public ClientSector ClientSector { get; }
    // Comportamento rico
}
```

**Por que DTOs?**
- ✅ Protege o domínio de mudanças na API
- ✅ Controle fino sobre serialização
- ✅ Validação separada (FluentValidation)

#### **2. Service Layer**

Orquestração de casos de uso.
```csharp
public sealed class RiskAnalysisService : IRiskAnalysisService
{
    public async Task<(IEnumerable<RiskLevel>, Dictionary<RiskLevel, RiskCategory>, long)> 
        AnalyzeTradesAsync(IEnumerable<Trade> trades, CancellationToken ct)
    {
        var stopwatch = Stopwatch.StartNew();
        
        // Orquestração
        var summary = InitializeSummary();
        var categories = new List<RiskLevel>();
        
        await Task.Run(() =>
        {
            foreach (var trade in trades)
            {
                var risk = _classifier.ClassifyTrade(trade);
                categories.Add(risk);
                summary[risk].AddTrade(trade);
            }
        }, ct);
        
        stopwatch.Stop();
        return (categories, summary, stopwatch.ElapsedMilliseconds);
    }
}
```

**Responsabilidades:**
- ✅ Coordenar entidades de domínio
- ✅ Medir performance
- ✅ Logging
- ✅ Transações (se necessário)

#### **3. Validator Pattern (FluentValidation)**

Validação declarativa e testável.
```csharp
public sealed class TradeRequestValidator : AbstractValidator<TradeRequestDto>
{
    public TradeRequestValidator()
    {
        RuleFor(x => x.Value)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Valor deve ser >= 0");
        
        RuleFor(x => x.ClientSector)
            .Must(s => s == "Public" || s == "Private")
            .WithMessage("Setor inválido");
    }
}
```

---

## 🌐 Web Layer (Apresentação)

### Estrutura
```
TradeRiskApi.Web/
├── Controllers/
│   └── TradesController.cs
├── Middleware/
│   └── ExceptionHandlingMiddleware.cs
└── Program.cs
```

### Padrões de Design

#### **1. RESTful API**
```
POST   /api/trades/classify    # Classificar trades
POST   /api/trades/analyze     # Análise estatística
GET    /api/trades/health      # Health check
GET    /health                 # Health checks detalhados
```

**Convenções:**
- ✅ Verbos HTTP corretos (POST para comandos)
- ✅ Nomes de recursos no plural
- ✅ Códigos de status apropriados (200, 400, 500)

#### **2. Middleware Pipeline**
```csharp
app.UseMiddleware<ExceptionHandlingMiddleware>();  // 1º - Captura exceções
app.UseHttpsRedirection();                         // 2º - Redireciona HTTP→HTTPS
app.UseCors("AllowAll");                          // 3º - CORS
app.UseAuthorization();                           // 4º - Autorização
app.MapControllers();                             // 5º - Roteamento
app.MapHealthChecks("/health");                   // 6º - Health checks
```

**Por que Middleware?**
- ✅ Lógica transversal (cross-cutting concerns)
- ✅ Execução em ordem
- ✅ Código reutilizável

#### **3. Dependency Injection**
```csharp
builder.Services.AddScoped<IRiskClassificationService, RiskClassificationService>();
builder.Services.AddScoped<IRiskAnalysisService, RiskAnalysisService>();
builder.Services.AddHealthChecks()
    .AddCheck<RiskClassificationHealthCheck>("risk-classification");
```

**Lifetime Scopes:**
- `Scoped`: Uma instância por requisição HTTP
- `Singleton`: Uma instância para toda aplicação
- `Transient`: Nova instância a cada injeção

---

## ⚡ Performance e Otimizações

### 1. **Single-Pass Algorithm**

Classificação e agregação em **O(n)** - uma única passada.
```csharp
// ❌ RUIM - Duas passadas O(2n)
var categories = trades.Select(ClassifyTrade).ToList();
foreach (var trade in trades)
    summary[ClassifyTrade(trade)].AddTrade(trade);

// ✅ BOM - Uma passada O(n)
foreach (var trade in trades)
{
    var risk = ClassifyTrade(trade);
    categories.Add(risk);
    summary[risk].AddTrade(trade);
}
```

### 2. **List Pre-sizing**

Evita realocações de memória.
```csharp
// ✅ Pre-aloca capacidade
var categories = new List<RiskLevel>(tradeList.Count);
```

### 3. **Dictionary para Lookup O(1)**
```csharp
var summary = new Dictionary<RiskLevel, RiskCategory>
{
    [RiskLevel.LOWRISK] = new RiskCategory(RiskLevel.LOWRISK),
    [RiskLevel.MEDIUMRISK] = new RiskCategory(RiskLevel.MEDIUMRISK),
    [RiskLevel.HIGHRISK] = new RiskCategory(RiskLevel.HIGHRISK)
};
```

### 4. **Async/Await para CPU-Bound**
```csharp
return await Task.Run(() =>
{
    // Processamento CPU-intensive
    return tradeList.Select(ClassifyTrade).ToList();
}, cancellationToken);
```

**Por que Task.Run?**
- ✅ Não bloqueia thread pool ASP.NET
- ✅ Permite cancelamento
- ✅ Escalabilidade

---

## 🧪 Testabilidade

### Arquitetura facilita testes por:

1. **Dependency Injection**
```csharp
// Fácil de mockar
var mockService = new Mock<IRiskClassificationService>();
var sut = new RiskAnalysisService(mockService.Object, logger);
```

2. **Interfaces**
```csharp
public interface IRiskClassificationService
{
    RiskLevel ClassifyTrade(Trade trade);
}
```

3. **Entidades Puras (sem dependências)**
```csharp
// Teste direto, sem mocks
var trade = new Trade(500000, ClientSector.Public);
var result = trade.ClassifyRisk();
Assert.Equal(RiskLevel.LOWRISK, result);
```

---

## 🔐 Segurança

### Implementado:

1. **HTTPS Redirection**
```csharp
app.UseHttpsRedirection();
```

2. **CORS Configurado**
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
```

3. **Validação de Entrada**
```csharp
[Required]
[Range(0, double.MaxValue)]
public decimal Value { get; set; }
```

### Próximos Passos:

- [ ] JWT Authentication
- [ ] Rate Limiting
- [ ] Input Sanitization
- [ ] API Key Management

---

## 📊 Diagramas

### Fluxo de Requisição
```
┌──────────┐
│  Client  │
└────┬─────┘
     │ POST /api/trades/classify
     ↓
┌─────────────────────────────┐
│   TradesController          │
│   - Recebe TradeRequestDto  │
│   - Valida (FluentValid)    │
└────┬────────────────────────┘
     │ MapToDomain(dto)
     ↓
┌─────────────────────────────┐
│  RiskClassificationService  │
│  - ClassifyTradesAsync()    │
└────┬────────────────────────┘
     │ ClassifyTrade(trade)
     ↓
┌─────────────────────────────┐
│      Trade (Entity)         │
│  - ClassifyRisk()           │
└────┬────────────────────────┘
     │ return RiskLevel
     ↓
┌─────────────────────────────┐
│     TradeResponseDto        │
│  - categories: string[]     │
└─────────────────────────────┘
```

### Estrutura de Pastas
```
TradeRiskApi/
├── src/
│   ├── TradeRiskApi.Domain/
│   │   ├── Entities/
│   │   ├── ValueObjects/
│   │   ├── Enums/
│   │   └── Interfaces/
│   ├── TradeRiskApi.Application/
│   │   ├── DTOs/
│   │   ├── Services/
│   │   ├── Validators/
│   │   └── HealthChecks/
│   └── TradeRiskApi.Web/
│       ├── Controllers/
│       ├── Middleware/
│       └── Program.cs
├── tests/
│   ├── TradeRiskApi.UnitTests/
│   └── TradeRiskApi.IntegrationTests/
└── docs/
    ├── README.md
    └── ARCHITECTURE.md
```

---

## 🚀 Evolução e Escalabilidade

### Preparado para:

1. **Microserviços**
   - Domain e Application podem ser extraídos
   - Comunicação via mensageria (RabbitMQ/Kafka)

2. **CQRS (Command Query Responsibility Segregation)**
   - Separar comandos (POST) de queries (GET)
   - Otimizar cada lado independentemente

3. **Event Sourcing**
   - Armazenar eventos de classificação
   - Auditoria completa

4. **Cache Distribuído**
   - Redis para resultados frequentes
   - Invalidação inteligente

---

## 📚 Referências

- **Clean Architecture** - Robert C. Martin
- **Domain-Driven Design** - Eric Evans
- **Implementing Domain-Driven Design** - Vaughn Vernon
- **ASP.NET Core Documentation** - Microsoft
- **FluentValidation** - Jeremy Skinner

---

**Última atualização:** 21/03/2026  
**Versão:** 2.0