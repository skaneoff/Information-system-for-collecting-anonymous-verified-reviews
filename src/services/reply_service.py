import logging
from fastapi import HTTPException, status

from src.models.reply import Reply
from src.utils.validators import moderate_text

logger = logging.getLogger("app.services.reply")


def create_reply(db, feedback_id, text):
    try:
        text = moderate_text(text)
    except ValueError as e:
        logger.warning("Reply moderation failed for feedback %s: %s", feedback_id, e)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        ) from e
    reply = Reply(feedback_id=feedback_id, text=text)
    db.add(reply)
    try:
        db.commit()
        db.refresh(reply)
        logger.info("Created reply id=%s for feedback_id=%s", reply.id, feedback_id)
        return reply
    except Exception:
        db.rollback()
        logger.critical("Failed to create reply for feedback %s", feedback_id, exc_info=True)
        raise
