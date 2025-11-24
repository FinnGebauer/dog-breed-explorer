terraform {
  required_version = ">= 1.6.0"

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

# Storage bucket for raw data
resource "google_storage_bucket" "raw" {
  name     = "${var.gcp_project}-dog-raw"
  location = var.bigquery_location
  uniform_bucket_level_access = true
}

resource "google_bigquery_dataset" "raw" {
  dataset_id = "raw"
  location   = var.bigquery_location
  delete_contents_on_destroy = false
}

# Service account for ingestion
resource "google_service_account" "ingest_sa" {
  account_id   = "ingest-runner"
  display_name = "Ingestion Runner SA"
}

# IAM permissions
resource "google_storage_bucket_iam_member" "ingest_writer" {
  bucket = google_storage_bucket.raw.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ingest_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "raw_writer" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.ingest_sa.email}"
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
