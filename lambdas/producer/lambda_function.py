import csv
import io
import json
import os
import urllib.parse

import boto3

s3 = boto3.client("s3")
sqs = boto3.client("sqs")
QUEUE_URL = os.environ["QUEUE_URL"]


def detect_delimiter(sample: str) -> str:
    try:
        return csv.Sniffer().sniff(sample, delimiters=",;|\t").delimiter
    except csv.Error:
        return ","


def chunks(items, size=10):
    for i in range(0, len(items), size):
        yield items[i:i + size]


def lambda_handler(event, context):
    total_messages = 0

    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        response = s3.get_object(Bucket=bucket, Key=key)
        content = response["Body"].read().decode("utf-8-sig")

        delimiter = detect_delimiter(content[:4096])
        reader = csv.DictReader(io.StringIO(content), delimiter=delimiter)

        tipo = "referencia" if key.startswith("referencia/") else "evento"

        entries = []
        for row_number, row in enumerate(reader, start=2):
            message = {
                "tipo": tipo,
                "source_bucket": bucket,
                "source_key": key,
                "row_number": row_number,
                "payload": {k: v for k, v in row.items() if k is not None},
            }
            entries.append({
                "Id": str(len(entries)),
                "MessageBody": json.dumps(message, ensure_ascii=False),
            })

            if len(entries) == 10:
                result = sqs.send_message_batch(QueueUrl=QUEUE_URL, Entries=entries)
                if result.get("Failed"):
                    raise RuntimeError(f"Falha ao publicar lote no SQS: {result['Failed']}")
                total_messages += len(entries)
                entries = []

        if entries:
            result = sqs.send_message_batch(QueueUrl=QUEUE_URL, Entries=entries)
            if result.get("Failed"):
                raise RuntimeError(f"Falha ao publicar lote no SQS: {result['Failed']}")
            total_messages += len(entries)

        print(json.dumps({
            "arquivo": key,
            "tipo": tipo,
            "mensagens_enviadas": total_messages,
        }, ensure_ascii=False))

    return {"statusCode": 200, "mensagens_enviadas": total_messages}
