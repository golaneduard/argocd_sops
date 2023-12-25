from typing import Optional

from pydantic import BaseModel, Field


class PostBase(BaseModel):
    id: int
    content: str
    title: str

    class Config:
        orm_mode = True


class CreatePost(PostBase):
    class Config:
        orm_mode = True
