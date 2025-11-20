import os
import logging

from ingest.src.pipeline import fetch_breeds, write_raw_to_gcs, load_to_bigquery


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)


def main():
    api_key = os.getenv("DOG_API_KEY")
    gcs_bucket = os.getenv("GCS_BUCKET")
    gcs_prefix = os.getenv("GCS_PREFIX", "dog_api")
    bq_dataset = os.getenv("BQ_DATASET", "bronze")

    if not gcs_bucket:
        raise ValueError("Missing required environment variable: GCS_BUCKET")

    logging.info("Starting Dog API ingestion…")

    logging.info("Fetching dog breeds…")
    data = fetch_breeds(api_key)
    logging.info("Fetched %d records", len(data))

    logging.info("Writing raw JSON to GCS bucket=%s", gcs_bucket)
    blob_path = write_raw_to_gcs(data, gcs_bucket, gcs_prefix)
    logging.info("Raw written to gs://%s/%s", gcs_bucket, blob_path)

    logging.info("Loading into BigQuery dataset=%s", bq_dataset)
    load_info = load_to_bigquery(data, bq_dataset)
    logging.info("Load info: %s", load_info)

    logging.info("Ingestion completed successfully.")


if __name__ == "__main__":
    main()
