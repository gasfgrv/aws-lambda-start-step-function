# aws-lambda-start-step-function

Exemplo de uma AWS Lambda feita com Python que inicia o fluxo de uma AWS Step Function.

## Arquivo Amazon States Language

```json
{
  "Comment": "Exemplo de ter um trigger a partir de uma fila SQS+Lambda",
  "StartAt": "Solicita H9",
  "States": {
    "Solicita H9": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "arn:aws:lambda:us-east-1:087347546867:function:lambdaTrataDados:$LATEST",
        "Payload": {
          "Input.$": "$"
        }
      },
      "Next": "Atualiza BD"
    },
    "Atualiza BD": {
      "Type": "Pass",
      "Parameters": {
        "DadosTabela": {
          "requestId.$": "$.SdkResponseMetadata.RequestId",
          "statusCode.$": "$.Payload.statusCode",
          "body.$": "$.Payload.body.Input"
        }
      },
      "End": true
    }
  }
}
```
## Permissão para a Lambda rodar a Step Function

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "states:StartExecution",
            "Resource": "arn:aws:states:aws-zone:aws-account:stateMachine:StateMachineName"
        }
    ]
}
```
