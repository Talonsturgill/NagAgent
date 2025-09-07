# Use official Python runtime as base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy backend files
COPY NagAgent-Backend-Python/requirements.txt ./requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend application
COPY NagAgent-Backend-Python/ ./

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Create .env file if it doesn't exist
RUN touch .env

# Set environment variable for port (Railway will override this)
ENV PORT=8000

# Expose port
EXPOSE $PORT

# Start the application with startup script
CMD python startup.py