# Roteiro de evidências — Atividade 6

Crie capturas de tela e salve nesta pasta `evidencias/` com nomes numerados.

## Evidências mínimas

1. `01_terraform_apply.png` — infraestrutura provisionada.
2. `02_s3_input.png` — bucket de entrada.
3. `03_lambda_producer.png` — função e trigger S3.
4. `04_sqs.png` — fila principal e DLQ.
5. `05_lambda_consumer.png` — função e trigger SQS.
6. `06_rds.png` — instância PostgreSQL.
7. `07_upload_referencia.png` — referência enviada ao S3.
8. `08_log_referencia.png` — log de UPSERT.
9. `09_upload_eventos.png` — eventos enviados ao S3.
10. `10_log_consumer.png` — processamento/enriquecimento.
11. `11_s3_output.png` — arquivos de saída.
12. `12_json_enriquecido.png` — conteúdo de um resultado.

## Evidências complementares

- métricas da fila SQS;
- número de invocações das Lambdas;
- mensagem na DLQ em teste controlado;
- `terraform output`;
- diagrama arquitetural;
- comparação do registro original com o registro enriquecido.
