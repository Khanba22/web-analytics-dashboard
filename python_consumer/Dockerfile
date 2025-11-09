# Python Kafka Consumer Dockerfile
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for confluent-kafka
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    librdkafka-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Create logs directory
RUN mkdir -p /data/logs

# Run consumer
CMD ["python", "app.py"]

