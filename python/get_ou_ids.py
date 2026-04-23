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
        "<ou-path>/": {
            "ou_id":       "<AWS OU ID, e.g. ou-ab12-12345678>",
            "ou_id_path":  "<org-id>/<root-id>/<ou-id>/... (slash-joined IDs for full path)>",
            "assignments": [ <original assignment entries from input for this OU> ]
        },
        ...
    }

    Notes:
    - The outer wrapper {"result": "..."} satisfies the Terraform external data source
      requirement that all output values are strings.
    - Output is keyed by OU path (with trailing "/"), not by OU ID.
    - When multiple input paths resolve to the same OU the assignments lists are merged.
    - Wildcard segment "*" matches all child OUs at that level of the hierarchy.
"""

import argparse
import json
import logging

from ou_path_resolver import OuPathResolver, create_organizations_client, terraform_json_output

# Configure logging (stdout reserved for final JSON output)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Resolve OU IDs for given OU paths.")
    parser.add_argument(
        "--expected_org_id",
        required=True,
        help="Expected AWS Organizations ID (e.g., o-xxxxxxxxxx)",
    )
    parser.add_argument(
        "--expected_root_ou_id",
        required=True,
        help="Expected Root OU ID (e.g., r-xxxx)",
    )
    parser.add_argument(
        "--ou_assignments_json",
        required=True,
        help="JSON string: { '/root/Path': <assignments> }",
    )
    parser.add_argument(
        "--role-arn",
        dest="role_arn",
        help="Optional role ARN to assume",
        default=None,
    )
    parser.add_argument(
        "--endpoint-url",
        dest="endpoint_url",
        help="AWS Organizations API endpoint URL override",
        default=None,
    )
    return parser.parse_args()


def main():
    args = _parse_args()
    ou_assignments = json.loads(args.ou_assignments_json)
    if not isinstance(ou_assignments, dict):
        raise ValueError("ou_assignments_json must decode to an object/dict")

    org_client = create_organizations_client(args.endpoint_url, args.role_arn)
    resolver = OuPathResolver(logger, org_client)
    resolver.validate_org(args.expected_org_id, args.expected_root_ou_id)
    terraform_json_output(resolver.resolve_ou_paths_with_assignments(ou_assignments))


if __name__ == "__main__":
    main()
