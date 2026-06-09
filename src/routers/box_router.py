from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from sqlalchemy.orm import Session

from src.core.logger import logger
from src.db.database import get_db
from src.middlewares.rate_limit import check_rate
from src.schemas.box import BoxCreateResponse
from src.services.box_service import create_box
from src.services.user_service import get_user_by_token

_db_dependency = Depends(get_db)

router = APIRouter()


@router.post("/box", response_model=BoxCreateResponse, status_code=status.HTTP_200_OK)
def create_box_endpoint(
    request: Request,
    authorization: str = Header(None, alias="Authorization"),
    db: Session = _db_dependency,
):
    logger.info("Box create request received from ip=%s", request.client.host)
    check_rate(request.client.host, "POST:/box")
    user_id = None
    if authorization:
        token = authorization
        if token.lower().startswith("bearer "):
            token = token[7:].strip()
        user = get_user_by_token(db, token)
        if user:
            user_id = user.id
    box = create_box(db, user_id=user_id)
    if not box:
        logger.error("Unable to create box for user_id=%s", user_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to create box",
        )
    logger.info("Box created successfully %s", box.uuid)
    return box
