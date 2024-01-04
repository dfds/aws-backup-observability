import json
import os

import requests
import boto3
from botocore.config import Config
from aws_lambda_powertools import Logger
import urllib.parse

config = Config(
    region_name='eu-central-1'
)
logger = Logger()


def handler(event, context):
    logger.set_correlation_id(context.aws_request_id)
    logger.info('Received event: {}'.format(json.dumps(event, indent=2)))

    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    s3 = boto3.client('s3')
    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        csv_content = response['Body'].read().decode('utf-8').splitlines()
        report = []

        keys = csv_content[0].split(',')
        keys2 = []

        for key in keys:
            x = key.split('[', 1)[0].replace('"', '').lower().title().replace(' ', '')
            res = x[0].lower() + x[1:]
            keys2.append(res)

        for line in csv_content[1:]:
            values_list = line.split(',')
            values = []
            for value in values_list:
                values.append(value.replace('"', ''))
            res = dict(map(lambda i, j: (i, j), keys2, values))
            report.append(res)
        failed_jobs = []

        for item in report:
            if item['jobStatus'] in ['ABORTED', 'FAILED', 'EXPIRED', 'PARTIAL']:
                failed_jobs.append(item)

        slack_webhook_url = os.getenv('SLACK_WEBHOOK')

        if len(failed_jobs) > 0:
            for job in failed_jobs:
                payload = {
                    'blocks': [
                        {
                            'type': 'section',
                            'text': {
                                'type': 'mrkdwn',
                                'text': 'Backup job did not complete in *{}*'.format(job['accountId'])
                            }
                        },
                        {
                            'type': 'section',
                            'fields': [
                                {
                                    'type': 'mrkdwn',
                                    'text': '*Job ID*\n{}'.format(job['backupJobId'])
                                },
                                {
                                    'type': 'mrkdwn',
                                    'text': '*Job status*\n{}'.format(job['jobStatus'])
                                },
                                {
                                    'type': 'mrkdwn',
                                    'text': '*Region*\n{}'.format(job['region'])
                                },
                                {
                                    'type': 'mrkdwn',
                                    'text': '*Status message*\n{}'.format(job['statusMessage'])
                                }
                            ]
                        }
                    ]
                }
                try:
                    response = requests.post(slack_webhook_url, data=json.dumps(payload))
                    response.raise_for_status()
                    logger.info('Sent message for {}'.format(job['backupJobId']))
                    logger.info('Response: {}'.format(response.status_code))
                except requests.exceptions.RequestException as err:
                    logger.error('Request error: {}'.format(err))
    except Exception as e:
        logger.error('Error getting {} object from {} bucket'.format(bucket, key))
        raise e
