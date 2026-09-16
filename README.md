# Atividade 6 — Pipeline em Cloud Computing com S3, Lambda, SQS e PostgreSQL

## 1. Objetivo

Implementar e validar na AWS um pipeline orientado a eventos com o fluxo:

**Amazon S3 (entrada) → AWS Lambda Producer → Amazon SQS → AWS Lambda Consumer → Amazon RDS PostgreSQL (enriquecimento) → Amazon S3 (saída)**

A solução foi executada e validada ponta a ponta em 16/09/2026 na região `us-east-2`.

## 2. Arquitetura implementada

```mermaid
flowchart LR
    A[S3 Input] -->|ObjectCreated: eventos/*.csv| B[Lambda atividade6-producer]
    B -->|1 mensagem por registro| C[SQS atividade6-pipeline-queue]
    C -->|Event Source Mapping| D[Lambda atividade6-consumer]
    D -->|SELECT| E[(RDS PostgreSQL)]
    D -->|PutObject JSON| F[S3 Output]
    C --> G[SQS DLQ]
```

### Componentes validados

- Bucket de entrada: `atividade6-input-041525320433-us-east-2`
- Bucket de saída: `atividade6-output-041525320433-us-east-2`
- Lambda Producer: `atividade6-producer`
- Fila principal: `atividade6-pipeline-queue`
- DLQ: `atividade6-pipeline-dlq`
- Lambda Consumer: `atividade6-consumer`
- RDS PostgreSQL: `atividade6-postgres`
- Runtime das Lambdas: Python 3.12

## 3. Funcionamento

1. Um arquivo CSV é enviado para o prefixo `eventos/` no bucket de entrada.
2. O S3 aciona automaticamente a Lambda Producer.
3. A Producer lê o CSV, identifica o delimitador e publica uma mensagem SQS para cada linha.
4. O SQS aciona a Lambda Consumer por meio de Event Source Mapping.
5. A Consumer normaliza o CNPJ, consulta a tabela `dim_enriquecimento` no PostgreSQL e monta o registro enriquecido.
6. Cada resultado é persistido em JSON no bucket de saída, no prefixo `processed/YYYY/MM/DD/`.
7. Mensagens que falharem repetidamente são encaminhadas para a DLQ.

## 4. Teste ponta a ponta validado

Arquivo de teste utilizado:

```csv
protocolo,cnpj,valor
REC-E2E-001,11.111.111/0001-91,150.00
REC-E2E-002,22.222.222/0001-82,320.50
REC-E2E-003,99.999.999/0001-99,80.00
```

Resultado observado:

| Protocolo | Enriquecimento | Categoria | Descrição |
|---|---|---|---|
| REC-E2E-001 | encontrado | Servicos | Empresa Exemplo A |
| REC-E2E-002 | encontrado | Comercio | Empresa Exemplo B |
| REC-E2E-003 | não encontrado | null | null |

Indicadores finais:

- 3 mensagens produzidas;
- 3 mensagens processadas;
- 0 mensagens remanescentes na fila principal;
- 0 mensagens na DLQ;
- 3 novos arquivos JSON no S3 Output.

## 5. Estrutura do projeto

```text
C3-Trabalho-Ingestao-Pipeline-Atividade7/
├── docs/
│   ├── 01_solucao_proposta.md
│   └── 02_roteiro_evidencias.md
├── evidencias/
│   ├── Manifesto_Evidencias_Atividade6.csv
│   ├── README_EVIDENCIAS.md
│   ├── Relatorio_Evidencias_Atividade6_AWS.docx
│   ├── logs/
│   └── scripts/
├── infra/
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── versions.tf
├── lambdas/
│   ├── consumer/
│   │   ├── lambda_function.py
│   │   └── requirements.txt
│   └── producer/
│       └── lambda_function.py
├── sample/
│   ├── eventos/eventos.csv
│   └── referencia/referencia.csv
├── scripts/
│   ├── build_lambdas.ps1
│   ├── deploy.ps1
│   ├── destroy.ps1
│   └── teste_pipeline.ps1
├── .gitignore
└── README.md
```

## 6. Evidências

A pasta `evidencias/` contém:

- relatório consolidado em Word;
- manifesto das evidências;
- logs sanitizados das execuções;
- scripts para coleta de evidências;
- evidência do PostgreSQL;
- registro do teste ponta a ponta.

Os logs foram sanitizados para não expor senha de banco ou credenciais AWS.

## 7. Segurança

Não versionar:

- `terraform.tfvars`;
- arquivos `.env`;
- arquivos `*environment*.json`;
- Access Keys AWS;
- senhas do PostgreSQL;
- chaves privadas.

Para fins acadêmicos, a Lambda Consumer utiliza variáveis de ambiente. Em ambiente de produção, recomenda-se armazenar credenciais no AWS Secrets Manager.

## 8. Sincronização local

Repositório remoto:

`https://github.com/brtostes/C3-Trabalho-Ingestao-Pipeline-Atividade7`

Na pasta local:

```powershell
cd "D:\GitHub\C3-Trabalho-Ingestao-Pipeline-Atividade7"
git remote set-url origin https://github.com/brtostes/C3-Trabalho-Ingestao-Pipeline-Atividade7.git
git fetch origin
git pull --ff-only origin main
```

## 9. Resultado final

O pipeline foi validado de forma integrada, comprovando o processamento automático desde a entrada do CSV no S3 até a persistência dos registros enriquecidos no bucket de saída, utilizando SQS para desacoplamento e PostgreSQL para enriquecimento dos dados.
