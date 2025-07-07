from sqlmodel import SQLModel
from app.models.category import CategoryType


# Shared properties
class CategoryBase(SQLModel):
    name: str
    type: CategoryType


# Properties to receive on item creation
class CategoryCreate(CategoryBase):
    pass


# Properties to receive on item update
class CategoryUpdate(CategoryBase):
    pass


# Properties to return to client
class Category(CategoryBase):
    id: int

    class Config:
        from_attributes = True
