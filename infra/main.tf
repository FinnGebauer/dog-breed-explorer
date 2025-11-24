terraform {
  required_version = ">= 1.6"

  backend "gcs" {
    bucket = "dog_breed_explorer_tf_state"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.region
}


#############################################
# ENABLE APIs
#############################################

resource "google_project_service" "cloudfunctions" {
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudscheduler" {
  service = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "runapi" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "bigquery_api" {
  service = "bigquery.googleapis.com"
  disable_on_destroy = false
}

#############################################
# BIGQUERY DATASETS
#############################################

resource "google_bigquery_dataset" "raw" {
  dataset_id = "raw"
  location   = var.bigquery_location
  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "staging" {
  dataset_id = "dog_breeds_dev_staging"
  location   = var.bigquery_location
  delete_contents_on_destroy = false
}

resource "google_bigquery_dataset" "marts" {
  dataset_id = "dog_breeds_dev_marts"
  location   = var.bigquery_location
  delete_contents_on_destroy = false
}

#############################################
# SERVICE ACCOUNTS
#############################################

resource "google_service_account" "function_sa" {
  account_id   = "dog-breed-ingestion"
  display_name = "Dog Breed Ingestion Runner"
}

resource "google_project_iam_member" "function_bq_editor" {
  project = var.gcp_project
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "function_bq_job" {
  project = var.gcp_project
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "function_storage_admin" {
  project = var.gcp_project
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = var.gcp_project
  location       = var.region
  cloud_function = google_cloudfunctions2_function.ingestion.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.function_sa.email}"
}

#############################################
# FUNCTION SOURCE
#############################################

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../ingest"
  output_path = "${path.module}/function-source.zip"

  excludes = [
    "__pycache__",
    "*.pyc",
    ".venv",
    ".pytest_cache",
    "tests",
    ".git",
    ".gitignore",
    "poetry.lock",
    "pyproject.toml",
  ]
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.gcp_project}-function-src"
  location = var.bigquery_location
}

resource "google_storage_bucket_object" "function_zip_file" {
  name   = "function-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

#############################################
# CLOUD FUNCTION
#############################################

resource "google_cloudfunctions2_function" "ingestion" {
  name     = "dog-breed-ingestion"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"

    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_zip_file.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    timeout_seconds    = 540
    available_memory   = "1Gi"

    environment_variables = {
      DOG_API_KEY = var.dog_api_key
      DATASET     = "raw"
      GCS_BUCKET  = var.gcs_bucket
      DESTINATION__BIGQUERY__LOCATION = "EU"
    }

    service_account_email = google_service_account.function_sa.email
  }
}

#############################################
# CLOUD SCHEDULER TRIGGER FOR JOB
#############################################

resource "google_cloud_scheduler_job" "ingestion_schedule" {
  name      = "dog-breed-ingestion-job"
  schedule  = "0 2 * * *"
  time_zone = "UTC"
  region    = var.region

  http_target {
    uri         = google_cloudfunctions2_function.ingestion.service_config[0].uri
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.function_sa.email
    }
  }
}

#############################################
# DBT DOCS HOSTING
#############################################

resource "google_storage_bucket" "dbt_docs" {
  name     = "${var.gcp_project}-dbt-docs"
  location = var.bigquery_location
  
  uniform_bucket_level_access = true
  
  website {
    main_page_suffix = "index.html"
  }
}

# Make docs publicly accessible
resource "google_storage_bucket_iam_member" "dbt_docs_public" {
  bucket = google_storage_bucket.dbt_docs.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Grant CI/CD service account write access
resource "google_storage_bucket_iam_member" "dbt_docs_cicd" {
  bucket = google_storage_bucket.dbt_docs.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:github-actions@${var.gcp_project}.iam.gserviceaccount.com"
}

