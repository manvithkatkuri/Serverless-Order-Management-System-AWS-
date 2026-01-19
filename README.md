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

