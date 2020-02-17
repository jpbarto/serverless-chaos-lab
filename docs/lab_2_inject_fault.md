# Lab 2: Evaluate failure injection with AWS Lambda

## Overview

In this lab you will use the ETL Lambda function created in the previous lab to experiment with the [failure-lambda]() NPM package.

```json
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "eu-west-2",
      "eventTime": "2020-02-16T23:59:20.011Z",
      "eventName": "ObjectCreated:Put",
      "userIdentity": {
        "principalId": "AWS:AROAIQS4NNAGDABCDEILY:joeuser"
      },
      "requestParameters": {
        "sourceIPAddress": "18.130.212.123"
      },
      "responseElements": {
        "x-amz-request-id": "08F6AA9326A9EAA4",
        "x-amz-id-2": "/Rwi0Hz/zestFebmxfy1L6Kr1kypE4Q35kfakKOb6t7oJOUhdMz7L83L2ZCqu8UUG6StSyUlajsdzE8Q4MQVkQOnEMlR3Rcp"
      },
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "tf-s3-lambda-20200216014810664500000002",
        "bucket": {
          "name": "< YOUR S3 BUCKET NAME >",
          "ownerIdentity": {
            "principalId": "A3N0SH1NMZ1234"
          },
          "arn": "arn:aws:s3:::< YOUR S3 BUCKET NAME >"
        },
        "object": {
          "key": "input/data_object_1.json",
          "size": 146,
          "eTag": "1ca3c94e4f092f9568e638f1d927f68a",
          "sequencer": "005E49D75858B18ABE"
        }
      }
    }
  ]
}
```