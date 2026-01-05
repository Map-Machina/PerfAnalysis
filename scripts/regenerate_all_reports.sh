#!/bin/bash
#
# Regenerate all analysis reports using automated-Reporting R code
#
# This script runs on the host machine and generates PDF reports using
# the R markdown system in automated-Reporting for all analyses in the database.
#

set -e

echo "================================================================"
echo "Regenerate Analysis Reports - Using automated-Reporting"
echo "================================================================"
echo ""

# Get list of all analyses from database
echo "Fetching analyses from database..."
ANALYSES=$(docker-compose exec -T xatbackend python manage.py shell -c "
from analysis.models import CaptureAnalysis
import json
analyses = CaptureAnalysis.objects.all()
result = []
for a in analyses:
    result.append({
        'id': a.pk,
        'owner': a.owner.username,
        'collector': a.collected.collector.machinename,
        'csv_file': a.collected.file.path,
        'description': a.collected.description
    })
print(json.dumps(result))
" 2>/dev/null | grep '^\[')

if [ -z "$ANALYSES" ] || [ "$ANALYSES" = "[]" ]; then
    echo "No analyses found in database"
    exit 0
fi

echo "Found $(echo "$ANALYSES" | jq '. | length') analyses"
echo ""

# Process each analysis
echo "$ANALYSES" | jq -c '.[]' | while read -r analysis; do
    ANALYSIS_ID=$(echo "$analysis" | jq -r '.id')
    OWNER=$(echo "$analysis" | jq -r '.owner')
    COLLECTOR=$(echo "$analysis" | jq -r '.collector')
    CSV_FILE=$(echo "$analysis" | jq -r '.csv_file')
    DESCRIPTION=$(echo "$analysis" | jq -r '.description')

    echo "----------------------------------------------------------------"
    echo "Processing Analysis ID: $ANALYSIS_ID"
    echo "  Owner: $OWNER"
    echo "  Collector: $COLLECTOR"
    echo "  Description: $DESCRIPTION"
    echo "----------------------------------------------------------------"

    # CSV file is inside the container, copy it to host
    TEMP_DIR=$(mktemp -d)
    echo "  Working directory: $TEMP_DIR"

    HOST_CSV="$TEMP_DIR/data.csv"
    echo "  Copying CSV from container..."
    if docker cp "perfanalysis-xatbackend:$CSV_FILE" "$HOST_CSV" 2>/dev/null; then
        echo "  ✓ CSV copied to host"
    else
        echo "  ✗ Failed to copy CSV file from container: $CSV_FILE"
        echo "  Skipping..."
        rm -rf "$TEMP_DIR"
        echo ""
        continue
    fi

    # Run the report generation script
    echo "  Generating report..."
    if python3 scripts/generate_analysis_report.py "$HOST_CSV" "$TEMP_DIR"; then
        REPORT_PDF="$TEMP_DIR/report.pdf"

        if [ -f "$REPORT_PDF" ]; then
            echo "  ✓ Report generated successfully"

            # Copy PDF into container and save to database
            REPORT_FILENAME="analysis_report_${ANALYSIS_ID}_$(date +%Y%m%d).pdf"

            # Copy PDF to a temp location in container
            docker cp "$REPORT_PDF" perfanalysis-xatbackend:/tmp/report_upload.pdf

            # Save to database using Django shell
            docker-compose exec -T xatbackend python manage.py shell -c "
from analysis.models import CaptureAnalysis
from django.core.files.base import ContentFile

analysis = CaptureAnalysis.objects.get(pk=$ANALYSIS_ID)

with open('/tmp/report_upload.pdf', 'rb') as f:
    pdf_content = f.read()

analysis.report.save('$REPORT_FILENAME', ContentFile(pdf_content), save=True)

import os
os.remove('/tmp/report_upload.pdf')

print(f'✓ Saved report to: {analysis.report.name}')
"

            PDF_SIZE=$(du -h "$REPORT_PDF" | cut -f1)
            echo "  ✓ Report saved to database: $REPORT_FILENAME ($PDF_SIZE)"
        else
            echo "  ✗ PDF not generated"
        fi
    else
        echo "  ✗ Report generation failed"
    fi

    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    echo ""
done

echo "================================================================"
echo "Report regeneration complete!"
echo "================================================================"
