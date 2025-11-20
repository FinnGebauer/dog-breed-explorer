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

Inspect the latest ingestion batch in the `bronze.dog_api_raw` table.

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
   export BQ_DATASET=bronze
   export DOG_API_KEY=your-api-key  # optional
   ```

3. Run ingestion:
   ```bash
   poetry run python ingest/src/runner.py
   ```