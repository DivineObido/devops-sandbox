# DevOps Sandbox Platform

A self-service platform for spinning up isolated temporary environments, deploying apps, simulating outages, monitoring health, and auto-destroying everything when the TTL expires. Think of it as a miniature internal Heroku with a chaos engineering toggle.

## Architecture


## Prerequisites

- Docker Desktop (must be running)
- Docker Compose v2
- Git


## Quick Start

```bash
git clone https://github.com/DivineObido/devops-sandbox/
cd devops-sandbox
docker compose up -d --build
```

Platform is ready. API docs at `http://localhost:8000/docs`


## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /envs | Create environment |
| GET | /envs | List active envs + TTL remaining |
| DELETE | /envs/{id} | Destroy environment |
| GET | /envs/{id}/logs | Last 100 lines of app.log |
| GET | /envs/{id}/health | Last 10 health check results |
| POST | /envs/{id}/outage | Trigger outage simulation |


## Outage Modes

| Mode | What it does |
|------|-------------|
| crash | Kills the container |
| pause | Freezes the container |
| network | Disconnects from nginx |
| recover | Restores whatever was broken |
| stress | Spikes CPU for 30s |

## Makefile Targets

```bash
make up                             # start platform
make down                           # stop everything
make create                         # create new env
make destroy ENV=env-abc123         # destroy specific env
make logs ENV=env-abc123            # tail env logs
make health                         # show all env statuses
make simulate ENV=env-abc123 MODE=pause
make clean                          # wipe all state and logs
```
