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
