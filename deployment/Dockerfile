FROM python:alpine3.19

RUN pip install fastapi \
                sqlalchemy \
                python-dotenv \
                psycopg2-binary \
                "uvicorn[standard]"

COPY .. app
WORKDIR app
