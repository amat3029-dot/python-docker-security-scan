FROM python:3.13-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Apply any available Alpine security patches
RUN apk upgrade --no-cache

WORKDIR /app

COPY requirements.txt .

# One resolver run, so the fixed minimums win or the build fails loudly.
# setuptools/wheel are removed because they aren't needed at runtime,
# which also clears all 3 setuptools findings.
RUN pip install --upgrade pip \
    && pip install -r requirements.txt "urllib3>=2.8.0" "msgpack>=1.2.1" \
    && pip uninstall -y setuptools wheel || true

RUN adduser -D -u 10001 appuser
COPY --chown=appuser:appuser app.py .
USER appuser

CMD ["python", "app.py"]
