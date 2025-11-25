# 🐕 Dog Breed Explorer

[![CI/CD](https://github.com/FinnGebauer/dog-breed-explorer/actions/workflows/ci.yml/badge.svg)](https://github.com/FinnGebauer/dog-breed-explorer/actions)
[![dbt docs](https://img.shields.io/badge/dbt-docs-orange)](https://storage.googleapis.com/dog-breed-explorer-478808-dbt-docs/index.html)

Production data pipeline analysing dog breeds. Built with **dlt**, **dbt**, **BigQuery**, and **Terraform** on GCP.

**Live Resources:**
- **GCP Project:** `dog-breed-explorer-478808`
- **dbt Docs:** https://storage.googleapis.com/dog-breed-explorer-478808-dbt-docs/index.html
- **Dashboard:** https://lookerstudio.google.com/reporting/f2038b7e-877c-4b0c-8b11-7f18e25db2b7

**Documentation:**
- **Architecture:** [docs/architecture.md](docs/architecture.md)
- **Runbook:** [docs/runbook.md](docs/runbook.md)

---

## Quick Start

```bash
# 1. Clone & authenticate
git clone https://github.com/FinnGebauer/dog-breed-explorer.git
cd dog-breed-explorer
gcloud auth application-default login

# 2. Deploy infrastructure
cd infra
cat > terraform.tfvars <<EOF
gcp_project = "dog-breed-explorer-478808"
dog_api_key = "YOUR_KEY"
alert_email = "your@email.com"
EOF
terraform init && terraform apply

# 3. Configure GitHub Secrets
# - GCP_SA_KEY: Service account JSON
# - DOG_API_KEY: Your API key

# 4. Push to trigger pipeline
git push origin main
```

**Local Development:**
```bash
# Ingestion
cd ingest && poetry install
export DOG_API_KEY="key" GCS_BUCKET="bucket" DATASET="raw"
poetry run python src/runner.py

# dbt
cd dbt/dog_breed_explorer && poetry install
poetry run dbt deps
poetry run dbt run --target dev
poetry run dbt test --target dev
```

---

## Task Deliverables

### Task 1: Environment ✓
- **Project:** `dog-breed-explorer-478808`
- **Repo:** https://github.com/FinnGebauer/dog-breed-explorer
- **IaC:** All in `infra/main.tf`

### Task 2: Ingestion (dlt) ✓
- **Pipeline:** `ingest/src/pipeline.py`
- **Schedule:** Daily 02:00 UTC via Cloud Scheduler
- **Outputs:** GCS JSON + BigQuery `raw.dog_api_raw`

### Task 3: dbt Models ✓
```
staging/stg_dog_api_raw       # Normalise, parse ranges, dedupe
intermediate/int_family_friendly_score  # implement a family-friendly score based on the temperaments
marts/dim_breed               # Descriptive attributes
marts/fact_breed_metrics      # Numeric measures
marts/dim_temperaments        # Unnested temperaments
```
- **Tests:** 50+ (schema, business logic, statistical)
- **Docs:** Auto-published to GCS

### Task 4: CI/CD ✓
- **PR:** dbt test on `dev` dataset
- **Main:** ingest → dbt run/test on `prod` → publish docs
- **Failure:** Email alert, pipeline fails

### Task 5: Data Quality ✓
- **Tests:** unique, not_null, relationships, custom SQL, dbt_expectations
- **Monitoring:** Cloud Logging + email alerts
- **Policy:** Any test failure blocks deployment

### Task 6: Insights ✓

**Dashboard:** https://lookerstudio.google.com/reporting/f2038b7e-877c-4b0c-8b11-7f18e25db2b7

**Key Findings:**

Longevity Advantage:
The top 10 longest-living breeds average 15+ years, with Maltese leading at 16.5 years. Notably, all top performers fall into Small or Medium weight classes (<25kg), reinforcing the inverse relationship between size and lifespan. For families seeking long-term companions, smaller breeds offer significantly extended ownership periods.
Note: Perfect 15-year uniformity in top breeds suggests potential data limitations in API source and real-world variation is to be expected.

Weight Distribution Insights:
Medium breeds (10-25kg) represent the largest segment, followed closely by Large breeds (25-45kg). This balanced distribution suggests family-friendly traits aren't size-dependent—contradicting the "bigger = better family dog" assumption. Only 12 Giant breeds qualify as family-friendly, indicating temperament challenges at extreme sizes.

Temperament Profile:
As temperaments were used to assign family-friendliness scores, the expected traits "Intelligent", "Affectionate", "Friendly", and "Loyal" dominate. These characteristics cluster around trainability and human bonding—critical for households with children. Lower frequencies of "Alert" and "Energetic" suggest family-friendly breeds trend toward calm, manageable temperaments.

The Sweet Spot:
The scatter plot reveals an optimal zone: 10-15 year lifespan, 10-35kg weight, with dense clustering of highly family-friendly breeds. This Medium weight class offers the best balance—manageable size for households, reasonable longevity, and proven temperament stability.

Actionable Recommendation:
Families should prioritize Medium-weight breeds scoring 70+ on family-friendliness. These dogs combine practical size, extended companionship (12-15 years), and proven child-compatible temperaments—delivering optimal value across emotional and practical dimensions.





---

## Data Model

**Star Schema:**
```
dim_breed                    fact_breed_metrics         dim_temperaments
├─ breed_id (PK)             ├─ breed_id (FK)           ├─ breed_id (FK)
├─ breed_name                ├─ weight_kg_min/max/avg   └─ temperament
├─ breed_group               ├─ height_cm_min/max/avg
├─ temperament               └─ life_span_years_*
├─ family_friendly_score
└─ weight_class
```

**Full Documentation:** [dbt docs](https://storage.googleapis.com/dog-breed-explorer-478808-dbt-docs/index.html)

---

## Security

**Security:**
- Least-privilege service accounts
- Data in EU region (GDPR-compliant)
- Secrets via GitHub Secrets + Terraform
- No credentials in code

---

## Future Improvements

**High Priority:**
- Consolidate `runner.py` and `main.py` (reduce duplication)
- Proper Cloud Logging (replace print statements)
- Secret Manager like sops (automated rotation)

**Medium Priority:**
- Terraform modules (reusable across projects)
- YAML-based trait management (non-engineer updates)

---

## Project Structure

```
dog-breed-explorer/
├── ingest/              # dlt pipeline
│   ├── src/pipeline.py  # dlt source
│   └── main.py          # Cloud Function
├── dbt/                 # dbt models
│   └── dog_breed_explorer/
│       └── models/      # staging, intermediate, marts
├── infra/               # Terraform IaC
│   └── main.tf          # All GCP resources
├── docs/                # Documentation
│   ├── architecture.md  # System design
│   └── runbook.md       # Operations guide
└── .github/workflows/   # CI/CD
    └── ci.yml
```

---

**Built by Finn Gebauer** | **Duration:** ~8 hours | **Updated:** Nov 25, 2024