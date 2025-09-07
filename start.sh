#!/bin/bash
# Start script for Railway
cd NagAgent-Backend-Python
python -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}