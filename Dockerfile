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

# Create .env file if it doesn't exist
RUN touch .env

# Set environment variable for port
ENV PORT=8000

# Expose port (Railway will override this)
EXPOSE $PORT

# Start the application with dynamic port
CMD uvicorn app.main:app --host 0.0.0.0 --port $PORT