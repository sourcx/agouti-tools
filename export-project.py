#!/usr/bin/env python3
"""Create a Camtrap DP export of an Agouti project, wait until it is ready and download it.

Replaces the deprecated create-export*.sh scripts, which used the CSV routes of the API.
The export is created asynchronously and takes a few minutes. The zip is unpacked into the
output directory (default output/export-<projectId>): datapackage.json, deployments.csv,
media.csv and observations.csv.

    python export-project.py <projectId>
    python export-project.py <projectId> --filters '{"deploymentIds": ["<id>"]}'
    python export-project.py <projectId> --events-only --split-by-deployment

Configuration, from the environment or the same files as the other scripts:
    API_URL        default: the contents of .api_url, else http://localhost:5001
    API_KEY_FILE   file with the X-API-KEY, default .api_key (e.g. .api_key_frank_prod)

The key's user must be admin, maintainer or coordinator of the project. Needs `requests`.
"""

import argparse
import csv
import io
import json
import os
import sys
import time
import zipfile
from collections import defaultdict
from pathlib import Path

import requests


class ExportError(RuntimeError):
    pass


def load_config():
    api_url = os.environ.get("API_URL")
    if not api_url:
        api_url_file = Path(".api_url")
        api_url = api_url_file.read_text().strip() if api_url_file.is_file() else "http://localhost:5001"
    api_key = Path(os.environ.get("API_KEY_FILE", ".api_key")).read_text().strip()
    return api_url.rstrip("/"), api_key


def message_of(response):
    try:
        return response.json().get("message", response.text)
    except ValueError:
        return response.text


def create_export(session, base, body, poll_seconds, timeout_seconds):
    deadline = time.time() + timeout_seconds
    while True:
        response = session.post(base, json=body)
        if response.status_code == 202:
            return response.json()["id"]
        if response.status_code == 409 and time.time() < deadline:
            print("Another export of this project is running, waiting...", file=sys.stderr)
            time.sleep(poll_seconds)
            continue
        raise ExportError(f"Could not create the export (HTTP {response.status_code}): {message_of(response)}")


def wait_until_completed(session, base, export_id, poll_seconds, timeout_seconds):
    deadline = time.time() + timeout_seconds
    while True:
        response = session.get(f"{base}/{export_id}")
        response.raise_for_status()
        record = response.json()
        if record["status"] == "Completed":
            print(
                f"Export completed: {record['deploymentsCount']} deployments, "
                f"{record['mediaCount']} media, {record['observationsCount']} observations",
                file=sys.stderr,
            )
            return record
        if record["status"] in ("Error", "Expired"):
            raise ExportError(f"Export {record['status']}: {record.get('error') or ''}")
        if time.time() >= deadline:
            raise ExportError("Gave up waiting for the export.")
        print(f"Export {record['status']}...", file=sys.stderr)
        time.sleep(poll_seconds)


def download_export(session, base, export_id):
    response = session.get(f"{base}/{export_id}/archive")
    response.raise_for_status()
    return zipfile.ZipFile(io.BytesIO(response.content))


def read_csv(package, name):
    """The field names and rows of a CSV file in the package."""
    with package.open(name) as stream:
        reader = csv.DictReader(io.TextIOWrapper(stream, "utf-8"))
        return reader.fieldnames or [], list(reader)


def write_csv(path, fieldnames, rows):
    with open(path, "w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_observation_files(package, output_dir, events_only, split_by_deployment):
    """The observation files the old CSV routes gave: events only, and one file per deployment.

    observations.csv of an export also has media-level rows (positions and bounding boxes),
    marked observationLevel = media; the old observations.csv only had the event rows.
    """
    fieldnames, rows = read_csv(package, "observations.csv")
    if events_only:
        rows = [row for row in rows if row["observationLevel"] == "event"]
        write_csv(output_dir / "observations-events.csv", fieldnames, rows)
    if split_by_deployment:
        per_deployment = defaultdict(list)
        for row in rows:
            per_deployment[row["deploymentID"]].append(row)
        for deployment_id, deployment_rows in per_deployment.items():
            write_csv(output_dir / f"observations-{deployment_id}.csv", fieldnames, deployment_rows)


def main():
    parser = argparse.ArgumentParser(description="Download a Camtrap DP export of an Agouti project.")
    parser.add_argument("project_id")
    parser.add_argument("--output-dir", help="default: output/export-<projectId>")
    parser.add_argument("--retention", default="1d", choices=["1d", "7d", "30d", "infinite"],
                        help="how long the server keeps the zip (default 1d)")
    parser.add_argument("--filters", default="{}", help="export filters as JSON (default: the complete project)")
    parser.add_argument("--events-only", action="store_true",
                        help="also write observations-events.csv without the media-level rows")
    parser.add_argument("--split-by-deployment", action="store_true",
                        help="also write observations-<deploymentID>.csv per deployment")
    parser.add_argument("--poll-seconds", type=int, default=15)
    parser.add_argument("--timeout-seconds", type=int, default=1800)
    args = parser.parse_args()

    api_url, api_key = load_config()
    base = f"{api_url}/v1/projects/{args.project_id}/exports"
    output_dir = Path(args.output_dir or f"output/export-{args.project_id}")
    body = {"retention": args.retention, "filters": json.loads(args.filters)}

    session = requests.Session()
    session.headers["X-API-KEY"] = api_key

    try:
        export_id = create_export(session, base, body, args.poll_seconds, args.timeout_seconds)
        print(f"Created export {export_id} (kept for {args.retention} after it completes)", file=sys.stderr)
        wait_until_completed(session, base, export_id, args.poll_seconds, args.timeout_seconds)
        package = download_export(session, base, export_id)
    except (ExportError, requests.RequestException) as error:
        sys.exit(str(error))

    output_dir.mkdir(parents=True, exist_ok=True)
    package.extractall(output_dir)
    write_observation_files(package, output_dir, args.events_only, args.split_by_deployment)
    print(f"Downloaded to {output_dir}", file=sys.stderr)


if __name__ == "__main__":
    main()
