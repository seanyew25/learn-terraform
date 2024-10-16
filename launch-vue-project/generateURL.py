import json
import boto3

# Initialize S3 client
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Extract HTTP method from the event
    http_method = event['httpMethod']
    
    # Extract the file name from query parameters or body
    if http_method == 'GET':
        file_name = event['queryStringParameters']['file_name']
    elif http_method == 'PUT':
        body = json.loads(event['body'])
        file_name = body['file_name']
    else:
        return {
            'statusCode': 405,
            'body': json.dumps('Method Not Allowed')
        }
    
    bucket_name = 'img-storage'
    
    # Determine the Content-Type based on the file extension
    if file_name.endswith('.jpg') or file_name.endswith('.jpeg'):
        content_type = 'image/jpeg'
    elif file_name.endswith('.png'):
        content_type = 'image/png'
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('Unsupported file type')
        }
    
    try:
        if http_method == 'PUT':
            # Generate presigned URL for uploading (PUT)
            presigned_url = s3_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': bucket_name,
                    'Key': file_name,
                    'ContentType': content_type  # Set Content-Type based on file extension
                },
                ExpiresIn=3600  # URL expiration time in seconds (1 hour)
            )
        elif http_method == 'GET':
            # Generate presigned URL for downloading (GET)
            presigned_url = s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': bucket_name, 'Key': file_name},
                ExpiresIn=3600  # URL expiration time in seconds (1 hour)
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'presigned_url': presigned_url})
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error generating presigned URL: {str(e)}")
        }
