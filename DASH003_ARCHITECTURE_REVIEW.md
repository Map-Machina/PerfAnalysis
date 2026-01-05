# Dash003 Architecture Review & Recommendations

**Date**: January 5, 2026
**Reviewer**: Claude Sonnet 4.5
**Purpose**: Evaluate whether Dash003 should be rebuilt as a web application and in what technology stack

---

## Executive Summary

**Current State**: Dash003 is a 8,938-line Shiny R application with hard-coded data sources and significant technical debt.

**Recommendation**: **YES**, rebuild as a modern web application integrated with XATbackend Django portal.

**Rationale**:
1. Hard-coded for exactly 5 hosts - not scalable
2. No database integration - reads static CSV files
3. Massive code duplication (5x for each host)
4. Authentication is basic and separate from main portal
5. Cannot leverage existing PerfAnalysis infrastructure

---

## Current Architecture Analysis

### Technology Stack
- **Framework**: Shiny (R web framework)
- **Visualization**: Plotly R
- **UI**: shinydashboard
- **Data**: Static CSV files (5 hosts, 44MB)
- **Authentication**: Sodium password hashing (in-memory credentials)

### Code Statistics
```
Total Lines:              8,938
CSV Reads:                5 (hard-coded file paths)
Plotly Visualizations:    250+
Reactive Expressions:     2 (very few - mostly procedural)
UI Outputs:               56 (renderPlotly, renderDataTable)
Menu Items:               ~30 (hard-coded for 5 hosts)
```

### Critical Issues

#### 1. **Hard-Coded Host Count**
```r
host0 <- read.csv("./host0_5sec.csv")
host1 <- read.csv("./host1_5sec.csv")
host2 <- read.csv("./host2_5sec.csv")
host3 <- read.csv("./host3_5sec.csv")
host4 <- read.csv("./host4_5sec.csv")
```

**Problem**: Cannot add/remove hosts without code changes. Not scalable.

#### 2. **Massive Code Duplication**
- Each of 5 hosts has nearly identical code blocks
- 8,938 lines / 5 hosts ≈ 1,788 lines per host
- Changes must be made 5 times (error-prone)

**Example**: One Hour Trending has 5 nearly identical sections (lines 150-194)

#### 3. **No Database Integration**
- All data loaded into memory from CSV files
- No connection to XATbackend database
- Cannot query by date range, collector, user, etc.
- 44MB of CSV loaded on every app restart

#### 4. **Separate Authentication**
```r
credentials = data.frame(
    username_id = c("demonstrator", "myuser"),
    passod   = sapply(c("batman", "mypass"),password_store),
    permission  = c("basic", "advanced"),
    stringsAsFactors = F
)
```

**Problem**:
- Not integrated with XATbackend Django authentication
- Users must maintain separate credentials
- No SSO, no role-based access control
- Password stored in code (security risk)

#### 5. **Static Menu Structure**
```r
menuItem("One Hour Trending", tabName="oneHourTrending", icon=icon("chart-area"),
    menuSubItem("Host 0", tabName="host0Trend", icon=icon("chart-area")),
    menuSubItem("Host 1", tabName="host1Trend", icon=icon("chart-area")),
    menuSubItem("Host 2", tabName="host2Trend", icon=icon("chart-area")),
    menuSubItem("Host 3", tabName="host3Trend", icon=icon("chart-area")),
    menuSubItem("Host 4", tabName="host4Trend", icon=icon("chart-area"))
)
```

**Problem**: Menu must be rewritten for each host count change

---

## Should This Be a Web Application?

### ✅ YES - Strong Arguments FOR Web Application

#### 1. **Multi-User Requirements**
- Already has authentication (proof of need)
- Fits PerfAnalysis multi-tenant model (XATbackend)
- Different users need different collector views

#### 2. **Database-Driven**
- XATbackend already stores CollectedData
- Real-time data from perfcollector2 via HTTP POST
- Historical analysis requires database queries

#### 3. **Integration Benefits**
- Unified authentication with XATbackend
- Reuse existing collector/analysis infrastructure
- Single portal for all PerfAnalysis features

