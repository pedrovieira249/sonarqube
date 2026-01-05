# 1. Instalar Java
sudo apt update
sudo apt install openjdk-17-jdk unzip wget -y

# 2. Baixar e instalar Sonar Scanner
cd /tmp
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip sonar-scanner-cli-5.0.1.3006-linux.zip
sudo mv sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner

# 3. Configurar PATH
echo 'export PATH=$PATH:/opt/sonar-scanner/bin' >> ~/.bashrc
source ~/.bashrc

# 4. Verificar
sonar-scanner --version

# SonarQube Docker Setup

Estrutura Docker para executar o SonarQube com PostgreSQL.

## Importante

Este setup usa `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true` para **desabilitar** as verificações de bootstrap do Elasticsearch. Isso permite que o SonarQube funcione **sem precisar configurar** o `vm.max_map_count` do sistema.

⚠️ **Nota**: Esta configuração é ideal para ambientes de desenvolvimento e testes. Para produção, é recomendado configurar corretamente o sistema em vez de desabilitar os checks.

## Requisitos do Sistema (Opcional para Produção)

Se você preferir **não** desabilitar os bootstrap checks (mais seguro para produção), remova a variável `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE` do docker-compose.yml e configure:

```bash
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
```

Para tornar permanente:

```bash
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf
```

## Estrutura

- **SonarQube**: Porta 9000
- **PostgreSQL**: Banco de dados interno
- **Volumes persistentes** para dados, extensões e logs

## Como usar

### Opção 1: Instalação Automatizada (Recomendado)

O comando `make install` ou `make start` faz tudo automaticamente:

```bash
make install
```

Este comando irá:
1. ✅ Verificar se o Java (openjdk-17-jdk) está instalado
2. ✅ Verificar se o Sonar Scanner está instalado
3. ✅ Instalar automaticamente o que estiver faltando
4. ✅ Parar containers em execução (se houver)
5. ✅ Iniciar os containers do SonarQube

**Nota**: Não se preocupe em executar múltiplas vezes - o comando valida antes de instalar!

### Opção 2: Instalação Manual

### 1. Iniciar os containers

```bash
docker-compose up -d
```

### 2. Verificar status

```bash
docker-compose ps
docker-compose logs -f sonarqube
```

### 3. Acessar o SonarQube

Abra o navegador em: `http://localhost:9000`

**Credenciais padrão:**
- Usuário: `admin`
- Senha: `admin`

⚠️ **Importante**: O SonarQube solicitará a alteração da senha no primeiro login.

### 4. Parar os containers

```bash
docker-compose down
```

### 5. Parar e remover volumes (cuidado - apaga os dados)

```bash
docker-compose down -v
```

## Analisar um projeto

### 📋 Passo 1: Criar Projeto no SonarQube

1. **Acesse o SonarQube**: `http://localhost:9000`
2. **Faça login** com as credenciais:
   - Usuário: `admin`
   - Senha: `admin` (você será solicitado a alterar no primeiro acesso)

3. **Crie um novo projeto**:
   - Clique em **"Create Project"** (canto superior direito)
   - Ou vá em **"Projects" > "Create Project"**

4. **Configure o projeto**:
   - Selecione **"Manually"**
   - Defina o **Project key** (ex: `meu-projeto-laravel`)
   - Defina o **Project display name** (ex: `Meu Projeto Laravel`)
   - Clique em **"Next"**

5. **Configurar análise**:
   - Selecione **"Use the global setting"** para branch
   - Clique em **"Create project"**

### 🔑 Passo 2: Gerar Token pelo Painel

Após criar o projeto, o SonarQube irá guiá-lo:

1. **Escolha a análise local**:
   - Selecione **"Locally"**

2. **Gerar token**:
   - O SonarQube mostrará a opção **"Generate a token"**
   - Clique em **"Generate"**
   - Dê um nome ao token (ex: `token-analise-local`)
   - Clique em **"Generate"**
   - **⚠️ IMPORTANTE**: Copie e guarde o token, ele não será mostrado novamente!

3. **Selecione a tecnologia**:
   - Escolha **"Other"** (para projetos PHP/Laravel/JavaScript)
   - Selecione seu sistema operacional: **"Linux"**

4. **Comando gerado automaticamente**:
   - O SonarQube exibirá o comando completo pronto para uso!
   - Exemplo do comando gerado:

```bash
sonar-scanner \
  -Dsonar.projectKey=meu-projeto-laravel \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=sqp_1234567890abcdefghijklmnopqrstuvwxyz
```

### 🚀 Passo 3: Executar a Análise

1. **Abra o terminal** na raiz do seu projeto
2. **Cole e execute** o comando gerado pelo SonarQube
3. **Aguarde** a análise ser concluída
4. **Visualize os resultados** no painel do SonarQube

