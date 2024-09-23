from http.client import HTTPException

from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
import crud, models, schemas
import database as db
# from db import SessionLocal, engine, get_db

models.Base.metadata.create_all(bind=db.engine)

app = FastAPI()

@app.get("/users/{user_id}")
def read_user(user_id: int, db: Session = Depends(db.get_db)):
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@app.get("/users/")
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(db.get_db)):
    users = crud.get_users(db, skip=skip, limit=limit)
    return users