from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from typing import List
from app import crud, models, schemas
from app.api import deps
from app.schemas.goal import GoalCreate, GoalUpdate

router = APIRouter()

@router.get("/", response_model=List[schemas.Goal])
def read_goals(db: Session = Depends(deps.get_db), current_user: models.User = Depends(deps.get_current_active_user)):
    return crud.goal.get_multi_by_user(db=db, user=current_user)

@router.post("/", response_model=schemas.Goal)
def create_goal(goal_in: GoalCreate, db: Session = Depends(deps.get_db), current_user: models.User = Depends(deps.get_current_active_user)):
    return crud.goal.create_with_user(db=db, obj_in=goal_in, user=current_user)

@router.put("/{id}", response_model=schemas.Goal)
def update_goal(id: int, goal_in: GoalUpdate, db: Session = Depends(deps.get_db), current_user: models.User = Depends(deps.get_current_active_user)):
    goal = crud.goal.get(db=db, id=id)
    if not goal or goal.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Goal not found")
    return crud.goal.update(db=db, db_obj=goal, obj_in=goal_in)

@router.delete("/{id}", response_model=schemas.Goal)
def delete_goal(id: int, db: Session = Depends(deps.get_db), current_user: models.User = Depends(deps.get_current_active_user)):
    goal = crud.goal.get(db=db, id=id)
    if not goal or goal.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Goal not found")
    return crud.goal.remove(db=db, id=id) 