const failureLambda = require('failure-lambda')

exports.handler = failureLambda(async (event, context) => {
    console.log ('Handling event', event);

    const response = {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!')
    };

    return response;
});
