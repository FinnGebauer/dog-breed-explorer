variable "gcp_project" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west3"
  description = "GCP region for Cloud Run and Artifact Registry"
}

variable "bigquery_location" {
  type    = string
  default = "EU"
  description = "BigQuery dataset location"
}

variable "dog_api_key" {
  type      = string
  sensitive = true
}

variable "gcs_bucket" {
  type        = string
  description = "GCS bucket for raw data storage"
}
