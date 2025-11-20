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
  project = var.project_id
  region  = var.region
}

# Storage bucket for raw data
resource "google_storage_bucket" "raw" {
  name     = "${var.project_id}-dog-raw"
  location = var.location
  uniform_bucket_level_access = true
}

# BigQuery datasets
resource "google_bigquery_dataset" "bronze" {
  dataset_id                  = "bronze"
  location                    = var.location
  delete_contents_on_destroy  = true
}

resource "google_bigquery_dataset" "curated" {
  dataset_id                  = "curated"
  location                    = var.location
  delete_contents_on_destroy  = true
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

resource "google_bigquery_dataset_iam_member" "bronze_writer" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.ingest_sa.email}"
}
