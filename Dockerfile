FROM python:3.14-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

ENV PATH="/app/.venv/bin:$PATH" \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

COPY src/pyproject.toml src/uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

COPY src/main ./main

EXPOSE 8080
CMD ["uvicorn", "main.app:app", "--host", "0.0.0.0", "--port", "8080"]
