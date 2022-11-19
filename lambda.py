import json
import os

import boto3

account_number = os.environ['ACC_NUM']
statemachine_name = os.environ['STATE_MACHINE']
aws_region = os.environ['REGION']


def lambda_handler(event, context):
    record = event['Records'][0]
    payload = record['body']
    sqs_message = json.dumps(payload, default=str)
    response = __start_state_machine(f"arn:aws:states:{aws_region}:{account_number}:stateMachine:{statemachine_name}",
                                     sqs_message)
    return {
        'status': response,
        'body': payload
    }


def __start_state_machine(state_machine_arn, sqs_message):
    client = boto3.client('stepfunctions')
    result = client.start_execution(stateMachineArn=state_machine_arn, input=sqs_message)
    return result['ResponseMetadata']['HTTPStatusCode']
