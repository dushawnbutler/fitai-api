import hashlib
import json
import os
from urllib.parse import unquote_plus

import boto3
from botocore.exceptions import ClientError


personalize = boto3.client("personalize")


def handler(event, context):
    results = []

    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])
        sequencer = record["s3"]["object"].get("sequencer", "")

        if not key.startswith("datasets/") or not key.endswith(".csv"):
            continue

        # A retry of the same S3 event uses the same Personalize job name.
        event_id = hashlib.sha256(
            f"{bucket}/{key}/{sequencer}".encode("utf-8")
        ).hexdigest()[:20]

        job_name = f"fitai-import-{event_id}"

        try:
            response = personalize.create_dataset_import_job(
                jobName=job_name,
                datasetArn=os.environ["DATASET_ARN"],
                dataSource={
                    "dataLocation": f"s3://{bucket}/{key}"
                },
                roleArn=os.environ["ROLE_ARN"],
                importMode="FULL",
            )

            results.append({
                "key": key,
                "jobArn": response["datasetImportJobArn"],
            })

        except ClientError as error:
            code = error.response["Error"]["Code"]

            if code == "ResourceAlreadyExistsException":
                results.append({
                    "key": key,
                    "status": "already-submitted",
                })
            else:
                raise

    print(json.dumps(results))
    return {"imports": results}
