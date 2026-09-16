import json
import os
import re
import uuid
from datetime import datetime, timezone

import boto3
import pg8000.dbapi

s3 = boto3.client("s3")


def normalize_cnpj(value):
    if value is None:
        return None
    digits = re.sub(r"\D", "", str(value))
    return digits if digits else None


def get_field(payload, *candidates):
    lowered = {str(k).strip().lower(): v for k, v in payload.items()}
    for candidate in candidates:
        value = lowered.get(candidate.lower())
        if value not in (None, ""):
            return value
    return None


def lambda_handler(event, context):
    output_bucket = os.environ["OUTPUT_BUCKET"]
    failures = []
    processed = 0

    conn = pg8000.dbapi.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "5432")),
        database=os.environ.get("DB_NAME", "postgres"),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        timeout=10,
    )

    try:
        for record in event.get("Records", []):
            message_id = record.get("messageId", str(uuid.uuid4()))

            try:
                body = json.loads(record["body"])
                payload = body.get("payload", body)

                protocolo = get_field(payload, "protocolo", "protocol", "id")
                cnpj_original = get_field(payload, "cnpj", "cnpj_empresa")
                valor = get_field(payload, "valor", "value")
                cnpj_norm = normalize_cnpj(cnpj_original)

                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT categoria, descricao
                    FROM public.dim_enriquecimento
                    WHERE cnpj_norm = %s
                    LIMIT 1
                    """,
                    (cnpj_norm,),
                )
                row = cursor.fetchone()
                cursor.close()

                result = {
                    "protocolo": protocolo,
                    "cnpj": cnpj_original,
                    "cnpj_norm": cnpj_norm,
                    "valor": valor,
                    "enriquecimento_encontrado": row is not None,
                    "categoria": row[0] if row else None,
                    "descricao": row[1] if row else None,
                    "source_message": body,
                    "processado_em": datetime.now(timezone.utc).isoformat(),
                }

                now = datetime.now(timezone.utc)
                protocolo_key = protocolo or "sem-protocolo"
                output_key = (
                    f"processed/{now:%Y/%m/%d}/"
                    f"{protocolo_key}-{uuid.uuid4().hex}.json"
                )

                s3.put_object(
                    Bucket=output_bucket,
                    Key=output_key,
                    Body=json.dumps(result, ensure_ascii=False, indent=2).encode("utf-8"),
                    ContentType="application/json",
                )

                processed += 1

                print(json.dumps({
                    "evento": "processado",
                    "protocolo": protocolo,
                    "cnpj_norm": cnpj_norm,
                    "enriquecimento_encontrado": row is not None,
                    "output_key": output_key,
                }, ensure_ascii=False))

            except Exception as exc:
                print(json.dumps({
                    "evento": "erro_processamento",
                    "message_id": message_id,
                    "erro": str(exc),
                }, ensure_ascii=False))
                failures.append({"itemIdentifier": message_id})

        return {"batchItemFailures": failures}

    finally:
        conn.close()
