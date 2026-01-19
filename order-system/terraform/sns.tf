resource "aws_sns_topic" "order_notifications" {
  name = "${var.project}-order-notifications"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
