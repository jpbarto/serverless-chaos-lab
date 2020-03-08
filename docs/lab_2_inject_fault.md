# Lab 2: Evaluate failure injection with AWS Lambda

## Overview

In this lab you will use the ETL Lambda function created in the previous lab to experiment with the [failure-lambda]() NPM package.

## Failure-Lambda

A challenge with serverless services like DynamoDB, SQS, and Lambda is that you cannot directly affect the underlying service to introduce disruption.  Some developers have begun to create abilities to simulate failures however and we will use one such library today to disrupt the Lambda function in our architecture.

[Failure-Lambda](https://github.com/gunnargrosch/failure-lambda)

1. Visit the [Lambda console](https://console.aws.amazon.com/lambda/home) and inspect the Lambda function.
1. Open the function named `ChaosTransformer-ABC123`
1. In the upper-right hand side of the function console configure a test event.
1. Use the test event below as the content of the event.  Be sure and replace `< YOUR S3 BUCKET NAME >` with the name of your S3 bucket.

Use the following as a test event for your Lambda function.  Be sure and set the bucket name appropriately.
```json
{
    "Records": [
        {
            "messageId": "129ec50c-d702-4754-aaba-efd5376c63ab",
            "receiptHandle": "AQEB/4rCbigFqvDg4MkiZ7jgp4WFgF75IKHcaOGFaHvkwivEoGnnTnULpt2Oo/CvCQ1vQUrJX4B3zsI9kzoJVI2uirzWck1b67mfRt/KoViQjyhJkcnpprUjEXMjYp3gzzqwXUEMayYkXr8u/CODVlblc2TetbhHFjzQjBpK3cNieqGifZKSfr5h6lhYU/MOLOmdg07Cl3Qlg5R8dfCaJn/E4aaomYLTtYQvmW6xook6+3u8vs1n1GCHz3CvINhH71xtHYRhoVIigTQJ++wSyZ3l5at2WpvIB17uo40TGv8Ms+dXB0LrqKOtpluM/E9Qwm7/Y0bFVtOOO5dx23gO6fjOckTnPij2MeeWAaz+tMOTp0Nl5bsh/ZhEGaIssZQgYDjeRodIM44thdgAaN+zO5/VyhCnSF6txbkm6JphKbx9okY=",
            "body": "{\"Records\":[{\"eventVersion\":\"2.1\",\"eventSource\":\"aws:s3\",\"awsRegion\":\"eu-west-2\",\"eventTime\":\"2020-03-08T00:40:44.110Z\",\"eventName\":\"ObjectCreated:Put\",\"userIdentity\":{\"principalId\":\"AWS:AROAJFPWDZIUZXQEFEFVE:i-00f000f4c212ad0d4\"},\"requestParameters\":{\"sourceIPAddress\":\"3.9.176.208\"},\"responseElements\":{\"x-amz-request-id\":\"81EBAE99F537B548\",\"x-amz-id-2\":\"7AZjqqd/CvQETeKNOh3o7ptM8LijvhhTA0nb6VhNOghuRNuEoIH2ZJ+dzJiiOOtkkmCMphMjFQBdhTvoU89WEgCmhPtnCWEV\"},\"s3\":{\"s3SchemaVersion\":\"1.0\",\"configurationId\":\"tf-s3-queue-20200308003213469500000002\",\"bucket\":{\"name\":\"< YOUR S3 BUCKET NAME >\",\"ownerIdentity\":{\"principalId\":\"A3N0SH1NMZ1W7G\"},\"arn\":\"arn:aws:s3:::< YOUR S3 BUCKET NAME >\"},\"object\":{\"key\":\"input/data_object_msg-1.json\",\"size\":175,\"eTag\":\"4bb6a876175bd3a503be348dcc5fbd9f\",\"sequencer\":\"005E643F0D2EB9D5EA\"}}}]}",
            "attributes": {
                "ApproximateReceiveCount": "1",
                "SentTimestamp": "1583628046604",
                "SenderId": "AIDAIKZTX7KCMFEFP3TLW",
                "ApproximateFirstReceiveTimestamp": "1583628050669"
            },
            "messageAttributes": {},
            "md5OfBody": "57107cfd574671604fde285823dcdef7",
            "eventSource": "aws:sqs",
            "eventSourceARN": "arn:aws:sqs:eu-west-2:776347451234:chaos-json-work-queue-cedab75de32b8513",
            "awsRegion": "eu-west-2"
        }
    ]
}
```

Create the test event and execute your function, it should execute normally.

Visit the [SSM Parameter Store console](https://console.aws.amazon.com/systems-manager/parameters) and modify the SSM parameter `failureLambdaConfig` governing the Failure-Lambda library and observe the effects of different configurations such as latency or blacklist.

When you're done be sure and set the SSM parameter back to a disabled value such as:

```json
{
    "isEnabled": false, 
    "failureMode": "latency", 
    "rate": 1, 
    "minLatency": 100, 
    "maxLatency": 400, 
    "exceptionMsg": "Exception message!", 
    "statusCode": 404, 
    "diskSpace": 100
}
```