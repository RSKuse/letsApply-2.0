#!/usr/bin/env python3
"""Convert an official DPSA vacancy circular into Let's Apply job documents."""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import tempfile
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


DPSA_NEWSROOM_URL = "https://www.dpsa.gov.za/newsroom/"
OFFICIAL_PDF_PATTERN = re.compile(
    r"""href=["']([^"']*PSV(?:%20|\s)*CIRCULAR(?:%20|\s)*\d+(?:%20|\s)*of(?:%20|\s)*\d+\.pdf)["']""",
    re.IGNORECASE,
)
CIRCULAR_PAGE_PATTERN = re.compile(
    r"""href=["']([^"']*/newsroom/psvc/circular-(\d+)-of-(\d{4})/?)["']""",
    re.IGNORECASE,
)
POST_PATTERN = re.compile(
    r"(?m)^POST\s+(\d{1,3}/\d{1,4})\s*:\s*(.+?)(?=^SALARY\s*:)",
    re.DOTALL,
)
FIELD_LABELS = (
    "SALARY",
    "CENTRE",
    "REQUIREMENTS",
    "DUTIES",
    "ENQUIRIES",
    "APPLICATIONS",
    "APPLICATION",
    "NOTE",
)


def fetch_url(url: str) -> bytes:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "LetsApplyVacancyImporter/1.0"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def discover_latest_pdf() -> str:
    page = fetch_url(DPSA_NEWSROOM_URL).decode("utf-8", errors="replace")
    candidates = []
    for raw_url in OFFICIAL_PDF_PATTERN.findall(page):
        url = urllib.parse.urljoin(DPSA_NEWSROOM_URL, html.unescape(raw_url))
        match = re.search(r"CIRCULAR(?:%20|\s)*0*(\d+)", url, re.IGNORECASE)
        if match:
            candidates.append((int(match.group(1)), url))

    if candidates:
        return max(candidates, key=lambda value: value[0])[1]

    circular_pages = []
    for raw_url, number, year in CIRCULAR_PAGE_PATTERN.findall(page):
        circular_pages.append(
            (int(year), int(number), urllib.parse.urljoin(DPSA_NEWSROOM_URL, raw_url))
        )

    if not circular_pages:
        raise RuntimeError("No official DPSA circular page was found on the newsroom page.")

    _, _, circular_page_url = max(circular_pages)
    circular_page = fetch_url(circular_page_url).decode("utf-8", errors="replace")
    pdf_candidates = []
    for raw_url in re.findall(r"""href=["']([^"']+\.pdf)["']""", circular_page, re.IGNORECASE):
        url = urllib.parse.urljoin(circular_page_url, html.unescape(raw_url))
        if "psv%20circular" in url.lower() or "psv circular" in urllib.parse.unquote(url).lower():
            pdf_candidates.append(url)

    if not pdf_candidates:
        raise RuntimeError("The latest DPSA circular page did not contain a full circular PDF.")

    return pdf_candidates[0]


def extract_pdf_text(pdf_path: Path) -> str:
    try:
        from pypdf import PdfReader
    except ImportError as error:
        raise RuntimeError("Install importer requirements with: pip install -r tools/requirements.txt") from error

    reader = PdfReader(str(pdf_path))
    pages = []
    for page in reader.pages:
        value = page.extract_text() or ""
        pages.append(normalize_text(value))
    return "\n".join(pages)


def normalize_text(value: str) -> str:
    value = value.replace("\u00a0", " ").replace("\u2011", "-")
    value = re.sub(r"(?<=\w)-\s*\n\s*(?=\w)", "", value)
    value = re.sub(r"[ \t]+", " ", value)
    value = re.sub(r"\n[ \t]+", "\n", value)
    value = re.sub(r"\n{3,}", "\n\n", value)
    return value.strip()


