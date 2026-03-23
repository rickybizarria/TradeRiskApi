# 🤝 Guia de Contribuição - Trade Risk Classification API

Obrigado por considerar contribuir para o projeto Trade Risk Classification API!

---

## 📋 Código de Conduta

Este projeto segue um Código de Conduta. Ao participar, você concorda em manter um ambiente respeitoso e acolhedor.

---

## 🚀 Como Contribuir

### 1. Fork e Clone
```bash
# Fork o repositório via GitHub UI

# Clone seu fork
git clone https://github.com/SEU-USUARIO/trade-risk-api.git
cd trade-risk-api

# Adicione o repositório original como upstream
git remote add upstream https://github.com/ORIGINAL-USUARIO/trade-risk-api.git
```

### 2. Criar Branch
```bash
# Atualize sua branch main
git checkout main
git pull upstream main

# Crie uma nova branch
git checkout -b feature/sua-funcionalidade
# ou
git checkout -b bugfix/correcao-do-bug
```

### 3. Fazer Mudanças

- Escreva código seguindo os padrões do projeto
- Adicione testes para novas funcionalidades
- Atualize documentação se necessário
- Mantenha commits atômicos e bem descritivos

### 4. Commit

Seguimos o padrão **Conventional Commits**:
```bash
git commit -m "feat: adiciona validação customizada para trades"
git commit -m "fix: corrige cálculo de risco para valores zerados"
git commit -m "docs: atualiza README com exemplos de uso"
git commit -m "test: adiciona testes para RiskCategory"
```

**Tipos de commit:**
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Documentação
- `test`: Testes
- `refactor`: Refatoração
- `perf`: Melhoria de performance
- `chore`: Tarefas de manutenção

### 5. Push e Pull Request
```bash
# Push para seu fork
git push origin feature/sua-funcionalidade

# Crie Pull Request via GitHub UI
```

---

## 📝 Padrões de Código

### C# Style Guide

Seguimos as convenções do C#:
```csharp
// ✅ BOM - PascalCase para classes e métodos
public sealed class TradeClassifier
{
    public RiskLevel ClassifyTrade(Trade trade) { }
}

// ✅ BOM - camelCase para variáveis locais
var tradeList = new List<Trade>();

// ✅ BOM - _camelCase para campos privados
private readonly ILogger _logger;

// ❌ RUIM - snake_case
public class trade_classifier { }
```

### Princípios SOLID

- **S**ingle Responsibility
- **O**pen/Closed
- **L**iskov Substitution
- **I**nterface Segregation
- **D**ependency Inversion

### Clean Code
```csharp
// ✅ BOM - Nomes descritivos
public async Task<IEnumerable<RiskLevel>> ClassifyTradesAsync(
    IEnumerable<Trade> trades, 
    CancellationToken cancellationToken)

// ❌ RUIM - Nomes genéricos
public async Task<IEnumerable<RiskLevel>> ProcessAsync(
    IEnumerable<Trade> t, 
    CancellationToken ct)
```

---

## 🧪 Testes

### Cobertura Mínima

- **Domain Layer**: 100%
- **Application Layer**: 90%+
- **Web Layer**: 80%+

### Executar Testes
```bash
# Todos os testes
dotnet test

# Com coverage
dotnet test /p:CollectCoverage=true
```

### Padrão AAA
```csharp
[Fact]
public void MethodName_Scenario_ExpectedBehavior()
{
    // Arrange
    var input = new Trade(1000000, ClientSector.Public);
    
    // Act
    var result = input.ClassifyRisk();
    
    // Assert
    Assert.Equal(RiskLevel.MEDIUMRISK, result);
}
```

---

## 📚 Documentação

### XML Comments
```csharp
/// <summary>
/// Classifica o risco de uma trade baseado em seu valor e setor do cliente
/// </summary>
/// <param name="trade">Trade a ser classificada</param>
/// <returns>Nível de risco calculado</returns>
/// <exception cref="ArgumentNullException">Quando trade é null</exception>
public RiskLevel ClassifyTrade(Trade trade)
{
    // ...
}
```

### README Updates

Se adicionar funcionalidade, atualize:
- README.md
- ARCHITECTURE.md (se aplicável)
- TESTING.md (se adicionar testes)

---

## 🔍 Code Review

### Checklist do Revisor

- [ ] Código segue padrões do projeto
- [ ] Testes cobrem funcionalidade
- [ ] Documentação atualizada
- [ ] Sem warnings de compilação
- [ ] Performance considerada
- [ ] Segurança considerada

### Checklist do Autor

Antes de criar PR:

- [ ] Branch atualizada com main
- [ ] Testes passando localmente
- [ ] Código formatado
- [ ] Commits bem descritos
- [ ] Documentação atualizada
- [ ] Self-review feito

---

## 🐛 Reportar Bugs

### Template de Issue
```markdown
**Descrição do Bug**
Descrição clara do que aconteceu.

**Para Reproduzir**
Passos para reproduzir:
1. Execute '...'
2. Envie request '...'
3. Veja erro

**Comportamento Esperado**
O que deveria acontecer.

**Screenshots**
Se aplicável, adicione screenshots.

**Ambiente**
- OS: [e.g. Windows 11]
- .NET Version: [e.g. 8.0.25]
- Browser: [e.g. Chrome 120]

**Contexto Adicional**
Qualquer informação adicional.
```

---

## 💡 Sugerir Funcionalidade

### Template de Feature Request
```markdown
**Problema Relacionado**
Descreva o problema que essa funcionalidade resolveria.

**Solução Proposta**
Descreva a solução que você gostaria de ver.

**Alternativas Consideradas**
Outras soluções que você considerou.

**Contexto Adicional**
Screenshots, mockups, etc.
```

---

## 🎯 Áreas para Contribuir

### Fácil (Good First Issue)

- Adicionar testes unitários
- Melhorar documentação
- Corrigir typos
- Adicionar exemplos de uso

### Médio

- Adicionar validações customizadas
- Melhorar tratamento de erros
- Adicionar novos endpoints
- Otimizar performance

### Avançado

- Implementar autenticação JWT
- Adicionar cache distribuído
- Implementar rate limiting
- Migrar para CQRS

---

## 📞 Contato

Dúvidas? Entre em contato:

- **GitHub Issues**: Para bugs e features
- **GitHub Discussions**: Para perguntas gerais
- **Email**: dev@trade-risk-api.com

---

**Obrigado por contribuir! 🎉**