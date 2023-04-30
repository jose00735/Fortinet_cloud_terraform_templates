import boto3
import re 
import json

def get_fortigate_amis(region):
    pattern_version = r"\((\d+\.\d+\.\d+)\)"
    pattern_license = r'AWSONDEMAND'
    ec2 = boto3.client('ec2', region_name=region)
    response = ec2.describe_images(
        Owners=['aws-marketplace'],
        Filters=[{'Name': 'name', 'Values': ['FortiGate*']}]
    )

    ami_list = []

    for image in response['Images']:
        ami_info = {
            'Architecture': image['Architecture'],
            'ImageId': image['ImageId'],
            'Version': image['Description'],
            'License': image['Description']
        }
        match = re.search(pattern_version, ami_info['Version'])
        ami_info['Version'] = match.group(1)
        if re.search(pattern_license, image['Description']):
            ami_info['License'] = "payg"
        else:
            ami_info['License'] = "byol"
        ami_list.append(ami_info)
        

    return ami_list

fortigate_amis = get_fortigate_amis('us-west-2')
with open("Amis.json", "w") as json_file:
    json.dump(fortigate_amis, json_file)
