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
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-csv-work-queue-90983042c82fb6e7" ],
                    [ ".", "NumberOfMessagesReceived", ".", "." ],
                    [ ".", "NumberOfMessagesDeleted", ".", "." ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
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
                    [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "chaos-error-queue-90983042c82fb6e7" ],
                    [ ".", "ApproximateAgeOfOldestMessage", ".", "." ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
                "stat": "Maximum",
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
                    [ "AWS/SNS", "NumberOfNotificationsFailed", "TopicName", "chaos-csv-notification-topic-90983042c82fb6e7" ],
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
                    [ "AWS/Lambda", "Duration", "FunctionName", "ChaosTransformer-90983042c82fb6e7", { "stat": "Average" } ],
                    [ ".", "Errors", ".", "." ],
                    [ ".", "Invocations", ".", "." ],
                    [ ".", "Throttles", ".", "." ],
                    [ ".", "ConcurrentExecutions", ".", ".", { "stat": "Average" } ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-west-2",
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
                    [ { "expression": "((m1 - m2)/m1)*100", "label": "Percent in Flight", "id": "e1", "period": 300, "region": "eu-west-2" } ],
                    [ { "expression": "(m4/m1)*100", "label": "Percent in Error", "id": "e2", "period": 300, "region": "eu-west-2" } ],
                    [ "AWS/Lambda", "Invocations", "FunctionName", "ChaosTransformer-90983042c82fb6e7", { "id": "m1", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-csv-work-queue-90983042c82fb6e7", { "id": "m2", "visible": false } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "ChaosTransformer-90983042c82fb6e7", { "id": "m4", "visible": false } ]
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
                    [ { "expression": "((m1 - m2)/m1)*100", "label": "Percent in Flight", "id": "e1", "period": 300, "region": "eu-west-2" } ],
                    [ { "expression": "(m4/m1)*100", "label": "Percent in Error", "id": "e2", "period": 300, "region": "eu-west-2" } ],
                    [ "AWS/Lambda", "Invocations", "FunctionName", "ChaosTransformer-90983042c82fb6e7", { "id": "m1", "visible": false } ],
                    [ "AWS/SQS", "NumberOfMessagesSent", "QueueName", "chaos-csv-work-queue-90983042c82fb6e7", { "id": "m2", "visible": false } ],
                    [ "AWS/Lambda", "Errors", "FunctionName", "ChaosTransformer-90983042c82fb6e7", { "id": "m4", "visible": false } ]
                ],
                "view": "singleValue",
                "region": "eu-west-2",
                "stat": "Sum",
                "period": 300,
                "title": "Pipeline Point in Time"
            }
        }
    ]
}
EOF

}