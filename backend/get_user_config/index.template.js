// backend/get_user_config/index.js
const {
  DynamoDBClient
} = require("@aws-sdk/client-dynamodb");

const {
  DynamoDBDocumentClient,
  GetCommand
} = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "${allowed_origin}",
  "Access-Control-Allow-Headers": "*",
  "Access-Control-Allow-Methods": "GET,OPTIONS",
};

exports.handler = async (event) => {

  if (event.requestContext.http.method == 'OPTIONS') {
    return {
        statusCode: 200,
        headers: CORS_HEADERS,
        body: '',
    };
  }

  const email = event.queryStringParameters?.email;

  if (!email) {
    return {
      statusCode: 400,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: "Missing 'email' query parameter" }),
    };
  }

  try {
    const command = new GetCommand({
      TableName: TABLE_NAME,
      Key: { email }
    });

    const result = await docClient.send(command);

    if (!result.Item) {
      return {
        statusCode: 404,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: "User not found" }),
      };
    }

    return {
      statusCode: 200,
      headers: CORS_HEADERS,
      body: JSON.stringify(result.Item),
    };
  } catch (error) {
    console.error("Error fetching user config:", error);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};