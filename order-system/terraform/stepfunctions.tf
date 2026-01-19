resource "aws_cloudwatch_log_group" "sfn_lg" {
  name              = "/aws/vendedlogs/states/${var.project}-order-workflow"
  retention_in_days = 14
}

resource "aws_sfn_state_machine" "order_workflow" {
  name     = "${var.project}-order-workflow"
  role_arn = aws_iam_role.sfn_exec.arn

  tracing_configuration { enabled = true }

  logging_configuration {
    level                  = "ALL"
    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.sfn_lg.arn}:*"
  }

  definition = jsonencode({
    Comment = "SQS callback workflow: SFN waits while consumer processes."
    StartAt = "EnqueueToSQS"
    States = {
      EnqueueToSQS = {
        Type           = "Task"
        Resource       = "arn:aws:states:::sqs:sendMessage.waitForTaskToken"
        TimeoutSeconds = 300
        Parameters = {
          QueueUrl = aws_sqs_queue.order_queue.url
          MessageBody = {
            "taskToken.$" = "$$.Task.Token"
            "orderId.$"   = "$.orderId"
            "payload.$"   = "$"
          }
        }
        Catch = [
          { ErrorEquals = ["PaymentFailed"], Next = "Refund" },
          { ErrorEquals = ["InventoryFailed"], Next = "Refund" },
          { ErrorEquals = ["States.Timeout"], Next = "Refund" },
          { ErrorEquals = ["States.ALL"], Next = "Refund" }
        ]
        Next = "SendNotification"
      }

      SendNotification = {
        Type     = "Task"
        Resource = aws_lambda_function.send_notification.arn
        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2.0
        }]
        Catch = [{ ErrorEquals = ["States.ALL"], Next = "DoneWithNotifyError" }]
        End   = true
      }

      Refund = {
        Type     = "Task"
        Resource = aws_lambda_function.compensate_refund.arn
        Next     = "Restock"
      }

      Restock = {
        Type     = "Task"
        Resource = aws_lambda_function.compensate_restock.arn
        Next     = "FailState"
      }

      DoneWithNotifyError = { Type = "Pass", End = true }

      FailState = { Type = "Fail", Error = "OrderFailed", Cause = "Compensation executed" }
    }
  })
}
