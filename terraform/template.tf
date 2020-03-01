terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "eu-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_id" "chaos_stack" {
  byte_length = 8
}

#########################################
#
# S3 bucket for receiving new data inputs
#
#########################################

resource "aws_s3_bucket" "chaos_bucket" {
  bucket = "chaos-bucket-${random_id.chaos_stack.hex}"
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

#########################################
#
# Chaos-prepared Lambda function
#
#########################################

resource "aws_dynamodb_table" "chaos_data_table" {
  name           = "chaos-data-${random_id.chaos_stack.hex}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "symbol"
  range_key       = "entryType"

  attribute {
    name = "symbol"
    type = "S"
  }

  attribute {
    name = "entryType"
    type = "S"
  }
}

#########################################
#
# Chaos-prepared Lambda function
#
#########################################

resource "aws_iam_role" "chaos_lambda_role" {
  name = "ChaosLambdaRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "chaos_policy" {
  name = "ChaosLambdaPermissions"
  role = aws_iam_role.chaos_lambda_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ssm:GetParameter"
        ],
        "Effect": "Allow",
        "Resource": "${aws_ssm_parameter.chaos_lambda_param.arn}"
      },
      {
        "Action": [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Effect": "Allow",
        "Resource": "${aws_s3_bucket.chaos_bucket.arn}/*"
      },
      {
        "Action": [
          "dynamodb:UpdateItem",
          "dynamodb:PutItem"
        ],
        "Effect": "Allow",
        "Resource": "${aws_dynamodb_table.chaos_data_table.arn}"
      },
      {
        "Action": [
          "sqs:SendMessage"
        ],
        "Effect": "Allow",
        "Resource": "${aws_sqs_queue.chaos_error_queue.arn}"
      },
      {
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Effect": "Allow",
        "Resource": "${aws_sqs_queue.chaos_json_queue.arn}"
      },
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
EOF
}

resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  event_source_arn = aws_sqs_queue.chaos_json_queue.arn
  function_name    = aws_lambda_function.chaos_lambda.arn
  batch_size = 1
}

data "archive_file" "chaos_lambda_zip" {
  source_dir  = "${path.module}/../src/"
  output_path = "${path.module}/../build/chaos_lambda.zip"
  type        = "zip"
}

resource "aws_lambda_function" "chaos_lambda" {
  filename         = "${path.module}/../build/chaos_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../build/chaos_lambda.zip")
  function_name    = "ChaosTransformer-${random_id.chaos_stack.hex}"
  handler          = "lambda.handler"
  memory_size      = 128
  role             = aws_iam_role.chaos_lambda_role.arn
  runtime          = "nodejs12.x"
  timeout          = 3

  dead_letter_config {
    target_arn = aws_sqs_queue.chaos_error_queue.arn
  }

  environment {
    variables = {
      FAILURE_INJECTION_PARAM = "failureLambdaConfig",
      CHAOS_DATA_TABLE = aws_dynamodb_table.chaos_data_table.id
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

#########################################
#
# Chaos Lambda configuration parameter
#
#########################################

resource "aws_ssm_parameter" "chaos_lambda_param" {
  name  = "failureLambdaConfig"
  type  = "String"
  value = "{\"isEnabled\": false, \"failureMode\": \"latency\", \"rate\": 1, \"minLatency\": 100, \"maxLatency\": 400, \"exceptionMsg\": \"Exception message!\", \"statusCode\": 404, \"diskSpace\": 100}"
}

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

#########################################
#
# CloudWatch Dashboard
#
#########################################

resource "aws_cloudwatch_dashboard" "chaos_board" {
  dashboard_name = "chaos-dashboard-${random_id.chaos_stack.hex}"

  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 3,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue.name}" ],
                    [ ".", "NumberOfMessagesReceived", ".", "." ],
                    [ ".", "NumberOfMessagesDeleted", ".", "." ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current.name}",
                "stat": "Sum",
                "period": 300,
                "title": "SQS Stats"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 3,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_error_queue.name}" ],
                    [ ".", "NumberOfMessagesReceived", ".", "." ],
                    [ ".", "NumberOfMessagesDeleted", ".", "." ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current.name}",
                "stat": "Sum",
                "period": 300,
                "title": "ETL Error Stats"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 24,
            "height": 3,
            "properties": {
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
                "stat": "Sum",
                "period": 300,
                "metrics": [
                    [ "AWS/SNS", "NumberOfNotificationsFailed", "TopicName", "${aws_sns_topic.chaos_topic.name}" ],
                    [ ".", "NumberOfNotificationsDelivered", ".", "." ],
                    [ ".", "NumberOfMessagesPublished", ".", "." ]
                ],
                "title": "SNS Stats"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 9,
            "width": 24,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Duration", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "stat": "Average" } ],
                    [ ".", "Errors", ".", "." ],
                    [ ".", "Invocations", ".", "." ],
                    [ ".", "Throttles", ".", "." ],
                    [ ".", "ConcurrentExecutions", ".", ".", { "stat": "Average" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current.name}",
                "stat": "Sum",
                "period": 300,
                "title": "Lambda Stats"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 15,
            "height": 3,
            "properties": {
                "metrics": [
                    [ { "expression": "((m1 - m2)/m1)*100", "label": "Percent in Flight", "id": "e1", "period": 300, "region": "${data.aws_region.current.name}" } ],
                    [ { "expression": "(m3/m1)*100", "label": "Percent in Error", "id": "e2", "period": 300, "region": "${data.aws_region.current.name}" } ],
                    [ "AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "id": "m1", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue.name}", { "id": "m2", "visible": false } ],
                    [ "...", "${aws_sqs_queue.chaos_error_queue.name}", { "id": "m3", "visible": false } ]
                ],
                "view": "timeSeries",
                "region": "${data.aws_region.current.name}",
                "stat": "Sum",
                "period": 300,
                "title": "Pipeline Trend",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 15,
            "y": 0,
            "width": 9,
            "height": 3,
            "properties": {
                "metrics": [
                    [ { "expression": "((m1 - m2)/m1)*100", "label": "Percent in Flight", "id": "e1", "period": 300, "region": "${data.aws_region.current.name}" } ],
                    [ { "expression": "(m3/m1)*100", "label": "Percent in Error", "id": "e2", "period": 300, "region": "${data.aws_region.current.name}" } ],
                    [ "AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "id": "m1", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue.name}", { "id": "m2", "visible": false } ],
                    [ "...", "${aws_sqs_queue.chaos_error_queue.name}", { "id": "m3", "visible": false } ]
                ],
                "view": "singleValue",
                "region": "${data.aws_region.current.name}",
                "stat": "Sum",
                "period": 300,
                "title": "Pipeline Point in Time"
            }
        }
    ]
}
EOF

}

