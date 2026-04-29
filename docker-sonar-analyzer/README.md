# SonarQube All-in-One Docker Analyzer

**Single Docker image** with SonarQube + Scanner built-in. No external dependencies.

## 🚀 Quick Start

### Build
```bash
docker build -t sonar-analyzer .
```

### Run
```bash
docker run --rm -v /path/to/code:/code -v /path/to/output:/output sonar-analyzer
```

### Windows
```bash
docker run --rm -v C:\your\code:/code -v C:\your\output:/output sonar-analyzer
```

## 📦 What's Inside

- **Kali Linux** base
- **SonarQube 10.4** server (embedded)
- **SonarScanner** CLI
- All analysis happens in one container

## 📊 Output

Report saved to: `/output/security-report.json`

## 📋 Push to Docker Hub

```bash
docker tag sonar-analyzer yourusername/sonar-analyzer:latest
docker push yourusername/sonar-analyzer:latest
```
