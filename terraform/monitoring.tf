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
            "x": 9,
            "y": 3,
            "width": 9,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue.name}", { "label": "Total Messages In (5 min)" } ],
                    [ ".", "NumberOfMessagesReceived", ".", ".", { "label": "Total Messages Out (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current.name}",
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
                "region": "${data.aws_region.current.name}",
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
                "region": "${data.aws_region.current.name}",
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
                    [ "AWS/Lambda", "Duration", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "stat": "Average", "label": "Avg Duration (5 min)" } ],
                    [ ".", "Errors", ".", ".", { "label": "Total Errors (5 min)" } ],
                    [ ".", "Invocations", ".", ".", { "label": "Total Invocations (5 min)" } ],
                    [ ".", "Throttles", ".", ".", { "label": "Total Throttles (5 min)" } ],
                    [ ".", "Concurrent.nameExecutions", ".", ".", { "stat": "Average", "label": "Avg Concurrent.name Executions (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current.name}",
                "stat": "Sum",
                "period": 300,
                "title": "JSON ETL Processor"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ { "expression": "(((2*m3) - (m1 + m2))/(2*m3))*100", "label": "Percent in Flight (5 min)", "id": "e1", "period": 300, "region": "${data.aws_region.current.name}" } ],
                    [ { "expression": "(m1/m2)*100", "label": "Percent Complete (5 min)", "id": "e3" } ],
                    [ { "expression": "(m4/m3)*100", "label": "Percent in Error (5 min)", "id": "e2", "period": 300, "region": "${data.aws_region.current.name}" } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue.name}", { "id": "m2", "visible": false } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "id": "m4", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_json_queue.name}", { "id": "m3", "visible": false } ],
                    [ "ChaosTransformer", "SymbolWriteCount", "DynamoDBTable", "${aws_dynamodb_table.chaos_data_table.name}", {"id": "m1", "visible": false}]
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
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ { "expression": "(((2*m3) - (m1 + m2))/(2*m3))*100", "label": "Percent in Flight (5 min)", "id": "e1", "period": 300, "region": "${data.aws_region.current.name}" } ],
                    [ { "expression": "(m1/m2)*100", "label": "Percent Complete (5 min)", "id": "e3" } ],
                    [ { "expression": "(m4/m3)*100", "label": "Percent in Error (5 min)", "id": "e2", "period": 300, "region": "${data.aws_region.current.name}" } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_csv_queue.name}", { "id": "m2", "visible": false } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.chaos_lambda.function_name}", { "id": "m4", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_json_queue.name}", { "id": "m3", "visible": false } ],
                    [ "ChaosTransformer", "SymbolWriteCount", "DynamoDBTable", "${aws_dynamodb_table.chaos_data_table.name}", { "id": "m1", "visible": false } ]
                ],
                "view": "singleValue",
                "region": "${data.aws_region.current.name}",
                "stat": "Sum",
                "period": 300,
                "title": "Pipeline Point in Time"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 3,
            "width": 9,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "${aws_sqs_queue.chaos_json_queue.name}", { "label": "Total Msg In (5 min)" } ],
                    [ ".", "NumberOfMessagesReceived", ".", ".", { "label": "Total Msg Out (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current.name}",
                "stat": "Sum",
                "period": 300,
                "title": "JSON Input Queue"
            }
        },
        {
            "type": "metric",
            "x": 18,
            "y": 3,
            "width": 6,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "ChaosTransformer", "SymbolWriteCount", "DynamoDBTable", "${aws_dynamodb_table.chaos_data_table.name}", { "label": "Total Updates (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "${data.aws_region.current.name}",
                "start": "-PT1H",
                "end": "P0D",
                "stat": "Sum",
                "period": 300,
                "title": "DynamoDB Update Count"
            }
        }
    ]
}
EOF

}
