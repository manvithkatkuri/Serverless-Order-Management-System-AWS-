# 🧾 Serverless Order Management System (AWS)

A **production-style serverless microservices architecture** built on AWS to manage customer orders using **API Gateway, Lambda, DynamoDB, Step Functions, SQS, SNS, and CloudWatch** — fully provisioned using **Terraform**.

---

## 📌 Project Overview

This project implements an **event-driven order processing system** where:

- Customers create and query orders via REST APIs  
- Orders are persisted in **Amazon DynamoDB**  
- Order processing is orchestrated using **AWS Step Functions**  
- Asynchronous processing is handled via **Amazon SQS**  
- Notifications are designed using **Amazon SNS (Email)**  
- Observability is implemented using **CloudWatch Logs, Metrics, and Alarms**  
- Entire infrastructure is managed as **Infrastructure as Code (IaC)** using **Terraform**

---

## 🏗️ Architecture Diagram (Logical)

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
+--> Amazon SQS (Order Queue → DLQ)
|
+--> Lambda (Process Payment)
|
+--> Lambda (Update Inventory)
|
+--> Lambda (Send Notification → SNS)
|
+--> Lambda (Compensation Logic)

CloudWatch

Logs (Lambda, Step Functions)

Custom Metrics

DLQ Alarm



---

## 🧩 AWS Services Used

| Service | Purpose |
|------|-------|
| Amazon API Gateway | REST API entry point with API Key protection |
| AWS Lambda | Stateless microservices |
| Amazon DynamoDB | Order persistence with GSIs |
| AWS Step Functions | Workflow orchestration |
| Amazon SQS + DLQ | Asynchronous processing and failure handling |
| Amazon SNS | Email notification system |
| Amazon CloudWatch | Logs, metrics, alarms |
| Terraform | Infrastructure provisioning |

---

## 🔐 Security & Best Practices

- API Gateway secured using **API Keys**
- IAM roles with **least privilege**
- DynamoDB **on-demand billing**
- Step Functions **X-Ray tracing enabled**
- CloudWatch **DLQ alarms**
- **CORS** enabled on APIs
- Terraform **state-safe deployments**

---

## 📁 Repository Structure

order-system/
├── terraform/
│ ├── apigw.tf
│ ├── lambda.tf
│ ├── dynamodb.tf
│ ├── stepfunctions.tf
│ ├── sqs.tf
│ ├── sns.tf
│ ├── observability.tf
│ ├── variables.tf
│ ├── outputs.tf
│ └── main.tf
│
├── openapi/
│ └── openapi.yaml
│
├── lambdas/
│ ├── create_order/
│ ├── get_order/
│ ├── list_orders/
│ ├── process_payment/
│ ├── update_inventory/
│ ├── send_notification/
│ ├── compensate_refund/
│ └── compensate_restock/
│
├── build/
│ └── *.zip
│
└── README.md




---

## 🚀 API Endpoints

### 🔹 Create Order
**POST** `/orders`

**Headers**

x-api-key: <API_KEY>
Content-Type: application/json


**Request Body**
```json
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

**Order Processing Workflow**

API Gateway receives request

Lambda validates request

Order stored in DynamoDB

Step Function execution starts

Payment processed asynchronously

Inventory updated

Notification step (SNS)

Compensation logic triggered on failure

Metrics & logs captured in CloudWatch

**Observability**
CloudWatch Metrics

Custom Metric: OrdersCreated

Namespace: order-system/Custom

Alarms

DLQ visible messages alarm

Alarm triggers when DLQ contains visible messages

Logs

Individual log groups per Lambda

Step Function execution logs

**SNS Email Notification (Assignment Note)**

Email subscription is created and confirmed

Emails are sent only when SNS Publish is executed

Assignment validates infrastructure setup, not manual triggering

Not receiving an email during API test is expected behavior

**Deployment Instructions**
Prerequisites

Terraform >= 1.5

AWS CLI configured (aws configure)

IAM user/role with permissions for API Gateway, Lambda, DynamoDB, Step Functions, SQS, SNS, CloudWatch, IAM

Deploy
cd terraform
terraform init
terraform plan
terraform apply

Outputs

After apply, Terraform outputs values like:

api_base_url

api_key_value

orders_table

order_queue_url

sns_topic_arn

state_machine_arn

**Testing (PowerShell)**
Set values from Terraform outputs
$API_BASE_URL = "https://<your-api-id>.execute-api.us-east-1.amazonaws.com/prod"
$API_KEY = "<your-api-key>"

1) Create an Order
$body = @{
  customerEmail = "test@example.com"
  items = @(
    @{ sku = "SKU123"; qty = 2 }
    @{ sku = "SKU999"; qty = 1 }
  )
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

2) Get Order by ID
$orderId = "<paste-order-id>"
Invoke-RestMethod `
  -Method GET `
  -Uri "$API_BASE_URL/orders/$orderId" `
  -Headers @{ "x-api-key" = $API_KEY }

3) List Orders (optional status filter)
Invoke-RestMethod `
  -Method GET `
  -Uri "$API_BASE_URL/orders?status=NEW" `
  -Headers @{ "x-api-key" = $API_KEY }