#### 4. **Scalability**
- Web apps handle dynamic host counts naturally
- Can add collectors without code changes
- API-driven data loading

#### 5. **Modern UX Expectations**
- Interactive dashboards are expected for this use case
- Real-time updates via WebSockets
- Responsive design for mobile/tablet

---

## Should This Be in R or Another Language?

### Current R Strengths
✅ Plotly R integration is mature
✅ Team already has R expertise (automated-Reporting)
✅ Statistical analysis capabilities (quantile, distributions)
✅ Data manipulation with dplyr is concise

### R/Shiny Weaknesses for This Use Case
❌ **Not web-native** - Shiny is a web framework wrapper around R
❌ **Single-threaded** - Poor scalability for concurrent users
❌ **Memory intensive** - Loads all data into R session
❌ **Separate deployment** - Cannot integrate into Django easily
❌ **Limited database ORM** - Not like Django models
❌ **Authentication complexity** - Not designed for enterprise auth
❌ **Maintenance burden** - Two separate tech stacks (Django + R)

---

## Recommended Architecture

### Option 1: Django + Plotly.js (RECOMMENDED)

**Stack**:
- **Backend**: Django (already have XATbackend)
- **Visualization**: Plotly.js (JavaScript)
- **API**: Django REST Framework
- **Real-time**: Django Channels (WebSockets)

**Architecture**:
```
┌─────────────────────────────────────────────┐
│         XATbackend Django Portal            │
│  ┌─────────────────────────────────────┐   │
│  │   Existing Features                 │   │
│  │  - Authentication (allauth)         │   │
│  │  - Collectors Management            │   │
│  │  - Analysis (PDF reports)           │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │   NEW: Interactive Dashboard         │   │
│  │  - /dashboard/collectors/           │   │
│  │  - /dashboard/compare/              │   │
│  │  - /dashboard/realtime/             │   │
│  │                                     │   │
│  │  Components:                        │   │
│  │  - Django views (render templates)  │   │
│  │  - REST API (JSON data endpoints)   │   │
│  │  - Plotly.js (client-side viz)      │   │
│  │  - WebSockets (real-time updates)   │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │   PostgreSQL Database  │
        │  - CollectedData       │
        │  - Collectors          │
        │  - Users (tenants)     │
        └────────────────────────┘
```

**Benefits**:
- ✅ Single technology stack (Python)
- ✅ Unified authentication/authorization
- ✅ Database ORM for complex queries
- ✅ Dynamic collector selection
- ✅ Real-time data updates
- ✅ Mobile-responsive
- ✅ Easy deployment (same as XATbackend)

**Implementation**:
```python
# Django View
def dashboard_collector(request, collector_id):
    collector = Collector.objects.get(pk=collector_id, owner=request.user)
    return render(request, 'dashboard/collector.html', {'collector': collector})

# Django REST API
class CollectorDataAPI(APIView):
    def get(self, request, collector_id):
        # Query last hour of data
        one_hour_ago = timezone.now() - timedelta(hours=1)
        data = CollectedData.objects.filter(
            collector_id=collector_id,
            collected_date__gte=one_hour_ago
        ).values('timestamp', 'cpu_user', 'cpu_iowait', 'mem_used')

        return Response({
            'timestamps': [d['timestamp'] for d in data],
            'cpu_user': [d['cpu_user'] for d in data],
            'cpu_iowait': [d['cpu_iowait'] for d in data],
            'mem_used': [d['mem_used'] for d in data],
        })

# Frontend (Plotly.js)
fetch(`/api/collectors/${collectorId}/data/`)
    .then(r => r.json())
    .then(data => {
        var trace1 = {
            x: data.timestamps,
            y: data.cpu_user,
            name: 'CPU User %',
            type: 'scatter'
        };
        Plotly.newPlot('chart', [trace1]);
    });
```

---

### Option 2: Django + React + Recharts

**Stack**:
- **Backend**: Django REST API
- **Frontend**: React SPA
- **Visualization**: Recharts or Plotly React
- **State Management**: React Query

**Benefits**:
- More modern SPA architecture
- Better for complex interactions
- Excellent developer experience

