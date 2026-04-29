#!/bin/bash
set -euo pipefail

# ============================================================================
# SonarQube All-in-One Analyzer
# Usage: docker run -v /path/to/code:/code -v /path/to/output:/output <image>
# ============================================================================

SONARQUBE_URL="http://localhost:9000"
SONAR_PROJECT_KEY="analysis-$(date +%s)"
CODE_PATH="/code"
OUTPUT_PATH="/output"
SONARQUBE_HOME="/opt/sonarqube"

echo "╔══════════════════════════════════════╗"
echo "║   SonarQube All-in-One Analyzer      ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Validate mounted code ────────────────────────────────────────────────────
if [ ! -d "$CODE_PATH" ] || [ -z "$(ls -A "$CODE_PATH" 2>/dev/null)" ]; then
    echo "❌ No code found at /code"
    echo ""
    echo "Mount your source code with:"
    echo "  docker run -v /absolute/path/to/code:/code <image>"
    exit 1
fi

mkdir -p "$OUTPUT_PATH"
echo "📂 Scanning: $CODE_PATH"
echo "📁 Output:   $OUTPUT_PATH"
echo "🔑 Project:  $SONAR_PROJECT_KEY"
echo ""

# ── STEP 1: Start SonarQube ──────────────────────────────────────────────────
echo "▶ Step 1/6 — Starting SonarQube server..."

# Required: disable Elasticsearch bootstrap checks (no sysctl inside container)
export SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
export ES_JAVA_OPTS="-Xms256m -Xmx512m"

# Start SonarQube in background, pipe logs to file for debugging
mkdir -p /tmp/sq-logs
$SONARQUBE_HOME/bin/linux-x86-64/sonar.sh console > /tmp/sq-logs/startup.log 2>&1 &
SQ_PID=$!

echo "  SonarQube PID: $SQ_PID (logs at /tmp/sq-logs/startup.log)"

# ── STEP 2: Wait for SonarQube to be ready ──────────────────────────────────
echo ""
echo "▶ Step 2/6 — Waiting for SonarQube to be ready..."

MAX_RETRIES=80   # 80 × 5s = ~7 minutes
RETRY_INTERVAL=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))

    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 3 \
        "$SONARQUBE_URL/api/system/status" 2>/dev/null || echo "000")

    if [ "$HTTP_STATUS" = "200" ]; then
        SQ_STATUS=$(curl -s "$SONARQUBE_URL/api/system/status" \
            | jq -r '.status // "UNKNOWN"' 2>/dev/null)

        if [ "$SQ_STATUS" = "UP" ]; then
            echo "  ✅ SonarQube UP after $((RETRY_COUNT * RETRY_INTERVAL))s"
            break
        fi
        echo "  [$((RETRY_COUNT * RETRY_INTERVAL))s] Status: $SQ_STATUS — waiting..."
    else
        if [ $((RETRY_COUNT % 6)) -eq 0 ]; then
            echo "  [$((RETRY_COUNT * RETRY_INTERVAL))s] Not ready yet (HTTP $HTTP_STATUS)..."
        fi
    fi

    # If the process died, show logs and abort
    if ! kill -0 $SQ_PID 2>/dev/null; then
        echo "❌ SonarQube process died unexpectedly"
        echo "--- startup log (last 50 lines) ---"
        tail -50 /tmp/sq-logs/startup.log 2>/dev/null || echo "(no log)"
        echo "--- sonar.log ---"
        tail -30 "$SONARQUBE_HOME/logs/sonar.log" 2>/dev/null || echo "(not found)"
        echo "--- es.log ---"
        tail -30 "$SONARQUBE_HOME/logs/es.log" 2>/dev/null || echo "(not found)"
        exit 1
    fi

    sleep $RETRY_INTERVAL
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ SonarQube failed to become ready after $((MAX_RETRIES * RETRY_INTERVAL))s"
    echo "--- startup log (last 80 lines) ---"
    tail -80 /tmp/sq-logs/startup.log 2>/dev/null || echo "(no log)"
    echo "--- web.log ---"
    tail -30 "$SONARQUBE_HOME/logs/web.log" 2>/dev/null || echo "(not found)"
    echo "--- es.log ---"
    tail -30 "$SONARQUBE_HOME/logs/es.log" 2>/dev/null || echo "(not found)"
    exit 1
