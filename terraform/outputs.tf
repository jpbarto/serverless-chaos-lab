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
AWS_REGION="${data.aws_region.current.name}"

export SQS_QUEUE_NAME SNS_TOPIC_NAME S3_BUCKET_NAME LAMBDA_FUNCTION_NAME AWS_REGION
EOF
}

resource "local_file" "steady_state_flight" {
  filename = "${path.module}/../chaos/steadyStateFlight.json"
  content = <<EOF
[
    {
        "Id": "pctFlight",
        "Expression": "((sqsInMsgCount - sqsOutMsgCount) / sqsInMsgCount)*100",
        "Label": "PercentInFlight"
    },
    {
        "Id": "sqsInMsgCount",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/SQS",
                "MetricName": "NumberOfMessagesSent",
                "Dimensions": [
                    {
                        "Name": "QueueName",
                        "Value": "${aws_sqs_queue.chaos_json_queue.name}"
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
        "Id": "sqsOutMsgCount",
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
        "Expression": "(lambdaErrors / sqsInMsgCount)*100",
        "Label": "PercentInError"
    },
    {
        "Id": "sqsInMsgCount",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/SQS",
                "MetricName": "NumberOfMessagesSent",
                "Dimensions": [
                    {
                        "Name": "QueueName",
                        "Value": "${aws_sqs_queue.chaos_json_queue.name}"
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
        "Id": "lambdaErrors",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/Lambda",
                "MetricName": "Errors",
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
    }
]
EOF
}
