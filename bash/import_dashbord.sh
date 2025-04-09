#!/bin/bash
# Import dashboard to Grafana

# Get Grafana admin password
GRAFANA_PASSWORD=6Hj1ogumRwNDqqGsGbWEK3IQsErfmflo29ktUkIi

# Get Grafana URL
GRAFANA_URL=http://127.0.0.1:63323

echo "Grafana URL: ${GRAFANA_URL}"
echo "Grafana admin password: ${GRAFANA_PASSWORD}"

# Add Prometheus data source
echo "Adding Prometheus data source..."
curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "admin:${GRAFANA_PASSWORD}" \
  "${GRAFANA_URL}/api/datasources" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus-server.monitoring.svc.cluster.local",
    "access": "proxy",
    "isDefault": true
  }'

# Import dashboard
echo "Importing dashboard..."
curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "admin:${GRAFANA_PASSWORD}" \
  "${GRAFANA_URL}/api/dashboards/db" \
  -d @- << EOF
{
  "dashboard": $(cat monitoring/ocr-dashboard.json),
  "overwrite": true
}
EOF

echo "Dashboard imported successfully"