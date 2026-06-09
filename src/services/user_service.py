import logging
from sqlalchemy.orm import Session

from src.models.user import User
from src.utils.security import generate_auth_token, hash_password, verify_password

logger = logging.getLogger("app.services.user")


def get_user_by_username(db: Session, username: str) -> User | None:
    return db.query(User).filter(User.username == username).first()


def get_user_by_token(db: Session, token: str) -> User | None:
    return db.query(User).filter(User.auth_token == token).first()


def create_user(db: Session, username: str, password: str) -> User:
    password_hash = hash_password(password)
    auth_token = generate_auth_token()
    user = User(username=username, password_hash=password_hash, auth_token=auth_token)
    db.add(user)
    try:
        db.commit()
        db.refresh(user)
        logger.info("Created new user %s", username)
        return user
    except Exception:
        db.rollback()
        logger.critical("Failed to create user %s", username, exc_info=True)
        raise


def authenticate_user(db: Session, username: str, password: str) -> User | None:
    user = get_user_by_username(db, username)
    if user is None:
        logger.warning("Authentication failed for unknown user %s", username)
        return None
    if not verify_password(password, user.password_hash):
        logger.warning("Authentication failed for user %s: invalid password", username)
        return None
    if not user.auth_token:
        user.auth_token = generate_auth_token()
        try:
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()
            logger.critical("Failed to refresh auth token for user %s", username, exc_info=True)
            raise
    logger.info("User authenticated successfully: %s", username)
    return user
