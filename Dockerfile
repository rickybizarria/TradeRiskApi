# ==============================================================================
# Dockerfile - Trade Risk Classification API
# Multi-stage build para otimizar tamanho da imagem final
# ==============================================================================

# ==============================================================================
# STAGE 1: Base Runtime
# ==============================================================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Configurar timezone (opcional)
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# ==============================================================================
# STAGE 2: Build
# ==============================================================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copiar arquivos de projeto e restaurar dependências
COPY ["src/TradeRiskApi.Web/TradeRiskApi.Web.csproj", "TradeRiskApi.Web/"]
COPY ["src/TradeRiskApi.Application/TradeRiskApi.Application.csproj", "TradeRiskApi.Application/"]
COPY ["src/TradeRiskApi.Domain/TradeRiskApi.Domain.csproj", "TradeRiskApi.Domain/"]

RUN dotnet restore "TradeRiskApi.Web/TradeRiskApi.Web.csproj"

# Copiar código-fonte
COPY src/ .

# Build da aplicação
WORKDIR "/src/TradeRiskApi.Web"
RUN dotnet build "TradeRiskApi.Web.csproj" -c Release -o /app/build

# ==============================================================================
# STAGE 3: Publish
# ==============================================================================
FROM build AS publish
RUN dotnet publish "TradeRiskApi.Web.csproj" -c Release -o /app/publish /p:UseAppHost=false

# ==============================================================================
# STAGE 4: Final
# ==============================================================================
FROM base AS final
WORKDIR /app

# Copiar arquivos publicados
COPY --from=publish /app/publish .

# Criar usuário não-root para segurança
RUN addgroup --system --gid 1000 appuser && \
    adduser --system --uid 1000 --ingroup appuser --shell /bin/sh appuser && \
    chown -R appuser:appuser /app

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1

ENTRYPOINT ["dotnet", "TradeRiskApi.Web.dll"]
```

---

## **📝 ARQUIVO 4: .dockerignore**

**📍 Localização:** `C:\Dev\TradeRiskApi\.dockerignore` (raiz do projeto)
```
# Ignorar builds e outputs
**/bin/
**/obj/
**/out/

# Ignorar testes
**/TestResults/
**/*.trx

# Ignorar arquivos do Visual Studio
**/.vs/
**/.vscode/
*.user
*.suo
*.cache

# Ignorar Git
.git/
.gitignore
.gitattributes

# Ignorar documentação
README.md
ARCHITECTURE.md
LICENSE

# Ignorar Docker
Dockerfile
.dockerignore
docker-compose.yml

# Ignorar arquivos de configuração local
**/appsettings.Development.json
**/appsettings.*.json
!**/appsettings.json

# Ignorar node_modules (se houver)
**/node_modules/

# Ignorar arquivos temporários
**/*.tmp
**/*.temp