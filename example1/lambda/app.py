import json
import os

import boto3
from botocore.config import Config


DEFAULT_PARAMETER_PREFIX = "/exam1/dev"


def aws_client(service_name, endpoint_url=None):
    client_args = {}
    if endpoint_url:
        client_args["endpoint_url"] = endpoint_url
    if service_name == "s3" and endpoint_url:
        client_args["config"] = Config(s3={"addressing_style": "path"})
    return boto3.client(service_name, **client_args)


def get_parameter(ssm, name):
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response["Parameter"]["Value"]


def lambda_handler(event, context):
    parameter_prefix = os.environ.get("PARAMETER_PREFIX", DEFAULT_PARAMETER_PREFIX)
    endpoint_url = os.environ.get("AWS_ENDPOINT_URL")

    ssm = aws_client("ssm", endpoint_url=endpoint_url)

    queue_name = get_parameter(ssm, f"{parameter_prefix}/sqs/name")
    bucket_name = get_parameter(ssm, f"{parameter_prefix}/s3/name")

    sqs = aws_client("sqs", endpoint_url=endpoint_url)
    s3 = aws_client("s3", endpoint_url=endpoint_url)

    queue_url = sqs.get_queue_url(QueueName=queue_name)["QueueUrl"]
    response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=int(os.environ.get("MAX_MESSAGES", "10")),
    )

    messages = response.get("Messages", [])
    for message in messages:
        try:
            body = json.loads(message["Body"])
            object_id = body.get("id", message["MessageId"])
        except json.JSONDecodeError:
            object_id = message["MessageId"]

        s3.put_object(
            Bucket=bucket_name,
            Key=f"{object_id}.json",
            Body=message["Body"],
            ContentType="application/json",
        )
        sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message["ReceiptHandle"],
        )

    return {
        "processed": len(messages),
        "queue_name": queue_name,
        "bucket_name": bucket_name,
    }
