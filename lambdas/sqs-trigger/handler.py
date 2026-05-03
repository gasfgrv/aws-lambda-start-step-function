import json
import os
import boto3

stepfunctions = boto3.client(
    'stepfunctions', endpoint_url=os.getenv("STEP_FUNCTIONS_ENDPOINT", "http://localstack:4566"))


def handler(event, _):
    print("📥 Evento SQS:")
    print(json.dumps(event))

    for record in event.get("Records", []):
        body = json.loads(record["body"])
        __start_workflow(body)

    return {"status": "ok"}


def __start_workflow(body):
    print("➡️ Enviando para Step Function:", body)

    try:
        response = stepfunctions.start_execution(
            stateMachineArn=os.getenv(
                "STEP_FUNCTION_ARN", "arn:aws:states:us-east-1:000000000000:stateMachine:my-state-machine"),
            input=json.dumps(body)
        )

        print("✅ Execution ARN:", response["executionArn"])
    except Exception as e:
        print("❌ Erro ao iniciar Step Function:", str(e))
