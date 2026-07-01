import os
import json
import logging
import base64
import boto3


logger = logging.getLogger()
logger.setLevel(logging.INFO)
rs = boto3.client("redshift-data")
WORKGROUP = os.environ["REDSHIFT_WORKGROUP"]
DB = os.environ.get("DB_NAME", "ecommerce_dwh")


def lambda_handler(event, context):
    rows, errors = [], []

    for rec in event["Records"]:
        try:
            data = json.loads(base64.b64decode(rec["kinesis"]["data"]).decode())
            rows.append(
                "("
                f"'{data['event_id'].replace(chr(39), chr(39) * 2)}',"
                f"'{data['user_id'].replace(chr(39), chr(39) * 2)}',"
                f"'{data.get('event_type', 'view')}',"
                f"GETDATE(), {float(data.get('value', 0))}"
                ")"
            )
        except Exception as e:
            logger.warning(f"Skipping malformed record: {e}")
            errors.append(str(e))
        
    if not rows:
        return {"processed": 0, "errors": len(errors)}
    
    rs.execute_statement(
        WorkgroupName=WORKGROUP,
        Database=DB,
        Sql=(
            "INSERT INTO events.raw(event_id, user_id, event_type, value)"
            f"VALUES {','.join(rows)}"
        )
    )

    return {"processed": len(rows), "errors": len(errors)}