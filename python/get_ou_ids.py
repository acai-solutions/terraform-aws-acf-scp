"""
ACAI Cloud Foundation (ACF)
Copyright (C) 2025 ACAI GmbH
Licensed under AGPL v3
#
This file is part of ACAI ACF.
Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.

For full license text, see LICENSE file in repository root.
For commercial licensing, contact: contact@acai.gmbh

Description:
    Resolves AWS Organizations OU IDs for given OU path strings. Accepts a JSON
    map of OU paths to SCP assignments, validates the organization and root OU,
    and outputs a JSON object mapping each path to its resolved OU ID.
    Optionally assumes a cross-account IAM role before querying the Organizations API.

    Output JSON structure (printed to stdout, compatible with Terraform external data source):
    {
        "result": "<JSON-encoded string>"
    }

    Where the decoded "result" value is:
    {
        "<ou-id>": {
            "path_name": "<human-readable OU path, e.g. /root/Workloads/Prod>",
            "path_id":   "<org-id>/<root-id>/<ou-id>/... (slash-joined IDs for full path)>",
            "assignments": [ <original assignment entries from input for this OU> ]
        },
        ...
    }

    Notes:
    - The outer wrapper {"result": "..."} satisfies the Terraform external data source
      requirement that all output values are strings.
    - When multiple input paths resolve to the same OU ID the assignments lists are merged.
    - Wildcard segment "*" matches all child OUs at that level of the hierarchy.
"""

import argparse
import json
import logging
from typing import Any, Dict, List, Optional

import boto3
from botocore.config import Config as boto3_config
from botocore.exceptions import BotoCoreError, ClientError

# Configure logging (stdout reserved for final JSON output)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Resolve OU IDs for given OU paths.")
    parser.add_argument(
        "--expected_org_id", required=True, help="Expected AWS Organizations ID (e.g., o-xxxxxxxxxx)"
    )
    parser.add_argument(
        "--expected_root_ou_id", required=True, help="Expected Root OU ID (e.g., r-xxxx)"
    )
    parser.add_argument(
        "--ou_assignments_json", required=True, help="JSON string: { '/root/Path': <assignments> }"
    )
    parser.add_argument(
        "--role-arn",
        dest="role_arn",
        help="Optional role ARN to assume (e.g. arn:aws:iam::123456789012:role/MyRole)",
        default=None,
    )
    parser.add_argument(
        "--endpoint-url",
        dest="endpoint_url",
        help="AWS Organizations API endpoint URL override (e.g. for AWS ESC: https://organizations.eusc-de-east-1.amazonaws.eu)",
        default=None,
    )
    return parser.parse_args()


def main():
    args = _parse_args()
    expected_org_id = args.expected_org_id
    expected_root_ou_id = args.expected_root_ou_id
    try:
        ou_assignments = json.loads(args.ou_assignments_json)
        if not isinstance(ou_assignments, dict):
            raise ValueError("ou_assignments_json must decode to an object/dict")
    except json.JSONDecodeError as e:
        logger.error("Invalid JSON for ou_assignments_json: %s", e)
        raise

    role_arn = args.role_arn
    endpoint_url = args.endpoint_url
    session = _assume_remote_role(role_arn) if role_arn else boto3.Session()

    if session is None:
        raise Exception(f"Was not able to assume role {role_arn}")

    try:
        boto3_config_settings = boto3_config(
            retries={"max_attempts": 10, "mode": "standard"},
            connect_timeout=10,
            read_timeout=30,
        )
        client_kwargs = {"config": boto3_config_settings}
        if endpoint_url:
            client_kwargs["endpoint_url"] = endpoint_url
            # SigV4 signing requires region_name to match the endpoint region.
            # Extract it from the hostname: organizations.{region}.amazonaws.{tld}
            hostname = endpoint_url.split("://", 1)[-1].split("/")[0]
            client_kwargs["region_name"] = hostname.split(".")[1]
        boto3_client = session.client("organizations", **client_kwargs)

        found_org_id = boto3_client.describe_organization()["Organization"]["Id"]
        found_root_ou_id = boto3_client.list_roots()["Roots"][0][
            "Id"
        ]  # Assume single root
        if (expected_org_id != found_org_id) or (
            expected_root_ou_id != found_root_ou_id
        ):
            raise ValueError(
                f"Not in the correct AWS Org. Required: {expected_org_id}/{expected_root_ou_id} "
                f"Found: {found_org_id}/{found_root_ou_id}"
            )

        ou_results = _process_ou_assignments(
            boto3_client, found_org_id, found_root_ou_id, ou_assignments
        )
        # Keep Terraform external data format: values must be strings
        print(json.dumps({"result": json.dumps(ou_results)}))
    except (ClientError, BotoCoreError) as e:
        logger.error("AWS Organizations error: %s", e)
        raise


