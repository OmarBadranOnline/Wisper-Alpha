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

## Optional AI threat analysis in final report

`automation/wisper.sh` can generate an extra AI-assisted threat analysis file during **Step 8: Generate Report**.

1. The script first generates the normal report.
2. It then asks whether to generate an optional AI analysis.
3. If no API key is found in an env file, it guides you to create/import one (Gemini free tier link included), then continues.

Supported providers and env keys:

| Provider | API key env var | Default model |
|---|---|---|
| Gemini | `GEMINI_API_KEY` (or `GOOGLE_API_KEY`) | `gemini-1.5-flash` |
| OpenAI | `OPENAI_API_KEY` | `gpt-4o-mini` |
| Anthropic | `ANTHROPIC_API_KEY` | `claude-3-5-haiku-latest` |
| OpenRouter | `OPENROUTER_API_KEY` | `openai/gpt-4o-mini` |

Optional shared config:

- `LLM_PROVIDER` = `gemini` / `openai` / `anthropic` / `openrouter`
- `LLM_MODEL` = provider model name override

Example `.env`:

```env
LLM_PROVIDER=gemini
LLM_MODEL=gemini-1.5-flash
GEMINI_API_KEY=your_key_here
```

## WSL troubleshooting (Windows-mounted repo)

If you run from `/mnt/<drive>/...`, you may hit:
- `env: 'bash\r': No such file or directory` (CRLF shell files)
- `Input/output error` while removing `app/backend/.venv` (Windows file locks)

Shell scripts are now normalized to LF through `.gitattributes` (`*.sh text eol=lf`).
If you cloned before that fix, re-clone or run `git add --renormalize .` from the repo root to refresh line endings.

If you still need to clear a locked backend venv on Windows, remove `app/backend/.venv` from PowerShell and rerun setup.

Recommended for best stability: clone and run the project inside native Linux filesystem (e.g., `~/wisper-linux`) instead of `/mnt/d/...`.

Note: project scripts now isolate environments by shell platform (`.venv-linux` on Linux, `.venv-win` on Git Bash/Windows), so locked legacy `.venv` folders are ignored.

## Web endpoints

- Frontend: `http://localhost:5173`
- Backend health: `http://localhost:8000/api/v1/health`
- Backend docs: `http://localhost:8000/api/docs`
