import os, time
import boto3

ddb = boto3.resource("dynamodb")
TABLE = os.environ["ORDERS_TABLE"]

def lambda_handler(event, context):
    order_id = event.get("orderId")
    if not order_id:
        return {"refunded": False, "reason": "Missing orderId"}

    table = ddb.Table(TABLE)
    now = int(time.time())
    table.update_item(
        Key={"pk": f"ORDER#{order_id}", "sk": f"META#{order_id}"},
        UpdateExpression="SET #s=:s, gsi1pk=:g, gsi1sk=:t, refundedAt=:r",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":s": "REFUNDED",
            ":g": "STATUS#REFUNDED",
            ":t": str(now),
            ":r": now
        },
    )
    return {"orderId": order_id, "refunded": True}
