VERT="\\033[1;32m"
NORMAL="\\033[0;39m"
ROUGE="\\033[1;31m"
ROSE="\\033[1;35m"
BLEU="\\033[1;34m"
BLANC="\\033[0;02m"
BLANCLAIR="\\033[1;08m"
JAUNE="\\033[1;33m"
CYAN="\\033[1;36m"

export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33'
export CLICOLOR=1

DOCKER = docker
DOCKER_COMPOSE = docker-compose

##===============================================================
## Configuration
##===============================================================

aliases: ## Configure aliases
	@if [[ ! -f web/bash_aliases ]]; then \
		cp web/bash_aliases.dist web/bash_aliases; \
		nano web/bash_aliases; \
		echo $(VERT)bash_aliases file configured!$(NORMAL); \
	else \
        echo $(VERT)bash_aliases file already configured$(NORMAL); \
    fi

cron: ## Configure the crontab file
	@if [[ ! -f web/crontab ]]; then \
		cp web/crontab.dist web/crontab; \
		nano web/crontab; \
		echo $(VERT)crontab file configured!$(NORMAL); \
	else \
		echo $(VERT)crontab file already configured$(NORMAL); \
	fi

ini: ## Configure the x-custom.ini file
	@if [[ ! -f web/x-custom.ini ]]; then \
		cp web/x-custom.ini.dist web/x-custom.ini; \
		nano web/x-custom.ini; \
		echo $(VERT)x-custom.ini file configured!$(NORMAL); \
	else \
		echo $(VERT)x-custom.ini file already configured$(NORMAL); \
	fi

env: ## Configure the env file
	@if [[ ! -f docker-env ]]; then \
		cp docker-env.dist docker-env; \
		nano docker-env; \
		echo $(VERT)docker-env file configured!$(NORMAL); \
	else \
		echo $(VERT)docker-env file already configured$(NORMAL); \
	fi

setup: ## Setup the environment
setup: aliases cron ini env

.PHONY: aliases cron ini env setup

##===============================================================
## Installation & Launch
##===============================================================

build: ## Build the environment
	$(DOCKER_COMPOSE) pull --ignore-pull-failures
	$(DOCKER_COMPOSE) build --pull

start: ## Start the environment
	@if [[ ! -f docker-env ]]; then \
		echo 'The default configuration has been applied because the "docker-env" file was not configured.'; \
		cp docker-env.dist docker-env; \
	fi
	$(DOCKER_COMPOSE) up -d --remove-orphans
	$(DOCKER_COMPOSE) ps

stop: ## Stop the environment
	$(DOCKER_COMPOSE) stop

restart: ## Restart the environment
restart: stop start

install: ## Install the environment
install: build start ssh

uninstall: ## Uninstall the environment
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

.PHONY: build start stop restart install uninstall

##===============================================================
## Connection
##===============================================================

go-web: ## Open a terminal in the "web" container
	$(DOCKER_COMPOSE) exec web   sh -c "/bin/bash"

go-mysql: ## Open a terminal in the "mysql" container
	$(DOCKER_COMPOSE) exec mysql sh -c "/bin/bash"

go-redis: ## Open a terminal in the "redis" container
	$(DOCKER_COMPOSE) exec redis sh -c "/bin/bash"

.PHONY: go-web go-mysql go-redis

##===============================================================
## Others
##===============================================================

cache: ## Flush everything stored into the "redis" container
	$(DOCKER_COMPOSE) exec -T redis sh -c "redis-cli FLUSHALL"

logs: ## Follow logs generated by all containers
	$(DOCKER_COMPOSE) logs -f --tail=0

logs-full: ## Follow logs generated by all containers from the containers creation
	$(DOCKER_COMPOSE) logs -f

ps: ## List all containers managed by the environment
	$(DOCKER_COMPOSE) ps

stats: ## Print real-time statistics about containers ressources usage
	docker stats $(docker ps --format={{.Names}})

ssh: ## Copy all SSH keys from the host to the "web" container
	$(DOCKER_COMPOSE) exec -T web sh -c "mkdir -p /root/.ssh"
	$(DOCKER) cp $(HOME)/.ssh $(shell docker-compose ps -q web):/root/

.PHONY: cache logs logs-full ps stats ssh

# Help
.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m##/[33m/'
.PHONY: help
