# Runbook — Dog Breed Explorer

## Prerequisites

Ensure the following environment variables are set:
- `DOG_API_KEY` (optional)
- `GCS_BUCKET`
- `BQ_DATASET`

## Manual Ingestion

Run the ingestion pipeline locally:

```bash
poetry run python ingest/src/runner.py
```

## Deploying Infrastructure

Deploy or update infrastructure with Terraform:

```bash
cd infra
terraform init
terraform apply -var="project_id=dog-breed-explorer-478808"
```

## Debugging

### Check Cloud Run Logs

View logs from the Cloud Run service:

```bash
gcloud run services logs read dog-breed-runner
```

### Check BigQuery

Inspect the latest ingestion batch in the `raw.dog_api_raw` table.

### Check Cloud Storage

Verify raw JSON objects exist at:
```
gs://<your-bucket>/dog_api/raw_YYYYMMDDTHHMMSSZ.json
```

## Project Structure

```
ingest/       # dlt ingestion pipeline
dbt/          # dbt models
infra/        # Terraform configuration
docs/         # Architecture diagrams and documentation
dashboards/   # Looker Studio exports
```

## Local Development Setup

1. Install dependencies:
   ```bash
   poetry install
   ```

2. Set required environment variables:
   ```bash
   export GCS_BUCKET=your-bucket
   export DATASET=dog_breeds_dev
   export DOG_API_KEY=your-api-key  # optional
   ```

3. Run ingestion:
   ```bash
   poetry run python ingest/src/runner.py
   ```

---

# Operational Runbook

## Daily Operations

### Monitor Pipeline

```bash
# Check function logs
gcloud functions logs read dog-breed-ingestion --gen2 --region=europe-west3 --limit=20

# Check BigQuery data
bq query 'SELECT COUNT(*) FROM `dog-breed-explorer-478808.raw.dog_api_raw`'

# Check dbt docs freshness
gsutil ls -l gs://dog-breed-explorer-478808-dbt-docs/index.html
```

**Success Indicators:**
- Function runs in 10-30s
- 173 rows in BigQuery
- All dbt tests passing
- No error emails

---

## Manual Operations

### Trigger Ingestion
```bash
gcloud scheduler jobs run dog-breed-ingestion-job --location=europe-west3
```

### Run dbt
```bash
cd dbt/dog_breed_explorer
poetry run dbt run --target prod
poetry run dbt test --target prod
```

### Deploy Infrastructure
```bash
cd infra
terraform plan
terraform apply
```

---

## Troubleshooting

### Function Fails
```bash
# Check logs
gcloud functions logs read dog-breed-ingestion --gen2 --region=europe-west3 --limit=50

# Common causes: API key expired, BigQuery permissions, timeout
# Fix: Update env vars or redeploy
terraform apply -target=google_cloudfunctions2_function.ingestion
```

### dbt Tests Fail
```bash
# Run locally to debug
cd dbt/dog_breed_explorer
poetry run dbt test --target dev --select test_name

# Check for data issues
bq query 'SELECT * FROM `dog-breed-explorer-478808.dog_breeds_marts.dim_breed` WHERE breed_id IS NULL'
```

### Dashboard Stale
```bash
# Check last BigQuery update
bq show dog-breed-explorer-478808:dog_breeds_marts.dim_breed | grep lastModified

# Force refresh
poetry run dbt run --target prod --full-refresh
```

---

**Key Commands Reference:**

```bash
# Function
gcloud functions describe dog-breed-ingestion --gen2 --region=europe-west3
gcloud functions logs read dog-breed-ingestion --gen2 --region=europe-west3

# Scheduler
gcloud scheduler jobs run dog-breed-ingestion-job --location=europe-west3

# BigQuery
bq ls --project_id=dog-breed-explorer-478808
bq query 'SELECT * FROM `dog-breed-explorer-478808.dog_breeds_marts.dim_breed` LIMIT 10'

# dbt
poetry run dbt run --target prod
poetry run dbt test --target prod
poetry run dbt docs generate && poetry run dbt docs serve

# Terraform
terraform plan
terraform apply
```