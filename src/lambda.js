const failureLambda = require('failure-lambda');

var AWS = require('aws-sdk');
const { parse } = require('json2csv');

const fields = ['objectName', 'submissionDate', 'color', 'age'];
const opts = { "fields": fields };


var s3 = new AWS.S3();

exports.handler = failureLambda(async (event, context, callback) => {
    console.log ('Handling event', JSON.stringify (event));

    var srcBucket = event.Records[0].s3.bucket.name;
    // Object key may have spaces or unicode non-ASCII characters.
    var srcKey    = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));
    var dstBucket = srcBucket;
    var dstKey    = "output/" + srcKey.replace(/input\//g, "") +".csv";

    console.log ("Reading JSON file", srcKey, "in bucket", srcBucket);

    const data = await s3.getObject({ Bucket: srcBucket, Key: srcKey }).promise ();
    jsonData = JSON.parse (data.Body.toString ('utf-8'));
    console.log ("Read data:", jsonData);

    try {
        const csvData = parse (jsonData, opts);
        console.log("CSV data", csvData);
        const result = await s3.putObject({ Bucket: dstBucket, Key: dstKey, Body: csvData, ContentType: 'text/csv' }).promise ();
    } catch (err) {
        console.error(err);
    }


    const response = {
        statusCode: 200,
        body: JSON.stringify('Input conversion complete')
    };

    console.log ("Object processed");
    callback(null, response);
});
