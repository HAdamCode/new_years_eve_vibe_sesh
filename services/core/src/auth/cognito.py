import os

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient, decode
from jwt.exceptions import InvalidTokenError

security = HTTPBearer()


def _get_cognito_region() -> str:
    region = os.getenv("COGNITO_REGION")
    if not region:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="COGNITO_REGION is not set",
        )
    return region


def _get_user_pool_id() -> str:
    user_pool_id = os.getenv("COGNITO_USER_POOL_ID")
    if not user_pool_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="COGNITO_USER_POOL_ID is not set",
        )
    return user_pool_id


def _get_app_client_id() -> str | None:
    return os.getenv("COGNITO_APP_CLIENT_ID")


def _get_jwks_url(region: str, user_pool_id: str) -> str:
    return (
        f"https://cognito-idp.{region}.amazonaws.com/"
        f"{user_pool_id}/.well-known/jwks.json"
    )


def _get_jwks_client(region: str, user_pool_id: str) -> PyJWKClient:
    url = _get_jwks_url(region, user_pool_id)
    return PyJWKClient(url)


def _verify_token(token: str) -> dict[str, object]:
    region = _get_cognito_region()
    user_pool_id = _get_user_pool_id()
    app_client_id = _get_app_client_id()
    issuer = f"https://cognito-idp.{region}.amazonaws.com/{user_pool_id}"

    jwks_client = _get_jwks_client(region, user_pool_id)
    try:
        signing_key = jwks_client.get_signing_key_from_jwt(token).key
    except InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        ) from exc

    try:
        if app_client_id:
            decoded = decode(
                token,
                signing_key,
                algorithms=["RS256"],
                audience=app_client_id,
                issuer=issuer,
            )
        else:
            decoded = decode(
                token,
                signing_key,
                algorithms=["RS256"],
                issuer=issuer,
                options={"verify_aud": False},
            )
    except InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        ) from exc

    token_use = decoded.get("token_use")
    if token_use not in {"access", "id"}:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unsupported token",
        )

    if token_use == "access" and app_client_id:
        if decoded.get("client_id") != app_client_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token client_id mismatch",
            )

    return decoded


def cognito_auth_required(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict[str, object]:
    return _verify_token(credentials.credentials)
