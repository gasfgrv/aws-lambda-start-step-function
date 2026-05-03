.PHONY: docker-up docker-down  docker-rebuild check-infra scan-table test-lambda-trigger test

DOCKER_COMPOSE_FILE=docker/docker-compose.yml
AWS_CLI=awslocal

docker-up:
	chmod +x docker/init/aws-init.sh
	@echo "Subindo infraestrutura local com LocalStack..."
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d

docker-down:
	@echo "Desligando infraestrutura local..."
	docker compose -f $(DOCKER_COMPOSE_FILE) down

docker-rebuild:
	@echo "Limpando e recriando infraestrutura..."
	docker compose -f $(DOCKER_COMPOSE_FILE) down -v
	@echo "Subindo infraestrutura local..."
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d

check-infra:
	@echo "Verificando infraestrutura local..."
	@echo ""
	@echo "Verificando SQS..."
	$(AWS_CLI) sqs list-queues
	@echo ""
	@echo "Verificando DynamoDB..."
	$(AWS_CLI) dynamodb list-tables
	@echo ""
	@echo "Veririficando IAM Roles..."
	$(AWS_CLI) iam list-roles --no-cli-pager
	@echo ""
	@echo "Verificando Lambdas..."
	$(AWS_CLI) lambda list-functions --no-cli-pager
	@echo ""
	@echo "Verificando Step Functions..."
	$(AWS_CLI) stepfunctions list-state-machines --no-cli-pager

scan-table:
	@echo "Escaneando tabela DynamoDB..."
	$(AWS_CLI) dynamodb scan --table-name my-table --no-cli-pager

test-lambda-trigger:
	@echo "Testando lambda de trigger..."
	$(AWS_CLI) lambda invoke --function-name sqs-trigger --payload fileb://./payload.json response.json

test:
	@echo "Testando fluxo completo..."
	$(AWS_CLI) sqs send-message --queue-url http://localhost:4566/000000000000/my-queue --message-body '{"key": "value"}'
	docker logs -f localstack