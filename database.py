from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
from pathlib import Path

dotenv_path = Path('.env')
load_dotenv(dotenv_path=dotenv_path)

PGSQL_ADDRESS = os.getenv('POSTGRESQL_ADDRRESS')
PGSQL_DB = os.getenv('POSTGRESQL_DATABASE')
PGSQL_USER = os.getenv('POSTGRESQL_USER')
PGSQL_PASSWORD = os.getenv('POSTGRESQL_PASSWORD')
PGSQL_PORT = os.getenv('POSTGRESQL_PORT')

SQLALCHEMY_DATABASE_URL = f'postgresql://{PGSQL_USER}:{PGSQL_PASSWORD}@{PGSQL_ADDRESS}/{PGSQL_DB}'


engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()