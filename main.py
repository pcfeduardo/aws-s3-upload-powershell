import os
import json
import boto3

json_file_path = "params.json"

with open(json_file_path, 'r') as file:
    json_content = json.load(file)

access_key = json_content['accessKey']
secret_key = json_content['secretKey']
region = json_content['region']
bucket_name = json_content['bucketName']
paths_list = json_content['pathsList']

s3 = boto3.client('s3', aws_access_key_id=access_key, aws_secret_access_key=secret_key, region_name=region)

for path in paths_list:
    if not os.path.exists(path):
        print("Path not found: {}".format(path))
        continue

    if os.path.isdir(path):
        for root, dirs, files in os.walk(path):
            for file in files:
                file_path = os.path.join(root, file)
                s3_key = os.path.relpath(file_path, path).replace('\\', '/')
                folder_name = os.path.basename(path)
                s3_key = "{}/{}".format(folder_name, s3_key)

                try:
                    print("Uploading folder {} to bucket {}".format(path, bucket_name))
                    s3.upload_file(file_path, bucket_name, s3_key, ExtraArgs={'ACL': 'private'})
                except Exception as e:
                    print("Error when uploading directory: {}. Error: {}".format(path, str(e)))
    elif os.path.isfile(path):
        file_name = os.path.basename(path)
        try:
            print("Uploading file {} to bucket {}".format(path, bucket_name))
            s3.upload_file(path, bucket_name, file_name, ExtraArgs={'ACL': 'private'})
        except Exception as e:
            print("Error when uploading file: {}. Error: {}".format(path, str(e)))
