import json, os, time
import boto3

ddb = boto3.resource("dynamodb")
TABLE = os.environ["ORDERS_TABLE"]

def lambda_handler(event, context):
    """
    event: { "orderId": "...", "items": [...], "failInventory": true/false }
    """
    order_id = event.get("orderId")
    if not order_id:
        raise Exception("Missing orderId")

    if event.get("failInventory"):
        raise Exception("Simulated inventory failure")

    table = ddb.Table(TABLE)
    now = int(time.time())

    table.update_item(
        Key={"pk": f"ORDER#{order_id}", "sk": f"META#{order_id}"},
        UpdateExpression="SET #s=:s, gsi1pk=:g, gsi1sk=:t, inventoryUpdatedAt=:t",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":s": "INVENTORY_UPDATED",
            ":g": "STATUS#INVENTORY_UPDATED",
            ":t": str(now),
        },
    )

    return {"orderId": order_id, "inventory": "updated"}
