import json
import os
from datetime import timedelta
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient

def main(req: func.HttpRequest) -> func.HttpResponse:
    credential = DefaultAzureCredential()
    client = LogsQueryClient(credential)
    workspace_id = os.environ["LOG_ANALYTICS_WORKSPACE_ID"]
    timespan = timedelta(days=30)

    queries = {
        "totalViews": """
requests
| where url contains "index.html" or url == "/" or name contains "GET /"
| count
""",
        "apiHealth": """
requests
| where name contains "GetResumeTelemetry"
| summarize SuccessRate = countif(success == true) * 100.0 / count()
""",
        "latency": """
requests
| where success == true
| summarize AvgLatencyMs = avg(duration)
""",
        "topRegion": """
requests
| where isnotempty(client_CountryOrRegion)
| summarize Requests = count() by client_CountryOrRegion
| top 1 by Requests desc
"""
    }

    try:
        total_views_result = client.query_workspace(workspace_id, queries["totalViews"], timespan=timespan)
        api_health_result = client.query_workspace(workspace_id, queries["apiHealth"], timespan=timespan)
        latency_result = client.query_workspace(workspace_id, queries["latency"], timespan=timespan)
        region_result = client.query_workspace(workspace_id, queries["topRegion"], timespan=timespan)

        total_views = total_views_result.tables[0].rows[0][0] if total_views_result.tables and total_views_result.tables[0].rows else 0
        success_rate = api_health_result.tables[0].rows[0][0] if api_health_result.tables and api_health_result.tables[0].rows else 100.0
        avg_latency = latency_result.tables[0].rows[0][0] if latency_result.tables and latency_result.tables[0].rows else 0
        top_region = region_result.tables[0].rows[0][0] if region_result.tables and region_result.tables[0].rows else "N/A"

        telemetry = {
            "totalViews": str(int(total_views)),
            "apiStatus": f"{round(float(success_rate), 1)}%",
            "latency": f"{round(float(avg_latency))}ms",
            "topRegion": str(top_region)
        }

        return func.HttpResponse(
            json.dumps(telemetry),
            mimetype="application/json",
            status_code=200,
            headers={"Access-Control-Allow-Origin": "*"}
        )

    except Exception as e:
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            mimetype="application/json",
            status_code=500
        )
