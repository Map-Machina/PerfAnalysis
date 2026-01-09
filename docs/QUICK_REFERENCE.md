# Quick Reference Card

## Target System Commands

```bash
# Run 10-minute collection at 1-second intervals
PCC_DURATION=10m PCC_FREQUENCY=1s PCC_COLLECTION=~/test.json ./pcc

# Run 1-hour collection at 15-second intervals
PCC_DURATION=1h PCC_FREQUENCY=15s PCC_COLLECTION=~/hourly.json ./pcc

# Trickle mode (stream to server)
PCC_MODE=trickle PCC_DURATION=10m PCC_FREQUENCY=1s \
PCC_SERVER=192.168.1.100:8080 PCC_APIKEY=mykey ./pcc
```

## Local Machine Commands

```bash
# Copy collection from target
scp user@target:~/test.json ~/projects/PerfAnalysis/results/

# Process JSON to CSV
PCR_COLLECTION=~/results/test.json PCR_OUTDIR=~/results/csv ./bin/pcprocess

# Docker services
docker compose up -d          # Start
docker compose down           # Stop
docker compose restart xatbackend  # Restart after code changes
docker compose ps             # Check status
docker compose logs -f xatbackend  # Watch logs

# Database queries
docker compose exec postgres psql -U perfadmin -d perfanalysis -c "SELECT * FROM collectors_collector;"
```

## Dashboard URLs

| Page | URL |
|------|-----|
| Home | http://localhost:8000/ |
| Dashboard | http://localhost:8000/dashboard/ |
| Collector Detail | http://localhost:8000/dashboard/collector/{id}/ |
| Compare | http://localhost:8000/dashboard/compare/ |

## Time Range Behavior

The dashboard uses **relative time ranges** based on the collection's data:

- `ALL` - Shows entire collection (oldest → newest)
- `1H` - Last hour of the collection
- `6H` - Last 6 hours of the collection
- `24H` - Last 24 hours of the collection
- `7D` - Last 7 days of the collection

Historical collections remain viewable indefinitely.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No data in charts | Click "ALL" button |
| Changes not visible | `docker compose restart xatbackend` |
| API returns 302 | Log in via browser |
| pcc not found | `chmod +x ~/pcc` |
