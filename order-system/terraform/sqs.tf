resource "aws_sqs_queue" "order_dlq" {
  name                      = "${var.project}-order-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "order_queue" {
  name                       = "${var.project}-order-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_dlq.arn
    maxReceiveCount     = 5
  })
}
