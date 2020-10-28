# Lab 4: Experiment with Service Disruption

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
                        -10.0,
                        50.0
                    ],
                    "target":"stdout"
                    },
                    "provider":{
                    "type":"process",
                    "path":"aws",
                    "arguments":"cloudwatch get-metric-data --metric-data-queries file://steadyStateFlight.json --start-time `date --date '5 min ago' -u '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date -u '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
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
                    "arguments":"cloudwatch get-metric-data --metric-data-queries file://steadyStateError.json --start-time `date --date '5 min ago' -u '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date -u '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
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
                "after": 300
            }
        }
    ],
    ```

1. Execute the experiment

    Now run the experiment.  As last time it will modify the failure-lambda configuration and then wait 5 minutes before re-evaluating the steady state.

    In this instance the percentage of messages in flight should be outside of tolerance.

## What have we learned?

1. Understanding the results

    Your experiment is configured to check a number of service level indicators to determine if the application is working normally.  The failed metric tracks the percentage of messages that are currently being processed by your ETL pipeline.  To see this metric for yourself you can execute the following AWS CLI command from within the `chaos` directory:

    > Note that the `date` command below assumes the Linux operating system.

    ```bash
    $ aws cloudwatch get-metric-data --metric-data-queries file://steadyStateFlight.json --start-time `date --date '5 min ago' -u '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date -u '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'
    ```

    As an alternative to the CLI you can visit your [CloudWatch metrics dashboard](https://console.aws.amazon.com/cloudwatch/home?#dashboards:) and look at the `Percent in Flight`.  Whether through the CLI or the AWS Console you should see that the Percentage in Flight is well over 20%.  You'll recall that this metric is calculated by subtracing the messages posted to the processed CSV SQS queue, and the records written to the DynamoDB table, from the messages posted to the JSON SQS queue and then dividing by the number of messages in the JSON queue.

    > ( ( (2*JSON messages) - (CSV messages + DynamoDB Writes) ) / (2*JSON messages) ) * 100

    Or alternatively

    > ( ( ( Messages In - Messages Out ) + ( Messages In - Records Stored ) ) / ( 2 * Messages In ) ) * 100

    The idea is that the number of messages in should always be, within tolerance, equal to the number of messages out, and the number of records written to the database.  

    In this experiement the number of messages in flight has grown wildly beyond normal expected tolerances, and even though half of the Lambda functions executing are not able to communicate with the DynamoDB service the error rate has remained within norms.  What is going on?

1. Behavior explained

    Diving into the metrics you'll notice that the number of messages going into the Output queue have remained roughly on par with the Input queue, but the number of DynamoDB Updates is roughly half; this would be inline with the 50% intermittent connectivity rate to DynamoDB.  But if the Lambda is unable to communicate with DynamoDB why isn't an error getting raised?

    If you visit the Monitoring tab of the Lambda function and scroll down to the list of the most expensive invocations these will likely be one of the executions that had difficulty connecting to DynamoDB.  To review the log entries copy the RequestID and click the LogStream link for the request.  On the CloudWatch Logs console, in the Filter Events search field paste the RequestID in quotes to view only those log entries that relate to the execution.  Along with the normal execution messages you should see messages such as the following which show the Lambda was unable to connect to DynamoDB:

    ```
    7b2c3ad9-0e0c-5c3c-83e7-6c2de114e600	INFO	Intercepted network connection to dynamodb.us-east-2.amazonaws.com
    ```

    If you look at the source code you'll notice that the Lambda should be outputting to the log when it has successfully written records to DynamoDB.  Due to the asynchronous nature of NodeJS the calls to DynamoDB (and S3) are being performed asynchronously.  This provides a tremendous performance advantage, an event-driven code base, but it also means that the Lambda may be leaving threads, which are still executing, behind when it exits.

## Iterate and improve

1. Fix it

    Looking at the source code for the Lambda you'll notice that the function ends with a `return` statement.  This returns control back to the Lambda system without waiting for the NodeJS event loop to be empty.  If this line is changed to use the `callback` function Lambda will then wait for the event loop to be empty, ie for the DyanmoDB calls to fail or succeed, before exiting the Lambda.  In this way the Lambda will continue to try to communicate with DynamoDB until the function times out, causing an error that is tracked by the Site Reliability Objectives.

    Modify the `lambda.js` to replace the return statement around line 133 with the following:
    
    ```javascript
    callback (null, response);
    ```

    Reapply your Terraform template to push the source code change into AWS.

1. Break it again

    Now re-run your Chaos experiment and notice that the experiment still fails but now it fails because the error rate is unnacceptably high.  How could you improve the architecture to better account for this situation?


## Summary

You have now concluded this workshop.  You have used Chaos-Toolkit and failure-lambda to develop and execute chaos experiments on a serverless architecture on AWS.  There are many more experiments which can be performed on this architecture to improve it, but how will you now use this informaiton to improve your own serverless architecture?
