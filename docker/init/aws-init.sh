#!/bin/bash
set -e

echo "🚀 Subindo infra..."

REGION=us-east-1
ROOT_DIR="/opt/code"   # vamos mapear isso no docker depois
BUILD_DIR=/tmp/lambda-build
LAMBDA_DIR="$ROOT_DIR/lambdas"

QUEUE_NAME=my-queue
TABLE_NAME=my-table
STATE_MACHINE_NAME=my-state-machine

# =========================
# SQS
# =========================
QUEUE_URL=$(awslocal sqs create-queue \
  --queue-name $QUEUE_NAME \
  --query 'QueueUrl' \
  --output text)

# =========================
# DynamoDB
# =========================
awslocal dynamodb create-table \
  --table-name $TABLE_NAME \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# =========================
# IAM
# =========================
ROLE_ARN=$(awslocal iam create-role \
  --role-name lambda-role \
  --assume-role-policy-document file:///dev/stdin \
  --query 'Role.Arn' \
  --output text <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "lambda.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF
)

# =========================
# Build Lambdas (zip)
# =========================
echo "📦 Empacotando lambdas..."

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

cd $LAMBDA_DIR/sqs-trigger

tar --exclude='test' \
    --exclude='.venv' \
    --exclude='__pycache__' \
    --exclude='.git' \
    --exclude='.pytest_cache' \
    -cf - . | tar -xf - -C $BUILD_DIR

pip install -r "$LAMBDA_DIR/sqs-trigger/requirements.txt" -t $BUILD_DIR

cd $BUILD_DIR
zip -r /tmp/sqs.zip .

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

cd $LAMBDA_DIR/process-data

tar --exclude='test' \
    --exclude='.venv' \
    --exclude='__pycache__' \
    --exclude='.git' \
    --exclude='.pytest_cache' \
    -cf - . | tar -xf - -C $BUILD_DIR

pip install -r "$LAMBDA_DIR/process-data/requirements.txt" -t $BUILD_DIR

cd $BUILD_DIR
zip -r /tmp/process.zip .

# =========================
# Criar Lambdas
# =========================
SQS_LAMBDA_ARN=$(awslocal lambda create-function \
  --function-name sqs-trigger \
  --runtime python3.14 \
  --handler handler.handler \
  --zip-file fileb:///tmp/sqs.zip \
  --role $ROLE_ARN \
  --environment Variables="{STATE_MACHINE_ARN=placeholder}" \
  --query 'FunctionArn' \
  --output text)

PROCESS_LAMBDA_ARN=$(awslocal lambda create-function \
  --function-name process-data \
  --runtime python3.14 \
  --handler handler.handler \
  --zip-file fileb:///tmp/process.zip \
  --role $ROLE_ARN \
  --environment Variables="{TABLE_NAME=$TABLE_NAME}" \
  --query 'FunctionArn' \
  --output text)

# =========================
# Step Function (arquivo real)
# =========================
echo "🔄 Criando Step Function..."

# substitui placeholder pelo ARN da lambda
sed "s|PROCESS_LAMBDA_ARN|$PROCESS_LAMBDA_ARN|g" \
  $ROOT_DIR/stepfunctions/state-machine.json > /tmp/sm.json

STATE_MACHINE_ARN=$(awslocal stepfunctions create-state-machine \
  --name $STATE_MACHINE_NAME \
  --definition file:///tmp/sm.json \
  --role-arn $ROLE_ARN \
  --query 'stateMachineArn' \
  --output text)

# atualiza lambda com ARN real
awslocal lambda update-function-configuration \
  --function-name sqs-trigger \
  --environment Variables="{STATE_MACHINE_ARN=$STATE_MACHINE_ARN}"

# =========================
# SQS -> Lambda
# =========================
QUEUE_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url $QUEUE_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

awslocal lambda create-event-source-mapping \
  --function-name sqs-trigger \
  --event-source-arn $QUEUE_ARN \
  --batch-size 1

echo "✅ Tudo pronto!"