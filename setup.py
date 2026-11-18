from setuptools import setup, find_packages

setup(
    name="nagagent-backend",
    version="1.0.0",
    description="NagAgent Backend API - AI Accountability Coach",
    author="Talon Sturgill",
    packages=find_packages(where="NagAgent-Backend-Python"),
    package_dir={"": "NagAgent-Backend-Python"},
    python_requires=">=3.11",
    install_requires=[
        "fastapi==0.104.1",
        "uvicorn[standard]==0.24.0",
        "sqlalchemy==2.0.23",
        "psycopg2-binary==2.9.9",
        "openai==1.3.7",
        "python-dotenv==1.2.2",
    ],
)