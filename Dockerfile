FROM python:3.12.12-slim-bookworm@sha256:593bd06efe90efa80dc4eee3948be7c0fde4134606dd40d8dd8dbcade98e669c AS runtime

ARG APP_VERSION=0.1.0
LABEL org.opencontainers.image.title="irexplorer" \
      org.opencontainers.image.version="${APP_VERSION}"
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    IREXPLORER_STUDY_DIR=/data IREXPLORER_STUDY_MODE=local \
    IREXPLORER_STUDY_ORIGIN=http://localhost:8000
WORKDIR /opt/irexplorer
COPY src/backend/requirements.lock /tmp/requirements.lock
RUN python -m pip install --no-cache-dir -r /tmp/requirements.lock \
    && useradd --uid 10001 --create-home app \
    && mkdir /data && chown app:app /data
COPY src ./src
COPY examples/curated ./examples/curated
COPY artefacts/curated ./artefacts/curated
COPY docs/curated-artefacts.sha256 ./docs/curated-artefacts.sha256
COPY Dockerfile docker-compose.yml .dockerignore ./
COPY scripts/build_release.py ./scripts/build_release.py
RUN python scripts/build_release.py "${APP_VERSION}"
USER app
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=2)"
CMD ["python", "-m", "uvicorn", "src.backend.api.app:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]

FROM runtime AS test
COPY tests ./tests
COPY Dockerfile.toolchain ./Dockerfile.toolchain
CMD ["python", "-m", "unittest", "discover", "-s", "tests", "-v"]

FROM runtime AS app