def clean_inline(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip(" \n\t:;-")


def find_field(segment: str, label: str) -> str:
    labels = "|".join(re.escape(item) for item in FIELD_LABELS)
    match = re.search(
        rf"(?ms)^{re.escape(label)}\s*:\s*(.*?)(?=^(?:{labels})\s*:|\Z)",
        segment,
    )
    return clean_inline(match.group(1)) if match else ""


def split_sentences(value: str, maximum: int = 12) -> list[str]:
    if not value:
        return []
    sentences = re.split(r"(?<=[.!?])\s+(?=[A-Z0-9])", clean_inline(value))
    return [sentence.strip() for sentence in sentences if len(sentence.strip()) > 2][:maximum]


def nearby_value(text: str, position: int, label: str, lookback: int = 14000) -> str:
    preceding = text[max(0, position - lookback):position]
    pattern = re.compile(rf"(?ms)^{re.escape(label)}\s*:\s*(.*?)(?=^[A-Z][A-Z ]+\s*:|\Z)")
    matches = list(pattern.finditer(preceding))
    return clean_inline(matches[-1].group(1)) if matches else ""


def department_before(text: str, position: int) -> str:
    preceding = text[max(0, position - 180000):position]
    patterns = [
        re.compile(r"(?m)^DEPARTMENT OF [A-Z][A-Z0-9 &,'()/-]+$"),
        re.compile(r"(?m)^[A-Z][A-Z0-9 &,'()/-]+ DEPARTMENT$"),
        re.compile(r"(?m)^PROVINCIAL ADMINISTRATION:\s*([A-Z][A-Z ]+)$"),
    ]
    candidates = []
    for pattern in patterns:
        candidates.extend((match.start(), clean_inline(match.group(0))) for match in pattern.finditer(preceding))
    if not candidates:
        return "South African Public Service"
    return max(candidates, key=lambda item: item[0])[1].title()


def parse_salary(value: str) -> tuple[int, int, str, str]:
    numbers = [
        int(re.sub(r"\D", "", raw))
        for raw in re.findall(r"R\s*\d[\d ]*", value, re.IGNORECASE)
        if re.sub(r"\D", "", raw)
    ]
    minimum = numbers[0] if numbers else 0
    maximum = numbers[1] if len(numbers) > 1 else minimum
    lowered = value.lower()
    if "per month" in lowered:
        period = "month"
    elif "per week" in lowered:
        period = "week"
    elif "per hour" in lowered:
        period = "hour"
    elif "per day" in lowered:
        period = "day"
    else:
        period = "annum"
    return minimum, maximum, "ZAR", period


def parse_reference(title: str, post_number: str) -> str:
    match = re.search(
        r"\bREF(?:ERENCE)?(?:\s+NO)?\s*[:.]?\s*([A-Z0-9][A-Z0-9 /_.-]+?)(?=\)|$)",
        title,
        re.IGNORECASE,
    )
    return clean_inline(match.group(1)) if match else post_number


def parse_title(value: str) -> str:
    value = clean_inline(value)
    value = re.sub(r"\s*\((?:REF(?:ERENCE)?(?:\s+NO)?|X\d+ POSTS?).*$", "", value, flags=re.IGNORECASE)
    value = value.rstrip(" :")
    return value.title() if value.isupper() else value


def first_email(value: str) -> str:
    match = re.search(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", value)
    return match.group(0).rstrip(".,;") if match else ""


def first_url(value: str) -> str:
    match = re.search(r"https?://[^\s)>]+", value)
    return match.group(0).rstrip(".,;") if match else ""


def first_date(value: str) -> str:
    match = re.search(
        r"\b(\d{1,2}\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+20\d{2})\b",
        value,
        re.IGNORECASE,
    )
    if not match:
        return ""
    try:
        return datetime.strptime(match.group(1), "%d %B %Y").date().isoformat()
    except ValueError:
        return match.group(1)


def application_method(application_text: str, requires_z83: bool) -> str:
    email = first_email(application_text)
    url = first_url(application_text)
    if email:
        return "governmentEmail" if requires_z83 else "email"
    if url:
        return "governmentWebsite" if requires_z83 else "externalWebsite"
    return "governmentManual" if requires_z83 else "manualInstruction"


def stable_document_id(post_number: str, reference: str) -> str:
    digest = hashlib.sha1(f"{post_number}|{reference}".encode("utf-8")).hexdigest()[:12]
    return f"dpsa-{post_number.replace('/', '-')}-{digest}"


def parse_jobs(text: str, source_url: str) -> list[dict]:
    matches = list(POST_PATTERN.finditer(text))
    jobs = []
    imported_at = datetime.now(timezone.utc).isoformat()

    for index, match in enumerate(matches):
        segment_end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        segment = text[match.start():segment_end]
        post_number = match.group(1)
        raw_title = match.group(2)
        reference = parse_reference(raw_title, post_number)
        title = parse_title(raw_title)
        department = department_before(text, match.start())

        salary_text = find_field(segment, "SALARY")
        centre = re.sub(r"\s+\d{1,3}$", "", find_field(segment, "CENTRE")).strip()
        requirements_text = find_field(segment, "REQUIREMENTS")
        duties_text = find_field(segment, "DUTIES")
        enquiry_text = find_field(segment, "ENQUIRIES")
        application_text = (
            find_field(segment, "APPLICATIONS")
            or find_field(segment, "APPLICATION")
            or nearby_value(text, match.start(), "APPLICATIONS")
            or nearby_value(text, match.start(), "APPLICATION")
        )
        closing_text = nearby_value(text, match.start(), "CLOSING DATE")
        closing_date = first_date(closing_text)
        minimum, maximum, currency, period = parse_salary(salary_text)

        combined_instructions = f"{application_text} {requirements_text}".lower()
        requires_z83 = True
        requires_certified = "certified" in combined_instructions
        requires_license = "driver" in requirements_text.lower() and "licence" in requirements_text.lower()
        application_email = first_email(application_text)
        application_url = first_url(application_text)
        method = application_method(application_text, requires_z83)

        jobs.append(
            {
                "id": stable_document_id(post_number, reference),
                "title": title,
                "companyName": department,
                "companyImageName": "",
                "location": {
                    "city": centre,
                    "region": "",
                    "country": "South Africa",
                },
                "jobType": "Public Service",
                "remote": False,
                "description": duties_text or requirements_text,
                "qualifications": split_sentences(requirements_text, maximum=8),
                "responsibilities": split_sentences(duties_text, maximum=12),
                "requirements": split_sentences(requirements_text, maximum=12),
                "experience": {
                    "minYears": 0,
                    "preferredYears": 0,
                    "details": requirements_text,
                },
                "compensation": {
                    "salaryRange": {
                        "min": minimum,
                        "max": maximum,
                        "currency": currency,
                        "period": period,
                    },
                    "benefits": [],
                },
                "application": {
                    "deadline": closing_date or clean_inline(closing_text),
                    "closingDate": closing_date,
                    "applicationUrl": application_url,
                    "applicationEmail": application_email,
                    "contactPhone": enquiry_text,
                    "method": method,
                    "formName": "Z83 Application for Employment" if requires_z83 else "",
                    "requiredForms": ["Z83 form"] if requires_z83 else [],
                    "requiredDocuments": ["Detailed CV"],
                    "instructions": application_text,
                    "requiresCoverLetter": False,
                    "requiresCV": True,
                    "requiresZ83": requires_z83,
                    "requiresCertifiedDocuments": requires_certified,
                    "referenceNumber": reference,
                    "postalAddress": application_text if "private bag" in application_text.lower() else "",
                    "handDeliveryAddress": application_text if "hand deliver" in application_text.lower() else "",
                    "requiresDriversLicense": requires_license,
                },
                "jobCategory": department,
                "postingDate": datetime.now(timezone.utc).date().isoformat(),
                "closingDate": closing_date,
                "visibility": {"featured": False, "promoted": False},
                "promoted": ["Government", "Z83"] if requires_z83 else ["Government"],
                "sourceName": "DPSA Public Service Vacancy Circular",
                "sourceUrl": source_url,
                "sourceJobId": reference,
                "sourceType": "government",
                "dateImported": imported_at,
                "verified": True,
                "publicationStatus": "published",
            }
        )

    return jobs


def publish_jobs(jobs: list[dict]) -> None:
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError as error:
        raise RuntimeError("Install importer requirements with: pip install -r tools/requirements.txt") from error

    service_account = os.environ.get("FIREBASE_SERVICE_ACCOUNT", "").strip()
    if not service_account:
        raise RuntimeError("FIREBASE_SERVICE_ACCOUNT is required when --publish is used.")

    credential_data = json.loads(service_account)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(credential_data))
    database = firestore.client()

    for start in range(0, len(jobs), 400):
        batch = database.batch()
        for job in jobs[start:start + 400]:
            document = database.collection("jobs").document(job["id"])
            payload = dict(job)
            payload.pop("id", None)
            batch.set(document, payload, merge=True)
        batch.commit()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", type=Path, help="Local official DPSA circular PDF")
    parser.add_argument("--pdf-url", help="Official DPSA circular URL")
    parser.add_argument("--output", type=Path, default=Path("imports/dpsa-vacancies.json"))
    parser.add_argument("--publish", action="store_true", help="Publish parsed jobs to Firestore")
    args = parser.parse_args()

    source_url = args.pdf_url or ""
    temporary_path = None
    pdf_path = args.pdf

    if pdf_path is None:
        source_url = source_url or discover_latest_pdf()
        temporary = tempfile.NamedTemporaryFile(suffix=".pdf", delete=False)
        temporary.write(fetch_url(source_url))
        temporary.close()
        temporary_path = Path(temporary.name)
        pdf_path = temporary_path

    try:
        jobs = parse_jobs(extract_pdf_text(pdf_path), source_url or str(pdf_path))
        if not jobs:
            raise RuntimeError("No vacancy posts were found in the circular.")

        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(jobs, indent=2, ensure_ascii=False), encoding="utf-8")
        if args.publish:
            publish_jobs(jobs)
        print(f"Parsed {len(jobs)} vacancies into {args.output}")
    finally:
        if temporary_path and temporary_path.exists():
            temporary_path.unlink()


if __name__ == "__main__":
    main()
