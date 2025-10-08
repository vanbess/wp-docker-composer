---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## Bug Description
A clear and concise description of what the bug is.

## To Reproduce
Steps to reproduce the behavior:
1. Run command '...'
2. See error '...'
3. Expected '...' but got '...'

## Expected Behavior
A clear and concise description of what you expected to happen.

## Environment
- OS: [e.g., Ubuntu 20.04, macOS 12.0, Windows 11]
- Docker Version: [e.g., 20.10.12]
- Docker Compose Version: [e.g., 2.2.3]
- WordPress Version: [e.g., 6.8]
- PHP Version: [e.g., 8.3]

## Configuration
```bash
# Your .env file (remove sensitive data):
WORDPRESS_PORT=8000
PHPMYADMIN_PORT=8080
# etc...
```

## Logs
```bash
# Output of ./composer.sh doctor:
[paste output here]

# Docker logs (if relevant):
docker-compose logs [service-name]
```

## Additional Context
Add any other context about the problem here.

## Checklist
- [ ] I have read the documentation
- [ ] I have searched existing issues
- [ ] I have tried the troubleshooting steps
- [ ] I can reproduce this consistently