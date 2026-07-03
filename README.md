# Real-Time E-Commerce Analytics Pipeline

AWS streaming pipeline processing 42M+ events using Kinesis → Lambda → Redshift Serverless → QuickSight. End-to-end latency under 30 seconds.

## Data

**Dataset:** [eCommerce Behavior Data from Multi-Category Store](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store)  
**Source:** Kaggle (mkechinov)  
**Size:** 42M+ rows

Place the file at `data/raw/2019-Oct.csv` before running the pipeline.

### Schema

| Column | Type | Description |
|--------|------|-------------|
| `event_time` | timestamp | When the event occurred |
| `event_type` | string | `view`, `cart`, `purchase`, `remove_from_cart` |
| `product_id` | string | Unique product identifier |
| `price` | float | Product price |
| `user_id` | string | Unique user identifier |
| `user_session` | string | Session identifier |

## Architecture
Kinesis Data Streams → Lambda → Redshift Serverless
                              → Firehose → S3

## Stack
- Kinesis Data Streams
- AWS Lambda (Python 3.11)
- Redshift Serverless
- Kinesis Firehose
- S3
- API Gateway
- Terraform (IaC)
- QuickSight

## QuickSight Chart

![QuickSight Dashboard](assets/quicksight_chart.png)

## Redshift Query

![Redshift Query Results](assets/redshift_query.png)

## Setup
**For Windows users:** all `make` commands require `make` to be installed.
1. Copy `terraform/envs/dev.tfvars.example` to `terraform/envs/dev.tfvars` and fill in your values
2. Run `make init`
3. Run `make up-storage`
4. Run `make up-compute`