import json
from ingest.src.pipeline import fetch_breeds


def test_fetch_breeds_structure(requests_mock):
    """Ensures the API returns a list and a valid structure."""
    mock_data = [{"id": 1, "name": "Test Breed"}]
    requests_mock.get(
        "https://api.thedogapi.com/v1/breeds",
        text=json.dumps(mock_data),
        status_code=200,
    )

    data = fetch_breeds(api_key=None)
    assert isinstance(data, list)
    assert data[0]["name"] == "Test Breed"
