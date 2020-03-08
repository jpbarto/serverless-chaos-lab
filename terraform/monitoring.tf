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
            "x": 12,
            "y": 3,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue}", { "label": "Total Messages In (5 min)" } ],
                    [ ".", "NumberOfMessagesReceived", ".", ".", { "label": "Total Messages Out (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current}",
                "stat": "Sum",
                "period": 300,
                "title": "CSV Output Queue"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${aws_sqs_queue.chaos_error_queue.name}", { "label": "Approx. Msgs in Queue (5 min)" } ],
                    [ ".", "ApproximateAgeOfOldestMessage", ".", ".", { "label": "Approx. Oldest Msg Age" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current}",
                "stat": "Maximum",
                "period": 300,
                "title": "ETL Error Queue"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SNS", "NumberOfNotificationsFailed", "TopicName", "${aws_sns_topic.chaos_topic.name}", { "label": "Error Count (5 min)" } ],
                    [ ".", "NumberOfNotificationsDelivered", ".", ".", { "label": "Total Messages Out (5 min)" } ],
                    [ ".", "NumberOfMessagesPublished", ".", ".", { "label": "Total Messages In (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current}",
                "stat": "Sum",
                "period": 300,
                "title": "CSV Output Topic"
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
                    [ "AWS/Lambda", "Duration", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "stat": "Average", "label": "Avg Duration" } ],
                    [ ".", "Errors", ".", ".", { "label": "Total Errors" } ],
                    [ ".", "Invocations", ".", ".", { "label": "Total Invocations" } ],
                    [ ".", "Throttles", ".", ".", { "label": "Total Throttles" } ],
                    [ ".", "ConcurrentExecutions", ".", ".", { "stat": "Average", "label": "Avg Concurrent Executions" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current}",
                "stat": "Sum",
                "period": 300,
                "title": "JSON ETL Processor"
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
                    [ { "expression": "((m3 - m2)/m3)*100", "label": "Percent in Flight", "id": "e1", "period": 300, "region": "${data.aws_region.current}" } ],
                    [ { "expression": "(m4/m3)*100", "label": "Percent in Error", "id": "e2", "period": 300, "region": "${data.aws_region.current}" } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue.name}", { "id": "m2", "visible": false } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "id": "m4", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_json_queue.name}", { "id": "m3", "visible": false } ]
                ],
                "view": "timeSeries",
                "region": "${data.aws_region.current}",
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
                    [ { "expression": "((m3 - m2)/m3)*100", "label": "Percent in Flight", "id": "e1", "period": 300, "region": "${data.aws_region.current}" } ],
                    [ { "expression": "(m4/m3)*100", "label": "Percent in Error", "id": "e2", "period": 300, "region": "${data.aws_region.current}" } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue.name}", { "id": "m2", "visible": false } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "id": "m4", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_json_queue.name}", { "id": "m3", "visible": false } ]
                ],
                "view": "singleValue",
                "region": "${data.aws_region.current}",
                "stat": "Sum",
                "period": 300,
                "title": "Pipeline Point in Time"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 3,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_json_queue.name}", { "label": "Total Msg In (5 min)" } ],
                    [ ".", "NumberOfMessagesReceived", ".", ".", { "label": "Total Msg Out (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current}",
                "stat": "Sum",
                "period": 300,
                "title": "JSON Input Queue"
            }
        }
    ]
}
EOF

}