# 🔧 Troubleshooting Guide

## Issue: SonarQube Fails to Start

### Symptoms
- Health check times out after 60 seconds
- Container exits immediately
- HTTP status returns `000` or non-200

### Solutions

| Cause | Fix |
|-------|-----|
| **Insufficient memory** | GitHub runners have 7GB. The container is limited to 4GB. If using self-hosted runners, ensure at least 4GB available. |
| **Elasticsearch bootstrap checks fail** | Already handled by `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true`. If still failing, add `-e SONAR_ES_JAVA_OPTS="-Xms512m -Xmx512m"` to docker run command. |
| **Port 9000 already in use** | Ensure no other service binds to 9000. Check with: `lsof -i :9000` or `netstat -tulpn \| grep 9000` |
| **Docker not available** | Ensure your runner has Docker installed and permissions set. GitHub-hosted runners include Docker by default. |

### Debug Steps
```bash
# View container logs
docker logs sonarqube-ephemeral-<RUN_ID>

# Check container status
docker ps -a | grep sonarqube

# Inspect resource usage
docker stats sonarqube-ephemeral-<RUN_ID>
```

---

## Issue: Password Change Fails (HTTP 400/401/500)

### Symptoms
- Step 4 returns non-204 status
- Error: "Failed to change admin password"

### Solutions

| Cause | Fix |
|-------|-----|
| **Secret not set** | Go to GitHub → Settings → Secrets → Add `SONAR_ADMIN_PASSWORD` |
| **Password too weak** | Use min 8 characters with mixed case, numbers, and symbols |
| **Password already changed** | If pipeline reruns on same container, password may already be changed. Each run creates a fresh container, so this shouldn't happen. |
| **SonarQube not fully ready** | Increase `MAX_RETRIES` in health check from 30 to 45 |

---

## Issue: Token Generation Fails

### Symptoms
- Step 5 returns empty token
- Error: "Failed to generate scanner token"

### Solutions

| Cause | Fix |
|-------|-----|
| **Wrong credentials** | Ensure `SONAR_ADMIN_PASSWORD` secret matches the password set in Step 4 |
| **Token name collision** | Token includes `${{ github.run_id }}` to ensure uniqueness. This should not happen. |
| **API endpoint changed** | SonarQube 10.x uses `/api/user_tokens/generate`. Verify your version matches. |

---

## Issue: SonarScanner Fails

### Symptoms
- Step 6 exits with error
- No analysis results appear

### Solutions

| Cause | Fix |
|-------|-----|
| **Network isolation** | Scanner runs in Docker container with `--network host`. Ensure localhost:9000 is accessible from host network. |
| **No source files found** | Check `sonar.inclusions` in workflow. Ensure your repo contains matching file extensions. |
| **Permission denied** | Scanner needs read access to workspace. GitHub Actions checkout provides this by default. |
| **Outdated scanner image** | The workflow uses `sonarsource/sonar-scanner-cli` (latest). Pin to a specific tag if needed: `sonarsource/sonar-scanner-cli:5.0` |

### Debug Mode
Add `-Dsonar.verbose=true` (already enabled) to see detailed scanner output.

---

## Issue: Quality Gate Check Times Out

### Symptoms
- Step 7/8 retries 30 times then fails
- Task status stuck in "PENDING" or "IN_PROGRESS"

### Solutions

| Cause | Fix |
|-------|-----|
| **Large codebase** | Increase `MAX_RETRIES` from 30 to 60 (adds 2.5 more minutes) |
| **SonarQube overloaded** | Resource limits (4GB/2CPU) may be too low for very large repos. Increase to 6GB if runner allows. |
| **Background CE task delayed** | SonarQube processes analysis asynchronously. Wait longer before checking. |

### Manual Quality Gate Check
```bash
curl -s -u admin:YOUR_PASSWORD \
  "http://localhost:9000/api/qualitygates/project_status?projectKey=YOUR_PROJECT_KEY" | jq .
```

---

## Issue: Container Cleanup Fails

### Symptoms
- Step 9 shows errors
- Dangling containers remain after pipeline

### Solutions

| Cause | Fix |
|-------|-----|
| **Container already stopped** | Handled by `2>/dev/null \|\| echo "Container already stopped"` |
| **Docker daemon issues** | Restart Docker on self-hosted runners. GitHub-hosted runners are ephemeral. |
| **Volume prune permission** | Runs with `|| true` to prevent pipeline failure on cleanup |

### Manual Cleanup
```bash
# Force remove container
docker rm -f sonarqube-ephemeral-<RUN_ID>

# Remove all stopped containers
docker container prune -f

# Remove dangling volumes
docker volume prune -f
```

---

## Common Error Codes

| HTTP Code | Meaning | Action |
|-----------|---------|--------|
| `000` | Connection refused | SonarQube not started yet. Wait longer. |
| `204` | Success (no content) | Expected for password change. |
| `401` | Unauthorized | Wrong credentials. Check secret. |
| `403` | Forbidden | Insufficient permissions. Use admin account. |
| `404` | Not found | Wrong API endpoint. Check SonarQube version. |
| `500` | Internal server error | SonarQube error. Check container logs. |

---

## Performance Optimization Tips

1. **Cache SonarQube image**: Use `docker pull` in a separate job to cache the image across runs
2. **Parallel analysis**: For monorepos, split by language using separate jobs
3. **Incremental analysis**: Use `sonar.branch.name` to analyze only changed files
4. **Reduce exclusions**: Be specific in `sonar.exclusions` to speed up scanning

---

## Pipeline Customization

### Add More Languages
Edit `sonar.inclusions` in Step 6:
```yaml
-Dsonar.inclusions="**/*.java,**/*.go,**/*.rb,..."
```

### Change SonarQube Version
Edit `SONARQUBE_IMAGE` in workflow:
```yaml
SONARQUBE_IMAGE: "sonarqube:latest"
```

### Adjust Timeout Limits
Edit `MAX_RETRIES` and `RETRY_INTERVAL` in relevant steps.

### Add Notifications
Add a step after Quality Gate check:
```yaml
- name: Notify on Failure
  if: failure()
  uses: slackapi/slack-github-action@v1.24.0
  with:
    payload: |
      {
        "text": "SonarQube pipeline failed for ${{ github.repository }}"
      }
```
