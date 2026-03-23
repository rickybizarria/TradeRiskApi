# ============================================================================
# SCRIPT DE VERIFICAÇÃO PRÉ-ENTREGA
# Trade Risk Classification API
# ============================================================================

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  VERIFICAÇÃO PRÉ-ENTREGA - TRADE RISK API" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$rootPath = "C:\Dev\TradeRiskApi"
Set-Location $rootPath

$issues = 0

# ============================================================================
# 1. VERIFICAR COMPILAÇÃO
# ============================================================================
Write-Host "[1/6] Verificando compilação..." -ForegroundColor Yellow
$buildResult = dotnet build -c Release 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Projeto compila sem erros" -ForegroundColor Green
} else {
    Write-Host "  [ERRO] Falha na compilação" -ForegroundColor Red
    $issues++
}

# ============================================================================
# 2. VERIFICAR TESTES
# ============================================================================
Write-Host ""
Write-Host "[2/6] Executando testes..." -ForegroundColor Yellow
$testResult = dotnet test --no-build -c Release 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Todos os testes passando" -ForegroundColor Green
} else {
    Write-Host "  [ERRO] Testes falharam" -ForegroundColor Red
    $issues++
}

# ============================================================================
# 3. VERIFICAR ARQUIVOS OBRIGATÓRIOS
# ============================================================================
Write-Host ""
Write-Host "[3/6] Verificando arquivos obrigatórios..." -ForegroundColor Yellow

$requiredFiles = @(
    "README.md",
    "ARCHITECTURE.md",
    "TESTING.md",
    "DEPLOYMENT.md",
    "DELIVERY_INSTRUCTIONS.md",
    "Dockerfile",
    ".gitignore",
    "TradeRiskApi.sln"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [FALTA] $file" -ForegroundColor Red
        $issues++
    }
}

# ============================================================================
# 4. VERIFICAR ESTRUTURA DE CÓDIGO
# ============================================================================
Write-Host ""
Write-Host "[4/6] Verificando estrutura de código..." -ForegroundColor Yellow

$codeFiles = @(
    "src\TradeRiskApi.Domain\Entities\Trade.cs",
    "src\TradeRiskApi.Domain\ValueObjects\Money.cs",
    "src\TradeRiskApi.Application\Services\RiskAnalysisService.cs",
    "src\TradeRiskApi.Web\Controllers\TradesController.cs",
    "src\TradeRiskApi.Web\Program.cs"
)

foreach ($file in $codeFiles) {
    if (Test-Path $file) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [FALTA] $file" -ForegroundColor Red
        $issues++
    }
}

# ============================================================================
# 5. VERIFICAR TESTES
# ============================================================================
Write-Host ""
Write-Host "[5/6] Verificando arquivos de teste..." -ForegroundColor Yellow

$testFiles = @(
    "tests\TradeRiskApi.UnitTests\Domain\TradeTests.cs",
    "tests\TradeRiskApi.IntegrationTests\Controllers\TradesControllerTests.cs"
)

foreach ($file in $testFiles) {
    if (Test-Path $file) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [FALTA] $file" -ForegroundColor Red
        $issues++
    }
}

# ============================================================================
# 6. VERIFICAR API RODANDO
# ============================================================================
Write-Host ""
Write-Host "[6/6] Verificando se API pode iniciar..." -ForegroundColor Yellow
Write-Host "  (Pressione Ctrl+C após verificar que a API iniciou)" -ForegroundColor Gray

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$rootPath\src\TradeRiskApi.Web'; dotnet run"
Start-Sleep -Seconds 10

try {
    $response = Invoke-WebRequest -Uri "http://localhost:5092/health" -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "  [OK] API iniciou com sucesso" -ForegroundColor Green
    }
} catch {
    Write-Host "  [AVISO] Não foi possível verificar API (pode já estar rodando)" -ForegroundColor Yellow
}

# ============================================================================
# RESUMO
# ============================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan

if ($issues -eq 0) {
    Write-Host "  ✅ TUDO PRONTO PARA ENTREGA!" -ForegroundColor Green
    Write-Host "  Nenhum problema encontrado." -ForegroundColor Green
} else {
    Write-Host "  ⚠️  $issues PROBLEMA(S) ENCONTRADO(S)" -ForegroundColor Red
    Write-Host "  Corrija antes de entregar." -ForegroundColor Red
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "1. Criar repositório no GitHub" -ForegroundColor White
Write-Host "2. git add . && git commit -m 'feat: solução completa'" -ForegroundColor White
Write-Host "3. git push origin main" -ForegroundColor White
Write-Host "4. Enviar email com link do repositório" -ForegroundColor White
Write-Host ""