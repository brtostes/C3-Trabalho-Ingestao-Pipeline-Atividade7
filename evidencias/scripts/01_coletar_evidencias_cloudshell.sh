#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-2"
ACCOUNT_ID="041525320433"
INPUT_BUCKET="atividade6-input-041525320433-us-east-2"
OUTPUT_BUCKET="atividade6-output-041525320433-us-east-2"
PRODUCER="atividade6-producer"
CONSUMER="atividade6-consumer"
QUEUE_NAME="atividade6-pipeline-queue"
DLQ_NAME="atividade6-pipeline-dlq"
RDS_INSTANCE="atividade6-postgres"
MAPPING_UUID="996c27fd-54e5-4ea4-8528-fa336f0ba2b9"

export AWS_DEFAULT_REGION="$REGION"
export AWS_REGION="$REGION"
export AWS_PAGER=""

DEST="$HOME/atividade6/evidencias_entrega"
rm -rf "$DEST"
mkdir -p "$DEST/output" "$DEST/codigo"

echo "[1/12] Identidade AWS"
aws sts get-caller-identity > "$DEST/01_identidade_aws.json"

echo "[2/12] Configuração Producer (sem variáveis de ambiente)"
aws lambda get-function-configuration --function-name "$PRODUCER" \
  --query '{FunctionName:FunctionName,Runtime:Runtime,State:State,LastUpdateStatus:LastUpdateStatus,Role:Role,Handler:Handler,Timeout:Timeout,MemorySize:MemorySize,CodeSize:CodeSize,LastModified:LastModified}' \
  > "$DEST/02_lambda_producer_config.json"

echo "[3/12] Configuração Consumer (sem variáveis de ambiente)"
aws lambda get-function-configuration --function-name "$CONSUMER" \
  --query '{FunctionName:FunctionName,Runtime:Runtime,State:State,LastUpdateStatus:LastUpdateStatus,Role:Role,Handler:Handler,Timeout:Timeout,MemorySize:MemorySize,VpcConfig:VpcConfig,CodeSize:CodeSize,LastModified:LastModified}' \
  > "$DEST/03_lambda_consumer_config.json"

echo "[4/12] SQS -> Consumer"
aws lambda get-event-source-mapping --uuid "$MAPPING_UUID" \
  --query '{UUID:UUID,State:State,BatchSize:BatchSize,FunctionArn:FunctionArn,EventSourceArn:EventSourceArn,LastProcessingResult:LastProcessingResult,FunctionResponseTypes:FunctionResponseTypes}' \
  > "$DEST/04_sqs_consumer_mapping.json"

echo "[5/12] S3 -> Producer"
aws s3api get-bucket-notification-configuration --bucket "$INPUT_BUCKET" \
  > "$DEST/05_s3_producer_notification.json"

echo "[6/12] Fila principal"
QUEUE_URL=$(aws sqs get-queue-url --queue-name "$QUEUE_NAME" --query QueueUrl --output text)
aws sqs get-queue-attributes --queue-url "$QUEUE_URL" \
  --attribute-names QueueArn ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible VisibilityTimeout RedrivePolicy \
  > "$DEST/06_sqs_principal.json"

echo "[7/12] DLQ"
DLQ_URL=$(aws sqs get-queue-url --queue-name "$DLQ_NAME" --query QueueUrl --output text)
aws sqs get-queue-attributes --queue-url "$DLQ_URL" \
  --attribute-names QueueArn ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  > "$DEST/07_sqs_dlq.json"

echo "[8/12] RDS (sem credenciais)"
aws rds describe-db-instances --db-instance-identifier "$RDS_INSTANCE" \
  --query 'DBInstances[0].{Nome:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine,EngineVersion:EngineVersion,Usuario:MasterUsername,Endpoint:Endpoint.Address,Porta:Endpoint.Port,VPC:DBSubnetGroup.VpcId,SubnetGroup:DBSubnetGroup.DBSubnetGroupName,SecurityGroups:VpcSecurityGroups[].VpcSecurityGroupId,Publico:PubliclyAccessible}' \
  > "$DEST/08_rds_config.json"

echo "[9/12] Logs Producer"
aws logs tail "/aws/lambda/$PRODUCER" --since 2h --format short \
  > "$DEST/09_log_producer.txt" || true

echo "[10/12] Logs Consumer"
aws logs tail "/aws/lambda/$CONSUMER" --since 2h --format short \
  > "$DEST/10_log_consumer.txt" || true

echo "[11/12] Listagens S3 e resultados"
aws s3 ls "s3://$INPUT_BUCKET/" --recursive > "$DEST/11_s3_input_lista.txt" || true
aws s3 ls "s3://$OUTPUT_BUCKET/processed/" --recursive > "$DEST/12_s3_output_lista.txt" || true
aws s3 cp "s3://$OUTPUT_BUCKET/processed/" "$DEST/output/" --recursive || true

echo "[12/12] Códigos-fonte locais"
cp "$HOME/atividade6/lambda/producer/lambda_function.py" "$DEST/codigo/producer_lambda_function.py" 2>/dev/null || true
cp "$HOME/atividade6/lambda/consumer/lambda_function.py" "$DEST/codigo/consumer_lambda_function.py" 2>/dev/null || true

cat > "$DEST/00_RESUMO.txt" <<EOF
ATIVIDADE 6 - EVIDÊNCIAS COLETADAS
Data UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')
Região: $REGION
Input bucket: $INPUT_BUCKET
Output bucket: $OUTPUT_BUCKET
Producer: $PRODUCER
Consumer: $CONSUMER
SQS: $QUEUE_NAME
DLQ: $DLQ_NAME
RDS: $RDS_INSTANCE
Observação: nenhum valor DB_PASSWORD foi coletado por este script.
EOF

ZIP="$HOME/atividade6/evidencias_atividade6_cloudshell.zip"
rm -f "$ZIP"
cd "$(dirname "$DEST")"
zip -r -q "$ZIP" "$(basename "$DEST")"

echo
echo "Coleta concluída."
echo "Pasta: $DEST"
echo "ZIP:   $ZIP"
echo "Use Ações/Actions > Download file no CloudShell e informe:"
echo "$ZIP"
