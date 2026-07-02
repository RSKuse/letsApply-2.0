#!/usr/bin/env python3
"""Import vacancies from approved public job-board APIs.

Supported sources:
- Greenhouse Job Board API
- Lever Postings API
- ReliefWeb API, once an approved app name has been issued

This importer does not scrape job websites. Each configured company must expose
its vacancies through the provider's documented public API.
"""

import argparse
import hashlib
import html
import json
import os
import re
from datetime import datetime, timezone
from html.parser import HTMLParser
from urllib.parse import quote
from urllib.request import Request, urlopen


class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        value = data.strip()
        if value:
            self.parts.append(value)


def fetch_json(url):
    request = Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "LetsApplyVacancyImporter/1.0",
        },
    )
    with urlopen(request, timeout=30) as response:
        return json.load(response)


def plain_text(value):
    if not value:
        return ""
    parser = TextExtractor()
    parser.feed(html.unescape(str(value)))
    return "\n".join(parser.parts)


def string_list(values):
    return [plain_text(value) for value in (values or []) if plain_text(value)]


def stable_id(provider, source_id):
    raw_value = f"{provider}:{source_id}".encode("utf-8")
    return hashlib.sha256(raw_value).hexdigest()[:28]


def iso_date(value):
    if value in (None, ""):
        return ""
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value / 1000, timezone.utc).date().isoformat()
    text = str(value).replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(text).date().isoformat()
    except ValueError:
        return ""


def pay_period(value):
    normalized = str(value or "").lower()
    if "hour" in normalized:
        return "hour"
    if "week" in normalized:
        return "week"
    if "month" in normalized:
        return "month"
    return "annum"


def salary_range(currency="", minimum=None, maximum=None, interval="annum"):
    return {
        "currency": currency or "",
        "min": minimum,
        "max": maximum,
        "period": pay_period(interval),
    }


def make_job(
    *,
    provider,
    source_id,
    source_name,
    source_url,
    title,
    company,
    location,
    description,
    requirements,
    responsibilities,
    job_type,
    remote,
    category,
    posting_date,
    closing_date="",
    logo_url="",
    salary=None,
):
    return {
        "id": stable_id(provider, source_id),
        "title": title or "Untitled opportunity",
        "companyName": company or source_name,
        "companyLogoURL": logo_url or "",
        "location": {
            "city": location or "",
            "province": "",
            "country": "",
            "remote": bool(remote),
        },
        "jobType": job_type or "Not specified",
        "description": description or "",
        "qualifications": [],
        "responsibilities": responsibilities or [],
        "requirements": requirements or [],
        "experience": "",
        "compensation": {
            "salaryRange": salary or salary_range(),
            "benefits": [],
        },
        "application": {
            "method": "externalWebsite",
            "applicationUrl": source_url,
            "applicationEmail": "",
            "instructions": "Review the official vacancy and submit on the employer's application page.",
            "referenceNumber": str(source_id),
            "requiresCV": True,
            "requiresCoverLetter": False,
            "requiresZ83": False,
            "requiresCertifiedDocuments": False,
            "requiresDriversLicense": False,
            "requiredForms": [],
            "requiredDocuments": [],
        },
        "jobCategory": category or "General",
        "postingDate": posting_date or datetime.now(timezone.utc).date().isoformat(),
        "closingDate": closing_date or "",
        "visibility": "published",
        "sourceName": source_name,
        "sourceUrl": source_url,
        "sourceJobId": str(source_id),
        "sourceType": "companyWebsite" if provider != "reliefweb" else "publicFeed",
        "dateImported": datetime.now(timezone.utc).isoformat(),
        "verified": True,
        "isFeatured": False,
    }


def greenhouse_jobs(config):
    token = config["token"]
    jobs_url = (
        f"https://boards-api.greenhouse.io/v1/boards/{quote(token)}/jobs"
        "?content=true"
    )
    board_url = f"https://boards-api.greenhouse.io/v1/boards/{quote(token)}"
    board = fetch_json(board_url)
    payload = fetch_json(jobs_url)
    company = config.get("company") or board.get("name") or token
    source_name = f"{company} - Greenhouse"
    logo_url = config.get("logoUrl", "")
    results = []

    for item in payload.get("jobs", []):
        location = (item.get("location") or {}).get("name", "")
        content = plain_text(item.get("content"))
        departments = [
            department.get("name", "")
            for department in item.get("departments", [])
            if department.get("name")
        ]
        results.append(
            make_job(
                provider="greenhouse",
                source_id=item.get("id"),
                source_name=source_name,
                source_url=item.get("absolute_url", ""),
                title=item.get("title", ""),
                company=company,
                location=location,
                description=content,
                requirements=[],
                responsibilities=[],
                job_type="Not specified",
                remote="remote" in location.lower(),
                category=departments[0] if departments else "General",
                posting_date=iso_date(item.get("updated_at")),
                logo_url=logo_url,
            )
        )
    return results


