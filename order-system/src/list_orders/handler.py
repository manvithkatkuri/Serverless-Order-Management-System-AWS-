import json, os, time
import boto3
from boto3.dynamodb.conditions import Key

ddb = boto3.resource("dynamodb")
TABLE = os.environ["ORDERS_TABLE"]
GSI = os.environ.get("GSI_NAME", "gsi_status")

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
        qs = event.get("queryStringParameters") or {}
        status = qs.get("status")

        table = ddb.Table(TABLE)

        if status:
            gsi_pk = f"STATUS#{status}"
            r = table.query(
                IndexName=GSI,
                KeyConditionExpression=Key("gsi1pk").eq(gsi_pk),
                Limit=50,
                ScanIndexForward=False
            )
            return resp(200, {"items": r.get("Items", [])})

        # fallback: scan (OK for assignment; in prod you’d avoid big scans)
        r = table.scan(Limit=50)
        return resp(200, {"items": r.get("Items", [])})

    except Exception as e:
        print("ERROR", str(e))
        return resp(500, {"message": "Internal error", "error": str(e)})
