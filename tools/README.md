# Vacancy Importer

The importer reads the official DPSA Public Service Vacancy Circular and maps each post to the Firestore `jobs` schema used by the iOS app.

Generate a reviewable JSON file:

```bash
python3 -m pip install -r tools/requirements.txt
python3 tools/import_dpsa_vacancies.py --pdf "/path/to/circular.pdf"
```

Publishing is intentionally separate from parsing. The GitHub workflow needs a repository secret named `FIREBASE_SERVICE_ACCOUNT` containing a restricted Firebase service-account JSON value. Never commit that value.

The importer only publishes source metadata and application instructions found in the official circular. Candidates still review and approve applications in the app.
