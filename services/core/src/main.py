import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from controllers.groups_controller import router as groups_router
from controllers.health_controller import router as health_router
from controllers.studies_controller import router as studies_router
from controllers.study_sessions_controller import router as study_sessions_router
from controllers.study_passages_controller import router as study_passages_router
from controllers.study_questions_controller import router as study_questions_router
from controllers.study_question_responses_controller import (
    router as study_question_responses_router,
)
from controllers.user_controller import router as user_router

app = FastAPI()

# CORS configuration for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(groups_router)
app.include_router(studies_router)
app.include_router(study_sessions_router)
app.include_router(study_passages_router)
app.include_router(study_questions_router)
app.include_router(study_question_responses_router)
app.include_router(user_router)


def _run_migrations() -> None:
    from alembic import command
    from alembic.config import Config

    base_dir = Path(__file__).resolve().parents[1]
    alembic_ini = base_dir / "alembic.ini"
    if not alembic_ini.exists():
        return

    config = Config(str(alembic_ini))
    db_url = os.getenv("DATABASE_URL")
    if db_url:
        config.set_main_option("sqlalchemy.url", db_url)
    command.upgrade(config, "head")


@app.on_event("startup")
def on_startup() -> None:
    _run_migrations()
