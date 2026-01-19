# Alarm if DLQ has messages
resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "${var.project}-dlq-visible-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0

  dimensions = {
    QueueName = aws_sqs_queue.order_dlq.name
  }
}

# Example metric filter for "ORDER_CREATED" logs (create_order lambda)
resource "aws_cloudwatch_log_metric_filter" "order_created_metric" {
  name           = "${var.project}-order-created"
  log_group_name = aws_cloudwatch_log_group.lg_create.name
  pattern        = "ORDER_CREATED"

  metric_transformation {
    name      = "OrdersCreated"
    namespace = "${var.project}/Custom"
    value     = "1"
  }

  depends_on = [
    aws_cloudwatch_log_group.lg_create
  ]
}

