# Evidências — Atividade 6 — Pipeline Streaming em AWS

## Objetivo
Este diretório documenta as evidências do desenvolvimento e da validação ponta a ponta da Atividade 6, cuja arquitetura implementada foi:

`S3 Input → Lambda Producer → SQS → Lambda Consumer → RDS PostgreSQL → S3 Output`

> O diretório/repositório local foi renomeado para `C3-Trabalho-Ingestao-Pipeline-Atividade7`. O conteúdo desta pasta continua correspondendo à **Atividade 6**, por isso os nomes dos recursos AWS e dos arquivos de evidência foram preservados.

## Resultado do teste final
- Arquivo de entrada: `eventos-20260916-183840.csv`.
- Registros enviados pela Producer ao SQS: **3**.
- Registros processados pela Consumer: **3**.
- Enriquecimento: `REC-E2E-001` e `REC-E2E-002` com correspondência; `REC-E2E-003` sem correspondência.
- Fila principal ao final: **0 disponíveis / 0 em voo**.
- DLQ ao final: **0 mensagens**.
- Arquivos no S3 Output: **1 antes / 4 depois / +3 novos**.

## Estrutura
- `Relatorio_Evidencias_Atividade6_AWS.docx`: relatório consolidado para entrega.
- `Manifesto_Evidencias_Atividade6.csv`: índice das evidências e respectivos status.
- `logs/`: transcrições sanitizadas das execuções no CloudShell.
- `scripts/01_coletar_evidencias_cloudshell.sh`: coleta novamente o estado atual dos recursos AWS sem expor senha.
- `scripts/02_instalar_pacote_no_windows.ps1`: instala/descompacta o pacote na pasta local do projeto.

## Segurança
Os logs desta pasta foram sanitizados. Valores de `DB_PASSWORD` e entradas de senha foram removidos. Nunca versionar credenciais em Git.

## Pasta local recomendada
`D:\GitHub\C3-Trabalho-Ingestao-Pipeline-Atividade7\evidencias`

## Evidências centrais
1. A Producer recebeu o CSV do bucket de entrada e enviou três mensagens ao SQS.
2. A Consumer processou as três mensagens, consultou o PostgreSQL e gravou três JSONs no S3 Output.
3. Dois registros foram enriquecidos com sucesso e um registro sem correspondência foi tratado sem falha.
4. A fila principal e a DLQ terminaram vazias.
5. Foram criados exatamente três novos objetos no S3 Output.

Gerado em: 16/09/2026 18:47
