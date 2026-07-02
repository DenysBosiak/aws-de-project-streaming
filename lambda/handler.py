import os
import time
import json
import logging
import base64
import boto3
from botocore.exceptions import ClientError


logger = logging.getLogger()
logger.setLevel(logging.INFO)
rs = boto3.client("redshift-data")
WORKGROUP = os.environ["REDSHIFT_WORKGROUP"]
DB = os.environ.get("DB_NAME", "ecommerce_dwh")


def wait_for_statement(statement_id, timeout=30):
    """Wait for a Redshift statement to complete."""

    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            response = rs.describe_statement(Id=statement_id)
            status = response["Status"]
            if status == "FINISHED":
                return True
            elif status in ["FAILED", "ABORTED"]:
                logger.error(f"Statement {statement_id} failed with status: {status}")
                return False
        except ClientError as e:
            logger.error(f"Error describing statement {statement_id}: {e}")
            return False
        time.sleep(1)
    logger.error("Redshift statement timed out after %ss", timeout)
    return False


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
    
    try:
        response = rs.execute_statement(
            WorkgroupName=WORKGROUP,
            Database=DB,
            Sql=(
                "INSERT INTO events.raw(event_id, user_id, event_type, value)"
                f"VALUES {','.join(rows)}"
            )   
        )
        statement_id = response["Id"]
        success = wait_for_statement(statement_id)
        if not success:
            raise RuntimeError(f"INSERT failed for statement {statement_id}")
    
    except Exception as e:
        logger.error(f"Error occurred while executing statement: {e}")
        raise

    return {"processed": len(rows), "errors": len(errors)}