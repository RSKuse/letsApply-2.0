# Vacancy Importer

The importer reads the official DPSA Public Service Vacancy Circular and maps each post to the Firestore `jobs` schema used by the iOS app.

Generate a reviewable JSON file:

```bash
python3 -m pip install -r tools/requirements.txt
python3 tools/import_dpsa_vacancies.py --pdf "/path/to/circular.pdf"
```

Publishing is intentionally separate from parsing. The GitHub workflow needs a repository secret named `FIREBASE_SERVICE_ACCOUNT` containing a restricted Firebase service-account JSON value. Never commit that value.

The importer only publishes source metadata and application instructions found in the official circular. Candidates still review and approve applications in the app.

## Approved Partner Feeds

`import_partner_jobs.py` supports documented public job-board APIs. It does not
scrape LinkedIn, Indeed, Glassdoor, or employer pages.

Configure repository variables in GitHub:

```text
GREENHOUSE_BOARDS_JSON=[{"company":"OpenAI","token":"openai"}]
LEVER_SITES_JSON=[{"company":"Example","site":"example","region":"global"}]
RELIEFWEB_APPNAME=approved-app-name
```

Each Greenhouse or Lever entry may include an optional HTTPS `logoUrl`. Only use
a company logo that the employer or an approved partner has supplied for this
purpose. ReliefWeb requires an approved app name before production API use.

The **Import partner vacancies** GitHub Action runs daily. It publishes current
jobs and expires Greenhouse or Lever jobs that disappear from a complete feed.
Keep `FIREBASE_SERVICE_ACCOUNT` in GitHub Actions secrets, never repository
variables or iOS source code.
