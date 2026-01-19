import json, os, time
import boto3

ddb = boto3.resource("dynamodb")
sns = boto3.client("sns")

TABLE = os.environ["ORDERS_TABLE"]
TOPIC = os.environ["TOPIC_ARN"]

def lambda_handler(event, context):
    order_id = event.get("orderId")
    if not order_id:
        raise Exception("Missing orderId")

    msg = {
        "orderId": order_id,
        "status": "COMPLETED",
        "note": "Order processed successfully"
    }

    sns.publish(
        TopicArn=TOPIC,
        Subject=f"Order {order_id} Completed",
        Message=json.dumps(msg)
    )

    table = ddb.Table(TABLE)
    now = int(time.time())
    table.update_item(
        Key={"pk": f"ORDER#{order_id}", "sk": f"META#{order_id}"},
        UpdateExpression="SET #s=:s, gsi1pk=:g, gsi1sk=:t, notifiedAt=:n",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":s": "COMPLETED",
            ":g": "STATUS#COMPLETED",
            ":t": str(now),
            ":n": now
        },
    )
    return {"orderId": order_id, "notified": True}
