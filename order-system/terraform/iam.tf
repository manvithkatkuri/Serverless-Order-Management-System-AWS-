resource "aws_iam_role" "lambda_exec" {
  name = "${var.project}-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project}-lambda-policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Logs
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      },
      # X-Ray
      {
        Effect   = "Allow",
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"],
        Resource = "*"
      },
      # DynamoDB read/write + GSI
      {
        Effect = "Allow",
        Action = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:DescribeTable"],
        Resource = [
          aws_dynamodb_table.orders.arn,
          "${aws_dynamodb_table.orders.arn}/index/*"
        ]
      },
      # Start Step Functions (create_order)
      {
        Effect   = "Allow",
        Action   = ["states:StartExecution"],
        Resource = [aws_sfn_state_machine.order_workflow.arn]
      },
      # SQS consume (process_payment)
      {
        Effect   = "Allow",
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ChangeMessageVisibility"],
        Resource = [aws_sqs_queue.order_queue.arn]
      },
      # Invoke update_inventory from process_payment
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = [aws_lambda_function.update_inventory.arn]
      },
      # SNS publish (send_notification)
      {
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = [aws_sns_topic.order_notifications.arn]
      },
      # Step Functions callback (process_payment)
      {
        Effect   = "Allow",
        Action   = ["states:SendTaskSuccess", "states:SendTaskFailure", "states:SendTaskHeartbeat"],
        Resource = "*"
      },
      # CloudWatch metrics (optional)
      {
        Effect   = "Allow",
        Action   = ["cloudwatch:PutMetricData"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "sfn_exec" {
  name = "${var.project}-sfn-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "${var.project}-sfn-policy"
  role = aws_iam_role.sfn_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # send message to SQS with callback token
      {
        Effect   = "Allow",
        Action   = ["sqs:SendMessage"],
        Resource = [aws_sqs_queue.order_queue.arn]
      },
      # invoke notification + compensation lambdas
      {
        Effect = "Allow",
        Action = ["lambda:InvokeFunction"],
        Resource = [
          aws_lambda_function.send_notification.arn,
          aws_lambda_function.compensate_refund.arn,
          aws_lambda_function.compensate_restock.arn
        ]
      },
      # X-Ray + logging delivery for SFN
      {
        Effect   = "Allow",
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogDelivery", "logs:GetLogDelivery", "logs:UpdateLogDelivery", "logs:DeleteLogDelivery", "logs:ListLogDeliveries", "logs:PutResourcePolicy", "logs:DescribeResourcePolicies", "logs:DescribeLogGroups"],
        Resource = "*"
      }
    ]
  })
}
