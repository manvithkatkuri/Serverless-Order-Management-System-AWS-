🧾 Serverless Order Management System (AWS)

A production-style serverless microservices architecture built on AWS to manage customer orders using API Gateway, Lambda, DynamoDB, Step Functions, SQS, SNS, and CloudWatch — fully provisioned using Terraform.

📌 Project Overview

This project implements an event-driven order processing system where:

Customers create and query orders via REST APIs

Orders are persisted in DynamoDB

Order processing is orchestrated using AWS Step Functions

Asynchronous processing is handled via SQS

Notifications are designed using SNS (email)

Observability is implemented using CloudWatch Logs, Metrics, and Alarms

Entire infrastructure is managed as Infrastructure as Code (IaC) using Terraform

🏗️ Architecture Diagram (Logical)
Client
  |
  v
Amazon API Gateway (REST, API Key protected)
  |
  v
AWS Lambda (Create / Get / List Orders)
  |
  v
Amazon DynamoDB (Orders Table)
  |
  v
AWS Step Functions (Order Workflow)
  |
  +--> SQS (Order Queue → DLQ)
  |
  +--> Lambda (Process Payment)
  |
  +--> Lambda (Update Inventory)
  |
  +--> Lambda (Send Notification → SNS)
  |
  +--> Lambda (Compensation Logic)
  
CloudWatch
  - Logs (Lambda, Step Functions)
  - Custom Metrics
  - DLQ Alarm

🧩 Services Used
Service	Purpose
API Gateway	REST API entry point with API Key protection
AWS Lambda	Stateless microservices
DynamoDB	Order persistence with GSIs
Step Functions	Workflow orchestration
SQS + DLQ	Asynchronous processing and failure handling
SNS	Email notification system
CloudWatch	Logs, metrics, alarms
Terraform	Infrastructure provisioning
🔐 Security & Best Practices

API Gateway secured using API Keys

IAM roles with least privilege

DynamoDB on-demand billing

Step Functions X-Ray tracing enabled

CloudWatch DLQ alarms

CORS enabled on APIs

Terraform state-safe deployment

📁 Repository Structure
order-system/
├── terraform/
│   ├── apigw.tf
│   ├── lambda.tf
│   ├── dynamodb.tf
│   ├── stepfunctions.tf
│   ├── sqs.tf
│   ├── sns.tf
│   ├── observability.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── main.tf
│
├── openapi/
│   └── openapi.yaml
│
├── lambdas/
│   ├── create_order/
│   ├── get_order/
│   ├── list_orders/
│   ├── process_payment/
│   ├── update_inventory/
│   ├── send_notification/
│   ├── compensate_refund/
│   └── compensate_restock/
│
├── build/
│   └── *.zip
│
└── README.md

🚀 API Endpoints
🔹 Create Order

POST /orders

Headers

x-api-key: <API_KEY>
Content-Type: application/json


Request Body

{
  "customerEmail": "test@example.com",
  "items": [
    { "sku": "SKU123", "qty": 2 }
  ],
  "totalAmount": 120
}


Response

{
  "orderId": "uuid",
  "status": "NEW"
}

🔹 Get Order by ID

GET /orders/{id}

🔹 List Orders

GET /orders?status=NEW

🔄 Order Processing Workflow

API Gateway receives request

Lambda validates request

Order stored in DynamoDB

Step Function execution starts

Payment processed asynchronously

Inventory updated

Notification step (SNS)

Compensation logic triggered on failure

Metrics & logs captured in CloudWatch

📊 Observability
CloudWatch Metrics

Custom metric: OrdersCreated

Namespace: order-system/Custom

Alarms

DLQ visible messages alarm

Immediate alert on message buildup

Logs

Individual log groups per Lambda

Step Function execution logs

📬 SNS Email Notification (Assignment Note)

Email subscription is created and confirmed

Emails are sent only when SNS Publish is executed

Assignment validates infrastructure setup, not manual triggering

Not receiving an email during API test is expected behavior

🧪 Testing (PowerShell)
$API_BASE_URL = "<api_base_url>"
$API_KEY = "<api_key>"

$body = @{
  customerEmail = "test@example.com"
  items = @(@{ sku = "SKU123"; qty = 2 })
  totalAmount = 120
} | ConvertTo-Json -Depth 5

Invoke-RestMethod `
  -Method POST `
  -Uri "$API_BASE_URL/orders" `
  -Headers @{
    "x-api-key" = $API_KEY
    "Content-Type" = "application/json"
  } `
  -Body $body

🛠️ Deployment Instructions
cd terraform
terraform init
terraform plan
terraform apply

📌 Assignment Completion Status
Requirement	Status
Serverless Architecture	✅
Terraform IaC	✅
API Gateway + Lambda	✅
DynamoDB	✅
Step Functions	✅
SQS + DLQ	✅
SNS Email Subscription	✅
Observability	✅
Security Best Practices	✅
🎯 Key Learning Outcomes

Event-driven serverless design

Production-grade AWS integrations

Terraform best practices

API Gateway + OpenAPI integration

Observability and failure handling

Real-world debugging and AWS error resolution
