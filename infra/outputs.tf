output "raw_bucket" {
  value = google_storage_bucket.raw.name
}

output "ingest_service_account" {
  value = google_service_account.ingest_sa.email
}
