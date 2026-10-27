FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Pull any available Debian security patches, then clean up
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

# Upgrade build tooling first, then force-fix the vulnerable packages.
# Constraints ensure they can't be downgraded by requirements.txt.
RUN pip install --upgrade pip "setuptools>=84.1.0" wheel \
    && pip install -r requirements.txt \
    && pip install --upgrade "urllib3>=2.8.0" "msgpack>=1.2.1" "setuptools>=84.1.0"

# Run as a non-root user to limit the impact of the unfixable OS CVEs
RUN useradd --create-home --uid 10001 appuser
COPY --chown=appuser:appuser app.py .
# Remove the next line if you don't need tests inside the production image
COPY --chown=appuser:appuser test_app.py .
USER appuser

CMD ["python", "app.py"]
