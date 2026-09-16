import csv
import io
import json
import os
import urllib.parse
from datetime import datetime, timezone

import boto3

s3 = boto3.client("s3")
sqs = boto3.client("sqs")

QUEUE_URL = os.environ["QUEUE_URL"]


def decode_csv(raw: bytes):
    try:
        return raw.decode("utf-8-sig"), "utf-8-sig"
    except UnicodeDecodeError:
        return raw.decode("latin-1"), "latin-1"


def detect_delimiter(text: str) -> str:
    first_line = text.splitlines()[0] if text.splitlines() else ""
    candidates = [",", ";", "|", "\t"]
    return max(candidates, key=first_line.count) if first_line else ","


def lambda_handler(event, context):
    total_messages = 0

    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        print(json.dumps({
            "evento": "arquivo_recebido",
            "bucket": bucket,
            "key": key,
        }, ensure_ascii=False))

        response = s3.get_object(Bucket=bucket, Key=key)
        content, encoding = decode_csv(response["Body"].read())
        delimiter = detect_delimiter(content)
        reader = csv.DictReader(io.StringIO(content), delimiter=delimiter)

        for row_number, row in enumerate(reader, start=2):
            message = {
                "tipo": "evento",
                "source_bucket": bucket,
                "source_key": key,
                "row_number": row_number,
                "encoding_detectado": encoding,
                "delimitador_detectado": delimiter,
                "payload": {k: v for k, v in row.items() if k is not None},
                "produzido_em": datetime.now(timezone.utc).isoformat(),
            }

            result = sqs.send_message(
                QueueUrl=QUEUE_URL,
                MessageBody=json.dumps(message, ensure_ascii=False),
            )

            total_messages += 1

            print(json.dumps({
                "evento": "mensagem_enviada",
                "row_number": row_number,
                "message_id": result["MessageId"],
            }, ensure_ascii=False))

        print(json.dumps({
            "evento": "arquivo_processado",
            "bucket": bucket,
            "key": key,
            "mensagens_enviadas": total_messages,
        }, ensure_ascii=False))

    return {
        "statusCode": 200,
        "mensagens_enviadas": total_messages,
    }
