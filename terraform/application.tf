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
          "dynamodb:PutItem",
          "dynamodb:GetItem"
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
  batch_size       = 1
}

resource "null_resource" "chaos_lambda_dependencies" {
  provisioner "local-exec" {
    command     = "npm install"
    working_dir = "../src"
  }
}

data "archive_file" "chaos_lambda_zip" {
  depends_on  = [null_resource.chaos_lambda_dependencies]
  source_dir  = "${path.module}/../src/"
  output_path = "${path.module}/../build/chaos_lambda.zip"
  type        = "zip"
}

resource "aws_lambda_function" "chaos_lambda" {
  depends_on = [data.archive_file.chaos_lambda_zip]

  filename         = "${path.module}/../build/chaos_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../src/lambda.js")
  function_name    = "ChaosTransformer-${random_id.chaos_stack.hex}"
  handler          = "lambda.handler"
  memory_size      = 128
  role             = aws_iam_role.chaos_lambda_role.arn
  runtime          = "nodejs12.x"
  timeout          = 3

  environment {
    variables = {
      FAILURE_INJECTION_PARAM = "failureLambdaConfig",
      CHAOS_DATA_TABLE        = aws_dynamodb_table.chaos_data_table.id
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
  value = "{\"isEnabled\": false}"
}