def _process_ou_assignments(
    boto3_client, org_id: str, root_ou_id: str, ou_assignments: Dict[str, Any]
) -> Dict[str, Any]:
    ou_results: Dict[str, Any] = {}
    for path, assignments in ou_assignments.items():
        # Normalize assignments to list
        assignments_list: List[Any] = (
            assignments if isinstance(assignments, list) else [assignments]
        )

        # Strip trailing slashes so "/root/a/b/" == "/root/a/b"
        path = path.rstrip("/") or "/root"

        if path == "/root":
            ou_results[root_ou_id] = {
                "path_name": "/root",
                "path_id": f"{org_id}/{root_ou_id}",
                "assignments": assignments_list,
            }
        else:
            normalized = path[len("/root") :]
            ous = _get_ous(
                boto3_client, root_ou_id, normalized, "/root", f"{org_id}/{root_ou_id}"
            )
            for ou in ous:
                if ou["id"] in ou_results:
                    # Merge rather than append nested list
                    ou_results[ou["id"]]["assignments"].extend(assignments_list)
                else:
                    ou_results[ou["id"]] = {
                        "path_name": ou["path_name"],
                        "path_id": ou["path_id"],
                        "assignments": assignments_list,
                    }
    return ou_results


def _get_ous(
    boto3_client,
    parent_ou_id,
    remaining_ou_path,
    recent_ou_path_name,
    recent_ou_path_id,
):
    def get_ous_for_criteria(parent_id, criteria):
        found_ous = []
        paginator = boto3_client.get_paginator("list_organizational_units_for_parent")
        for page in paginator.paginate(ParentId=parent_id):
            for ou in page["OrganizationalUnits"]:
                if ou["Name"] == criteria or criteria == "*":
                    found_ous.append(
                        {
                            "id": ou["Id"],
                            "name": ou["Name"],
                            "path_name": f'{recent_ou_path_name}/{ou["Name"]}',
                            "path_id": f'{recent_ou_path_id}/{ou["Id"]}',
                        }
                    )
        return found_ous

    results = []
    parts = remaining_ou_path.strip("/").split("/")
    first_element = parts[0]
    found_ous = get_ous_for_criteria(parent_ou_id, first_element)
    if len(parts) > 1:
        rest_of_path = "/" + "/".join(parts[1:])
        for result in found_ous:
            results.extend(
                _get_ous(
                    boto3_client,
                    result["id"],
                    rest_of_path,
                    f"{recent_ou_path_name}/{result['name']}",
                    f"{recent_ou_path_id}/{result['id']}",
                )
            )
    else:
        results.extend(found_ous)
    return results


def _assume_remote_role(remote_role_arn: Optional[str]) -> Optional[boto3.Session]:
    try:
        # Assumes the provided role in the auditing member account and returns a session
        sts_client = boto3.client("sts")
        response = sts_client.assume_role(
            RoleArn=remote_role_arn, RoleSessionName="RemoteSession"
        )
        return boto3.Session(
            aws_access_key_id=response["Credentials"]["AccessKeyId"],
            aws_secret_access_key=response["Credentials"]["SecretAccessKey"],
            aws_session_token=response["Credentials"]["SessionToken"],
        )
    except Exception as e:
        logger.error("Failed to assume role %s: %s", remote_role_arn, e)
        return None


if __name__ == "__main__":
    main()
