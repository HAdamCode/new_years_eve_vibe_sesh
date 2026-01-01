from fastapi import FastAPI

from controllers.health_controller import router as health_router

app = FastAPI()
app.include_router(health_router)
