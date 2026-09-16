import datetime as dt
import json
import os
import re

import boto3
import pg8000.native

s3 = boto3.client("s3")

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]

_connection = None


def get_connection():
    global _connection
    if _connection is None:
        _connection = pg8000.native.Connection(
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            timeout=10,
        )
    return _connection


def normalize_cnpj(value):
    if value is None:
        return None
    digits = re.sub(r"\D", "", str(value))
    return digits.zfill(14) if digits else None


def find_value(payload, candidates):
    lower_map = {str(k).strip().lower(): v for k, v in payload.items()}
    for candidate in candidates:
        if candidate.lower() in lower_map:
            return lower_map[candidate.lower()]
    return None


def ensure_schema(conn):
    conn.run("""
        CREATE TABLE IF NOT EXISTS dim_enriquecimento (
            cnpj_norm VARCHAR(14) PRIMARY KEY,
            categoria TEXT,
            descricao TEXT,
            atualizado_em TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.run("COMMIT")


def process_reference(conn, message):
    payload = message["payload"]
    cnpj = normalize_cnpj(find_value(payload, ["cnpj_norm", "cnpj", "cnpj empresa"]))
    if not cnpj:
        raise ValueError("Registro de referência sem CNPJ válido.")

    categoria = find_value(payload, ["categoria", "classificacao", "classificação", "enquadramento"])
    descricao = find_value(payload, ["descricao", "descrição", "razao_social", "razão social", "empresa"])

    conn.run("""
        INSERT INTO dim_enriquecimento (cnpj_norm, categoria, descricao, atualizado_em)
        VALUES (:cnpj, :categoria, :descricao, CURRENT_TIMESTAMP)
        ON CONFLICT (cnpj_norm) DO UPDATE
        SET categoria = EXCLUDED.categoria,
            descricao = EXCLUDED.descricao,
            atualizado_em = CURRENT_TIMESTAMP
    """, cnpj=cnpj, categoria=categoria, descricao=descricao)
    conn.run("COMMIT")

    return {
        "acao": "referencia_upsert",
        "cnpj_norm": cnpj,
        "categoria": categoria,
        "descricao": descricao,
    }


def process_event(conn, message, sqs_message_id):
    payload = dict(message["payload"])
    cnpj = normalize_cnpj(find_value(payload, ["cnpj_norm", "cnpj", "cnpj empresa"]))

    enriched = {
        **payload,
        "cnpj_norm": cnpj,
        "enriquecimento_encontrado": False,
    }

    if cnpj:
        rows = conn.run("""
            SELECT categoria, descricao
            FROM dim_enriquecimento
            WHERE cnpj_norm = :cnpj
        """, cnpj=cnpj)

        if rows:
            enriched["enriquecimento_encontrado"] = True
            enriched["categoria"] = rows[0][0]
            enriched["descricao"] = rows[0][1]

    enriched["_metadata"] = {
        "source_bucket": message.get("source_bucket"),
        "source_key": message.get("source_key"),
        "source_row_number": message.get("row_number"),
        "sqs_message_id": sqs_message_id,
        "processed_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    }

    now = dt.datetime.now(dt.timezone.utc)
    key = (
        f"processed/{now:%Y/%m/%d}/"
        f"{sqs_message_id}.json"
    )

    s3.put_object(
        Bucket=OUTPUT_BUCKET,
        Key=key,
        Body=json.dumps(enriched, ensure_ascii=False, indent=2).encode("utf-8"),
        ContentType="application/json",
    )

    return {
        "acao": "evento_enriquecido",
        "cnpj_norm": cnpj,
        "encontrado": enriched["enriquecimento_encontrado"],
        "output_key": key,
    }


def lambda_handler(event, context):
    failures = []
    conn = get_connection()
    ensure_schema(conn)

    for record in event.get("Records", []):
        message_id = record["messageId"]
        try:
            message = json.loads(record["body"])
            tipo = message.get("tipo", "evento")

            if tipo == "referencia":
                result = process_reference(conn, message)
            else:
                result = process_event(conn, message, message_id)

            print(json.dumps({
                "message_id": message_id,
                **result,
            }, ensure_ascii=False))

        except Exception as exc:
            try:
                conn.run("ROLLBACK")
            except Exception:
                pass

            print(json.dumps({
                "message_id": message_id,
                "erro": str(exc),
            }, ensure_ascii=False))
            failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": failures}
