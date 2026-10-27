# ---------- Build stage ----------
FROM python:3.13-alpine AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /build
COPY requirements.txt .

# Fixed minimums go in the same resolver run, so a conflicting pin fails the build
RUN pip install --upgrade pip \
    && pip install -r requirements.txt "urllib3>=2.8.0" "msgpack>=1.2.1" \
    && pip uninstall -y pip setuptools wheel

# ---------- Runtime stage ----------
FROM python:3.13-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Patch Alpine packages, then remove pip/setuptools/wheel (and pip's vendored libs) from the base image
RUN apk upgrade --no-cache \
    && python -m pip uninstall -y pip setuptools wheel || true

COPY --from=builder /opt/venv /opt/venv

RUN adduser -D -u 10001 appuser
WORKDIR /app
COPY --chown=appuser:appuser app.py .
USER appuser

CMD ["python", "app.py"]
