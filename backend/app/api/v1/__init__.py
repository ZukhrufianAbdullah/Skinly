from fastapi import APIRouter
from app.api.v1 import auth, scans, articles, feedback, health

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(scans.router)
api_router.include_router(articles.router)
api_router.include_router(feedback.router)
api_router.include_router(health.router)
