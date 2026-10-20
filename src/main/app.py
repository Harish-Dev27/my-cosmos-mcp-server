from contextlib import AsyncExitStack, asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from mcp.server.transport_security import TransportSecuritySettings

from .mcp_server import mcp


ACA_HOST = (
    "cosmos-mcp-server.lemonriver-b2a02dcf."
    "southindia.azurecontainerapps.io"
)

transport_security = TransportSecuritySettings(
    allowed_hosts=[
        ACA_HOST,
        f"{ACA_HOST}:*",
    ]
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with AsyncExitStack() as stack:
        await stack.enter_async_context(mcp.session_manager.run())
        yield


app = FastAPI(lifespan=lifespan)


@app.get("/health")
async def health():
    return JSONResponse({"status": "healthy"})


app.mount(
    "/",
    mcp.streamable_http_app(
        stateless_http=True,
        transport_security=transport_security,
    ),
)