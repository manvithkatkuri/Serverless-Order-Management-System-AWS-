locals {
  runtime = "python3.11"
}

# ---- ZIP PACKAGING (expects ../build exists) ----
data "archive_file" "create_order_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/create_order"
  output_path = "${path.module}/../build/create_order.zip"
}
data "archive_file" "get_order_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/get_order"
  output_path = "${path.module}/../build/get_order.zip"
}
data "archive_file" "list_orders_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/list_orders"
  output_path = "${path.module}/../build/list_orders.zip"
}
data "archive_file" "process_payment_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/process_payment"
  output_path = "${path.module}/../build/process_payment.zip"
}
data "archive_file" "update_inventory_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/update_inventory"
  output_path = "${path.module}/../build/update_inventory.zip"
}
data "archive_file" "send_notification_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/send_notification"
  output_path = "${path.module}/../build/send_notification.zip"
}
data "archive_file" "comp_refund_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/compensate_refund"
  output_path = "${path.module}/../build/compensate_refund.zip"
}
data "archive_file" "comp_restock_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/compensate_restock"
  output_path = "${path.module}/../build/compensate_restock.zip"
}

# ---- LAMBDAS ----
resource "aws_lambda_function" "create_order" {
  function_name    = "${var.project}-create-order"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = local.runtime
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.create_order_zip.output_path
  source_code_hash = data.archive_file.create_order_zip.output_base64sha256
  timeout          = 15
  memory_size      = 256

  environment {
    variables = {
      ORDERS_TABLE      = aws_dynamodb_table.orders.name
      STATE_MACHINE_ARN = aws_sfn_state_machine.order_workflow.arn
    }
  }
  tracing_config { mode = "Active" }
}

resource "aws_lambda_function" "get_order" {
  function_name    = "${var.project}-get-order"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = local.runtime
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.get_order_zip.output_path
  source_code_hash = data.archive_file.get_order_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256
  environment { variables = { ORDERS_TABLE = aws_dynamodb_table.orders.name } }
  tracing_config { mode = "Active" }
}

resource "aws_lambda_function" "list_orders" {
  function_name    = "${var.project}-list-orders"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = local.runtime
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.list_orders_zip.output_path
  source_code_hash = data.archive_file.list_orders_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256
  environment {
    variables = {
      ORDERS_TABLE = aws_dynamodb_table.orders.name
      GSI_NAME     = "gsi_status"
    }
  }
  tracing_config { mode = "Active" }
}

resource "aws_lambda_function" "update_inventory" {
  function_name    = "${var.project}-update-inventory"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = local.runtime
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.update_inventory_zip.output_path
  source_code_hash = data.archive_file.update_inventory_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256
  environment { variables = { ORDERS_TABLE = aws_dynamodb_table.orders.name } }
  tracing_config { mode = "Active" }
}

resource "aws_lambda_function" "process_payment" {
  function_name    = "${var.project}-process-payment"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = local.runtime
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.process_payment_zip.output_path
  source_code_hash = data.archive_file.process_payment_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      ORDERS_TABLE         = aws_dynamodb_table.orders.name
      UPDATE_INVENTORY_ARN = aws_lambda_function.update_inventory.arn
    }
  }
  tracing_config { mode = "Active" }
}

resource "aws_lambda_function" "send_notification" {
  function_name    = "${var.project}-send-notification"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = local.runtime
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.send_notification_zip.output_path
  source_code_hash = data.archive_file.send_notification_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      ORDERS_TABLE = aws_dynamodb_table.orders.name
      TOPIC_ARN    = aws_sns_topic.order_notifications.arn
    }
  }
  tracing_config { mode = "Active" }
}

resource "aws_lambda_function" "compensate_refund" {
  function_name    = "${var.project}-compensate-refund"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = local.runtime
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.comp_refund_zip.output_path
  source_code_hash = data.archive_file.comp_refund_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256
  environment { variables = { ORDERS_TABLE = aws_dynamodb_table.orders.name } }
  tracing_config { mode = "Active" }
}

resource "aws_lambda_function" "compensate_restock" {
  function_name    = "${var.project}-compensate-restock"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = local.runtime
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.comp_restock_zip.output_path
  source_code_hash = data.archive_file.comp_restock_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256
  environment { variables = { ORDERS_TABLE = aws_dynamodb_table.orders.name } }
  tracing_config { mode = "Active" }
}

# ---- SQS EVENT SOURCE -> process_payment ----
resource "aws_lambda_event_source_mapping" "sqs_to_process_payment" {
  event_source_arn = aws_sqs_queue.order_queue.arn
  function_name    = aws_lambda_function.process_payment.arn
  batch_size       = 5
  enabled          = true
}

# ---- LOG GROUPS ----
resource "aws_cloudwatch_log_group" "lg_create" {
  name              = "/aws/lambda/${aws_lambda_function.create_order.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lg_get" {
  name              = "/aws/lambda/${aws_lambda_function.get_order.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lg_list" {
  name              = "/aws/lambda/${aws_lambda_function.list_orders.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lg_proc" {
  name              = "/aws/lambda/${aws_lambda_function.process_payment.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lg_inv" {
  name              = "/aws/lambda/${aws_lambda_function.update_inventory.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lg_notif" {
  name              = "/aws/lambda/${aws_lambda_function.send_notification.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lg_ref" {
  name              = "/aws/lambda/${aws_lambda_function.compensate_refund.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lg_res" {
  name              = "/aws/lambda/${aws_lambda_function.compensate_restock.function_name}"
  retention_in_days = 14
}
