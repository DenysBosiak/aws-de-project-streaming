output "lambda_exec_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "firehose_role_arn" {
  value = aws_iam_role.firehose.arn
}
