# Quick Start Guide - Accessing the Portal

## 🌐 Access the Web Portal

Your PerfAnalysis portal is now ready to use!

### Portal URL
```
http://localhost:8000
```

### Login Credentials
```
Username: admin
Password: admin123
```

---

## 📋 Step-by-Step Access Instructions

### 1. Open Your Web Browser

Open any modern web browser (Chrome, Firefox, Safari, Edge)

### 2. Navigate to the Portal

Enter the URL in your address bar:
```
http://localhost:8000
```

### 3. Log In

You'll see a login page. Enter:
- **Username**: `admin`
- **Password**: `admin123`

### 4. Explore the Portal

Once logged in, you can:

#### View Dashboard
- See overview of all your collectors
- View recent data uploads
- Access quick statistics

#### Manage Collectors
Navigate to: **Collectors** → **Manage**
- View all registered collectors
- See collector status
- Upload performance data files

#### Setup New Collector
Navigate to: **Collectors** → **Setup**
- Register a new server/collector
- Get configuration instructions
- Download collector software

#### Upload Data
Navigate to: **Collectors** → **Upload**
- Upload the CSV file we generated: `/tmp/perfanalysis_test/performance_data_*.csv`
- Add a description
- View uploaded data

---

## 📁 Upload Test Data

We generated test data during the load test. Here's how to upload it:

### 1. Find the Test Data File

```bash
ls -lh /tmp/perfanalysis_test/
```

You should see files like:
- `performance_data_20260104_225624.csv`
- `performance_data_20260104_225624.json`

### 2. Upload via Portal

1. Log into http://localhost:8000
2. Navigate to **Collectors** → **Setup**
3. Create a collector (if you haven't already):
   - **Site Name**: "Test Site"
   - **Machine Name**: "test-server-01"
   - **Platform**: Select "Linux Server" (or create new)
4. Navigate to **Collectors** → **Manage**
5. Click on your collector
6. Click **Upload File**
7. Select the CSV file: `/tmp/perfanalysis_test/performance_data_*.csv`
8. Add description: "Load test data - heavy scenario"
9. Click **Upload**

### 3. View Your Data

After upload:
- You'll see the file listed under your collector
- View upload date, file size, description
- Download the file if needed
- View analysis (if available)

---

## 📊 Generate Reports (R Visualization)

### Option 1: Using R Console

```bash
# Enter R development container
docker-compose exec r-dev R

# In R console:
library(ggplot2)
library(data.table)

# Load your uploaded data
data <- fread("/path/to/uploaded/file.csv")

# Create CPU usage plot
ggplot(data, aes(x = timestamp, y = cpu_user)) +
  geom_line(color = "blue") +
  labs(title = "CPU Usage Over Time", x = "Time", y = "CPU %")
```

### Option 2: Export and Use R Studio

1. Download the CSV from the portal
2. Open in R Studio
3. Use the automated-Reporting scripts
4. Generate custom visualizations

---

## 🔍 Available Portal Features

### 1. Collectors Management
- **Path**: `/collectors/manage`
- **Features**: View all collectors, upload data, manage files

### 2. Collector Setup
- **Path**: `/collectors/setup/`
- **Features**: Register new servers, get installation instructions

### 3. Data Upload
- **Path**: `/collectors/manage/upload/<collector_id>/`
- **Features**: Upload CSV/JSON files, add descriptions

### 4. Admin Panel
- **Path**: `/admin/`
- **Features**: Advanced management (superuser only)
  - User management
  - Partner/tenant management
  - Database administration

### 5. Analysis Views
- **Path**: `/analysis/`
- **Features**: View performance analysis, trends, reports

---

## 🎨 Sample Visualizations You Can Create

With the uploaded data, you can create:

1. **CPU Utilization Trends**
   - Line charts over time
   - Peak usage identification
   - Average utilization

2. **Memory Usage Patterns**
   - Memory consumption over time
   - Available vs used memory
   - Swap usage

3. **Disk I/O Analysis**
   - Read/write throughput
   - I/O patterns
   - Performance bottlenecks

4. **Network Traffic**
   - RX/TX bytes over time
   - Packet statistics
   - Error rates

---

## 🛠️ Troubleshooting Portal Access

### Can't Access Portal?

**Check Services**:
```bash
docker-compose ps
```

**Restart XATbackend**:
```bash
docker-compose restart xatbackend
```

**View Logs**:
```bash
docker-compose logs xatbackend
```

### Login Not Working?

**Reset Admin Password**:
```bash
docker-compose exec xatbackend python manage.py shell <<'EOF'
from django.contrib.auth.models import User
user = User.objects.get(username='admin')
user.set_password('admin123')
user.save()
print("Password reset to: admin123")
EOF
```

### Page Not Found?

Make sure tenant is configured:
```bash
docker-compose exec xatbackend python manage.py shell <<'EOF'
from partners.models import Partner, Domain
print("Tenants:", Partner.objects.count())
print("Domains:", Domain.objects.count())
EOF
```

---

## 📱 API Access

You can also access data via API:

### Get API Token

1. Log into portal
2. Navigate to **Settings** → **API Tokens**
3. Generate new token

### Use API

```bash
# List collectors
curl -H "Authorization: Token YOUR_TOKEN_HERE" \
  http://localhost:8000/api/v1/collectors/

# Upload data
curl -X POST \
  -H "Authorization: Token YOUR_TOKEN_HERE" \
  -F "file=@/tmp/perfanalysis_test/performance_data_*.csv" \
  http://localhost:8000/api/v1/collectors/COLLECTOR_ID/upload/
```

---

## 📚 Next Steps

1. ✅ Access the portal at http://localhost:8000
2. ✅ Log in with admin/admin123
3. ✅ Create your first collector
4. ✅ Upload the test data we generated
5. ✅ Explore the visualizations
6. ✅ Set up real collectors on your servers

For detailed documentation, see:
- [USER_GUIDE.md](USER_GUIDE.md) - Complete user manual
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Production deployment
- [API Reference](USER_GUIDE.md#api-reference) - API documentation

---

## ✨ Demo Data Available

We've already generated test data for you:
- **Location**: `/tmp/perfanalysis_test/`
- **Scenario**: Heavy load (70% CPU)
- **Duration**: 60 seconds
- **Samples**: 12 data points
- **Quality**: 100% validated

Ready to upload and visualize!

---

**Need Help?** See [USER_GUIDE.md](USER_GUIDE.md) or check the FAQ section.
