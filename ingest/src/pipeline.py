import json
import requests
import dlt
from google.cloud import storage
from datetime import datetime
from typing import List, Dict


DOG_API_URL = "https://api.thedogapi.com/v1/breeds"


def fetch_breeds(api_key: str | None = None) -> List[Dict]:
    """Fetches the JSON array of dog breeds from The Dog API."""
    headers = {"x-api-key": api_key} if api_key else {}

    response = requests.get(DOG_API_URL, headers=headers, timeout=30)
    response.raise_for_status()

    data = response.json()
    if not isinstance(data, list):
        raise ValueError("Unexpected API response format: expected a list of objects")

    return data


def write_raw_to_gcs(data: List[Dict], bucket_name: str, prefix: str) -> str:
    """
    Saves raw JSON to GCS under a timestamped path for lineage and auditing.

    Returns:
        str: The GCS blob path used.
    """
    client = storage.Client()
    bucket = client.bucket(bucket_name)

    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    blob_path = f"{prefix}/raw_{ts}.json"

    blob = bucket.blob(blob_path)
    blob.upload_from_string(json.dumps(data), content_type="application/json")

    return blob_path


def load_to_bigquery(data: List[Dict], dataset: str) -> dict:
    """
    Loads data into BigQuery using dlt.
    - Creates a pipeline named 'dog_breeds'
    - Writes to {dataset}.dog_api_raw table
    """
    pipeline = dlt.pipeline(
        pipeline_name="dog_breeds",
        destination="bigquery",
        dataset_name=dataset,
    )

    # dlt will infer schema and upsert into table "dog_api_raw"
    load_info = pipeline.run(
        data,
        table_name="dog_api_raw",
        write_disposition="append",
    )

    return load_info
