import json
import logging
import os
from datetime import timedelta

import azure.functions as func
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential
from azure.monitor.query import LogsQueryClient, LogsQueryStatus

WORKSPACE_ID = os.environ.get("LOG_ANALYTICS_WORKSPACE_ID")
TABLE_NAME = os.environ.get("APP_REQUESTS_TABLE", "AppRequests")

# NOTE: KQL requires two separate 'extend' statements when the second
# extend references a column created in the first extend.
QUERY = """
let timeframe = 30d;
AppRequests
| where TimeGenerated >= ago(timeframe)
| summarize
    totalViews = count(),
    successful = countif(Success == true),
    avgLatencyMs = round(avg(DurationMs), 2)
| extend successRate = iff(totalViews == 0, 0.0, round((todouble(successful) / todouble(totalViews)) * 100.0, 2))
| extend apiHealth = iff(successRate >= 99.0, 'Healthy', iff(successRate >= 95.0, 'Degraded', 'Unhealthy'))
| project totalViews, successRate, avgLatencyMs, apiHealth
"""

FALLBACK = {
    "totalViews": 0,
    "successRate": 0.0,
    "avgLatencyMs": 0.0,
    "apiHealth": "Unknown"
}


def _get_credential():
    try:
        cred = ManagedIdentityCredential()
        logging.info("Using ManagedIdentityCredential")
        return cred
    except Exception as e:
        logging.warning(f"ManagedIdentityCredential failed: {e}, falling back to DefaultAzureCredential")
        return DefaultAzureCredential()


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("GetResumeTelemetry function invoked")
    try:
        if not WORKSPACE_ID:
            logging.error("LOG_ANALYTICS_WORKSPACE_ID is not set")
            return func.HttpResponse(
                json.dumps(FALLBACK),
                mimetype="application/json",
                status_code=200,
                headers={"Access-Control-Allow-Origin": "*"}
            )

        logging.info(f"WORKSPACE_ID = {WORKSPACE_ID}")

        credential = _get_credential()
        client = LogsQueryClient(credential)

        logging.info("Executing Log Analytics query...")
        result = client.query_workspace(
            workspace_id=WORKSPACE_ID,
            query=QUERY,
            timespan=timedelta(days=30)
        )

        logging.info(f"Query status = {result.status}")

        if result.status != LogsQueryStatus.SUCCESS or not result.tables or not result.tables[0].rows:
            logging.warning(f"Query did not return usable results. Status={result.status}")
            return func.HttpResponse(
                json.dumps(FALLBACK),
                mimetype="application/json",
                status_code=200,
                headers={"Access-Control-Allow-Origin": "*"}
            )

        row = result.tables[0].rows[0]
        logging.info(f"Raw row = {list(row)}")
        payload = {
            "totalViews": int(row[0] or 0),
            "successRate": float(row[1] or 0.0),
            "avgLatencyMs": float(row[2] or 0.0),
            "apiHealth": str(row[3] or "Unknown")
        }
        logging.info(f"Returning payload = {payload}")

        return func.HttpResponse(
            json.dumps(payload),
            mimetype="application/json",
            status_code=200,
            headers={"Access-Control-Allow-Origin": "*"}
        )

    except Exception as exc:
        logging.exception(f"Telemetry query failed with exception: {str(exc)}")
        return func.HttpResponse(
            json.dumps(FALLBACK),
            mimetype="application/json",
            status_code=200,
            headers={"Access-Control-Allow-Origin": "*"}
        )
