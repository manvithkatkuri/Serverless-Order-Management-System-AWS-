output "api_base_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}


output "api_key_value" {
  value     = aws_api_gateway_api_key.client_key.value
  sensitive = true
}

output "orders_table" {
  value = aws_dynamodb_table.orders.name
}

output "order_queue_url" {
  value = aws_sqs_queue.order_queue.url
}

output "sns_topic_arn" {
  value = aws_sns_topic.order_notifications.arn
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.order_workflow.arn
}
