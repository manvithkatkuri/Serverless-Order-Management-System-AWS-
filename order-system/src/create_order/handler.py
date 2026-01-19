import json, os, uuid, time
import boto3

ddb = boto3.resource("dynamodb")
sfn = boto3.client("stepfunctions")

TABLE = os.environ["ORDERS_TABLE"]
SFN_ARN = os.environ["STATE_MACHINE_ARN"]

def resp(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Api-Key",
            "Access-Control-Allow-Methods": "OPTIONS,GET,POST",
        },
        "body": json.dumps(body),
    }

def lambda_handler(event, context):
    try:
        if "body" not in event or not event["body"]:
            return resp(400, {"message": "Missing request body"})
        body = json.loads(event["body"])

        for k in ["customerEmail", "items", "totalAmount"]:
            if k not in body:
                return resp(400, {"message": f"Missing required field: {k}"})
        if not isinstance(body["items"], list) or len(body["items"]) == 0:
            return resp(400, {"message": "items must be a non-empty array"})

        order_id = str(uuid.uuid4())
        now = int(time.time())

        item = {
            "pk": f"ORDER#{order_id}",
            "sk": f"META#{order_id}",
            "orderId": order_id,
            "status": "NEW",
            "gsi1pk": "STATUS#NEW",
            "gsi1sk": str(now),
            "createdAt": now,
            "customerEmail": body["customerEmail"],
            "items": body["items"],
            "totalAmount": body["totalAmount"],
        }

        table = ddb.Table(TABLE)
        table.put_item(Item=item)

        print("ORDER_CREATED", order_id)

        sfn.start_execution(
            stateMachineArn=SFN_ARN,
            input=json.dumps({
                "orderId": order_id,
                "customerEmail": body["customerEmail"],
                "items": body["items"],
                "totalAmount": body["totalAmount"],
                "createdAt": now
            })
        )

        return resp(200, {"orderId": order_id, "status": "NEW"})

    except Exception as e:
        print("ERROR", str(e))
        return resp(500, {"message": "Internal error", "error": str(e)})