#########################################
#
# Outputs
#
#########################################

resource "local_file" "driver_variables" {
  filename = "${path.module}/../drivers/aws_resource_names.py"
  content  = <<EOF
SQS_QUEUE_NAME="${aws_sqs_queue.chaos_csv_queue.name}"
S3_BUCKET_NAME="${aws_s3_bucket.chaos_bucket.bucket}"
EOF
}

resource "local_file" "chaos_variables" {
  filename = "${path.module}/../chaos/aws_resource_names.sh"
  content  = <<EOF
#!$(which sh)

SQS_QUEUE_NAME="${aws_sqs_queue.chaos_csv_queue.name}"
SNS_TOPIC_NAME="${aws_sns_topic.chaos_topic.name}"
S3_BUCKET_NAME="${aws_s3_bucket.chaos_bucket.bucket}"
LAMBDA_FUNCTION_NAME="${aws_lambda_function.chaos_lambda.function_name}"

export SQS_QUEUE_NAME SNS_TOPIC_NAME S3_BUCKET_NAME LAMBDA_FUNCTION_NAME
EOF
}

resource "local_file" "steady_state_flight" {
  filename = "${path.module}/../chaos/steadyStateFlight.json"
  content = <<EOF
[
    {
        "Id": "pctFlight",
        "Expression": "((lambdaInvokes - sqsMsgCount) / lambdaInvokes)*100",
        "Label": "PercentInFlight"
    },
    {
        "Id": "lambdaInvokes",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/Lambda",
                "MetricName": "Invocations",
                "Dimensions": [
                    {
                        "Name": "FunctionName",
                        "Value": "${aws_lambda_function.chaos_lambda.function_name}"
                    }
                ]
            },
            "Period": 300,
            "Stat": "Sum",
            "Unit": "Count"
        },
        "ReturnData": false
    },
    {
        "Id": "sqsMsgCount",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/SQS",
                "MetricName": "NumberOfMessagesSent",
                "Dimensions": [
                    {
                        "Name": "QueueName",
                        "Value": "${aws_sqs_queue.chaos_csv_queue.name}"
                    }
                ]
            },
            "Period": 300,
            "Stat": "Sum",
            "Unit": "Count"
        },
        "ReturnData": false
    }
]
EOF
}

resource "local_file" "steady_state_error" {
  filename = "${path.module}/../chaos/steadyStateError.json"
  content = <<EOF
[
    {
        "Id": "pctError",
        "Expression": "(sqsErrCount / lambdaInvokes)*100",
        "Label": "PercentInError"
    },
    {
        "Id": "lambdaInvokes",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/Lambda",
                "MetricName": "Invocations",
                "Dimensions": [
                    {
                        "Name": "FunctionName",
                        "Value": "${aws_lambda_function.chaos_lambda.function_name}"
                    }
                ]
            },
            "Period": 300,
            "Stat": "Sum",
            "Unit": "Count"
        },
        "ReturnData": false
    },
    {
        "Id": "sqsErrCount",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/SQS",
                "MetricName": "NumberOfMessagesSent",
                "Dimensions": [
                    {
                        "Name": "QueueName",
                        "Value": "${aws_sqs_queue.chaos_error_queue.name}"
                    }
                ]
            },
            "Period": 300,
            "Stat": "Sum",
            "Unit": "Count"
        },
        "ReturnData": false
    }
]
EOF
}
