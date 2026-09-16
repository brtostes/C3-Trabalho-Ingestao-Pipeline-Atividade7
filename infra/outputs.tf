output "input_bucket_name" {
  value = aws_s3_bucket.input.bucket
}

output "output_bucket_name" {
  value = aws_s3_bucket.output.bucket
}

output "sqs_queue_url" {
  value = aws_sqs_queue.main.url
}

output "sqs_dlq_url" {
  value = aws_sqs_queue.dlq.url
}

output "producer_lambda_name" {
  value = aws_lambda_function.producer.function_name
}

output "consumer_lambda_name" {
  value = aws_lambda_function.consumer.function_name
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
