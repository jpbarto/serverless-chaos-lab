#########################################
#
# Chaos File Processed topic
#
#########################################

resource "aws_sns_topic" "chaos_topic" {
  name = "chaos-csv-notification-topic-${random_id.chaos_stack.hex}"

  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": {
          "Service": "s3.amazonaws.com" 
        },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:chaos-csv-notification-topic-${random_id.chaos_stack.hex}",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.chaos_bucket.arn}"}
        }
    }]
}
POLICY

}

#########################################
#
# Chaos File Processed queue 
#
#########################################

resource "aws_sqs_queue" "chaos_json_queue" {
  name = "chaos-json-work-queue-${random_id.chaos_stack.hex}"

  policy = <<EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com" 
      },
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:chaos-json-work-queue-${random_id.chaos_stack.hex}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.chaos_bucket.arn}" }
      }
    }
  ]
}
EOL
  redrive_policy = <<EOL
{
  "maxReceiveCount": 3,
  "deadLetterTargetArn": "${aws_sqs_queue.chaos_error_queue.arn}"
}
EOL
}

resource "aws_sqs_queue" "chaos_error_queue" {
  name = "chaos-error-queue-${random_id.chaos_stack.hex}"
}

resource "aws_sqs_queue" "chaos_csv_queue" {
  name = "chaos-csv-work-queue-${random_id.chaos_stack.hex}"
}

resource "aws_sqs_queue_policy" "chaos_queue_policy" {
  queue_url = aws_sqs_queue.chaos_csv_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": { "Service": "sns.amazonaws.com" },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.chaos_csv_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.chaos_topic.arn}"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_sns_topic_subscription" "csv_topic_subscription" {
  topic_arn = aws_sns_topic.chaos_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.chaos_csv_queue.arn
}