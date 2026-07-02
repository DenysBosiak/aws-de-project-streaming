import argparse
import base64
import csv
import json
import time
import uuid 
import boto3


EVENT_MAP = {
    "view": "page_view",
    "cart": "add_to_cart",
    "purchase": "purchase",
    "remove_from_cart": "remove_from_cart",
}


def parse_args():
    parser = argparse.ArgumentParser(description="Replay Kaggle events to Kinesis stream")
    parser.add_argument("--file", required=True, help="Path to the CSV file containing Kaggle events")
    parser.add_argument("--stream", required=True, help="Kinesis stream name")
    parser.add_argument("--limit", type=int, default=1000, help="Limit the number of records to send (for testing)")
    parser.add_argument("--batch", type=int, default=500, help="Number of records to send in each batch")
    parser.add_argument("--region", default="eu-north-1", help="AWS region")
    return parser.parse_args()


def map_row(row):
    return {
        "event_id": str(uuid.uuid4()),
        "user_id": row.get("user_id", "unknown"),
        "event_type": EVENT_MAP.get(row.get("event_type", "view"), "page_view"),
        "value": float(row.get("price", 0.0) or 0.0),  
        "product_id": row.get("product_id", ""),
        "brand": row.get("brand", ""),
    }


def main():
    args = parse_args()
    client = boto3.client("kinesis", region_name=args.region)
    batch, sent, errors = [], 0, 0

    with open(args.file, newline='', encoding='utf-8') as f:
        for i, row in enumerate(csv.DictReader(f)):
            if i >= args.limit:
                break
            payload = map_row(row)
            batch.append({
                "Data": json.dumps(payload).encode(),
                "PartitionKey": payload["user_id"]
            })

            if len(batch) == args.batch:
                response = client.put_records(StreamName=args.stream, Records=batch)
                errors += response.get('FailedRecordCount', 0)
                sent += len(batch) 
                print(f"Sent {sent:,} / {args.limit:,} | Errors: {errors}")
                batch = []
                time.sleep(0.1)  # Sleep to avoid throttling

        if batch:
            client.put_records(StreamName=args.stream, Records=batch)
            print(f"\nDone. Total: {sent:,} | Errors: {errors}")


if __name__ == "__main__":
    main()