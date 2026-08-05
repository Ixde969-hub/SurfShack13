FROM python:3.13-slim

WORKDIR /app
COPY broker.py /app/broker.py

ENV HOST=0.0.0.0 \
    PORT=8080 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 8080
USER 65534:65534
CMD ["python", "/app/broker.py"]