fi

# ── STEP 3: Change admin password ────────────────────────────────────────────
echo ""
echo "▶ Step 3/6 — Setting up credentials..."

ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -u admin:admin \
    -X POST \
    "$SONARQUBE_URL/api/users/change_password?login=admin&previousPassword=admin&password=${ADMIN_PASSWORD}" \
    2>/dev/null)

if [ "$HTTP_STATUS" = "204" ]; then
    echo "  ✅ Admin credentials configured"
else
    echo "  ⚠️  Password change returned HTTP $HTTP_STATUS — using default"
    ADMIN_PASSWORD="admin"
fi

# ── STEP 4: Generate scanner token ───────────────────────────────────────────
echo ""
echo "▶ Step 4/6 — Generating scanner token..."

TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -u "admin:${ADMIN_PASSWORD}" \
    -X POST \
    "$SONARQUBE_URL/api/user_tokens/generate" \
    --data-urlencode "name=scanner-token-${SONAR_PROJECT_KEY}" \
    2>/dev/null)

HTTP_CODE=$(echo "$TOKEN_RESPONSE" | tail -1)
BODY=$(echo "$TOKEN_RESPONSE" | head -n -1)
SCANNER_TOKEN=$(echo "$BODY" | jq -r '.token // empty' 2>/dev/null)

if [ -z "$SCANNER_TOKEN" ] || [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Failed to generate scanner token (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
    exit 1
fi

echo "  ✅ Token generated"

# ── STEP 5: Run SonarScanner ─────────────────────────────────────────────────
echo ""
echo "▶ Step 5/6 — Running code analysis..."
echo "   This may take several minutes depending on project size..."
echo ""

/opt/sonar-scanner/bin/sonar-scanner \
    -Dsonar.projectKey="${SONAR_PROJECT_KEY}" \
    -Dsonar.projectName="Code Analysis" \
    -Dsonar.sources="${CODE_PATH}" \
    -Dsonar.host.url="${SONARQUBE_URL}" \
    -Dsonar.token="${SCANNER_TOKEN}" \
    -Dsonar.qualitygate.wait=true \
    -Dsonar.java.source=17 \
    -Dsonar.inclusions="**/*.java,**/*.js,**/*.ts,**/*.jsx,**/*.tsx,**/*.py,**/*.cs,**/*.html,**/*.css,**/*.json,**/*.xml,**/*.sql,**/*.sh,**/*.yml,**/*.yaml,**/*.md" \
    -Dsonar.exclusions="**/node_modules/**,**/vendor/**,**/.git/**,**/target/**,**/bin/**,**/obj/**,**/dist/**,**/build/**,**/*.min.js,**/*.min.css,**/__pycache__/**,**/*.pyc" \
    2>&1 | grep -v "^DEBUG" || true

echo ""
echo "  ✅ Analysis submitted"

# ── STEP 6: Wait for background task ────────────────────────────────────────
echo ""
echo "▶ Step 6/6 — Waiting for SonarQube to process results..."

MAX_RETRIES=60
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))

    TASK_RESPONSE=$(curl -s \
        -u "admin:${ADMIN_PASSWORD}" \
        "$SONARQUBE_URL/api/ce/component?component=${SONAR_PROJECT_KEY}" 2>/dev/null)

    TASK_STATUS=$(echo "$TASK_RESPONSE" | jq -r '.current.status // "PENDING"' 2>/dev/null)

    if [ "$TASK_STATUS" = "SUCCESS" ] || [ "$TASK_STATUS" = "FAILED" ] || [ "$TASK_STATUS" = "CANCELED" ]; then
        echo "  ✅ Processing complete: $TASK_STATUS"
        break
    fi

    if [ $((RETRY_COUNT % 4)) -eq 0 ]; then
        echo "  [$((RETRY_COUNT * 5))s] Task status: $TASK_STATUS..."
    fi
    sleep 5
