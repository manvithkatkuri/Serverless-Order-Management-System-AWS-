import json, os
import boto3

ddb = boto3.resource("dynamodb")
TABLE = os.environ["ORDERS_TABLE"]

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
        order_id = (event.get("pathParameters") or {}).get("id")
        if not order_id:
            return resp(400, {"message": "Missing order id"})

        table = ddb.Table(TABLE)
        r = table.get_item(Key={"pk": f"ORDER#{order_id}", "sk": f"META#{order_id}"})
        if "Item" not in r:
            return resp(404, {"message": "Order not found"})

        return resp(200, r["Item"])
    except Exception as e:
        print("ERROR", str(e))
        return resp(500, {"message": "Internal error", "error": str(e)})
