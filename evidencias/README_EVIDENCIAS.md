# Evidências — Atividade 6 — Pipeline Streaming em AWS

## Objetivo

Este diretório documenta as evidências do desenvolvimento e da validação ponta a ponta da atividade, cuja arquitetura implementada foi:

`S3 Input → Lambda Producer → SQS → Lambda Consumer → RDS PostgreSQL → S3 Output`

## Resultado do teste final

- Arquivo de entrada: `eventos-20260916-183840.csv`.
- Registros enviados pela Producer ao SQS: **3**.
- Registros processados pela Consumer: **3**.
- Enriquecimento: `REC-E2E-001` e `REC-E2E-002` com correspondência; `REC-E2E-003` sem correspondência.
- Fila principal ao final: **0 disponíveis / 0 em voo**.
- DLQ ao final: **0 mensagens**.
- Arquivos no S3 Output: **1 antes / 4 depois / +3 novos**.

## Arquivos de evidência

- `Relatorio_Evidencias_Atividade6_AWS.docx`: relatório consolidado da execução.
- `Manifesto_Evidencias_Atividade6.csv`: índice das evidências e respectivos status.
- `08_teste_referencia_postgresql.png`: evidência da base de referência PostgreSQL.
- `logs/01_execucao_infraestrutura_e_producer_sanitizado.txt`: configuração e execução da infraestrutura e da Producer.
- `logs/02_criacao_consumer_e_autenticacao_sanitizado.txt`: criação/configuração da Consumer e conexão com PostgreSQL.
- `logs/03_teste_ponta_a_ponta_sanitizado.txt`: teste integrado final do pipeline.

## Segurança

Os logs desta pasta foram sanitizados. Valores de `DB_PASSWORD` e entradas de senha foram removidos. Credenciais não devem ser versionadas no Git.

## Pasta local

`D:\GitHub\C3-Trabalho-Ingestao-Pipeline-Atividade7\evidencias`

## Evidências centrais

1. A Producer recebeu o CSV do bucket de entrada e enviou três mensagens ao SQS.
2. A Consumer processou as três mensagens, consultou o PostgreSQL e gravou três JSONs no S3 Output.
3. Dois registros foram enriquecidos com sucesso e um registro sem correspondência foi tratado sem falha.
4. A fila principal e a DLQ terminaram vazias.
5. Foram criados exatamente três novos objetos no S3 Output.

Gerado em: 16/09/2026
