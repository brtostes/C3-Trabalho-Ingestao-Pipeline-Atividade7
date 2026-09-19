# Plano passo a passo — Atividade 7

## 1. Objetivo da atividade

Implementar e demonstrar um pipeline de ingestão orientado a eventos em ambiente AWS, com o seguinte fluxo funcional:

```text
S3 / RAW (reclamações)
        ↓
Lambda Producer
        ↓
Amazon SQS
        ↓
Lambda Consumer / Enriquecedora
        ↓
Consulta SQL em PostgreSQL/RDS
        ↓
Mensagem tratada e enriquecida
        ↓
S3 Output
```

O repositório já contém uma implementação-base tecnicamente validada com essa arquitetura. Para a Atividade 7, a estratégia será **reutilizar a infraestrutura e o código existentes**, revisar cada componente com o aluno e gerar uma nova rodada de evidências específicas da atividade.

## 2. Ambiente conhecido

- Repositório: `brtostes/C3-Trabalho-Ingestao-Pipeline-Atividade7`
- Pasta local esperada: `D:\\GitHub\\C3-Trabalho-Ingestao-Pipeline-Atividade7`
- AWS: ambiente Try Catch Finally
- Região: `us-east-2` (Ohio)
- Bucket de entrada existente: `atividade6-input-041525320433-us-east-2`
- Bucket de saída existente: `atividade6-output-041525320433-us-east-2`
- Lambda Producer existente: `atividade6-producer`
- Fila SQS existente: `atividade6-pipeline-queue`
- DLQ existente: `atividade6-pipeline-dlq`
- Lambda Consumer existente: `atividade6-consumer`
- RDS PostgreSQL existente: `atividade6-postgres`
- IAM Role existente: `atividade6-lambda-role`
- Runtime das Lambdas: Python 3.12

## 3. Estratégia didática

O desenvolvimento será realizado em etapas curtas. Só avançaremos para a próxima etapa após confirmar que a anterior funcionou.

### Etapa 1 — Sincronizar e conferir o repositório local
Objetivo: garantir que a pasta local contém a versão atual do GitHub.

### Etapa 2 — Conferir os recursos AWS existentes
Objetivo: verificar se buckets, Lambdas, SQS e RDS continuam disponíveis no ambiente.

### Etapa 3 — Entender e validar a Lambda Producer
Objetivo: acompanhar como um CSV no S3 é lido e convertido em uma mensagem SQS por registro.

### Etapa 4 — Entender e validar a fila SQS
Objetivo: verificar fila principal, DLQ, política de redrive e recebimento das mensagens.

### Etapa 5 — Entender e validar o PostgreSQL/RDS
Objetivo: conferir a tabela de enriquecimento e a chave utilizada na consulta SQL.

### Etapa 6 — Entender e validar a Lambda Consumer
Objetivo: receber cada mensagem SQS, consultar o PostgreSQL, enriquecer o registro e gravar JSON no S3 Output.

### Etapa 7 — Teste ponta a ponta da Atividade 7
Objetivo: enviar novo arquivo de teste ao S3 e comprovar automaticamente todo o fluxo.

### Etapa 8 — Evidências
Objetivo: registrar CloudWatch, SQS, RDS, Lambdas e objetos de saída sem expor credenciais.

### Etapa 9 — Documentação e apresentação
Objetivo: atualizar README, relatório de evidências e material para apresentação da atividade.

## 4. Critérios de sucesso

A Atividade 7 será considerada tecnicamente demonstrada quando houver evidência de que:

1. um CSV foi inserido no bucket S3 de entrada;
2. a Lambda Producer foi acionada;
3. cada registro do CSV gerou uma mensagem na SQS;
4. a Lambda Consumer recebeu as mensagens;
5. a Consumer consultou o banco SQL;
6. os registros foram enriquecidos;
7. os resultados foram gravados no S3 de saída;
8. a fila principal terminou sem backlog;
9. mensagens com falha, se houver, possam ser encaminhadas à DLQ;
10. os logs do CloudWatch permitam rastrear o fluxo.

## 5. Regra de segurança

Nunca versionar ou capturar em evidências:

- senha do PostgreSQL;
- AWS Access Key ID;
- AWS Secret Access Key;
- tokens;
- arquivos `.env`;
- chaves privadas;
- arquivos com credenciais.

## 6. Status

- [x] Repositório GitHub localizado.
- [x] Implementação-base localizada.
- [x] Arquitetura compatível com o enunciado identificada.
- [x] Plano passo a passo registrado.
- [x] Etapa 1 — sincronização e conferência local.
- [ ] Etapa 2 — inventário atual dos recursos AWS.
- [ ] Etapa 3 — validação da Producer.
- [ ] Etapa 4 — validação da SQS.
- [ ] Etapa 5 — validação do PostgreSQL/RDS.
- [ ] Etapa 6 — validação da Consumer.
- [ ] Etapa 7 — novo teste ponta a ponta.
- [ ] Etapa 8 — evidências da Atividade 7.
- [ ] Etapa 9 — documentação/apresentação final.

## 7. Observação sobre os nomes `atividade6-*`

Os recursos AWS existentes mantêm o prefixo `atividade6-` porque foram criados em uma execução anterior. Isso não altera a arquitetura funcional exigida na Atividade 7. A decisão inicial é reaproveitá-los para evitar reprovisionamento desnecessário no laboratório AWS. Se a entrega exigir nomenclatura exclusiva da Atividade 7, os recursos poderão ser duplicados ou renomeados quando tecnicamente viável, após a validação funcional.
