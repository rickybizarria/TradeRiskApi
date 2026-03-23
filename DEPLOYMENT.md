# 🚀 Guia de Deploy - Trade Risk Classification API

## Visão Geral

Este documento descreve como fazer deploy da aplicação em diferentes ambientes.

---

## 📋 Índice

- [Ambientes](#ambientes)
- [Deploy Local](#deploy-local)
- [Deploy Docker](#deploy-docker)
- [Deploy Azure](#deploy-azure)
- [Deploy AWS](#deploy-aws)
- [Configuração](#configuração)
- [Monitoramento](#monitoramento)

---

## 🌍 Ambientes

### Development (Local)
```bash
cd src/TradeRiskApi.Web
dotnet run --environment Development
```

Acesso: `https://localhost:7183`

### Staging
```bash
dotnet run --environment Staging
```

### Production
```bash
dotnet run --environment Production
```

---

## 💻 Deploy Local

### Pré-requisitos

- .NET 8 SDK instalado
- Porta 7183 (HTTPS) e 5092 (HTTP) disponíveis

### Passos

1. **Clonar repositório**
```bash
git clone https://github.com/seu-usuario/trade-risk-api.git
cd trade-risk-api
```

2. **Restaurar dependências**
```bash
dotnet restore
```

3. **Build**
```bash
dotnet build -c Release
```

4. **Publicar**
```bash
dotnet publish src/TradeRiskApi.Web/TradeRiskApi.Web.csproj -c Release -o ./publish
```

5. **Executar**
```bash
cd publish
dotnet TradeRiskApi.Web.dll
```

---

## 🐳 Deploy Docker

### Build da Imagem
```bash
docker build -t trade-risk-api:latest .
```

### Executar Container

#### Desenvolvimento (HTTP)
```bash
docker run -d \
  --name trade-risk-api \
  -p 8080:80 \
  -e ASPNETCORE_ENVIRONMENT=Development \
  trade-risk-api:latest
```

Acesso: `http://localhost:8080`

#### Produção (HTTPS)

1. **Gerar certificado de desenvolvimento**
```bash
dotnet dev-certs https -ep ${HOME}/.aspnet/https/aspnetapp.pfx -p YourSecurePassword
dotnet dev-certs https --trust
```

2. **Executar com HTTPS**
```bash
docker run -d \
  --name trade-risk-api \
  -p 8080:80 \
  -p 8443:443 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ASPNETCORE_URLS="https://+;http://+" \
  -e ASPNETCORE_Kestrel__Certificates__Default__Password="YourSecurePassword" \
  -e ASPNETCORE_Kestrel__Certificates__Default__Path=/https/aspnetapp.pfx \
  -v ${HOME}/.aspnet/https:/https:ro \
  trade-risk-api:latest
```

Acesso: `https://localhost:8443`

### Docker Compose
```bash
docker-compose up -d
```

Parar:
```bash
docker-compose down
```

Ver logs:
```bash
docker-compose logs -f
```

---

## ☁️ Deploy Azure

### Azure App Service

#### Via Azure CLI

1. **Login**
```bash
az login
```

2. **Criar Resource Group**
```bash
az group create \
  --name rg-trade-risk-api \
  --location eastus
```

3. **Criar App Service Plan**
```bash
az appservice plan create \
  --name plan-trade-risk-api \
  --resource-group rg-trade-risk-api \
  --sku B1 \
  --is-linux
```

4. **Criar Web App**
```bash
az webapp create \
  --name trade-risk-api \
  --resource-group rg-trade-risk-api \
  --plan plan-trade-risk-api \
  --runtime "DOTNET|8.0"
```

5. **Deploy**
```bash
az webapp deployment source config-zip \
  --resource-group rg-trade-risk-api \
  --name trade-risk-api \
  --src ./publish.zip
```

#### Via Visual Studio

1. Clique direito no projeto `TradeRiskApi.Web`
2. **Publicar...**
3. Selecione **Azure**
4. Selecione **Azure App Service (Windows/Linux)**
5. Configure credenciais e publique

---

### Azure Container Instances (ACI)

1. **Push imagem para Azure Container Registry**
```bash
# Criar ACR
az acr create \
  --resource-group rg-trade-risk-api \
  --name traderiskacr \
  --sku Basic

# Login no ACR
az acr login --name traderiskacr

# Tag e push
docker tag trade-risk-api:latest traderiskacr.azurecr.io/trade-risk-api:latest
docker push traderiskacr.azurecr.io/trade-risk-api:latest
```

2. **Deploy no ACI**
```bash
az container create \
  --resource-group rg-trade-risk-api \
  --name trade-risk-api-container \
  --image traderiskacr.azurecr.io/trade-risk-api:latest \
  --cpu 1 \
  --memory 1 \
  --registry-login-server traderiskacr.azurecr.io \
  --registry-username <username> \
  --registry-password <password> \
  --dns-name-label trade-risk-api \
  --ports 80
```

URL: `http://trade-risk-api.<region>.azurecontainer.io`

---

### Azure Kubernetes Service (AKS)

1. **Criar cluster AKS**
```bash
az aks create \
  --resource-group rg-trade-risk-api \
  --name aks-trade-risk-api \
  --node-count 2 \
  --enable-addons monitoring \
  --generate-ssh-keys
```

2. **Conectar ao cluster**
```bash
az aks get-credentials \
  --resource-group rg-trade-risk-api \
  --name aks-trade-risk-api
```

3. **Deploy**

Criar arquivo `k8s-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trade-risk-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: trade-risk-api
  template:
    metadata:
      labels:
        app: trade-risk-api
    spec:
      containers:
      - name: trade-risk-api
        image: traderiskacr.azurecr.io/trade-risk-api:latest
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
---
apiVersion: v1
kind: Service
metadata:
  name: trade-risk-api-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: trade-risk-api
```

Deploy:
```bash
kubectl apply -f k8s-deployment.yaml
```

---

## 🌐 Deploy AWS

### AWS Elastic Beanstalk

1. **Instalar EB CLI**
```bash
pip install awsebcli
```

2. **Inicializar**
```bash
eb init -p "64bit Amazon Linux 2 v2.3.0 running .NET Core" trade-risk-api
```

3. **Criar ambiente**
```bash
eb create trade-risk-api-env
```

4. **Deploy**
```bash
dotnet publish -c Release -o ./publish
cd publish
zip -r ../publish.zip .
cd ..
eb deploy
```

5. **Abrir aplicação**
```bash
eb open
```

---

### AWS ECS (Elastic Container Service)

1. **Push para ECR**
```bash
# Criar repositório ECR
aws ecr create-repository --repository-name trade-risk-api

# Login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Tag e push
docker tag trade-risk-api:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/trade-risk-api:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/trade-risk-api:latest
```

2. **Criar task definition** (via console AWS ou CLI)

3. **Criar cluster e service**

---

## ⚙️ Configuração

### Variáveis de Ambiente

#### Development
```bash
ASPNETCORE_ENVIRONMENT=Development
ASPNETCORE_URLS=https://localhost:7183;http://localhost:5092
```

#### Production
```bash
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=https://+:443;http://+:80
AllowedHosts=*.yourdomain.com
```

### appsettings.Production.json

**📍 Criar:** `src\TradeRiskApi.Web\appsettings.Production.json`
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning",
      "TradeRiskApi": "Information"
    }
  },
  "AllowedHosts": "*.yourdomain.com"
}
```

---

## 📊 Monitoramento

### Health Checks
```bash
curl https://your-domain.com/health
```

Resposta esperada:
```json
{
  "status": "Healthy",
  "results": {
    "risk-classification": {
      "status": "Healthy",
      "description": "Serviço de classificação operacional"
    }
  }
}
```

### Logs

#### Docker
```bash
docker logs -f trade-risk-api
```

#### Azure
```bash
az webapp log tail --name trade-risk-api --resource-group rg-trade-risk-api
```

#### Kubernetes
```bash
kubectl logs -f deployment/trade-risk-api
```

---

## 🔒 SSL/TLS

### Let's Encrypt (Produção)

#### Nginx Reverse Proxy

1. **Instalar Certbot**
```bash
sudo apt-get install certbot python3-certbot-nginx
```

2. **Obter certificado**
```bash
sudo certbot --nginx -d yourdomain.com
```

3. **Configurar Nginx** (`/etc/nginx/sites-available/trade-risk-api`)
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:5092;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

4. **Renovação automática**
```bash
sudo certbot renew --dry-run
```

---

## 🎯 CI/CD Pipeline

### GitHub Actions

**📍 Criar:** `.github\workflows\ci-cd.yml`
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 8.0.x
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --configuration Release --no-restore
    
    - name: Test
      run: dotnet test --no-build --verbosity normal --configuration Release
    
    - name: Publish
      run: dotnet publish src/TradeRiskApi.Web/TradeRiskApi.Web.csproj -c Release -o ./publish
    
    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: trade-risk-api
        path: ./publish

  deploy-staging:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    
    steps:
    - name: Download artifact
      uses: actions/download-artifact@v3
      with:
        name: trade-risk-api
        path: ./publish
    
    - name: Deploy to Staging
      run: |
        echo "Deploy to staging environment"
        # Adicionar comandos de deploy aqui

  deploy-production:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Download artifact
      uses: actions/download-artifact@v3
      with:
        name: trade-risk-api
        path: ./publish
    
    - name: Deploy to Production
      run: |
        echo "Deploy to production environment"
        # Adicionar comandos de deploy aqui
```

---

## 📈 Escalabilidade

### Load Balancing

#### Azure Load Balancer
```bash
az network lb create \
  --resource-group rg-trade-risk-api \
  --name lb-trade-risk-api \
  --sku Standard \
  --frontend-ip-name frontend \
  --backend-pool-name backendpool
```

#### AWS Application Load Balancer
```bash
aws elbv2 create-load-balancer \
  --name trade-risk-api-alb \
  --subnets subnet-12345 subnet-67890 \
  --security-groups sg-12345
```

### Auto Scaling

#### Azure (App Service)
```bash
az monitor autoscale create \
  --resource-group rg-trade-risk-api \
  --resource trade-risk-api \
  --resource-type Microsoft.Web/sites \
  --name autoscale-trade-risk-api \
  --min-count 2 \
  --max-count 10 \
  --count 2
```

---

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. Porta já em uso
```bash
# Windows
netstat -ano | findstr :7183
taskkill /PID <PID> /F

# Linux
sudo lsof -i :7183
sudo kill -9 <PID>
```

#### 2. Certificado SSL inválido
```bash
dotnet dev-certs https --clean
dotnet dev-certs https --trust
```

#### 3. Container não inicia
```bash
docker logs trade-risk-api
docker exec -it trade-risk-api /bin/bash
```

#### 4. Health check falhando
```bash
curl -v http://localhost:8080/health
```

---

## ✅ Checklist de Deploy

Antes de fazer deploy para produção:

- [ ] Testes passando (`dotnet test`)
- [ ] Build de Release sem warnings
- [ ] Variáveis de ambiente configuradas
- [ ] SSL/TLS configurado
- [ ] Health checks funcionando
- [ ] Logs configurados
- [ ] Backup de dados (se aplicável)
- [ ] Plano de rollback definido
- [ ] Monitoramento ativo
- [ ] Documentação atualizada

---

**Última atualização:** 21/03/2026