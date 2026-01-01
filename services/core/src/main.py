import os
from pathlib import Path

from fastapi import FastAPI

from controllers.groups_controller import router as groups_router
from controllers.health_controller import router as health_router

app = FastAPI()
app.include_router(health_router)
app.include_router(groups_router)


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