```bash
# Exemplo de execução
cd /caminho/do/seu/projeto
sonar-scanner \
  -Dsonar.projectKey=meu-projeto-laravel \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=sqp_1234567890abcdefghijklmnopqrstuvwxyz
```

### 📝 Passo 4: (Opcional) Criar arquivo sonar-project.properties

Para evitar passar parâmetros via linha de comando, crie um arquivo `sonar-project.properties` na raiz do projeto:

```properties
# Informações do Projeto
sonar.projectKey=meu-projeto-laravel
sonar.projectName=Meu Projeto Laravel
sonar.projectVersion=1.0

# Configurações de Análise
sonar.sources=.
sonar.sourceEncoding=UTF-8

# Exclusões (pastas que não devem ser analisadas)
sonar.exclusions=vendor/**,node_modules/**,storage/**,bootstrap/cache/**,public/**

# Para PHP/Laravel
sonar.language=php
sonar.php.coverage.reportPaths=coverage.xml
sonar.php.tests.reportPath=tests/report.xml

# Host e Token (NUNCA commite o token no Git!)
sonar.host.url=http://localhost:9000
sonar.token=sqp_1234567890abcdefghijklmnopqrstuvwxyz
```

Com o arquivo criado, execute apenas:

```bash
sonar-scanner
```

⚠️ **IMPORTANTE**: Adicione o `sonar-project.properties` no `.gitignore` para não expor seu token:

```bash
echo "sonar-project.properties" >> .gitignore
```

### 🔄 Gerenciar Tokens Existentes

Se precisar criar novos tokens ou revogar tokens antigos:

1. Acesse: `http://localhost:9000`
2. Clique no seu **avatar** (canto superior direito)
3. Vá em **"My Account"**
4. Clique na aba **"Security"**
5. Seção **"Tokens"**:
   - **Generate**: Criar novo token
   - **Revoke**: Revogar token existente

### 💡 Dicas para Projetos Laravel/PHP

#### Instalação de ferramentas de qualidade de código (opcional):

```bash
# PHPUnit para testes
composer require --dev phpunit/phpunit

# PHP_CodeSniffer para análise de código
composer require --dev squizlabs/php_codesniffer

# PHPStan para análise estática
composer require --dev phpstan/phpstan
```

#### Exemplo de sonar-project.properties otimizado para Laravel:

```properties
# Projeto
sonar.projectKey=meu-laravel-app
sonar.projectName=Minha Aplicação Laravel
sonar.projectVersion=1.0

# Código fonte
sonar.sources=app,routes,config,database
sonar.tests=tests

# Exclusões
sonar.exclusions=vendor/**,\
  node_modules/**,\
  storage/**,\
  bootstrap/cache/**,\
  public/**,\
  resources/views/**,\
  database/migrations/**

# PHP
sonar.language=php
sonar.sourceEncoding=UTF-8

# Relatórios de cobertura (se usar PHPUnit com cobertura)
sonar.php.coverage.reportPaths=coverage.xml
sonar.php.tests.reportPath=junit.xml

# Conexão
sonar.host.url=http://localhost:9000
sonar.token=SEU_TOKEN_AQUI
```

#### Gerar relatório de cobertura com PHPUnit:

```bash
# Executar testes com cobertura
./vendor/bin/phpunit --coverage-clover coverage.xml --log-junit junit.xml

# Depois executar a análise do SonarQube
sonar-scanner
```

## Comandos Make Disponíveis

```bash
make help          # Lista todos os comandos disponíveis
make install       # Instala dependências e inicia o projeto (recomendado)
make start         # Mesmo que 'install'
make up            # Inicia os containers
make down          # Para os containers
make restart       # Reinicia os containers
make logs          # Exibe logs do SonarQube
make logs-db       # Exibe logs do PostgreSQL
make status        # Mostra status dos containers
make clean         # Remove containers e volumes (apaga dados)
make access        # Abre o SonarQube no navegador
```

## Troubleshooting

### Container não inicia

Verifique os logs:
```bash
docker-compose logs sonarqube
```

### Erro de memória

Ajuste as configurações de memória no `.env`:
```env
SONAR_JAVA_OPTS=-Xmx2048m -Xms512m
```

### Permissões de volume

Se houver problemas de permissão:
```bash
sudo chown -R 1000:1000 volumes/
```

## Recursos Úteis

- [Documentação oficial do SonarQube](https://docs.sonarqube.org/latest/)
- [SonarQube para PHP](https://docs.sonarqube.org/latest/analysis/languages/php/)
- [Analisando projetos Laravel](https://laravel-news.com/sonarqube)