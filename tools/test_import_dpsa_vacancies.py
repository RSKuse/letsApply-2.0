import unittest
from unittest.mock import patch

from import_dpsa_vacancies import (
    DPSA_NEWSROOM_URL,
    discover_latest_pdf,
    inject_click_here_links,
    parse_experience,
    parse_jobs,
)


class DPSAImporterTests(unittest.TestCase):

    def test_parses_government_email_vacancy(self):
        text = """
DEPARTMENT OF DIGITAL SERVICES
CLOSING DATE : 10 July 2026
APPLICATIONS : Submit a signed Z83 and CV by email to jobs@example.gov.za.

POST 22/01 : RISK ANALYST (REF NO: DS/01/2026)
SALARY : R657 477 - R989 678 per annum
CENTRE : Pretoria
REQUIREMENTS : A relevant degree. Three years of risk analysis experience. A valid driver's licence.
DUTIES : Analyse operational risks. Prepare reports for senior management.
ENQUIRIES : Ms Example Tel: 012 000 0000
APPLICATIONS : Email jobs@example.gov.za before the closing date.
"""

        jobs = parse_jobs(text, "https://www.dpsa.gov.za/example.pdf")

        self.assertEqual(len(jobs), 1)
        job = jobs[0]
        self.assertEqual(job["title"], "Risk Analyst")
        self.assertEqual(job["application"]["referenceNumber"], "DS/01/2026")
        self.assertEqual(job["application"]["method"], "governmentEmail")
        self.assertEqual(job["application"]["applicationEmail"], "jobs@example.gov.za")
        self.assertEqual(job["compensation"]["salaryRange"]["min"], 657477)
        self.assertEqual(job["compensation"]["salaryRange"]["max"], 989678)
        self.assertEqual(job["closingDate"], "2026-07-10")
        self.assertTrue(job["application"]["requiresZ83"])
        self.assertTrue(job["application"]["requiresDriversLicense"])
        self.assertEqual(job["experience"]["minYears"], 3)

    def test_inherits_presidency_application_destination(self):
        text = """
ANNEXURE N

THE PRESIDENCY
APPLICATIONS : Apply by email to applications@presidency.gov.za or hand deliver at
Government Avenue, Union Buildings, Pretoria.
CLOSING DATE : 10 July 2026

POST 22/140 : DIRECTOR: POLICY (REF NO: PRES/01/2026)
SALARY : R1 216 824 per annum
CENTRE : Pretoria
REQUIREMENTS : An appropriate degree and at least five (5) years' relevant experience.
DUTIES : Lead policy development and provide strategic advice.
ENQUIRIES : Ms Example Tel: 012 000 0000
"""

        job = parse_jobs(text, "https://www.dpsa.gov.za/circular-22.pdf")[0]

        self.assertEqual(job["companyName"], "The Presidency")
        self.assertEqual(
            job["application"]["applicationEmail"],
            "applications@presidency.gov.za",
        )
        self.assertEqual(job["application"]["method"], "governmentEmail")
        self.assertEqual(job["experience"]["minYears"], 5)

    def test_experience_without_a_stated_year_does_not_invent_zero_years(self):
        self.assertEqual(
            parse_experience("Relevant management experience will be an advantage."),
            (0, 0),
        )

    def test_uses_known_department_portal_when_circular_has_no_email(self):
        text = """
ANNEXURE H

DEPARTMENT OF HIGHER EDUCATION AND TRAINING
APPLICATIONS : Applications must be submitted through the Department's
electronic recruitment system.
CLOSING DATE : 10 July 2026

POST 22/80 : DEPUTY DIRECTOR: EVALUATION (REF NO: DHET/01/2026)
SALARY : R1 101 468 per annum
CENTRE : Pretoria
REQUIREMENTS : A relevant degree and five years of evaluation experience.
DUTIES : Coordinate programme evaluations and prepare management reports.
"""

        job = parse_jobs(text, "https://www.dpsa.gov.za/circular-22.pdf")[0]

        self.assertEqual(job["application"]["method"], "governmentWebsite")
        self.assertEqual(
            job["application"]["applicationUrl"],
            "https://z83.ngnscan.co.za/login",
        )

    def test_restores_hidden_click_here_hyperlink(self):
        text = "APPLICATION : Link: CLICK HERE"

        result = inject_click_here_links(
            text,
            ["https://forms.gle/example-post-form"],
        )
        job_text = f"""
ANNEXURE B
DEPARTMENT OF COMMUNICATIONS AND DIGITAL TECHNOLOGIES
POST 22/04 : DIRECTOR: DIGITAL SERVICES (REF: DIRDS)
SALARY : R1 317 384 per annum
CENTRE : Pretoria
REQUIREMENTS : A relevant degree and five years of experience.
DUTIES : Manage digital services.
{result}
"""
        job = parse_jobs(job_text, "https://www.dpsa.gov.za/circular-22.pdf")[0]

        self.assertEqual(
            job["application"]["applicationUrl"],
            "https://forms.gle/example-post-form",
        )
        self.assertEqual(job["application"]["method"], "governmentWebsite")
        self.assertTrue(job["verified"])

    def test_post_specific_email_overrides_department_website(self):
        text = """
ANNEXURE C
DEPARTMENT OF PUBLIC WORKS
APPLICATIONS : Apply online at https://careers.example.gov.za.

POST 22/10 : POLICY ANALYST (REF: PW/10)
SALARY : R500 000 per annum
CENTRE : Pretoria
REQUIREMENTS : Three years of policy experience.
DUTIES : Analyse policy.
APPLICATION : Email analyst-applications@example.gov.za.
"""

        job = parse_jobs(text, "https://www.dpsa.gov.za/circular-22.pdf")[0]

        self.assertEqual(
            job["application"]["applicationEmail"],
            "analyst-applications@example.gov.za",
        )
        self.assertEqual(job["application"]["method"], "governmentEmail")

    def test_last_post_does_not_inherit_next_annexure_destination(self):
        text = """
ANNEXURE B
DEPARTMENT OF COMMUNICATIONS
POST 22/11 : DIRECTOR: COMMUNICATIONS (REF: COM/11)
SALARY : R1 000 000 per annum
CENTRE : Pretoria
REQUIREMENTS : Five years of management experience.
DUTIES : Lead communications.
APPLICATION : Link: CLICK HERE

ANNEXURE C
DEPARTMENT OF CORRECTIONAL SERVICES
APPLICATIONS : Apply online at https://careers.dcs.gov.za/.
POST 22/12 : ADMINISTRATOR (REF: DCS/12)
SALARY : R300 000 per annum
CENTRE : Pretoria
REQUIREMENTS : Two years of administration experience.
DUTIES : Provide administration.
"""

        jobs = parse_jobs(text, "https://www.dpsa.gov.za/circular-22.pdf")

        self.assertEqual(jobs[0]["application"]["applicationUrl"], "")
        self.assertEqual(jobs[0]["application"]["method"], "governmentManual")
        self.assertFalse(jobs[0]["verified"])
        self.assertEqual(
            jobs[1]["application"]["applicationUrl"],
            "https://careers.dcs.gov.za/",
        )

    @patch("import_dpsa_vacancies.fetch_url")
    def test_latest_circular_prefers_newest_year_before_number(self, fetch_url):
        fetch_url.return_value = b"""
        <a href="/documents/PSV%20CIRCULAR%2047%20of%202025.pdf">Old</a>
        <a href="/documents/PSV%20CIRCULAR%2022%20of%202026.pdf">New</a>
        """

        result = discover_latest_pdf()

        self.assertEqual(
            result,
            "https://www.dpsa.gov.za/documents/PSV%20CIRCULAR%2022%20of%202026.pdf",
        )
        fetch_url.assert_called_once_with(DPSA_NEWSROOM_URL)


if __name__ == "__main__":
    unittest.main()
