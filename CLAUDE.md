# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Beacon by Brainz Lab

Uptime monitoring service that watches your endpoints, APIs, and services from multiple global locations.

**Domain**: beacon.brainzlab.ai

**Tagline**: "Always watching"

**Status**: Not yet implemented - see beacon-claude-code-prompt.md for full specification

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         BEACON (Rails 8)                         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Dashboard   │  │     API      │  │  MCP Server  │           │
│  │  (Hotwire)   │  │  (JSON API)  │  │   (Ruby)     │           │
│  │ /dashboard/* │  │  /api/v1/*   │  │   /mcp/*     │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                           │                  │                   │
│                           ▼                  ▼                   │
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

## Tech Stack

- **Backend**: Rails 8 API + Dashboard
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Database**: PostgreSQL with TimescaleDB
- **Cache**: Redis (status cache, rate limiting)
- **Background Jobs**: Solid Queue
- **Real-time**: ActionCable (live status updates)
- **Regions**: Multi-region checkers (Fly.io/Railway)

## Key Models

- **UptimeMonitor**: Endpoint to check (HTTP, SSL, DNS, TCP) - renamed from `Monitor` to avoid conflict with Ruby's built-in Monitor class
- **CheckResult**: Individual check result with timing
- **Incident**: Downtime event with timeline
- **IncidentUpdate**: Status updates during incident
- **StatusPage**: Public status page configuration
- **StatusPageMonitor**: Monitors displayed on status page
- **MaintenanceWindow**: Scheduled maintenance periods
- **AlertRule**: Alert conditions for monitors
- **SslCertificate**: SSL certificate tracking

## Check Types

- **HTTP**: Status code, response time, body content
- **SSL**: Certificate expiry, validity
- **DNS**: Resolution, propagation
- **TCP**: Port connectivity

## MCP Tools

| Tool | Description |
|------|-------------|
| `beacon_status` | Get current status of all monitors |
| `beacon_incidents` | List active incidents |
| `beacon_history` | Get uptime history for a monitor |

## API Endpoints

- `GET /api/v1/monitors` - List monitors
- `POST /api/v1/monitors` - Create monitor
- `GET /api/v1/monitors/:id/checks` - Get check history
- `GET /api/v1/incidents` - List incidents
- `GET /api/v1/status-pages` - List public status pages

Authentication: `Authorization: Bearer <key>` or `X-API-Key: <key>`
