import os
import json
import uuid
import boto3

dynamodb = boto3.resource('dynamodb', endpoint_url=os.getenv(
    "DYNAMODB_ENDPOINT", "http://localstack:4566"))
table = dynamodb.Table(os.getenv("DYNAMODB_TABLE", "my-table"))


def handler(event, _):
    print("⚙️ Evento recebido:")
    print(json.dumps(event))
    __save_to_dynamodb(event)
    return {"status": "processed"}


def __save_to_dynamodb(event):
    item = {
        "id": str(uuid.uuid4()),
        "payload": event
    }

    try:
        table.put_item(Item=item)
        print("💾 Salvo no DynamoDB:", item)
    except Exception as e:
        print("❌ Erro ao salvar no DynamoDB:", str(e))
