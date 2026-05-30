from typing import Any


def success(data: Any = None, message: str = "ok") -> dict:
    result = {"success": True, "message": message}
    if data is not None:
        result["data"] = data
    return result


def error(message: str = "error", code: int = 400) -> dict:
    return {"success": False, "message": message, "code": code}
