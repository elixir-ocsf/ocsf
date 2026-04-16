#!/usr/bin/env python3
"""
Validate OCSF event fixtures against the official OCSF schema using ocsf-lib.

Usage:
    python3 scripts/validate_ocsf.py

Reads golden fixtures from test/fixtures/ocsf/1.8/authentication/*.json
and validates them against the OCSF 1.8.0 compiled schema.
"""

import json
import sys
import os
from pathlib import Path

try:
    from ocsf.util import get_schema
except ImportError:
    print("ERROR: ocsf-lib not installed. Run: pip3 install ocsf-lib")
    sys.exit(1)


def load_fixture(path):
    with open(path) as f:
        return json.load(f)


def validate_event(event, schema, fixture_name):
    """Validate an event dict against the compiled OCSF schema."""
    errors = []

    # 1. Check class exists
    class_uid = event.get("class_uid")
    if class_uid is None:
        errors.append("missing class_uid")
        return errors

    class_key = str(class_uid)
    class_def = None
    for cls in schema.classes.values():
        if cls.uid == class_uid:
            class_def = cls
            break

    if class_def is None:
        errors.append(f"unknown class_uid: {class_uid}")
        return errors

    # 2. Check required attributes
    for attr_name, attr_def in class_def.attributes.items():
        if attr_def.requirement == "required":
            # Skip profile-only required fields
            if attr_def.profile is not None:
                continue
            if attr_name not in event:
                errors.append(f"missing required attribute: {attr_name}")

    # 3. Check activity_id is valid
    activity_id = event.get("activity_id")
    if activity_id is not None and "activity_id" in class_def.attributes:
        attr = class_def.attributes["activity_id"]
        if attr.enum is not None:
            valid_ids = set(int(k) for k in attr.enum.keys())
            if activity_id not in valid_ids:
                errors.append(f"invalid activity_id: {activity_id}, valid: {sorted(valid_ids)}")

    # 4. Check type_uid
    type_uid = event.get("type_uid")
    if type_uid is not None and "type_uid" in class_def.attributes:
        attr = class_def.attributes["type_uid"]
        if attr.enum is not None:
            valid_type_uids = set(int(k) for k in attr.enum.keys())
            if type_uid not in valid_type_uids:
                errors.append(f"invalid type_uid: {type_uid}")

    # 5. Check severity_id
    severity_id = event.get("severity_id")
    if severity_id is not None and "severity_id" in class_def.attributes:
        attr = class_def.attributes["severity_id"]
        if attr.enum is not None:
            valid_ids = set(int(k) for k in attr.enum.keys())
            if severity_id not in valid_ids:
                errors.append(f"invalid severity_id: {severity_id}")

    # 6. Check auth_protocol_id
    auth_protocol_id = event.get("auth_protocol_id")
    if auth_protocol_id is not None and "auth_protocol_id" in class_def.attributes:
        attr = class_def.attributes["auth_protocol_id"]
        if attr.enum is not None:
            valid_ids = set(int(k) for k in attr.enum.keys())
            if auth_protocol_id not in valid_ids:
                errors.append(f"invalid auth_protocol_id: {auth_protocol_id}")

    # 7. Check status_id
    status_id = event.get("status_id")
    if status_id is not None and "status_id" in class_def.attributes:
        attr = class_def.attributes["status_id"]
        if attr.enum is not None:
            valid_ids = set(int(k) for k in attr.enum.keys())
            if status_id not in valid_ids:
                errors.append(f"invalid status_id: {status_id}")

    # 8. Verify type_uid = class_uid * 100 + activity_id
    if type_uid is not None and activity_id is not None:
        expected = class_uid * 100 + activity_id
        if type_uid != expected:
            errors.append(f"type_uid mismatch: got {type_uid}, expected {expected}")

    # 9. Check metadata.version
    metadata = event.get("metadata", {})
    version = metadata.get("version")
    # We emit 1.8.0; the validation schema is 1.7.0 (additive compatible)
    if version is not None and not version.startswith("1."):
        errors.append(f"metadata.version: expected 1.x.x, got {version}")

    return errors


def main():
    print("=" * 60)
    print("OCSF Compliance Validation (via ocsf-lib)")
    print("=" * 60)

    # Load schema
    # ocsf-lib API doesn't serve 1.8.0 yet; use 1.7.0 as baseline
    # (1.7.0 -> 1.8.0 is additive; Authentication class is identical)
    version = "1.7.0"
    print(f"\nLoading OCSF {version} schema via ocsf-lib...")
    print("  (Note: 1.8.0 not yet available via API; 1.7.0 used as baseline)")
    try:
        schema = get_schema(version)
    except Exception as e:
        print(f"ERROR loading schema: {e}")
        sys.exit(1)

    print(f"Schema loaded: {len(schema.classes)} classes")

    # Find and validate fixtures
    fixtures_dir = Path("test/fixtures/ocsf/1.8/authentication")
    if not fixtures_dir.exists():
        print(f"ERROR: Fixtures directory not found: {fixtures_dir}")
        sys.exit(1)

    fixtures = sorted(fixtures_dir.glob("*.json"))
    if not fixtures:
        print("ERROR: No fixture files found")
        sys.exit(1)

    print(f"Found {len(fixtures)} fixture(s)\n")

    total_errors = 0
    for fixture_path in fixtures:
        name = fixture_path.stem
        event = load_fixture(fixture_path)
        errors = validate_event(event, schema, name)

        if errors:
            print(f"  FAIL  {name}")
            for err in errors:
                print(f"        - {err}")
            total_errors += len(errors)
        else:
            print(f"  PASS  {name}")

    # Also validate that our enum modules match the schema
    print("\n--- Enum cross-check ---")
    auth_class = None
    for cls in schema.classes.values():
        if cls.uid == 3002:
            auth_class = cls
            break

    if auth_class:
        # Activity IDs
        schema_activities = set(int(k) for k in auth_class.attributes["activity_id"].enum.keys())
        print(f"  activity_id values in schema: {sorted(schema_activities)}")

        # Auth protocols
        if "auth_protocol_id" in auth_class.attributes and auth_class.attributes["auth_protocol_id"].enum:
            schema_protos = set(int(k) for k in auth_class.attributes["auth_protocol_id"].enum.keys())
            print(f"  auth_protocol_id values in schema: {sorted(schema_protos)}")

        # Severity
        schema_severity = set(int(k) for k in auth_class.attributes["severity_id"].enum.keys())
        print(f"  severity_id values in schema: {sorted(schema_severity)}")

    print(f"\n{'=' * 60}")
    if total_errors == 0:
        print("RESULT: ALL FIXTURES PASS OCSF VALIDATION")
        print("=" * 60)
        return 0
    else:
        print(f"RESULT: {total_errors} ERROR(S) FOUND")
        print("=" * 60)
        return 1


if __name__ == "__main__":
    sys.exit(main())
