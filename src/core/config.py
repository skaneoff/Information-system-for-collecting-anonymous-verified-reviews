import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL is None:
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD")
    db_name = os.getenv("DB_NAME")
    db_host = os.getenv("DB_HOST", "db")
    db_port = os.getenv("DB_PORT", "5432")

    if not all([db_user, db_password, db_name]):
        raise RuntimeError(
            "PostgreSQL configuration is required. Set DATABASE_URL or DB_USER, DB_PASSWORD, DB_NAME."
        )

    DATABASE_URL = (
        f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    )

if not DATABASE_URL.startswith("postgresql"):
    raise RuntimeError("DATABASE_URL must use PostgreSQL: postgresql://...")
