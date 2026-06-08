import base64
import json
import os
from decimal import Decimal
from urllib.parse import unquote

import boto3
from botocore.exceptions import ClientError


TABLE_NAME = os.environ.get("TABLE_NAME")
AWS_ENDPOINT_URL = os.environ.get("AWS_ENDPOINT_URL")


def dynamodb_table():
    if not TABLE_NAME:
        raise RuntimeError("TABLE_NAME environment variable is required")

    resource_args = {}
    if AWS_ENDPOINT_URL:
        resource_args["endpoint_url"] = AWS_ENDPOINT_URL

    return boto3.resource("dynamodb", **resource_args).Table(TABLE_NAME)


def response(status_code, body=None):
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body or {}, default=json_default),
    }


def json_default(value):
    if isinstance(value, Decimal):
        if value % 1 == 0:
            return int(value)
        return float(value)
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")


def parse_json_body(event):
    body = event.get("body")
    if not body:
        return {}

    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    try:
        return json.loads(body, parse_float=Decimal)
    except json.JSONDecodeError:
        raise ValueError("Request body must be valid JSON")


def path_segments(event):
    raw_path = event.get("rawPath") or event.get("path") or "/"
    segments = [unquote(part) for part in raw_path.split("/") if part]

    if segments and segments[0] != "users" and len(segments) > 1 and segments[1] == "users":
        segments = segments[1:]

    return segments


def user_id_from_request(event, segments):
    path_parameters = event.get("pathParameters") or {}
    query_parameters = event.get("queryStringParameters") or {}

    if len(segments) >= 2 and segments[0] == "users":
        return segments[1]

    return (
        path_parameters.get("UserId")
        or path_parameters.get("userId")
        or query_parameters.get("UserId")
        or query_parameters.get("userId")
    )


def handle_post(table, event):
    item = parse_json_body(event)
    user_id = item.get("UserId")
    if not user_id:
        return response(400, {"message": "UserId is required"})

    try:
        table.put_item(
            Item=item,
            ConditionExpression="attribute_not_exists(UserId)",
        )
    except ClientError as error:
        if error.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return response(409, {"message": "User already exists", "UserId": user_id})
        raise

    return response(201, {"item": item})


def handle_get(table, user_id):
    if user_id:
        result = table.get_item(Key={"UserId": user_id})
        item = result.get("Item")
        if not item:
            return response(404, {"message": "User not found", "UserId": user_id})
        return response(200, {"item": item})

    result = table.scan()
    items = result.get("Items", [])

    while "LastEvaluatedKey" in result:
        result = table.scan(ExclusiveStartKey=result["LastEvaluatedKey"])
        items.extend(result.get("Items", []))

    return response(200, {"items": items})


def handle_put(table, event, user_id):
    if not user_id:
        return response(400, {"message": "UserId is required"})

    body = parse_json_body(event)
    body["UserId"] = user_id
    attributes = {key: value for key, value in body.items() if key != "UserId"}

    if not attributes:
        return response(400, {"message": "At least one updatable field is required"})

    names = {f"#field{index}": key for index, key in enumerate(attributes)}
    values = {f":value{index}": value for index, value in enumerate(attributes.values())}
    update_expression = "SET " + ", ".join(
        f"{name} = :value{index}" for index, name in enumerate(names)
    )

    try:
        result = table.update_item(
            Key={"UserId": user_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
            ConditionExpression="attribute_exists(UserId)",
            ReturnValues="ALL_NEW",
        )
    except ClientError as error:
        if error.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return response(404, {"message": "User not found", "UserId": user_id})
        raise

    return response(200, {"item": result["Attributes"]})


def handle_delete(table, user_id):
    if not user_id:
        return response(400, {"message": "UserId is required"})

    try:
        table.delete_item(
            Key={"UserId": user_id},
            ConditionExpression="attribute_exists(UserId)",
        )
    except ClientError as error:
        if error.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return response(404, {"message": "User not found", "UserId": user_id})
        raise

    return response(200, {"deleted": True, "UserId": user_id})


def handler(event, context):
    try:
        method = event.get("requestContext", {}).get("http", {}).get("method")
        method = method or event.get("httpMethod", "")
        method = method.upper()

        segments = path_segments(event)
        if not segments or segments[0] != "users" or len(segments) > 2:
            return response(404, {"message": "Not found"})

        table = dynamodb_table()
        user_id = user_id_from_request(event, segments)

        if method == "POST" and len(segments) == 1:
            return handle_post(table, event)
        if method == "GET":
            return handle_get(table, user_id)
        if method == "PUT" and len(segments) == 2:
            return handle_put(table, event, user_id)
        if method == "DELETE" and len(segments) == 2:
            return handle_delete(table, user_id)

        return response(405, {"message": "Method not allowed"})
    except ValueError as error:
        return response(400, {"message": str(error)})
    except Exception as error:
        print(f"Unhandled error: {error}")
        return response(500, {"message": "Internal server error"})
