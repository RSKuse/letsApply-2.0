import unittest
from unittest.mock import patch

from import_partner_jobs import greenhouse_jobs, lever_jobs


class PartnerImporterTests(unittest.TestCase):

    @patch("import_partner_jobs.fetch_json")
    def test_maps_greenhouse_job(self, fetch_json):
        fetch_json.side_effect = [
            {"name": "Example Labs"},
            {
                "jobs": [
                    {
                        "id": 123,
                        "title": "Risk Analyst",
                        "absolute_url": "https://boards.greenhouse.io/example/123",
                        "updated_at": "2026-06-30T09:00:00Z",
                        "location": {"name": "Johannesburg, South Africa"},
                        "departments": [{"name": "Risk"}],
                        "content": "<p>Analyse operational risk.</p>",
                    }
                ]
            },
        ]

        jobs = greenhouse_jobs(
            {"token": "example", "logoUrl": "https://example.com/logo.png"}
        )

        self.assertEqual(len(jobs), 1)
        self.assertEqual(jobs[0]["companyName"], "Example Labs")
        self.assertEqual(jobs[0]["jobCategory"], "Risk")
        self.assertEqual(jobs[0]["sourceJobId"], "123")
        self.assertEqual(jobs[0]["application"]["method"], "externalWebsite")
        self.assertEqual(
            jobs[0]["companyLogoURL"], "https://example.com/logo.png"
        )

    @patch("import_partner_jobs.fetch_json")
    def test_maps_lever_remote_salary(self, fetch_json):
        fetch_json.return_value = [
            {
                "id": "abc",
                "text": "iOS Engineer",
                "hostedUrl": "https://jobs.lever.co/example/abc",
                "descriptionPlain": "Build accessible iOS products.",
                "createdAt": 1782806400000,
                "workplaceType": "remote",
                "categories": {
                    "location": "Remote",
                    "commitment": "Full-time",
                    "team": "Engineering",
                },
                "lists": [
                    {
                        "text": "Requirements",
                        "content": "<li>Swift and UIKit experience</li>",
                    }
                ],
                "salaryRange": {
                    "currency": "USD",
                    "min": 80000,
                    "max": 120000,
                    "interval": "year",
                },
            }
        ]

        jobs = lever_jobs({"site": "example", "company": "Example Labs"})

        self.assertEqual(len(jobs), 1)
        self.assertTrue(jobs[0]["location"]["remote"])
        self.assertEqual(
            jobs[0]["compensation"]["salaryRange"]["currency"], "USD"
        )
        self.assertEqual(
            jobs[0]["compensation"]["salaryRange"]["period"], "annum"
        )
        self.assertIn("Swift and UIKit", jobs[0]["requirements"][0])


if __name__ == "__main__":
    unittest.main()
