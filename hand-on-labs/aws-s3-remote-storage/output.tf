output "s3_bucket_id" {
  value = aws_s3_bucket.s3.id
}
output "s3_bucket_arn" {
  value = aws_s3_bucket.s3.arn
}

output "s3_bucket_domain_name" {
  value = aws_s3_bucket.s3.bucket_domain_name
}

output "s3_hosted_zone_id" {
  value = aws_s3_bucket.s3.hosted_zone_id
}

output "s3_bucket_region" {
  value = aws_s3_bucket.s3.region
}
