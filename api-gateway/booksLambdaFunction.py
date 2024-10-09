# import json
# import boto3

# client = boto3.client('dynamodb')
# dynamodb = boto3.resource("dynamodb")
# table = dynamodb.Table('Books')
# tableName = 'Books'


# def lambda_handler(event, context):
#     body = {}
#     statusCode = 200
#     headers = {
#         "Content-Type": "application/json"
#     }
#     # print(event)
#     try:
#         if event['routeKey'] == "DELETE /books/{id}":
#             table.delete_item(
#                 Key={'id': event['pathParameters']['id']})
#             body = 'Deleted item ' + event['pathParameters']['id']
#         elif event['routeKey'] == "GET /books/{id}":
#             body = table.get_item(
#                 Key={'id': event['pathParameters']['id']})
#             body = body["Item"]
#             responseBody = [
#                 {'ID': body["ID"], 'BookTitle': body["BookTitle"], 'author': body['author']}]
#             body = responseBody
#         elif event['routeKey'] == "GET /books":
#             body = table.scan()
#             body = body["Items"]
#             print("ITEMS----")
#             print(body)
#             responseBody = []
#             for items in body:
#                 responseItems = [
#                     {'ID': body["ID"], 'BookTitle': body["BookTitle"], 'author': body['author']}
#                 ]
#                 responseBody.append(responseItems)
#             body = responseBody
#         elif event['routeKey'] == "PUT /books":
#             requestJSON = json.loads(event['body'])
#             table.put_item(
#                 Item={
#                     'ID': requestJSON["ID"], 
#                     'BookTitle': requestJSON["BookTitle"], 
#                     'author': requestJSON['author']
#                 })
#             body = 'Put item ' + requestJSON['id']
#     except KeyError:
#         statusCode = 400
#         body = 'Unsupported route: ' + event['routeKey']
#     body = json.dumps(body)
#     res = {
#         "statusCode": statusCode,
#         "headers": {
#             "Content-Type": "application/json"
#         },
#         "body": body
#     }
#     return res

import json
import boto3


client = boto3.client('dynamodb')
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table('Books')

def lambda_handler(event, context):
    body = {}
    statusCode = 200
    headers = {
        "Content-Type": "application/json"
    }

    try:
        # Handle DELETE /books/{id}
        if event['httpMethod'] == "DELETE" and event['path'] == "/books/{id}":
            # Extract ID from path parameters
            id = event['pathParameters']['id']
            table.delete_item(Key={'ID': id})  # Use correct key name if it's 'ID'
            body = f'Deleted item {id}'
        
        # Handle GET /books/{id}
        elif event['httpMethod'] == "GET" and event['path'] == "/books/{id}":
            id = event['pathParameters']['id']
            response = table.get_item(Key={'ID': id})  # Use correct key name
            body = response.get("Item", {})
            if not body:
                statusCode = 404
                body = {'error': f'Item with ID {id} not found.'}
            else:
                body = {'ID': body["ID"], 'BookTitle': body["BookTitle"], 'author': body['author']}
        
        # Handle GET /books
        elif event['httpMethod'] == "GET" and event['path'] == "/books":
            response = table.scan()
            items = response.get("Items", [])
            body = [{'ID': str(item["ID"]), 'BookTitle': item["BookTitle"], 'author': item['author']} for item in items]
            # body = items

        # Handle PUT /books
        elif event['httpMethod'] == "PUT" and event['path'] == "/books":
            requestJSON = json.loads(event['body'])
            table.put_item(
                Item={
                    'ID': requestJSON["ID"], 
                    'BookTitle': requestJSON["BookTitle"], 
                    'author': requestJSON['author']
                })
            body = f'Put item {requestJSON["ID"]}'

        # Handle unsupported methods
        else:
            statusCode = 400
            body = {'error': 'Unsupported method or path.'}

    except KeyError as e:
        statusCode = 400
        body = {'error': f'Missing parameter: {str(e)}'}
    except Exception as e:
        statusCode = 500
        body = {'error': str(e)}

    body = json.dumps(body)
    res = {
        "statusCode": statusCode,
        "headers": headers,
        "body": body
    }
    return res
