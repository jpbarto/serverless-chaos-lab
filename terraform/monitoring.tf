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