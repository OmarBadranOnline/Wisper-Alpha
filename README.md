# Wisper-Alpha

Linux-first reconnaissance platform with a web monitor (FastAPI + React) and a terminal orchestrator (`wisper.sh`).

## Project layout

| Path | Purpose |
|---|---|
| `app/backend` | FastAPI API, models, services, backend tests |
| `app/frontend` | React + Vite monitoring UI |
| `automation/wisper.sh` | Terminal recon and report-generation flow |
| `reporting` | Reporting package artifacts |
| `docs` | Full planning and design documentation |
| `start.sh` | Interactive launcher (Recon mode / Web mode) |
| `setup-and-start.sh` | Install dependencies, then launch |
| `run-unit-tests.sh` | Backend + frontend + recon/report checks |

## Quick start (Linux)

```bash
chmod +x ./*.sh automation/wisper.sh
./setup-and-start.sh
```

Or launch directly after setup:

```bash
./start.sh
```

Launcher options:
1. **Recon Terminal Mode**: runs `automation/wisper.sh`
2. **Web Monitor Mode**: starts backend (`:8000`) and frontend (`:5173`)

## Testing

```bash
./run-unit-tests.sh
```

This runs:
1. Backend unit tests (`pytest`)
2. Frontend production build (`npm run build`)
3. Recon script syntax validation (`bash -n automation/wisper.sh`)
4. Reporting artifact structure validation

## Web endpoints

- Frontend: `http://localhost:5173`
- Backend health: `http://localhost:8000/api/v1/health`
- Backend docs: `http://localhost:8000/api/docs`

