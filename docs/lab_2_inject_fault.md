# Lab 2: Evaluate failure injection with AWS Lambda

## Overview

In this lab you will use the [failure-lambda](https://www.npmjs.com/package/failure-lambda) NPM package to inject failures into the AWS Lambda function of your ETL architecture.

## Failure-Lambda

A challenge with serverless services like DynamoDB, SQS, and Lambda is that you cannot directly affect the underlying service to introduce disruption.  Some developers have begun to create abilities to simulate failures however and we will use one such library today to disrupt the Lambda function in our architecture.

[Failure-Lambda](https://github.com/gunnargrosch/failure-lambda) was created by [Gunnar Grosch](https://grosch.se/) to allow teams to inject turbulence into NodeJS code.  It provides a wrapper around NodeJS functions and can artificially cause:

 - latency
 - network disruption
 - disk out of space errors
 - artificial exceptions
 - return a specific response code

If you review the [code](../src/lambda.js) for your AWS Lambda function you will note that it already has the failure-lambda wrapper in place.  The Lambda function also has an environment variable defined which points at an key-value pair in AWS Parameter Store.  Have a look at the [AWS Lambda console](https://console.aws.amazon.com/lambda/home?#/functions) to find the name of the parameter and then review the current value of the parameter in the [Parameter Store console](https://console.aws.amazon.com/systems-manager/parameters?).

## Test your Lambda Function

1. Create an AWS Lambda test event

    To begin experimenting with the Failure-Lambda package we will need to first create a Test Event that we can use to execute the Lambda function.  Looking at the detail page for your Lambda function on the [AWS Lambda console](https://console.aws.amazon.com/lambda/home?#/functions) you will see in the upper-right of the screen a drop down labeled `Select a test event` next to a `Test` button.  From the drop down select `Configure test events`.

1. Define the event body

    Give the event a name such as `TestObject001` and use the following JSON.  Be sure and modify the JSON replacing the two occurrences of `< YOUR S3 BUCKET NAME >` with the name of your S3 bucket.

    ```json
    {
        "Records": [
            {
                "messageId": "129ec50c-d702-4754-aaba-efd5376c63ab",
                "receiptHandle": "AQEB/4rCbig4Mkm6JphKbx9okY=",
                "body": "{\"Records\":[{\"eventVersion\":\"2.1\",\"eventSource\":\"aws:s3\",\"awsRegion\":\"eu-west-2\",\"eventTime\":\"2020-03-08T00:40:44.110Z\",\"eventName\":\"ObjectCreated:Put\",\"userIdentity\":{\"principalId\":\"AWS:AROAZXQEFEFVE:i-00f000f4c212ad0d4\"},\"requestParameters\":{\"sourceIPAddress\":\"3.9.176.208\"},\"responseElements\":{\"x-amz-request-id\":\"81EBAE99F537B548\",\"x-amz-id-2\":\"7AZjqqd/C7ptM8LijtnCWEV\"},\"s3\":{\"s3SchemaVersion\":\"1.0\",\"configurationId\":\"tf-s3-queue-20203213469500000002\",\"bucket\":{\"name\":\"< YOUR S3 BUCKET NAME >\",\"ownerIdentity\":{\"principalId\":\"A3N0SH17G\"},\"arn\":\"arn:aws:s3:::< YOUR S3 BUCKET NAME >\"},\"object\":{\"key\":\"input/data_object_msg-1.json\",\"size\":175,\"eTag\":\"4bb6a876175bd3a503be348dcc5fbd9f\",\"sequencer\":\"005E643F0D2EB9D5EA\"}}}]}",
                "attributes": {
                    "ApproximateReceiveCount": "1",
                    "SentTimestamp": "1583628046604",
                    "SenderId": "AIDAIKZTX7KCMABLW",
                    "ApproximateFirstReceiveTimestamp": "1583628050669"
                },
                "messageAttributes": {},
                "md5OfBody": "57107cfd574671604fde285823dcdef7",
                "eventSource": "aws:sqs",
                "eventSourceARN": "arn:aws:sqs:eu-west-2:771234451234:chaos-json-work-queue-cedabABCD32b8513",
                "awsRegion": "eu-west-2"
            }
        ]
    }
    ```

1. Perform a successful test

    Before we start injecting failures lets ensure your function is testing normally.  Click the `Test` button with your new test event defined.  The results should result in a `Succeeded` status.

1. Configure Failure-Lambda for latency injection

    Modify the parameter store value you found earlier to have the following value:

    ```json
    {
        "isEnabled": true, 
        "failureMode": "latency", 
        "rate": 1, 
        "minLatency": 1000, 
        "maxLatency": 5000
    }
    ```

    This instructs the Failure-Lambda wrapper in the Lambda function to inject latency for every execution (`rate: 1`) with a random latency between 1 second and 5 seconds.

1. Execute the impaired Lambda function

    Return to the AWS Lambda console and re-run your Lambda test, observe the results.  How long did the function take to execute?  If you execute it again how long does it take a second time around?  What is the impact of the latency injection?  Does it cause any failures?

1. Configure Failure-Lambda for network failure

    Failure-Lambda has the ability to block network access to specified domains.  This simulates a loss of connectivity which could be caused by a network outage or a service disruption at an endpoint.  To inject network failure set the parameter to a value of the following:

    ```json
    { 
        "isEnabled": true, 
        "failureMode": "blacklist", 
        "rate": 1, 
        "blacklist": ["dynamodb.*.amazonaws.com"]
    }
    ```

    This configuration will cause failure-lambda to, 100% of the time, disallow any network communication with the DynamoDB service in any AWS region.

1. Execute the network impaired Lambda function

    Return to the AWS Lambda console again and execute the Lambda function.  What are the effects of the network issue?

1. Disable the Failure-Lambda wrapper

    To prepare for your first chaos experiment temporarily disable the Failure-Lambda wrapper.  Set the parameter value back to the following to disable failure injection:

    ```json
    {
        "isEnabled": false
    }
    ```

## Summary

In this lab you learned about the Failure-Lambda NodeJS library and how it can be used to inject artificial failures and disruption into your Lambda functions.

In [the next lab](lab_3_chaos_experiment.md) you will craft your first chaos experiment which will use the failure-lambda library to perturb your ETL architecture and observe the system's ability to perform in turbulent conditions.