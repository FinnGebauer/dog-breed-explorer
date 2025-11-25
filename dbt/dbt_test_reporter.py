import json
import sys
from pathlib import Path


def report_dbt_test_results():
    """Report dbt test results to Cloud Logging."""
    results_path = Path("dog_breed_explorer/target/run_results.json")
    
    if not results_path.exists():
        print(json.dumps({
            "message": "No run_results.json found - tests may not have run",
            "severity": "WARNING",
            "component": "dbt-tests"
        }))
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

    summary = {
        "total_tests": len(results.get("results", [])),
        "passed": passes,
        "failed": len(errors),
        "warnings": len(warnings),
    }

    if errors:
        print(json.dumps({
            "message": f"❌ dbt test failures detected: {len(errors)} failed, {len(warnings)} warnings",
            "dbt_errors": errors,
            "dbt_warnings": warnings,
            "summary": summary,
            "severity": "ERROR",
            "component": "dbt-tests"
        }))
        sys.exit(1)
    elif warnings:
        print(json.dumps({
            "message": f"⚠️  dbt tests passed with warnings: {len(warnings)} warnings",
            "dbt_warnings": warnings,
            "summary": summary,
            "severity": "WARNING",
            "component": "dbt-tests"
        }))
    else:
        print(json.dumps({
            "message": f"✅ All dbt tests passed! ({passes} tests)",
            "summary": summary,
            "severity": "INFO",
            "component": "dbt-tests"
        }))


if __name__ == "__main__":
    report_dbt_test_results()
