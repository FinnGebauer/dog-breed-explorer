"""
Cloud Function entry point for dog breed data ingestion.
"""
import functions_framework
import os


@functions_framework.http
def main(request):
    """HTTP Cloud Function entry point."""
    try:
        # Import here to avoid issues with Cloud Functions environment
        from src.pipeline import fetch_breeds, write_raw_to_gcs, load_to_bigquery
        
        api_key = os.getenv("DOG_API_KEY")
        gcs_bucket = os.getenv("GCS_BUCKET")
        gcs_prefix = os.getenv("GCS_PREFIX", "dog_api")
        bq_dataset = os.getenv("DATASET", "raw")

        if not gcs_bucket:
            raise ValueError("Missing required environment variable: GCS_BUCKET")

        print("Starting Dog API ingestion...")
        
        print("Fetching dog breeds...")
        data = fetch_breeds(api_key)
        print(f"Fetched {len(data)} records")

        print(f"Writing raw JSON to GCS bucket={gcs_bucket}")
        blob_path = write_raw_to_gcs(data, gcs_bucket, gcs_prefix)
        print(f"Raw written to gs://{gcs_bucket}/{blob_path}")

        print(f"Loading into BigQuery dataset={bq_dataset}")
        load_info = load_to_bigquery(data, bq_dataset)
        print(f"Load info: {load_info}")

        print("Ingestion completed successfully.")
        
        return {"status": "success", "message": "Dog breed ingestion completed successfully"}, 200
    except Exception as e:
        print(f"Error during ingestion: {str(e)}")
        import traceback
        traceback.print_exc()
        return {"status": "error", "message": str(e)}, 500