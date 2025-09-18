"""
ACAI Cloud Foundation (ACF)
Copyright (C) 2025 ACAI GmbH
Licensed under AGPL v3
#
This file is part of ACAI ACF.
Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.

For full license text, see LICENSE file in repository root.
For commercial licensing, contact: contact@acai.gmbh


"""

import json
import sys
import boto3
import botocore
from botocore.config import Config as boto3_config


def main():
    # org_mgmt_role_arn provided?

    expected_org_id = sys.argv[1]
    expected_root_ou_id = sys.argv[2]
    ou_assignments = json.loads(sys.argv[3])
    role_arn = sys.argv[4] if len(sys.argv) > 4 else None
    
    session = _assume_remote_role(role_arn) if role_arn else boto3.Session()

    if session == None:
        raise Exception(f"Was not able to assume role {role_arn}")
        
    else:
        boto3_config_settings = boto3_config(
            retries = {
                'max_attempts' : 10, 
                'mode': 'standard' 
        })
        boto3_client = session.client('organizations', config=boto3_config_settings)
        
        found_org_id = boto3_client.describe_organization()['Organization']['Id'] 
        found_root_ou_id = boto3_client.list_roots()['Roots'][0]['Id']  # Assume single root
        if (expected_org_id != found_org_id or expected_root_ou_id != found_root_ou_id):
            raise(Exception(f"Not in the correct AWS Org. Required: {expected_org_id}/{expected_root_ou_id} Found: {found_org_id}/{found_root_ou_id}"))

        ou_results = _process_ou_assignments(boto3_client, found_org_id, found_root_ou_id, ou_assignments)
        print(json.dumps({"result": json.dumps(ou_results)}))

def _process_ou_assignments(boto3_client, org_id, root_ou_id, ou_assignments):
    ou_results = {}
    for path, assignments in ou_assignments.items():
        if path == '/root':
            ou_results[root_ou_id] = {'path_name':'/root', "path_id": f'{org_id}/{root_ou_id}', 'assignments': assignments}
        else:
            path = path.replace("/root", "", 1)
            ous = _get_ous(boto3_client, root_ou_id, path, "/root", f'{org_id}/{root_ou_id}')
            for ou in ous:
                if ou['id'] in ou_results:
                    ou_results[ou['id']]['assignments'].append(assignments)
                else:
                    ou_results[ou['id']] = {
                        "path_name": ou['path_name'], 
                        "path_id": ou['path_id'], 
                        "assignments": assignments
                    }
    return ou_results

def _get_ous(boto3_client, parent_ou_id, remaining_ou_path, recent_ou_path_name, recent_ou_path_id):
    def get_ous_for_criteria(parent_id, criteria):
        found_ous = []
        paginator = boto3_client.get_paginator('list_organizational_units_for_parent')
        for page in paginator.paginate(ParentId=parent_id):
            for ou in page['OrganizationalUnits']:
                if ou['Name'] == criteria or criteria == "*":
                    found_ous.append(
                        {
                            'id': ou['Id'], 
                            'name': ou['Name'], 
                            'path_name': f'{recent_ou_path_name}/{ou["Name"]}',
                            'path_id': f'{recent_ou_path_id}/{ou["Id"]}'
                        }
                    )
        return found_ous

    results = []
    parts = remaining_ou_path.strip("/").split('/')    
    first_element = parts[0]
    found_ous = get_ous_for_criteria(parent_ou_id, first_element)
    if len(parts) > 1:
        rest_of_path = '/' + '/'.join(parts[1:])
        for result in found_ous:
            results.extend(_get_ous(boto3_client, result['id'], rest_of_path, f"{recent_ou_path_name}/{result['name']}", f"{recent_ou_path_id}/{result['id']}" ))
    else:
        results.extend(found_ous)
    return results

def _assume_remote_role(remote_role_arn):
    try:
        # Assumes the provided role in the auditing member account and returns a session
        # Beginning the assume role process for account
        sts_client = boto3.client('sts')

        response = sts_client.assume_role(
            RoleArn=remote_role_arn,
            RoleSessionName='RemoteSession'
        )

        # Storing STS credentials
        session = boto3.Session(
            aws_access_key_id=response["Credentials"]["AccessKeyId"],
            aws_secret_access_key=response["Credentials"]["SecretAccessKey"],
            aws_session_token=response["Credentials"]["SessionToken"]
        )
        return session

    except Exception as e:
        return None


if __name__ == "__main__":
    main()

