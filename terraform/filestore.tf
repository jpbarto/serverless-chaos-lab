#########################################
#
# S3 bucket for receiving new data inputs
#
#########################################

resource "aws_s3_bucket" "chaos_bucket" {
  bucket = "chaos-bucket-${random_id.chaos_stack.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.chaos_bucket.id

  block_public_acls   = true
  block_public_policy = true
}

output "chaos_bucket_name" {
  value = aws_s3_bucket.chaos_bucket.id
}

resource "aws_s3_bucket_notification" "chaos_bucket_notifications" {
  bucket = aws_s3_bucket.chaos_bucket.id

  queue {
    queue_arn     = aws_sqs_queue.chaos_json_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "input/"
    filter_suffix = ".json"
  }

  topic {
    topic_arn     = aws_sns_topic.chaos_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "output/"
    filter_suffix = ".csv"
  }
}
