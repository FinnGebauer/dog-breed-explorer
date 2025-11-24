import json
import logging
import sys
from pathlib import Path
import google.cloud.logging


def report_dbt_test_results():
    """Report dbt test results to Cloud Logging."""
    logging_client = google.cloud.logging.Client()
    logging_client.setup_logging()
    
    # Find run_results.json
    results_path = Path("dog_breed_explorer/target/run_results.json")
    
    if not results_path.exists():
        logging.warning("No run_results.json found - tests may not have run")
        return
    
    with open(results_path) as f:
        results = json.load(f)

    errors = []
    warnings = []
    passes = 0
    
    for r in results.get("results", []):
        if r["status"] == "fail":
            errors.append({
                "test_name": r["unique_id"],
                "status": r["status"],
                "execution_time": r["execution_time"],
                "failures": r.get("failures"),
                "message": r.get("message", ""),
            })
        elif r["status"] == "warn":
            warnings.append({
                "test_name": r["unique_id"],
                "status": r["status"],
                "execution_time": r["execution_time"],
            })
        elif r["status"] == "pass":
            passes += 1

    # Log summary
    summary = {
        "total_tests": len(results.get("results", [])),
        "passed": passes,
        "failed": len(errors),
        "warnings": len(warnings),
    }

    if errors:
        logging.error(
            f"❌ dbt test failures detected: {len(errors)} failed, {len(warnings)} warnings",
            extra={
                "dbt_errors": errors,
                "dbt_warnings": warnings,
                "summary": summary,
            }
        )
        sys.exit(1)  # Exit with error code for CI/CD
    elif warnings:
        logging.warning(
            f"⚠️  dbt tests passed with warnings: {len(warnings)} warnings",
            extra={"dbt_warnings": warnings, "summary": summary}
        )
    else:
        logging.info(
            f"✅ All dbt tests passed! ({passes} tests)",
            extra={"summary": summary}
        )


if __name__ == "__main__":
    report_dbt_test_results()
