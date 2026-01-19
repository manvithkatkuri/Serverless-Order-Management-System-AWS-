┌──────────────┐
│   Client     │
│ (Postman /   │
│  Browser)    │
└──────┬───────┘
       │
       │  POST /orders
       │  GET  /orders
       │  GET  /orders/{id}
       │
┌──────▼──────────────────────────┐
│        API Gateway (REST)        │
│  - API Key                      │
│  - Request Validation           │
│  - CORS                         │
└──────┬──────────────────────────┘
       │
       │ invoke
       ▼
┌──────────────────────────┐
│  Lambda: create_order    │
│  - Validate request      │
│  - Save order (NEW)      │
│  - Start Step Function   │
└──────┬───────────────────┘
       │
       │ StartExecution
       ▼
┌────────────────────────────────────────┐
│   Step Functions (Order Workflow)       │
│                                        │
│  1. Send message to SQS                 │
│     (waitForTaskToken)                 │
│                                        │
│  2. WAIT (tracks order state)           │
└──────┬─────────────────────────────────┘
       │
       │ SQS message
       │ (order + taskToken)
       ▼
┌──────────────────────────┐
│        SQS Queue         │
│  - Async buffer          │
│  - Retry                 │
│  - DLQ on failure        │
└──────┬───────────────────┘
       │
       │ trigger
       ▼
┌──────────────────────────┐
│ Lambda: process_payment  │
│ (SQS Consumer)           │
│                          │
│ - Update status          │
│ - Process payment        │
│ - Call update_inventory  │
│ - Callback StepFn        │
└──────┬───────────────────┘
       │
       │ Invoke
       ▼
┌──────────────────────────┐
│ Lambda: update_inventory │
│ - Update stock           │
└──────┬───────────────────┘
       │
       │ SendTaskSuccess / Failure
       ▼
┌────────────────────────────────────────┐
│   Step Functions (resumes execution)    │
│                                        │
│  Success → Send Notification            │
│  Failure → Refund + Restock             │
└──────┬─────────────────────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Lambda: send_notification│
│ - Publish to SNS         │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│     SNS Topic            │
│ - Email / SMS fan-out    │
└──────────────────────────┘
