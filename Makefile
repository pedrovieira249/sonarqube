.PHONY: help up down restart logs status clean setup install check-java check-scanner start

help: ## Mostra este menu de ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

check-java:
	@echo "🔍 Verificando instalação do Java..."
	@if command -v java >/dev/null 2>&1; then \
		echo "✅ Java já está instalado:"; \
		java -version 2>&1 | head -n 1; \
	else \
		echo "📦 Java não encontrado. Instalando openjdk-17-jdk..."; \
		sudo apt update && sudo apt install -y openjdk-17-jdk unzip wget; \
		echo "✅ Java instalado com sucesso!"; \
		java -version 2>&1 | head -n 1; \
	fi

check-scanner:
	@echo "🔍 Verificando instalação do Sonar Scanner..."
	@if [ -d "/opt/sonar-scanner" ] && [ -f "/opt/sonar-scanner/bin/sonar-scanner" ]; then \
		echo "✅ Sonar Scanner já está instalado:"; \
		/opt/sonar-scanner/bin/sonar-scanner --version 2>&1 | head -n 1; \
	else \
		echo "📦 Sonar Scanner não encontrado. Instalando..."; \
		cd /tmp && \
		wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip && \
		unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip && \
		sudo rm -rf /opt/sonar-scanner && \
		sudo mv sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner && \
		rm sonar-scanner-cli-5.0.1.3006-linux.zip; \
		if ! grep -q "/opt/sonar-scanner/bin" ~/.bashrc; then \
			echo 'export PATH=$$PATH:/opt/sonar-scanner/bin' >> ~/.bashrc; \
		fi; \
		export PATH=$$PATH:/opt/sonar-scanner/bin; \
		echo "✅ Sonar Scanner instalado com sucesso!"; \
		/opt/sonar-scanner/bin/sonar-scanner --version 2>&1 | head -n 1; \
	fi

start: check-java check-scanner ## Valida/instala dependências e inicia o projeto
	@echo ""
	@echo "🐳 Preparando ambiente Docker..."
	@if docker-compose ps | grep -q "Up"; then \
		echo "⚠️  Containers já estão rodando. Reiniciando..."; \
		docker-compose down; \
	fi
	@echo "🚀 Iniciando containers..."
	@docker-compose up -d
	@echo ""
	@echo "✅ Projeto iniciado com sucesso!"
	@echo "📊 Aguardando SonarQube inicializar..."
	@sleep 5
	@echo ""
	@echo "🌐 Acesse: http://localhost:9000"
	@echo "👤 Usuário: admin"
	@echo "🔑 Senha: admin"
	@echo ""
	@echo "📝 Para ver os logs: make logs"

install: start ## Alias para 'start' - valida, instala dependências e inicia o projeto

setup: ## Configura os requisitos do sistema
	@echo "Configurando requisitos do sistema..."
	sudo sysctl -w vm.max_map_count=524288
	sudo sysctl -w fs.file-max=131072
	@echo "Configuração concluída!"

up: ## Inicia os containers
	docker-compose up -d

down: ## Para os containers
	docker-compose down

restart: ## Reinicia os containers
	docker-compose restart

logs: ## Exibe os logs do SonarQube
	docker-compose logs -f sonarqube

logs-db: ## Exibe os logs do PostgreSQL
	docker-compose logs -f db

status: ## Mostra o status dos containers
	docker-compose ps

clean: ## Remove containers e volumes (CUIDADO: apaga dados)
	@echo "ATENÇÃO: Isso irá remover todos os dados!"
	@read -p "Tem certeza? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "Containers e volumes removidos!"; \
	fi

access: ## Abre o SonarQube no navegador
	@echo "Abrindo http://localhost:9000"
	@which xdg-open > /dev/null && xdg-open http://localhost:9000 || echo "Acesse: http://localhost:9000"

install-scanner: ## Instala o sonar-scanner globalmente
	npm install -g sonar-scanner