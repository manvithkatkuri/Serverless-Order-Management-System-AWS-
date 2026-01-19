import json, os, time
import boto3

ddb = boto3.resource("dynamodb")
sf  = boto3.client("stepfunctions")
lam = boto3.client("lambda")

TABLE = os.environ["ORDERS_TABLE"]
UPDATE_INV_ARN = os.environ["UPDATE_INVENTORY_ARN"]

def update_status(order_id: str, status: str):
    table = ddb.Table(TABLE)
    now = int(time.time())
    table.update_item(
        Key={"pk": f"ORDER#{order_id}", "sk": f"META#{order_id}"},
        UpdateExpression="SET #s=:s, gsi1pk=:g, gsi1sk=:t, updatedAt=:u",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":s": status,
            ":g": f"STATUS#{status}",
            ":t": str(now),
            ":u": now
        },
    )

def lambda_handler(event, context):
    for record in event.get("Records", []):
        body = json.loads(record["body"])
        token = body["taskToken"]
        payload = body.get("payload", {})
        order_id = payload.get("orderId") or body.get("orderId")

        try:
            if not order_id:
                raise Exception("Missing orderId")

            update_status(order_id, "PROCESSING")

            # simulate payment
            if payload.get("failPayment"):
                raise Exception("Simulated payment failure")

            update_status(order_id, "PAID")

            # invoke update_inventory lambda
            inv_event = {
                "orderId": order_id,
                "items": payload.get("items", []),
                "failInventory": payload.get("failInventory", False)
            }
            inv_resp = lam.invoke(
                FunctionName=UPDATE_INV_ARN,
                InvocationType="RequestResponse",
                Payload=json.dumps(inv_event).encode("utf-8"),
            )
            inv_payload = json.loads(inv_resp["Payload"].read().decode("utf-8"))
            if "errorMessage" in inv_payload:
                raise Exception(inv_payload["errorMessage"])

            # callback success to SFN
            sf.send_task_success(
                taskToken=token,
                output=json.dumps({
                    "orderId": order_id,
                    "status": "PAYMENT_AND_INVENTORY_OK"
                })
            )

        except Exception as e:
            err = str(e)
            print("ERROR", err)

            # decide error type for SFN Catch
            error_name = "PaymentFailed"
            if "inventory" in err.lower():
                error_name = "InventoryFailed"

            update_status(order_id or "UNKNOWN", "FAILED")

            sf.send_task_failure(
                taskToken=token,
                error=error_name,
                cause=err[:1000]
            )
