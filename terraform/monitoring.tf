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
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-csv-work-queue-90983042c82fb6e7", { "label": "Total Messages In (5 min)" } ],
                    [ ".", "NumberOfMessagesReceived", ".", ".", { "label": "Total Messages Out (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
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
                    [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "chaos-error-queue-90983042c82fb6e7", { "label": "Approx. Msgs in Queue (5 min)" } ],
                    [ ".", "ApproximateAgeOfOldestMessage", ".", ".", { "label": "Approx. Oldest Msg Age" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
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
                    [ "AWS/SNS", "NumberOfNotificationsFailed", "TopicName", "chaos-csv-notification-topic-90983042c82fb6e7", { "label": "Error Count (5 min)" } ],
                    [ ".", "NumberOfNotificationsDelivered", ".", ".", { "label": "Total Messages Out (5 min)" } ],
                    [ ".", "NumberOfMessagesPublished", ".", ".", { "label": "Total Messages In (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
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
                    [ "AWS/Lambda", "Duration", "FunctionName", "ChaosTransformer-90983042c82fb6e7", { "stat": "Average", "label": "Avg Duration" } ],
                    [ ".", "Errors", ".", ".", { "label": "Total Errors" } ],
                    [ ".", "Invocations", ".", ".", { "label": "Total Invocations" } ],
                    [ ".", "Throttles", ".", ".", { "label": "Total Throttles" } ],
                    [ ".", "ConcurrentExecutions", ".", ".", { "stat": "Average", "label": "Avg Concurrent Executions" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
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
                    [ { "expression": "((m3 - m2)/m3)*100", "label": "Percent in Flight", "id": "e1", "period": 300, "region": "eu-west-2" } ],
                    [ { "expression": "(m4/m3)*100", "label": "Percent in Error", "id": "e2", "period": 300, "region": "eu-west-2" } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-csv-work-queue-90983042c82fb6e7", { "id": "m2", "visible": false } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "ChaosTransformer-90983042c82fb6e7", { "id": "m4", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-json-work-queue-90983042c82fb6e7", { "id": "m3", "visible": false } ]
                ],
                "view": "timeSeries",
                "region": "eu-west-2",
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
                    [ { "expression": "((m3 - m2)/m3)*100", "label": "Percent in Flight", "id": "e1", "period": 300, "region": "eu-west-2" } ],
                    [ { "expression": "(m4/m3)*100", "label": "Percent in Error", "id": "e2", "period": 300, "region": "eu-west-2" } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-csv-work-queue-90983042c82fb6e7", { "id": "m2", "visible": false } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "ChaosTransformer-90983042c82fb6e7", { "id": "m4", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-json-work-queue-90983042c82fb6e7", { "id": "m3", "visible": false } ]
                ],
                "view": "singleValue",
                "region": "eu-west-2",
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
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-json-work-queue-90983042c82fb6e7", { "label": "Total Msg In (5 min)" } ],
                    [ ".", "NumberOfMessagesReceived", ".", ".", { "label": "Total Msg Out (5 min)" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
                "stat": "Sum",
                "period": 300,
                "title": "JSON Input Queue"
            }
        }
    ]
}
EOF

}