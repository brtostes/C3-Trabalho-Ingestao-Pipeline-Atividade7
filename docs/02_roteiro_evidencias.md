# Roteiro de evidências — Atividade 6

A pasta `evidencias/` consolida as evidências efetivamente produzidas no desenvolvimento e na validação do pipeline.

## Evidências principais já registradas

1. Configuração e execução da Lambda Producer.
2. Configuração e execução da Lambda Consumer.
3. Integração S3 → Producer.
4. Integração SQS → Consumer.
5. Teste manual da Consumer com acesso ao PostgreSQL.
6. Teste ponta a ponta com três registros.
7. Logs do CloudWatch da Producer.
8. Logs do CloudWatch da Consumer.
9. Estado final da fila principal: 0 mensagens disponíveis e 0 em voo.
10. Estado final da DLQ: 0 mensagens.
11. Criação de três novos JSONs no S3 Output.
12. Conteúdo dos JSONs enriquecidos e do registro sem correspondência.

## Teste de referência

Arquivo de entrada utilizado:

`eventos-20260916-183840.csv`

Resultados:

| Protocolo | CNPJ normalizado | Enriquecimento |
|---|---|---|
| REC-E2E-001 | 11111111000191 | Servicos / Empresa Exemplo A |
| REC-E2E-002 | 22222222000182 | Comercio / Empresa Exemplo B |
| REC-E2E-003 | 99999999000199 | sem correspondência |

## Arquivos de evidência

- `Relatorio_Evidencias_Atividade6_AWS.docx`
- `Manifesto_Evidencias_Atividade6.csv`
- `README_EVIDENCIAS.md`
- `logs/01_execucao_infraestrutura_e_producer_sanitizado.txt`
- `logs/02_criacao_consumer_e_autenticacao_sanitizado.txt`
- `logs/03_teste_ponta_a_ponta_sanitizado.txt`
- `08_teste_referencia_postgresql.png`

## Evidências adicionais recomendadas

Caso seja necessário complementar a apresentação, registrar capturas do Console AWS mostrando:

- bucket de entrada e notificação S3;
- Lambda Producer;
- fila SQS e DLQ;
- Event Source Mapping da Consumer;
- Lambda Consumer;
- RDS PostgreSQL;
- objetos `processed/` no bucket de saída;
- métricas e logs do CloudWatch.

## Segurança

Nunca registrar ou versionar:

- senha do PostgreSQL;
- Access Key / Secret Access Key;
- arquivos `.env`;
- arquivos de configuração com credenciais.

Os logs disponibilizados no repositório foram sanitizados.
