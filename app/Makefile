.PHONY: backend frontend install test docker-up docker-down

# ── Local dev ──────────────────────────────────────────────────────────────────

backend:
	cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

frontend:
	cd frontend && npm run dev

install:
	cd backend && pip install -r requirements.txt
	cd frontend && npm install

test:
	cd backend && pytest --cov=app tests/ -v

# ── Docker ─────────────────────────────────────────────────────────────────────

docker-up:
	docker compose up --build -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

# ── Shortcuts ──────────────────────────────────────────────────────────────────

dev: install
	@echo "Run 'make backend' and 'make frontend' in separate terminals."
