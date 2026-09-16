# Solução implementada — Atividade 6

## 1. Objetivo

Implementar um pipeline em cloud no qual arquivos CSV armazenados no Amazon S3 sejam convertidos em mensagens, processados por Amazon SQS e AWS Lambda, enriquecidos por consulta a PostgreSQL no Amazon RDS e persistidos novamente em Amazon S3.

## 2. Arquitetura validada

Fluxo implementado e testado em 16/09/2026:

`S3 Input → Lambda Producer → SQS → Lambda Consumer → RDS PostgreSQL → S3 Output`

Recursos principais:

- região: `us-east-2`;
- Lambda Producer: `atividade6-producer`;
- SQS: `atividade6-pipeline-queue`;
- DLQ: `atividade6-pipeline-dlq`;
- Lambda Consumer: `atividade6-consumer`;
- RDS: `atividade6-postgres`;
- bucket de entrada: `atividade6-input-041525320433-us-east-2`;
- bucket de saída: `atividade6-output-041525320433-us-east-2`.

## 3. Fluxo lógico

1. Um CSV é enviado para `eventos/` no bucket de entrada.
2. O S3 gera evento `ObjectCreated`.
3. A Lambda Producer lê o CSV.
4. Cada linha é serializada em JSON e enviada individualmente ao SQS.
5. O Event Source Mapping do Lambda consulta a fila e aciona a Consumer.
6. A Consumer normaliza o CNPJ e consulta `public.dim_enriquecimento` no PostgreSQL.
7. O registro enriquecido é salvo em `processed/YYYY/MM/DD/` no bucket de saída.
8. Em falhas repetidas, a mensagem pode ser encaminhada à DLQ.

## 4. Estratégia de enriquecimento

A tabela de referência utilizada no teste contém CNPJ normalizado, categoria e descrição. A Consumer executa uma consulta por `cnpj_norm` e inclui no JSON final:

- `enriquecimento_encontrado`;
- `categoria`;
- `descricao`.

Quando não existe correspondência, o registro é preservado, `enriquecimento_encontrado` recebe `false` e os campos de enriquecimento permanecem nulos.

## 5. Teste realizado

Foram enviados três registros:

- `REC-E2E-001`: correspondência encontrada — `Servicos / Empresa Exemplo A`;
- `REC-E2E-002`: correspondência encontrada — `Comercio / Empresa Exemplo B`;
- `REC-E2E-003`: nenhuma correspondência.

Resultados observados:

- 3 mensagens enviadas pela Producer;
- 3 mensagens processadas pela Consumer;
- 3 novos objetos JSON gravados no S3 Output;
- fila principal ao final com 0 mensagens;
- DLQ ao final com 0 mensagens.

## 6. Decisões arquiteturais

- Dois buckets distintos evitam recursão do gatilho S3.
- SQS desacopla ingestão e processamento.
- DLQ permite isolamento de falhas persistentes.
- RDS permanece privado em VPC.
- A Consumer utiliza `ReportBatchItemFailures` para tratamento parcial de lote.
- O tamanho de lote adotado na validação foi 1, facilitando rastreabilidade por mensagem.
- O timeout da Consumer foi configurado em 60 segundos.

## 7. Segurança

Credenciais não devem ser versionadas. A senha do PostgreSQL utilizada durante o laboratório não está armazenada nos arquivos do repositório. Em produção, recomenda-se AWS Secrets Manager.

## 8. Critérios de aceite atendidos

- gatilho automático do S3 validado;
- envio SQS validado;
- acionamento automático da Consumer validado;
- consulta ao PostgreSQL validada;
- enriquecimento validado;
- gravação no S3 Output validada;
- DLQ configurada e vazia após teste bem-sucedido;
- logs do CloudWatch registrados como evidência.
