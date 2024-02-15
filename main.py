from fastapi import FastAPI
import models
from routes import router
from database import engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(router)

