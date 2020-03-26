# Lab 4: Second Chaos Experiment

## Objective

In this lab you will experiment with a different failure mode that could effect your application.  The application relies on the DynamoDB service, lets inject intermittent connectivity to the service and observe how the overall application responds.

## Service Availability

In the last lab you created your first chaos experiment using the Chaos Toolkit.  In this lab you will explore a different failure mode and examine how the application performs.  The failure mode we want to explore in this lab is the waivering availability of a dependency.  We cannot temporarily disrupt the DynamoDB service however we can temporarily disrupt connectivity to the service.

To simulate a service disruption we will again use the failure-lambda library's `blacklist` feature to block access to the DyanmoDB API some percentage of the time.

## The Next Experiment

1. Start your experiment definition

    Lets start as we did last time by creating a skeleton template for this experiment.  Create a file named `exp_2-dynamodb_disruption.json` with the following contents:

    ```json
    {
        "version":"1.0.0",
        "title":"Dependency disruption should not impact processing",
        "description":"Disrupt access to the DynamoDB service and ensure files are still processed.",
        "tags":[
            "serverless",
            "cloudnative",
            "etl"
        ],
        "configuration":{
            "s3_bucket":{
                "type":"env",
                "key":"S3_BUCKET_NAME"
            },
            "sns_topic":{
                "type":"env",
                "key":"SNS_TOPIC_NAME"
            },
            "lambda_function":{
                "type":"env",
                "key":"LAMBDA_FUNCTION_NAME"
            }
        },
        "steady-state-hypothesis":{
            "title":"System operating within norms",
            "probes":[
                {
                    "type":"probe",
                    "name":"zero-sns-errors",
                    "tolerance":0,
                    "provider":{
                    "type":"python",
                    "module":"chaosaws.cloudwatch.probes",
                    "func":"get_metric_statistics",
                    "arguments":{
                        "namespace":"AWS/SNS",
                        "metric_name":"NumberOfNotificationsFailed",
                        "dimension_name":"TopicName",
                        "dimension_value":"${sns_topic}",
                        "statistic":"Sum",
                        "duration":900
                    }
                    }
                },
                {
                    "type":"probe",
                    "name":"messages-in-flight",
                    "tolerance":{
                    "type":"range",
                    "range":[
                        0.0,
                        80.0
                    ],
                    "target":"stdout"
                    },
                    "provider":{
                    "type":"process",
                    "path":"aws",
                    "arguments":"cloudwatch get-metric-data --metric-data-queries file://steadyStateFlight.json --start-time `date --date '5 min ago' '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
                    }
                },
                {
                    "type":"probe",
                    "name":"normal-error-rates",
                    "tolerance":{
                    "type":"range",
                    "range":[
                        0.0,
                        5.0
                    ],
                    "target":"stdout"
                    },
                    "provider":{
                    "type":"process",
                    "path":"aws",
                    "arguments":"cloudwatch get-metric-data --metric-data-queries file://steadyStateError.json --start-time `date --date '5 min ago' '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
                    }
                }
            ]
        },
        "method":[
        ],
        "rollbacks":[
            {
                "type":"action",
                "name":"Disable Lambda failures",
                "provider":{
                    "type":"process",
                    "path":"aws",
                    "arguments":"ssm put-parameter --name failureLambdaConfig --type String --overwrite --value '{\"isEnabled\": false}'"
                }
            }
        ]
    }
    ```

    Everything in this template is the same as last time, you have the same steady state definition, the same rollback.  The title and description are updated to reflect the nature of the experiment however.

1. Actions

    To simulate a service disruption with DynamoDB you will use the `blacklist` feature of the failure-lambda library.  Similar to the last experiment, define an action which configures the failure-lambda library to block access to any URL which matches the DynamoDB endpoint URI 50% of the time.

    ```json
    "method":[
        {
            "type":"action",
            "name":"Enable Lambda failure: BLACKLIST",
            "provider":{
                "type":"process",
                "path":"aws",
                "arguments":"ssm put-parameter --name failureLambdaConfig --type String --overwrite --value '{\"isEnabled\": true, \"failureMode\": \"blacklist\", \"rate\": 0.5, \"blacklist\": [\"dynamodb.*.amazonaws.com\"]}'"
            },
            "pauses":{
                "after": 180
            }
        }
    ],
    ```

1. Execute the experiment

    Now run the experiment.  As last time it will modify the failure-lambda configuration and then wait 5 minutes before re-evaluating the steady state.

    In this instance the percentage of messages in flight should be outside of tolerance.

1. Understanding the results

    Your experiment is configured to check a number of KPIs to determine if the application is working normally.  The failed metric tracks the percentage of messages that are currently being processed by your ETL pipeline.  To see this metric for yourself you can execute the following AWS CLI command from within the `chaos` directory:

    ```bash
    $ aws cloudwatch get-metric-data --metric-data-queries file://steadyStateFlight.json --start-time `date --date '5 min ago' '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'
    ```

    As an alternative to the CLI you can visit your [CloudWatch metrics dashboard](https://console.aws.amazon.com/cloudwatch/home?#dashboards:) and look at the `Percent in Flight`.  Whether through the CLI or the AWS Console you should see that the Percentage in Flight is negative.  You'll recall that this metric is calculated by subtracing the messages posted to the processed CSV SQS queue from the messages posted to the JSON SQS queue and then dividing by the number of messages in the JSON queue.

    > ( ( JSON messages - CSV messages ) / JSON messages ) * 100

    Or alternatively

    > ( ( Messages In - Messages Out ) / Messages In ) * 100

    The idea is that the number of messages in will always equal or be greater than the number of messages out.  So if the result is a negative number then the number of messages out is GREATER than the number of messages in.  How could this be?  Why would this be happening?

1. Behavior explained

    Hopefully its clear that in order for the `Percent in Flight` to be a negative number the number of messages flowing out of the pipeline are greater than the messages flowing in.  This suggests that the architecture is processing messages multiple times, causing duplication.

    If you visit the Monitoring tab of the Lambda function and scroll down to the list of the most expensive invocations these will likely be one of the executions that had difficulty connecting to DynamoDB.  To review the log entries copy the RequestID and click the LogStream link for the request.  On the CloudWatch Logs console, in the Filter Events search field paste the RequestID in quotes to view only those log entries that relate to the execution.  Along with the normal execution messages you should see messages such as the following which show the Lambda was unable to connect to DynamoDB:

    ```
    7b2c3ad9-0e0c-5c3c-83e7-6c2de114e600	INFO	Intercepted network connection to dynamodb.us-east-2.amazonaws.com
    ```

1. Fix it

    Looking at the source code you will notice that, around line 41, there is a call to DynamoDB which tries to check for a prior record of the message having been processed.  This is an asynchronous call and so, while NodeJS waits for DynamoDB to respond, it continues executing, making additional calls to DynamoDB and Amazon S3.  As a result, even though DynamoDB may be having issues the Lambda itself still writes output to Amazon S3.

    To correct this we can instruct NodeJS to wait for the call to DynamoDB to return, this will prevent any further processing until connectivity to DynamoDB has been confirmed.  Update the source code to add the `await` modifier to the initial call to DynamoDB:

    ```javascript
    var ddbData = await ddb.get (params).promise ();
    ```

    Reapply your Terraform template to push the source code change into AWS.

1. Break it again

    Now re-run your Chaos experiment and notice that the experiment still fails but now it fails because the error rate is unnacceptably high.  How could you improve the architecture to better account for this situation?


## Summary