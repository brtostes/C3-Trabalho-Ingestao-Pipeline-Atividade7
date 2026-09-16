# Solução proposta — Atividade 6

## 1. Problema

A atividade exige a implementação de um pipeline em cloud no qual dados armazenados no Amazon S3 sejam convertidos em mensagens, enfileirados no Amazon SQS, consumidos por uma função AWS Lambda e enriquecidos mediante consulta a um banco SQL, com persistência do resultado novamente no Amazon S3.

## 2. Decisão arquitetural

Foi adotada arquitetura orientada a eventos e desacoplada. O S3 atua como camada de entrada persistente; a primeira Lambda converte registros tabulares em mensagens; o SQS controla a taxa de entrega e oferece retentativa; a segunda Lambda realiza o processamento por mensagem; e o PostgreSQL fornece dados de referência para o enriquecimento.

A escolha de dois buckets, um de entrada e outro de saída, reduz o risco de recursão acidental do gatilho S3.

## 3. Fluxo lógico

1. O usuário envia um CSV ao bucket de entrada.
2. O S3 gera um evento `ObjectCreated`.
3. A Lambda Producer obtém o objeto e interpreta o CSV.
4. Cada linha é serializada em JSON e enviada ao SQS.
5. O Lambda Event Source Mapping consulta a fila e invoca a Lambda Consumer.
6. A Consumer:
   - normaliza o CNPJ;
   - se a mensagem for de referência, realiza `UPSERT` no PostgreSQL;
   - se a mensagem for um evento, consulta a dimensão por CNPJ;
   - incorpora ao payload os atributos de enriquecimento;
   - grava o registro final no bucket S3 de saída.
7. Falhas específicas retornam à fila por meio de resposta parcial de lote.
8. Após o limite de recebimentos, a mensagem é encaminhada à DLQ.

## 4. Estratégia de dados

Para tornar o laboratório autônomo, a carga da dimensão de enriquecimento também percorre a fila. Assim, não é necessário disponibilizar o PostgreSQL à Internet nem executar `INSERT` manualmente.

Os arquivos no prefixo `referencia/` alimentam o banco; os arquivos no prefixo `eventos/` são enriquecidos.

## 5. Relação com as atividades anteriores

A solução conserva conceitos já exercitados anteriormente — ingestão, camadas, normalização, banco relacional, tratamento programático, orquestração e qualidade — e acrescenta os conceitos de processamento orientado a eventos, desacoplamento, filas, retentativa e funções serverless.

Como continuidade didática, recomenda-se substituir os arquivos de amostra pelos mesmos dados de reclamações e enquadramento utilizados nas atividades anteriores.

## 6. Critérios de aceitação

A atividade poderá ser considerada tecnicamente demonstrada quando:

- o upload de um arquivo no S3 disparar automaticamente a Lambda Producer;
- a fila receber mensagens correspondentes às linhas do arquivo;
- a Lambda Consumer for acionada pela fila;
- a tabela PostgreSQL receber registros de referência;
- os eventos forem consultados/enriquecidos pelo banco;
- os resultados forem gravados automaticamente no S3;
- os logs demonstrarem o processamento;
- a DLQ e as retentativas estiverem configuradas.

## 7. Pontos a discutir no relatório

- diferença entre processamento em lote e processamento orientado a eventos;
- papel da fila como mecanismo de desacoplamento e amortecimento;
- semântica de entrega "at least once";
- necessidade de idempotência;
- impacto do tamanho do batch;
- segurança de rede do RDS;
- custos associados aos recursos cloud;
- possibilidade de evolução para Kinesis ou MSK/Kafka em cenários de streaming contínuo.
