// require the failure-lambda wrapper to support Chaos Engineering
const failureLambda = require('failure-lambda');

// require the AWS SDK to communicate with S3 and DynamoDB
var AWS = require('aws-sdk');
// require json2csv to parse the JSON files published to S3
const { parse } = require('json2csv');

const fields = ['objectName', 'submissionDate', 'author', 'formatVersion'];
const opts = { "fields": fields };

var s3 = new AWS.S3();
var ddb = new AWS.DynamoDB.DocumentClient();
var cloudwatch = new AWS.CloudWatch();

var chaosDataTable = process.env.CHAOS_DATA_TABLE;

exports.handler = failureLambda(async(event, context, callback) => {
    console.log('ETL processor handling event', JSON.stringify(event));

    var s3Event = JSON.parse(event.Records[0].body);
    console.log('Extracted S3 event', JSON.stringify(s3Event));

    // retrieve key fields from the S3 event object
    var srcBucket = s3Event.Records[0].s3.bucket.name;
    // Object key may have spaces or unicode non-ASCII characters.
    var srcKey = decodeURIComponent(s3Event.Records[0].s3.object.key.replace(/\+/g, " "));
    var dstBucket = srcBucket;
    var dstKey = "output/" + srcKey.replace(/input\//g, "") + ".csv";

    console.log("Reading JSON file", srcKey, "in bucket", srcBucket);

    const data = await s3.getObject({ Bucket: srcBucket, Key: srcKey }).promise();
    var jsonData = JSON.parse(data.Body.toString('utf-8'));
    console.log("Retrieved JSON data:", jsonData);

    // Update the database with the latest summary of the symbol
    let params = {
        TableName: chaosDataTable,
        Key: {
            "symbol": jsonData.symbol,
            "entryType": "latest"
        },
        UpdateExpression: "ADD updateCount :i, symbolValue :v SET lastMessage = :mid",
        ExpressionAttributeValues: {
            ":mid": jsonData.messageId,
            ":v": jsonData.value,
            ":i": 1
        },
        ReturnValues: "UPDATED_NEW"
    };
    ddb.update(params, function(err, data) {
        if (err) {
            console.error("Unable to update", jsonData.symbol, "aggregate record in DynamoDB, Error JSON:", JSON.stringify(err, null, 2));
        }
        else {
            console.log("Updated DynamoDB for", jsonData.symbol, ":", JSON.stringify(data, null, 2));
        }
    });

    // record the individual record
    var dateStr = (new Date()).toISOString();
    params = {
        TableName: chaosDataTable,
        Key: {
            "symbol": jsonData.symbol,
            "entryType": dateStr + "#" + jsonData.messageId
        },
        UpdateExpression: "SET symbolValue =:v, processingTimestamp = :d, messageId = :mid",
        ExpressionAttributeValues: {
            ":mid": jsonData.messageId,
            ":v": jsonData.value,
            ":d": dateStr
        },
        ReturnValues: "UPDATED_NEW"
    };
    ddb.update(params, function(err, data) {
        if (err) {
            console.error("Unable to record message ID in DynamoDB, Error JSON:", JSON.stringify(err, null, 2));
        }
        else {
            console.log("Recorded", jsonData.symbol, "message ID", jsonData.messageId, "in DynamoDB", JSON.stringify(data, null, 2));
            
            var cwParams = {
                MetricData: [{
                    MetricName: 'SymbolWriteCount',
                    Dimensions: [{
                        Name: 'DynamoDBTable',
                        Value: chaosDataTable
                    }],
                    StorageResolution: 1,
                    Timestamp: new Date(),
                    Unit: 'Count',
                    Value: 1,
                }],
                Namespace: 'ChaosTransformer'
            };

            cloudwatch.putMetricData(cwParams, function(err, data) {
                if (err) {
                    console.log("Error logging custom metrics:", err, err.stack);
                } else {
                    console.log("Successfully logged custom metric update:", data); 
                }
            });

        }
    });


    /**
     * Perform the ETL and write the converted data to S3
     */
    try {
        const csvData = parse(jsonData, opts);
        console.log("Parsed CSV data from JSON:", csvData);
        const result = await s3.putObject({ Bucket: dstBucket, Key: dstKey, Body: csvData, ContentType: 'text/csv' }).promise();
    }
    catch (err) {
        console.error(err);
        callback(err);
    }

    /**
     * Respond completion back to the Lambda systems
     * */
    const response = {
        statusCode: 200,
        body: JSON.stringify('Input conversion complete')
    };

    console.log("ETL processer completed processing of", srcKey, "in bucket", srcBucket);
    return response;
});
