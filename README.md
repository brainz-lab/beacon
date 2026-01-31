# Beacon

Uptime monitoring from multiple global locations.

[![CI](https://github.com/brainz-lab/beacon/actions/workflows/ci.yml/badge.svg)](https://github.com/brainz-lab/beacon/actions/workflows/ci.yml)
[![CodeQL](https://github.com/brainz-lab/beacon/actions/workflows/codeql.yml/badge.svg)](https://github.com/brainz-lab/beacon/actions/workflows/codeql.yml)
[![codecov](https://codecov.io/gh/brainz-lab/beacon/graph/badge.svg)](https://codecov.io/gh/brainz-lab/beacon)
[![License: OSAaSy](https://img.shields.io/badge/License-OSAaSy-blue.svg)](LICENSE)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-red.svg)](https://www.ruby-lang.org)

## Quick Start

```bash
# With Docker Compose (from brainzlab root)
docker-compose --profile beacon up

# Create a monitor
POST /api/v1/monitors { "url": "https://api.example.com", "interval": 60 }
```

## Installation

### With Docker

```bash
docker pull brainzllc/beacon:latest

docker run -d \
  -p 3000:3000 \
  -e DATABASE_URL=postgres://user:pass@host:5432/beacon \
  -e REDIS_URL=redis://host:6379/6 \
  -e RAILS_MASTER_KEY=your-master-key \
  brainzllc/beacon:latest
```

### Local Development

```bash
bin/setup
bin/rails server
```

## Configuration

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection | Yes |
| `REDIS_URL` | Redis for status cache | Yes |
| `RAILS_MASTER_KEY` | Rails credentials | Yes |
| `BRAINZLAB_PLATFORM_URL` | Platform URL for auth | Yes |

### Tech Stack

- **Ruby** 3.4.7 / **Rails** 8.1
- **PostgreSQL** 16 with TimescaleDB
- **Redis** 7 (status cache, rate limiting)
- **Hotwire** (Turbo + Stimulus) / **Tailwind CSS**
- **Solid Queue** / **ActionCable** (live status updates)
- **Multi-region checkers** (Fly.io/Railway)

## Usage

### Check Types

| Type | Description | Checks |
|------|-------------|--------|
| **HTTP** | Web endpoint monitoring | Status code, response time, body content |
| **SSL** | Certificate monitoring | Expiry date, validity chain |
| **DNS** | DNS health | Resolution, propagation |
| **TCP** | Port connectivity | Open ports, response time |

### Create a Monitor

```ruby
POST /api/v1/monitors
{
  "monitor": {
    "name": "Production API",
    "url": "https://api.example.com/health",
    "check_type": "http",
    "interval": 60,
    "timeout": 30,
    "regions": ["nyc", "lon", "sin"],
    "alert_threshold": 2
  }
}
```

### Status Page

Create public status pages for your users:
- Custom domain support
- Component grouping
- Incident timeline
- Maintenance windows

### Alerting

Get notified when services go down:
- Multi-region verification (avoid false positives)
- Configurable thresholds
- Integration with Signal for notifications

## API Reference

### Monitors
- `GET /api/v1/monitors` - List monitors
- `POST /api/v1/monitors` - Create monitor
- `GET /api/v1/monitors/:id/checks` - Get check history

### Incidents
- `GET /api/v1/incidents` - List incidents
- `POST /api/v1/incidents/:id/update` - Post incident update

### Status Pages
- `GET /api/v1/status-pages` - List public status pages
- `POST /api/v1/status-pages` - Create status page

### MCP Tools

| Tool | Description |
|------|-------------|
| `beacon_status` | Get current status of all monitors |
| `beacon_incidents` | List active incidents |
| `beacon_history` | Get uptime history for a monitor |

Full documentation: [docs.brainzlab.ai/products/beacon](https://docs.brainzlab.ai/products/beacon/overview)

## Self-Hosting

### Docker Compose

```yaml
services:
  beacon:
    image: brainzllc/beacon:latest
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/beacon
      REDIS_URL: redis://redis:6379/6
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}
      BRAINZLAB_PLATFORM_URL: http://platform:3000
    depends_on:
      - db
      - redis
```

### Testing

```bash
bin/rails test
bin/rubocop
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for development setup and contribution guidelines.

## License

This project is licensed under the [OSAaSy License](LICENSE).
