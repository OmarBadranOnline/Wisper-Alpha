# Wisper-Alpha

Linux-first reconnaissance platform with a web monitor (FastAPI + React) and a terminal orchestrator (`wisper.sh`).

## Project layout

| Path | Purpose |
|---|---|
| `app/backend` | FastAPI API, models, services, backend tests |
| `app/frontend` | React + Vite monitoring UI |
| `automation/wisper.sh` | Terminal recon and report-generation flow |
| `start.sh` | Interactive launcher (Recon mode / Web mode) |
| `setup-and-start.sh` | Install dependencies, then launch |
| `run-unit-tests.sh` | Backend + frontend + recon checks |

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

## WSL troubleshooting (Windows-mounted repo)

If you run from `/mnt/<drive>/...`, you may hit:
- `env: 'bash\r': No such file or directory` (CRLF shell files)
- `Input/output error` while removing `app/backend/.venv` (Windows file locks)

Use:

```bash
powershell.exe -NoProfile -Command "Remove-Item -Recurse -Force 'D:\Study Books\ITNS 410 Pentesting\Project\app\backend\.venv'"
sed -i 's/\r$//' install-dependencies.sh setup-and-start.sh start.sh run-unit-tests.sh automation/wisper.sh
chmod +x ./*.sh automation/wisper.sh
bash ./install-dependencies.sh
```

Recommended for best stability: clone and run the project inside native Linux filesystem (e.g., `~/wisper-linux`) instead of `/mnt/d/...`.

Note: project scripts now isolate environments by shell platform (`.venv-linux` on Linux, `.venv-win` on Git Bash/Windows), so locked legacy `.venv` folders are ignored.

## Web endpoints

- Frontend: `http://localhost:5173`
- Backend health: `http://localhost:8000/api/v1/health`
- Backend docs: `http://localhost:8000/api/docs`