done

# ── Fetch findings ───────────────────────────────────────────────────────────
echo ""
echo "📥 Fetching findings..."

AUTH="admin:${ADMIN_PASSWORD}"
PK="${SONAR_PROJECT_KEY}"

HOTSPOTS=$(curl -s -u "$AUTH" "$SONARQUBE_URL/api/hotspots/search?projectKey=${PK}&ps=500" 2>/dev/null)
VULNS=$(curl -s -u "$AUTH" "$SONARQUBE_URL/api/issues/search?componentKeys=${PK}&types=VULNERABILITY&ps=500" 2>/dev/null)
SMELLS=$(curl -s -u "$AUTH" "$SONARQUBE_URL/api/issues/search?componentKeys=${PK}&types=CODE_SMELL&ps=500" 2>/dev/null)
BUGS=$(curl -s -u "$AUTH" "$SONARQUBE_URL/api/issues/search?componentKeys=${PK}&types=BUG&ps=500" 2>/dev/null)

HOTSPOT_COUNT=$(echo "$HOTSPOTS" | jq -r '.paging.total // 0' 2>/dev/null || echo 0)
VULN_COUNT=$(echo "$VULNS"     | jq -r '.paging.total // 0' 2>/dev/null || echo 0)
SMELL_COUNT=$(echo "$SMELLS"   | jq -r '.paging.total // 0' 2>/dev/null || echo 0)
BUG_COUNT=$(echo "$BUGS"       | jq -r '.paging.total // 0' 2>/dev/null || echo 0)

# ── Generate report ──────────────────────────────────────────────────────────
REPORT_FILE="${OUTPUT_PATH}/security-report.json"

jq -n \
    --arg project   "$SONAR_PROJECT_KEY" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg sonar_url "$SONARQUBE_URL" \
    --argjson hotspot_count "$HOTSPOT_COUNT" \
    --argjson vuln_count    "$VULN_COUNT" \
    --argjson smell_count   "$SMELL_COUNT" \
    --argjson bug_count     "$BUG_COUNT" \
    --argjson hotspots      "$HOTSPOTS" \
    --argjson vulns         "$VULNS" \
    --argjson smells        "$SMELLS" \
    --argjson bugs          "$BUGS" \
    '{
      report_metadata: {
        project_key:   $project,
        generated_at:  $timestamp,
        sonarqube_url: $sonar_url
      },
      summary: {
        vulnerabilities:    $vuln_count,
        security_hotspots:  $hotspot_count,
        bugs:               $bug_count,
        code_smells:        $smell_count
      },
      vulnerabilities:   $vulns,
      security_hotspots: $hotspots,
      bugs:              $bugs,
      code_smells:       $smells
    }' > "$REPORT_FILE"

# ── Print summary ─────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║           Analysis Results           ║"
echo "╚══════════════════════════════════════╝"
echo ""
printf "  %-28s %s\n" "🔴 Vulnerabilities:"   "$VULN_COUNT"
printf "  %-28s %s\n" "🟡 Security hotspots:" "$HOTSPOT_COUNT"
printf "  %-28s %s\n" "🐛 Bugs:"              "$BUG_COUNT"
printf "  %-28s %s\n" "🧹 Code smells:"       "$SMELL_COUNT"
echo ""
echo "📄 Full report: $REPORT_FILE"
echo ""

# ── Stop SonarQube ────────────────────────────────────────────────────────────
$SONARQUBE_HOME/bin/linux-x86-64/sonar.sh stop > /dev/null 2>&1 || true

# ── Exit code ─────────────────────────────────────────────────────────────────
if [ "$VULN_COUNT" -gt 0 ] || [ "$HOTSPOT_COUNT" -gt 0 ]; then
    echo "❌ FAIL — Security issues detected. Review the report."
    exit 1
else
    echo "✅ PASS — No critical security issues found."
    if [ "$BUG_COUNT" -gt 0 ] || [ "$SMELL_COUNT" -gt 0 ]; then
        echo "   ⚠️  Non-critical issues found — check the report for details."
    fi
    exit 0
fi