**Drawbacks**:
- More complex build process
- Requires JavaScript expertise
- Heavier initial learning curve

---

### Option 3: Keep Shiny but Integrate (NOT RECOMMENDED)

**Approach**:
- Keep Shiny app separate
- Connect to PostgreSQL database
- Use iframe to embed in Django portal

**Why NOT Recommended**:
- ❌ Still two separate applications
- ❌ Still has all Shiny scalability issues
- ❌ Authentication integration is complex
- ❌ Two deployment processes
- ❌ Iframe has security/UX issues (as we saw with PDFs)

---

## Migration Strategy

### Phase 1: Foundation (2-3 weeks)
1. Create Django app: `dashboard`
2. Design REST API endpoints:
   - `/api/collectors/<id>/data/` (time series)
   - `/api/collectors/<id>/stats/` (percentiles)
   - `/api/collectors/compare/` (multi-collector)
3. Set up URL routing and templates
4. Create base dashboard layout (reuse XATbackend theme)

### Phase 2: Core Visualizations (3-4 weeks)
1. **One Hour Trending**
   - CPU, Memory, Disk, Network time series
   - Last 1 hour of 5-second data
   - Plotly.js line charts with hover tooltips

2. **Host Utilization Detail**
   - Full time series (not just 1 hour)
   - Multiple metrics on single chart
   - Zoomable/pannable

3. **Utilization Tables**
   - DataTables.js (same as used in XATbackend)
   - Percentile calculations (can use PostgreSQL or Python)
   - Export to CSV

### Phase 3: Advanced Features (2-3 weeks)
1. **Machine Comparisons**
   - Multi-collector selection
   - Side-by-side time series
   - Radar charts (Plotly.js supports this)

2. **Real-Time Updates**
   - Django Channels + WebSockets
   - Auto-refresh when new data arrives
   - Live streaming from perfcollector2

### Phase 4: Polish & Optimization (1-2 weeks)
1. Performance optimization (caching, query optimization)
2. Mobile responsive design
3. User preferences (save chart configurations)
4. Export visualizations to PNG/PDF

**Total Estimated Time**: 8-12 weeks

---

## Code Comparison

### Current Shiny R (Hard-coded)
```r
# Hard-coded for 5 hosts
host0 <- read.csv("./host0_5sec.csv")
host1 <- read.csv("./host1_5sec.csv")
# ... (repeated 5 times)

# Hard-coded menu
menuSubItem("Host 0", tabName="host0Trend"),
menuSubItem("Host 1", tabName="host1Trend"),
# ... (repeated 5 times)

# Hard-coded plots
output$host0_1hr_plot <- renderPlotly({ ... })
output$host1_1hr_plot <- renderPlotly({ ... })
# ... (repeated 5 times)
```

**Total**: ~8,938 lines for 5 hosts

### Proposed Django + Plotly.js (Dynamic)
```python
# Django View - works for ANY number of collectors
def collector_dashboard(request, collector_id):
    collector = get_object_or_404(Collector, pk=collector_id, owner=request.user)
    return render(request, 'dashboard/collector.html', {
        'collector': collector
    })

# API - dynamic data loading
class CollectorDataAPI(APIView):
    def get(self, request, collector_id):
        hours = int(request.GET.get('hours', 1))
        data = CollectedData.objects.filter(
            collector_id=collector_id,
            collected_date__gte=timezone.now() - timedelta(hours=hours)
        ).values('timestamp', 'cpu_user', 'cpu_iowait', 'mem_used')
        return Response(list(data))
```

```javascript
// Frontend - single template for all collectors
fetch(`/api/collectors/${collectorId}/data/?hours=1`)
    .then(r => r.json())
    .then(data => {
        const traces = [
            {x: data.map(d => d.timestamp), y: data.map(d => d.cpu_user), name: 'CPU User'},
            {x: data.map(d => d.timestamp), y: data.map(d => d.cpu_iowait), name: 'I/O Wait'},
        ];
        Plotly.newPlot('chart', traces);
    });
```

**Total**: ~500-800 lines for unlimited collectors

**Code Reduction**: ~90% less code, infinitely more scalable

