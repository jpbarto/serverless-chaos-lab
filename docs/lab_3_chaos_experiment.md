# Lab 3: Your first Chaos Experiment

## Objective

Using Chaos-Toolkit work through the process of designing a hypothesis and creating an experiment to test the hypothesis.

## Outline

The following experiment should cause the Lambda function to exceed its allotted runtime.  A simple fix, merely extend the Lambda allowed run time.

Update the Terraform code to change the runtime to a value of 2 minutes.

reapply the terraform.

## Chaos Experiment

```json
{
  "version": "1.0.0",
  "title": "Delay should not impact processing",
  "description": "Inject latency into Lambda function execution and ensure files are still processed.",
  "tags": [
      "serverless",
      "cloudnative",
      "etl"
  ],
  "configuration": {
      "s3_bucket": {
          "type": "env",
          "key": "S3_BUCKET_NAME"
      },
      "sns_topic": {
          "type": "env",
          "key": "SNS_TOPIC_NAME"
      },
      "lambda_function": {
          "type": "env",
          "key": "LAMBDA_FUNCTION_NAME"
      }
  },
  "steady-state-hypothesis": {
      "title": "Services are all available and healthy",
      "probes": [
          {
              "type": "probe",
              "name": "zero-sns-errors",
              "tolerance": 0,
              "provider": {
                  "type": "python",
                  "module": "chaosaws.cloudwatch.probes",
                  "func": "get_metric_statistics",
                  "arguments": {
                      "namespace": "AWS/SNS",
                      "metric_name": "NumberOfNotificationsFailed",
                      "dimension_name": "TopicName",
                      "dimension_value": "${sns_topic}",
                      "statistic": "Sum",
                      "duration": 900
                  }
              }
          },
          {
              "type": "probe",
              "name": "messages-in-flight",
              "tolerance": {
                  "type": "range",
                  "range": [1.0, 6.0],
                  "target": "stdout"
              },
              "provider": {
                  "type": "process",
                  "path": "aws",
                  "arguments": "cloudwatch get-metric-data --region eu-west-2 --metric-data-queries file://steadyStateFlight.json --start-time `date -v-5M '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
              }
          },
          {
              "type": "probe",
              "name": "normal-error-rates",
              "tolerance": {
                  "type": "range",
                  "range": [0.0, 2.0],
                  "target": "stdout"
              },
              "provider": {
                  "type": "process",
                  "path": "aws",
                  "arguments": "cloudwatch get-metric-data --region eu-west-2 --metric-data-queries file://steadyStateError.json --start-time `date -v-5M '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
              }
          }
      ]
  },
  "method": [
      {
          "type": "action",
          "name": "Enable Lambda failure: LATENCY",
          "provider": {
              "type": "process",
              "path": "aws",
              "arguments": "ssm put-parameter --name failureLambdaConfig --type String --overwrite --value '{\"isEnabled\": true, \"failureMode\": \"latency\", \"rate\": 0.5, \"minLatency\": 3000, \"maxLatency\": 4000, \"exceptionMsg\": \"Exception message!\", \"statusCode\": 404, \"diskSpace\": 100}'"
          },
          "pauses": {
              "after": 360
          }
      }
  ],
  "rollbacks": [
      {
          "type": "action",
          "name": "Disable Lambda failures",
          "provider": {
              "type": "process",
              "path": "aws",
              "arguments": "ssm put-parameter --name failureLambdaConfig --type String --overwrite --value '{\"isEnabled\": false, \"failureMode\": \"latency\", \"rate\": 0.5, \"minLatency\": 30, \"maxLatency\": 40, \"exceptionMsg\": \"Exception message!\", \"statusCode\": 404, \"diskSpace\": 100}'"
          }
      }
  ]
}
```