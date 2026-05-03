import json
from handler import handler

def __run_lambda_tests():
    """
    Executa testes para a função lambda.
    Rodar o seguinte comando para executar os testes: python -m test.handler_test
    """
    test_event = {
        "Records": [
            {
                "body": json.dumps({"message": "Hello from SQS!"})
            }
        ]
    }

    handler(test_event, None)


if __name__ == "__main__":
    __run_lambda_tests()
