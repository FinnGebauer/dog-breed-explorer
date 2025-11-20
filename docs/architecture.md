# Architecture Overview

This project implements an end-to-end modern data pipeline:

1. **Ingestion (dlt)**  
   - Fetches data from The Dog API  
   - Stores raw JSON in Google Cloud Storage  
   - Loads data into BigQuery (`bronze` dataset)

2. **Transformation (dbt)**  
   - Staging models to normalize the API schema  
   - Mart models for analytics (life span, weight, temperament)

3. **Orchestration**
   - Cloud Run executes `runner.py`  
   - Cloud Scheduler triggers ingestion daily at 02:00 UTC

4. **IaC (Terraform)**  
   - Creates GCS bucket, BigQuery datasets, and service accounts

5. **CI/CD (GitHub Actions)**  
   - Linting, testing, dbt validation

6. **Dashboard**
   - Looker Studio with insights on dog breeds

