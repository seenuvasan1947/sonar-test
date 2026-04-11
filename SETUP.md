# 📋 Environment Variables & Setup Instructions

## ✅ NO Secrets Required!

This pipeline is **fully self-contained**. Since the SonarQube container is:
- 🔄 Fresh every run (no persistence)
- 🗑️ Destroyed after analysis
- 🔐 Password auto-generated randomly each run

**You don't need to configure anything!** Just push and the pipeline runs.

---

## Environment Variables (Defined in Workflow)

These are **automatically set** in the pipeline — no manual configuration needed:

| Variable | Default Value | Purpose |
|----------|---------------|---------|
| `SONARQUBE_IMAGE` | `sonarqube:10.4-community` | Docker image to use |
| `SONARQUBE_CONTAINER` | `sonarqube-ephemeral-${{ github.run_id }}` | Container name (unique per run) |
| `SONARQUBE_URL` | `http://localhost:9000` | SonarQube server URL |
| `SONAR_ADMIN_USER` | `admin` | Default admin username |
| `SONAR_ADMIN_PASSWORD_DEFAULT` | `admin` | Default admin password (changed in Step 4) |
| `SONAR_PROJECT_KEY` | `multi-lang-project-${{ github.run_id }}` | Unique project key per run |

---

## Supported Languages

The pipeline scans for:

- ☕ **Java** (`.java`)
- 🟨 **JavaScript/TypeScript** (`.js`, `.ts`, `.jsx`, `.tsx`)
- 🐍 **Python** (`.py`)
- 🔷 **C#** (`.cs`)
- 🌐 **Web** (`.html`, `.css`, `.json`, `.xml`)
- 📝 **Other** (`.sql`, `.sh`, `.yml`, `.yaml`, `.md`)

---

## Pipeline Execution Flow

```
┌─────────────────────────────────────────┐
│  1. Checkout Code                       │
├─────────────────────────────────────────┤
│  2. Start SonarQube Docker Container    │
│     (4GB RAM, 2 CPU limit)              │
├─────────────────────────────────────────┤
│  3. Health Check Polling                │
│     (max 60s, 2s intervals)             │
├─────────────────────────────────────────┤
│  4. Change Admin Password               │
│     (admin → secret value)              │
├─────────────────────────────────────────┤
│  5. Generate Scanner Token              │
│     (memory-only, via GITHUB_OUTPUT)    │
├─────────────────────────────────────────┤
│  6. Run SonarQube Scanner               │
│     (multi-language analysis)           │
├─────────────────────────────────────────┤
│  7. Wait for Analysis Processing        │
│     (max 5min, 5s intervals)            │
├─────────────────────────────────────────┤
│  8. Check Quality Gate                  │
│     ✅ PASS → Continue                  │
│     ❌ FAIL → Pipeline fails            │
├─────────────────────────────────────────┤
│  9. Cleanup Container (always runs)     │
│     (stop + rm + volume prune)          │
└─────────────────────────────────────────┘
```

---

## Resource Constraints

| Resource | Limit | Reason |
|----------|-------|--------|
| **Memory** | 4GB | Prevents OOM on constrained runners |
| **CPU** | 2.0 cores | Fair sharing with other jobs |
| **Timeout** | 60s startup | Adequate for SonarQube boot |
| **Concurrency** | 1 per branch | Avoids port/resource conflicts |
