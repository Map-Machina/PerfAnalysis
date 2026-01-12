# PerfAnalysis API Contract Specification

**Version**: 1.0
**Last Updated**: 2026-01-11
**Base URL**: `https://portal.perfanalysis.com` (production) | `http://localhost:8000` (development)

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Collectors API](#2-collectors-api)
3. [Metrics API](#3-metrics-api)
4. [Containers API](#4-containers-api)
5. [Reports API](#5-reports-api)
6. [User Preferences API](#6-user-preferences-api)
7. [Error Handling](#7-error-handling)
8. [Rate Limiting](#8-rate-limiting)

---

## 1. Authentication

### 1.1 Obtain Token

**Endpoint**: `POST /api/v1/auth/token/`

**Description**: Authenticate user and obtain JWT tokens

**Request**:
```json
{
  "username": "string",
  "password": "string"
}
```

**Response** (200 OK):
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "first_name": "Admin",
    "last_name": "User"
  }
}
```

**Response** (401 Unauthorized):
```json
{
  "error": "INVALID_CREDENTIALS",
  "message": "Invalid username or password"
}
```

---

### 1.2 Refresh Token

**Endpoint**: `POST /api/v1/auth/token/refresh/`

**Description**: Refresh an expired access token

**Request**:
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response** (200 OK):
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

---

### 1.3 Get Current User

**Endpoint**: `GET /api/v1/auth/user/`

**Authorization**: Bearer Token required

**Response** (200 OK):
```json
{
  "id": 1,
  "username": "admin",
  "email": "admin@example.com",
  "first_name": "Admin",
  "last_name": "User"
}
```

---

### 1.4 Logout

**Endpoint**: `POST /api/v1/auth/logout/`

**Authorization**: Bearer Token required

**Response** (204 No Content)

---

## 2. Collectors API

### 2.1 List Collectors

**Endpoint**: `GET /dashboard/api/collectors/`

**Authorization**: Bearer Token required

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "name": "pcc-test-vm",
    "hostname": "pcc-test-vm.internal",
    "ip_address": "10.0.0.5",
    "status": "online",
    "last_seen": "2026-01-11T22:30:00Z",
    "os_info": "Ubuntu 22.04 LTS",
    "cpu_model": "Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz",
    "cpu_count": 4,
    "memory_total_gb": 16.0,
    "cloud_provider": "azure",
    "region": "eastus",
    "instance_type": "Standard_B4ms",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-11T22:30:00Z"
  },
  {
    "id": 2,
    "name": "perftest-vm-02",
    "hostname": "perftest-vm-02.oraclevcn.com",
    "ip_address": "137.131.22.223",
    "status": "online",
    "last_seen": "2026-01-11T22:28:00Z",
    "os_info": "Oracle Linux 8.9",
    "cpu_model": "AMD EPYC 7763 64-Core Processor",
    "cpu_count": 2,
    "memory_total_gb": 4.0,
    "cloud_provider": "oci",
    "region": "us-phoenix-1",
    "instance_type": "VM.Standard.E4.Flex",
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-11T22:28:00Z"
  }
]
```

---

### 2.2 Get Collector

**Endpoint**: `GET /dashboard/api/collectors/{id}/`

**Authorization**: Bearer Token required

**Response** (200 OK):
```json
{
  "id": 1,
  "name": "pcc-test-vm",
  "hostname": "pcc-test-vm.internal",
  "ip_address": "10.0.0.5",
  "status": "online",
  "last_seen": "2026-01-11T22:30:00Z",
  "os_info": "Ubuntu 22.04 LTS",
  "cpu_model": "Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz",
  "cpu_count": 4,
  "memory_total_gb": 16.0,
  "cloud_provider": "azure",
  "region": "eastus",
  "instance_type": "Standard_B4ms",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-11T22:30:00Z"
}
```

---

## 3. Metrics API

### 3.1 Get CPU Metrics

**Endpoint**: `GET /dashboard/api/collectors/{id}/cpu/`

**Authorization**: Bearer Token required

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `hours` | integer | 24 | Time range in hours (1, 6, 24, 168, 720) |

**Response** (200 OK):
```json
{
  "timestamps": [
    "2026-01-11T21:00:00Z",
    "2026-01-11T21:00:15Z",
    "2026-01-11T21:00:30Z"
  ],
  "user": [25.5, 26.1, 24.8],
  "system": [10.2, 10.5, 10.1],
  "idle": [64.3, 63.4, 65.1],
  "iowait": [0.0, 0.0, 0.0],
  "steal": [0.0, 0.0, 0.0],
  "irq": [0.0, 0.0, 0.0],
  "softirq": [0.0, 0.0, 0.0]
}
```

---

### 3.2 Get Memory Metrics

**Endpoint**: `GET /dashboard/api/collectors/{id}/memory/`

**Authorization**: Bearer Token required

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `hours` | integer | 24 | Time range in hours |

**Response** (200 OK):
```json
{
  "timestamps": [
    "2026-01-11T21:00:00Z",
    "2026-01-11T21:00:15Z",
    "2026-01-11T21:00:30Z"
  ],
  "used": [8192, 8250, 8195],
  "available": [8576, 8518, 8573],
  "cached": [4096, 4102, 4098],
  "buffers": [512, 515, 513],
  "percent_used": [50.0, 50.4, 50.1],
  "total_gb": 16.0
}
```

---

### 3.3 Get Disk Metrics

**Endpoint**: `GET /dashboard/api/collectors/{id}/disk/`

**Authorization**: Bearer Token required

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `hours` | integer | 24 | Time range in hours |

**Response** (200 OK):
```json
{
  "timestamps": [
    "2026-01-11T21:00:00Z",
    "2026-01-11T21:00:15Z",
    "2026-01-11T21:00:30Z"
  ],
  "devices": [
    {
      "name": "sda",
      "read_bytes": [1048576, 2097152, 1572864],
      "write_bytes": [524288, 786432, 655360],
      "read_ops": [100, 150, 125],
      "write_ops": [50, 75, 62],
      "utilization": [25.5, 30.2, 27.8]
    },
    {
      "name": "sdb",
      "read_bytes": [0, 0, 0],
      "write_bytes": [0, 0, 0],
      "read_ops": [0, 0, 0],
      "write_ops": [0, 0, 0],
      "utilization": [0, 0, 0]
    }
  ]
}
```

---

### 3.4 Get Network Metrics

**Endpoint**: `GET /dashboard/api/collectors/{id}/network/`

**Authorization**: Bearer Token required

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `hours` | integer | 24 | Time range in hours |

**Response** (200 OK):
```json
{
  "timestamps": [
    "2026-01-11T21:00:00Z",
    "2026-01-11T21:00:15Z",
    "2026-01-11T21:00:30Z"
  ],
  "interfaces": [
    {
      "name": "eth0",
      "rx_bytes": [1073741824, 1082130432, 1090519040],
      "tx_bytes": [536870912, 541065216, 545259520],
      "rx_packets": [100000, 100500, 101000],
      "tx_packets": [50000, 50250, 50500],
      "utilization": [15.5, 16.2, 15.8]
    }
  ]
}
```

---

### 3.5 Get Collector Statistics

**Endpoint**: `GET /dashboard/api/collectors/{id}/stats/`

**Authorization**: Bearer Token required

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `hours` | integer | 24 | Time range in hours |

**Response** (200 OK):
```json
{
  "cpu": {
    "user": {
      "min": 0.5,
      "max": 98.2,
      "avg": 25.5,
      "stddev": 15.2,
      "current": 26.1,
      "p50": 22.0,
      "p75": 35.0,
      "p90": 50.0,
      "p95": 65.0,
      "p97_5": 75.0,
      "p99": 85.0,
      "p100": 98.2
    },
    "system": {
      "min": 0.1,
      "max": 25.5,
      "avg": 10.2,
      "stddev": 5.1,
      "current": 10.5,
      "p50": 9.0,
      "p75": 12.0,
      "p90": 18.0,
      "p95": 20.0,
      "p97_5": 22.0,
      "p99": 24.0,
      "p100": 25.5
    },
    "iowait": {
      "min": 0.0,
      "max": 15.2,
      "avg": 0.5,
      "stddev": 1.2,
      "current": 0.0,
      "p50": 0.0,
      "p75": 0.5,
      "p90": 1.0,
      "p95": 2.0,
      "p97_5": 5.0,
      "p99": 10.0,
      "p100": 15.2
    }
  },
  "memory": {
    "percent_used": {
      "min": 45.0,
      "max": 75.0,
      "avg": 50.5,
      "stddev": 5.2,
      "current": 50.4,
      "p50": 50.0,
      "p75": 52.0,
      "p90": 58.0,
      "p95": 62.0,
      "p97_5": 68.0,
      "p99": 72.0,
      "p100": 75.0
    }
  },
  "disk": {
    "sda": {
      "read_ops": {
        "min": 0,
        "max": 5000,
        "avg": 150,
        "stddev": 200,
        "current": 125,
        "p50": 100,
        "p75": 200,
        "p90": 500,
        "p95": 1000,
        "p97_5": 2000,
        "p99": 3500,
        "p100": 5000
      },
      "write_ops": {
        "min": 0,
        "max": 2500,
        "avg": 75,
        "stddev": 100,
        "current": 62,
        "p50": 50,
        "p75": 100,
        "p90": 250,
        "p95": 500,
        "p97_5": 1000,
        "p99": 1750,
        "p100": 2500
      }
    }
  },
  "network": {
    "eth0": {
      "rx_bytes": {
        "min": 0,
        "max": 125000000,
        "avg": 10000000,
        "stddev": 15000000,
        "current": 8388608,
        "p50": 5000000,
        "p75": 15000000,
        "p90": 50000000,
        "p95": 75000000,
        "p97_5": 100000000,
        "p99": 115000000,
        "p100": 125000000
      },
      "tx_bytes": {
        "min": 0,
        "max": 62500000,
        "avg": 5000000,
        "stddev": 7500000,
        "current": 4194304,
        "p50": 2500000,
        "p75": 7500000,
        "p90": 25000000,
        "p95": 37500000,
        "p97_5": 50000000,
        "p99": 57500000,
        "p100": 62500000
      }
    }
  }
}
```

---

### 3.6 Compare Collectors

**Endpoint**: `GET /dashboard/api/compare/`

**Authorization**: Bearer Token required

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `collectors` | string | Yes | Comma-separated collector IDs (e.g., "1,2,3") |
| `hours` | integer | No | Time range in hours (default: 24) |

**Response** (200 OK):
```json
{
  "collectors": [
    {
      "id": 1,
      "name": "pcc-test-vm",
      "hostname": "pcc-test-vm.internal"
    },
    {
      "id": 2,
      "name": "perftest-vm-02",
      "hostname": "perftest-vm-02.oraclevcn.com"
    }
  ],
  "metrics": {
    "cpu": {
      "1": {
        "timestamps": ["2026-01-11T21:00:00Z"],
        "user": [25.5],
        "system": [10.2]
      },
      "2": {
        "timestamps": ["2026-01-11T21:00:00Z"],
        "user": [45.2],
        "system": [15.5]
      }
    }
  },
  "stats": {
    "1": {
      "cpu": { "user": { "avg": 25.5 } }
    },
    "2": {
      "cpu": { "user": { "avg": 45.2 } }
    }
  }
}
```

---

## 4. Containers API

### 4.1 List Containers

**Endpoint**: `GET /dashboard/api/collectors/{id}/containers/`

**Authorization**: Bearer Token required

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "container_id": "abc123def456",
    "name": "nginx-proxy",
    "image": "nginx:latest",
    "status": "running",
    "collector_id": 1,
    "cpu_percent": 5.2,
    "memory_percent": 12.5,
    "memory_usage_mb": 256,
    "network_rx_bytes": 1048576,
    "network_tx_bytes": 524288,
    "created_at": "2026-01-10T00:00:00Z",
    "updated_at": "2026-01-11T22:30:00Z"
  }
]
```

---

### 4.2 Get Container Metrics

**Endpoint**: `GET /dashboard/api/collectors/{collector_id}/containers/{container_id}/cpu/`

**Authorization**: Bearer Token required

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `hours` | integer | 24 | Time range in hours |

**Response** (200 OK):
```json
{
  "timestamps": [
    "2026-01-11T21:00:00Z",
    "2026-01-11T21:00:15Z"
  ],
  "cpu_percent": [5.2, 5.5],
  "memory_percent": [12.5, 12.8],
  "memory_usage_mb": [256, 262],
  "network_rx_bytes": [1048576, 1097152],
  "network_tx_bytes": [524288, 548864]
}
```

---

### 4.3 Get Container Aggregate

**Endpoint**: `GET /dashboard/api/collectors/{id}/containers/aggregate/`

**Authorization**: Bearer Token required

**Response** (200 OK):
```json
{
  "total_containers": 5,
  "running_containers": 4,
  "timestamps": [
    "2026-01-11T21:00:00Z",
    "2026-01-11T21:00:15Z"
  ],
  "total_cpu_percent": [25.5, 26.2],
  "total_memory_mb": [1280, 1310]
}
```

---

## 5. Reports API

### 5.1 List Reports

**Endpoint**: `GET /api/v1/reports/`

**Authorization**: Bearer Token required

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "name": "Performance Report - pcc-test-vm - 2026-01-11",
    "collector_id": 1,
    "collector_name": "pcc-test-vm",
    "status": "completed",
    "format": "html",
    "file_url": "/media/reports/report_1_20260111.html",
    "file_size_bytes": 1048576,
    "time_range_hours": 24,
    "created_at": "2026-01-11T20:00:00Z",
    "completed_at": "2026-01-11T20:05:00Z",
    "error_message": null
  }
]
```

---

### 5.2 Generate Report

**Endpoint**: `POST /api/v1/reports/generate/`

**Authorization**: Bearer Token required

**Request**:
```json
{
  "collector_id": 1,
  "format": "html",
  "time_range_hours": 24,
  "include_containers": true
}
```

**Response** (202 Accepted):
```json
{
  "id": 2,
  "name": "Performance Report - pcc-test-vm - 2026-01-11",
  "collector_id": 1,
  "status": "pending",
  "format": "html",
  "created_at": "2026-01-11T22:35:00Z"
}
```

---

### 5.3 Get Report Status

**Endpoint**: `GET /api/v1/reports/{id}/`

**Authorization**: Bearer Token required

**Response** (200 OK):
```json
{
  "id": 2,
  "name": "Performance Report - pcc-test-vm - 2026-01-11",
  "collector_id": 1,
  "collector_name": "pcc-test-vm",
  "status": "generating",
  "format": "html",
  "file_url": null,
  "file_size_bytes": null,
  "time_range_hours": 24,
  "created_at": "2026-01-11T22:35:00Z",
  "completed_at": null,
  "error_message": null
}
```

---

## 6. User Preferences API

### 6.1 Get Preferences

**Endpoint**: `GET /dashboard/preferences/`

**Authorization**: Bearer Token required

**Response** (200 OK):
```json
{
  "default_time_range": "24h",
  "default_collector_id": 1,
  "chart_theme": "light",
  "refresh_interval_seconds": 60,
  "show_containers": true,
  "visible_metrics": ["cpu", "memory", "disk", "network"]
}
```

---

### 6.2 Update Preferences

**Endpoint**: `POST /dashboard/preferences/`

**Authorization**: Bearer Token required

**Request**:
```json
{
  "default_time_range": "6h",
  "default_collector_id": 2,
  "chart_theme": "dark",
  "refresh_interval_seconds": 30
}
```

**Response** (200 OK):
```json
{
  "default_time_range": "6h",
  "default_collector_id": 2,
  "chart_theme": "dark",
  "refresh_interval_seconds": 30,
  "show_containers": true,
  "visible_metrics": ["cpu", "memory", "disk", "network"]
}
```

---

## 7. Error Handling

### Standard Error Response

All API errors return a consistent format:

```json
{
  "error": "ERROR_CODE",
  "message": "Human-readable error description",
  "details": {}
}
```

### Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | `BAD_REQUEST` | Invalid request parameters |
| 401 | `UNAUTHORIZED` | Missing or invalid authentication |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource conflict |
| 422 | `VALIDATION_ERROR` | Input validation failed |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Server error |

### Validation Error Example

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Validation failed",
  "details": {
    "collector_id": ["This field is required"],
    "format": ["Must be one of: html, pdf"]
  }
}
```

---

## 8. Rate Limiting

### Limits

| Endpoint Type | Limit | Window |
|---------------|-------|--------|
| Authentication | 5 requests | 1 minute |
| Read endpoints | 100 requests | 1 minute |
| Write endpoints | 20 requests | 1 minute |

### Rate Limit Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1704999600
```

### Rate Limit Exceeded Response

**HTTP 429 Too Many Requests**:
```json
{
  "error": "RATE_LIMITED",
  "message": "Rate limit exceeded. Please retry after 60 seconds.",
  "details": {
    "retry_after": 60
  }
}
```

---

## Appendix: Time Range Mapping

| Value | Hours | Description |
|-------|-------|-------------|
| `1h` | 1 | Last hour |
| `6h` | 6 | Last 6 hours |
| `24h` | 24 | Last 24 hours |
| `7d` | 168 | Last 7 days |
| `30d` | 720 | Last 30 days |
| `all` | null | All available data |

---

**Document Version**: 1.0
**Last Updated**: 2026-01-11
