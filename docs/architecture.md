# Architecture Overview

This project implements an end-to-end modern data pipeline:

1. **Ingestion (dlt)**  
   - Fetches data from The Dog API  
   - Stores raw JSON in Google Cloud Storage  
   - Loads data into BigQuery (`raw` dataset)

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

# Architecture Deep Dive

## High-Level Overview

```
Dog API → Cloud Function (dlt) → GCS + BigQuery (raw)
                                        ↓
                                   dbt (staging → marts)
                                        ↓
                                   Looker Studio

CI/CD: GitHub Actions (PR: test dev | Main: deploy prod)
Monitoring: Cloud Logging + Email alerts
```

**Key Design Decisions:**
- **dlt:** Schema evolution, automatic retries, incremental-ready
- **Cloud Functions:** Serverless, pay-per-invoke, scales to zero
- **Star schema:** Optimized for analytical queries
- **Fail-hard tests:** Bad data worse than no data

---

## Detailed System Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    INGESTION LAYER                        │
└──────────────────────────────────────────────────────────┘
                            │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
    ▼                       ▼                       ▼
Cloud Scheduler    Cloud Function (dlt)      Dog API
(Daily 02:00)                             (thedogapi.com)
                   
                            │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
   ┌──────────────────┐        ┌─────────────────┐
   │  Cloud Storage   │        │  BigQuery (raw) │
   │  (JSON archive)  │        │                 │
   └──────────────────┘        └────────┬────────┘
                                        │
┌───────────────────────────────────────┼──────────┐
│                  TRANSFORMATION LAYER │          │
└──────────────────────────────────────────────────┘
                                        │
                          ┌─────────────▼─────────────┐
                          │      dbt (CI/CD)          │
                          │  ┌──────────────────┐     │
                          │  │ Staging (views)  │     │
                          │  └────────┬─────────┘     │
                          │           │               │
                          │  ┌────────▼─────────┐     │
                          │  │ Intermediate     │     │
                          │  └────────┬─────────┘     │
                          │           │               │
                          │  ┌────────▼─────────┐     │
                          │  │ Marts (tables)   │     │
                          │  │ - dim_breed      │     │
                          │  │ - fact_metrics   │     │
                          │  └──────────────────┘     │
                          └─────────────┬─────────────┘
                                        │
┌───────────────────────────────────────┼──────────┐
│                  CONSUMPTION LAYER    │          │
└──────────────────────────────────────────────────┘
                                        │
                     ┌──────────────────┴──────────────────┐
                     │                                     │
                     ▼                                     ▼
             ┌──────────────┐                    ┌──────────────┐
             │Looker Studio │                    │ dbt Docs     │
             │  Dashboard   │                    │ (GCS hosted) │
             └──────────────┘                    └──────────────┘
```

---

## Key Components

**Ingestion:**
- **Cloud Scheduler:** Triggers daily at 02:00 UTC
- **Cloud Function:** Runs dlt pipeline (Python 3.11, 1GB RAM, 540s timeout)
- **Outputs:** GCS JSON archive + BigQuery raw table

**Transformation:**
- **dbt:** Staging (normalize) → Intermediate (business logic) → Marts (star schema)
- **Materialization:** Views for staging/intermediate, tables for marts
- **Tests:** 50+ schema, business logic, and statistical validations

**CI/CD:**
- **PR:** dbt test on `dev` dataset
- **Main:** ingest → dbt run/test on `prod` → publish docs → alert on failure

**Monitoring:**
- **Cloud Logging:** Function execution, dbt test results
- **Alerts:** Email on test failures (fail-hard policy)

---

## Data Flow

**Daily Pipeline:**
1. Scheduler triggers function at 02:00 UTC
2. dlt fetches Dog API → writes GCS + BigQuery
3. (Optional) GitHub Actions triggers dbt
4. dbt transforms raw → staging → marts
5. dbt runs 50+ tests (pipeline fails if any fail)
6. Publish docs to GCS

**Development Flow:**
1. Developer pushes PR
2. GitHub Actions runs dbt test on `dev`
3. Merge to main → production deployment

---

## Security

**IAM (Least Privilege):**
- Function SA: `bigquery.dataEditor`, `storage.objectAdmin`, `logging.logWriter`
- CI/CD SA: `bigquery.dataEditor`, `cloudfunctions.developer`, `storage.objectAdmin`

**Data Residency:** All resources in EU

**Secrets:** GitHub Secrets + Terraform variables (no credentials in code)

---

**For operations, see [runbook.md](runbook.md)**