def lever_jobs(config):
    site = config["site"]
    region = config.get("region", "global")
    host = "api.eu.lever.co" if region == "eu" else "api.lever.co"
    payload = fetch_json(
        f"https://{host}/v0/postings/{quote(site)}?mode=json"
    )
    company = config.get("company") or site
    source_name = f"{company} - Lever"
    logo_url = config.get("logoUrl", "")
    results = []

    for item in payload:
        categories = item.get("categories") or {}
        location = categories.get("location", "")
        workplace_type = str(item.get("workplaceType") or "").lower()
        lists = item.get("lists") or []
        responsibilities = []
        requirements = []
        for section in lists:
            heading = str(section.get("text") or "").lower()
            values = [plain_text(section.get("content"))]
            if "require" in heading or "qualif" in heading:
                requirements.extend(value for value in values if value)
            else:
                responsibilities.extend(value for value in values if value)

        salary = salary_range()
        salary_value = item.get("salaryRange") or {}
        if salary_value:
            salary = salary_range(
                salary_value.get("currency", ""),
                salary_value.get("min"),
                salary_value.get("max"),
                salary_value.get("interval", "annum"),
            )

        results.append(
            make_job(
                provider="lever",
                source_id=item.get("id"),
                source_name=source_name,
                source_url=item.get("hostedUrl") or item.get("applyUrl") or "",
                title=item.get("text", ""),
                company=company,
                location=location,
                description=plain_text(
                    item.get("descriptionPlain")
                    or item.get("description")
                    or item.get("additionalPlain")
                ),
                requirements=requirements,
                responsibilities=responsibilities,
                job_type=categories.get("commitment", "Not specified"),
                remote=workplace_type == "remote" or "remote" in location.lower(),
                category=categories.get("team", "General"),
                posting_date=iso_date(item.get("createdAt")),
                logo_url=logo_url,
                salary=salary,
            )
        )
    return results


def reliefweb_jobs(app_name, limit=100):
    url = (
        "https://api.reliefweb.int/v1/jobs"
        f"?appname={quote(app_name)}&limit={min(limit, 1000)}"
        "&profile=full&preset=latest"
    )
    payload = fetch_json(url)
    results = []

    for item in payload.get("data", []):
        fields = item.get("fields") or {}
        organizations = fields.get("source") or []
        company = (
            organizations[0].get("name", "ReliefWeb")
            if organizations
            else "ReliefWeb"
        )
        countries = string_list(
            country.get("name") for country in (fields.get("country") or [])
        )
        source_url = fields.get("url") or fields.get("url_alias") or ""
        results.append(
            make_job(
                provider="reliefweb",
                source_id=item.get("id"),
                source_name="ReliefWeb",
                source_url=source_url,
                title=fields.get("title", ""),
                company=company,
                location=", ".join(countries),
                description=plain_text(fields.get("body")),
                requirements=[],
                responsibilities=[],
                job_type="Not specified",
                remote=False,
                category="Humanitarian",
                posting_date=iso_date((fields.get("date") or {}).get("created")),
                closing_date=iso_date(
                    (fields.get("date") or {}).get("closing")
                ),
            )
        )
    return results


def load_json_environment(name):
    raw_value = os.environ.get(name, "").strip()
    if not raw_value:
        return []
    value = json.loads(raw_value)
    if not isinstance(value, list):
        raise ValueError(f"{name} must contain a JSON array.")
    return value


def collect_jobs():
    jobs = []
    complete_sources = []

    for config in load_json_environment("GREENHOUSE_BOARDS_JSON"):
        source_jobs = greenhouse_jobs(config)
        jobs.extend(source_jobs)
        company = config.get("company") or config["token"]
        complete_sources.append(f"{company} - Greenhouse")

    for config in load_json_environment("LEVER_SITES_JSON"):
        source_jobs = lever_jobs(config)
        jobs.extend(source_jobs)
        company = config.get("company") or config["site"]
        complete_sources.append(f"{company} - Lever")

    reliefweb_app_name = os.environ.get("RELIEFWEB_APPNAME", "").strip()
    if reliefweb_app_name:
        jobs.extend(reliefweb_jobs(reliefweb_app_name))

    return jobs, complete_sources


def publish_jobs(jobs, complete_sources):
    import firebase_admin
    from firebase_admin import credentials, firestore

    service_account = os.environ.get("FIREBASE_SERVICE_ACCOUNT", "").strip()
    if not service_account:
        raise RuntimeError("FIREBASE_SERVICE_ACCOUNT is required to publish.")

    credential_data = json.loads(service_account)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(credential_data))
    database = firestore.client()

    active_ids_by_source = {}
    for job in jobs:
        active_ids_by_source.setdefault(job["sourceName"], set()).add(job["id"])
        database.collection("jobs").document(job["id"]).set(job, merge=True)

    for source_name in complete_sources:
        active_ids = active_ids_by_source.get(source_name, set())
        existing = database.collection("jobs").where(
            "sourceName", "==", source_name
        ).stream()
        for document in existing:
            if document.id not in active_ids:
                document.reference.set({"visibility": "expired"}, merge=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--publish", action="store_true")
    parser.add_argument("--output", default="partner_jobs.json")
    args = parser.parse_args()

    jobs, complete_sources = collect_jobs()
    with open(args.output, "w", encoding="utf-8") as output_file:
        json.dump(jobs, output_file, ensure_ascii=False, indent=2)

    if args.publish and jobs:
        publish_jobs(jobs, complete_sources)

    print(
        json.dumps(
            {
                "jobs": len(jobs),
                "sources": sorted(set(job["sourceName"] for job in jobs)),
                "published": bool(args.publish and jobs),
                "output": args.output,
            }
        )
    )


if __name__ == "__main__":
    main()
