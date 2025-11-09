# PySpark ETL Job Dockerfile
FROM eclipse-temurin:11-jre-jammy

# Install Python 3.11
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Download PostgreSQL JDBC driver
RUN mkdir -p /opt/spark/jars && \
    curl -L https://jdbc.postgresql.org/download/postgresql-42.6.0.jar \
    -o /opt/spark/jars/postgresql-42.6.0.jar

# Copy application code
COPY etl_job.py .
COPY etl_entrypoint.py .

# Create necessary directories
RUN mkdir -p /data/logs /data/processed /data/tmp

# Set Python to use UTF-8 encoding
ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

# Run the entrypoint script
CMD ["python3", "etl_entrypoint.py"]

