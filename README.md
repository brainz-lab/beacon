# Beacon - Uptime Monitoring

Beacon is an uptime monitoring service that watches your endpoints, APIs, and services from multiple global locations. Part of the Brainz Lab observability suite.

## Features

- **HTTP Monitoring**: Status codes, response time, body content checks
- **SSL Monitoring**: Certificate expiry, validity tracking
- **DNS Monitoring**: Resolution, propagation checking
- **TCP Monitoring**: Port connectivity verification
- **Ping Monitoring**: ICMP reachability tests
- **Multi-Region**: Check from NYC, London, Singapore, Sydney
- **Status Pages**: Public status pages with custom branding
- **Incidents**: Automatic incident creation and management
- **Maintenance Windows**: Scheduled maintenance with notifications

## Quick Start

```bash
# From brainzlab root
docker-compose --profile beacon up

# Access at http://localhost:4006
```

## Development

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Start server
bin/rails server

# Run tests
bin/rails test
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/monitors` | List all monitors |
| `POST /api/v1/monitors` | Create a monitor |
| `GET /api/v1/monitors/:id` | Get monitor details |
| `POST /api/v1/monitors/:id/pause` | Pause monitoring |
| `POST /api/v1/monitors/:id/resume` | Resume monitoring |
| `GET /api/v1/incidents` | List incidents |
| `GET /api/v1/status_pages` | List status pages |

## MCP Tools

| Tool | Description |
|------|-------------|
| `beacon_list_monitors` | List all monitors with status |
| `beacon_check_status` | Get detailed monitor status |
| `beacon_create_monitor` | Create new monitor |
| `beacon_get_uptime` | Get uptime statistics |
| `beacon_list_incidents` | List active/resolved incidents |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         BEACON (Rails 8)                         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Dashboard   │  │     API      │  │  MCP Server  │           │
│  │  (Hotwire)   │  │  (JSON API)  │  │   (Ruby)     │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                           │                  │                   │
│              ┌─────────────────────────────────────┐            │
│              │   PostgreSQL + TimescaleDB + Redis  │            │
│              └─────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
        ▲                                       │
        │ Check                                 │ Alert
┌───────┴───────┐                     ┌────────┴────────┐
│ Global Nodes  │                     │ Signal/Slack/   │
│ NYC/LON/SIN   │                     │ PagerDuty       │
└───────────────┘                     └─────────────────┘
```

## License

Proprietary - Brainz Lab