---

## Database Schema Extensions

The XATbackend database already has what we need, but we should add:

```python
# In collectors/models.py (or dashboard/models.py)

class DashboardPreference(models.Model):
    """Store user dashboard preferences"""
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    collector = models.ForeignKey(Collector, on_delete=models.CASCADE)
    default_time_range = models.IntegerField(default=1)  # hours
    metrics_visible = models.JSONField(default=list)  # ['cpu_user', 'mem_used', ...]
    chart_type = models.CharField(max_length=20, default='line')  # line, area, bar
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class CollectorComparison(models.Model):
    """Saved multi-collector comparison configurations"""
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)  # "Production Servers"
    collectors = models.ManyToManyField(Collector)
    metrics = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)
```

---

## Technical Recommendations

### 1. **Use Django + Plotly.js** (Option 1)
- Lowest complexity
- Fastest to implement
- Leverages existing XATbackend
- Python-only backend
- Plotly.js is powerful and well-documented

### 2. **Query Optimization**
```python
# Use PostgreSQL window functions for percentiles
from django.db.models import F, Window
from django.db.models.functions import PercentileCont

CollectedData.objects.filter(
    collector_id=collector_id,
    timestamp__gte=start_time
).annotate(
    cpu_p50=Window(
        expression=PercentileCont(0.50, expression=F('cpu_user')),
        partition_by=[F('collector_id')]
    ),
    cpu_p95=Window(
        expression=PercentileCont(0.95, expression=F('cpu_user')),
        partition_by=[F('collector_id')]
    ),
)
```

### 3. **Caching Strategy**
```python
from django.core.cache import cache

def get_collector_stats(collector_id, hours=1):
    cache_key = f'collector_stats_{collector_id}_{hours}'
    stats = cache.get(cache_key)

    if stats is None:
        # Query database
        stats = calculate_stats(collector_id, hours)
        cache.set(cache_key, stats, timeout=300)  # 5 min cache

    return stats
```

### 4. **Real-Time Updates**
```python
# In consumers.py (Django Channels)
class CollectorDataConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.collector_id = self.scope['url_route']['kwargs']['collector_id']
        await self.channel_layer.group_add(
            f'collector_{self.collector_id}',
            self.channel_name
        )
        await self.accept()

    async def new_data(self, event):
        # Send new data point to client
        await self.send(text_data=json.dumps({
            'timestamp': event['timestamp'],
            'cpu_user': event['cpu_user'],
            'mem_used': event['mem_used'],
        }))
```

---

## Conclusion

### Should Dash003 be a web application?
**YES** - It already is one (Shiny), but it should be rebuilt as a modern, integrated web application.

### Should it be in R or another language?
**Python/Django + JavaScript/Plotly.js** - for these reasons:

1. **Integration**: Seamless with XATbackend (unified auth, database, deployment)
2. **Scalability**: Dynamic host count, efficient database queries, caching
3. **Maintainability**: ~90% less code, no duplication, single tech stack
4. **Features**: Real-time updates, advanced filtering, user preferences
5. **Security**: Leverages Django's mature authentication/authorization
6. **Cost**: Single deployment, single monitoring, single skill set

### R Still Has Value
Keep R for **automated-Reporting** (static PDF generation). The strengths of R:
- Statistical analysis
- Publication-quality static visualizations
- Batch processing
- ggplot2 for PDF reports

But for **interactive dashboards**, Django + Plotly.js is the superior choice.

---

## Next Steps

1. **Create proof-of-concept** (1 week)
   - Single collector dashboard
   - One hour trending chart
   - Verify Plotly.js matches Shiny R output

2. **User feedback** (1 week)
   - Show to Dan McDougal
   - Validate that Plotly.js can replicate all Shiny visualizations
   - Confirm database query performance

3. **Full implementation** (8-12 weeks)
   - Follow migration strategy above
   - Deprecate Dash003 Shiny app
   - Integrate into XATbackend portal

4. **Documentation** (1 week)
   - API documentation
   - User guide
   - Developer guide

---

**Generated by**: Claude Sonnet 4.5
**Date**: January 5, 2026
