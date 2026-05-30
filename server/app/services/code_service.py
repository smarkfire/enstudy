from app.utils.redis import redis_client

CODE_PREFIX = "sms_code:"
RATE_PREFIX = "sms_rate:"
DAILY_PREFIX = "sms_daily:"
FAIL_PREFIX = "sms_fail:"

CODE_TTL = 300
RATE_TTL = 60
DAILY_TTL = 86400
FAIL_TTL = 300
MAX_DAILY = 10
MAX_FAIL = 3


async def store_code(phone: str, code: str) -> None:
    key = f"{CODE_PREFIX}{phone}"
    await redis_client.setex(key, CODE_TTL, code)
    fail_key = f"{FAIL_PREFIX}{phone}"
    await redis_client.delete(fail_key)


async def verify_code(phone: str, code: str) -> bool:
    key = f"{CODE_PREFIX}{phone}"
    stored = await redis_client.get(key)
    if stored is None:
        return False

    fail_key = f"{FAIL_PREFIX}{phone}"
    fail_count = await redis_client.get(fail_key)
    if fail_count is not None and int(fail_count) >= MAX_FAIL:
        await redis_client.delete(key)
        await redis_client.delete(fail_key)
        return False

    if stored == code:
        await redis_client.delete(key)
        await redis_client.delete(fail_key)
        return True
    else:
        await redis_client.incr(fail_key)
        if not fail_count:
            await redis_client.expire(fail_key, FAIL_TTL)
        return False


async def check_rate_limit(phone: str) -> bool:
    rate_key = f"{RATE_PREFIX}{phone}"
    if await redis_client.exists(rate_key):
        return False
    await redis_client.setex(rate_key, RATE_TTL, "1")

    daily_key = f"{DAILY_PREFIX}{phone}"
    count = await redis_client.incr(daily_key)
    if count == 1:
        await redis_client.expire(daily_key, DAILY_TTL)
    return count <= MAX_DAILY
