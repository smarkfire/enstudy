import random
import logging

from alibabacloud_dysmsapi20170525.client import Client as DysmsClient
from alibabacloud_dysmsapi20170525 import models as sms_models
from alibabacloud_tea_openapi import models as open_api_models

from app.config import settings
from app.services.code_service import store_code, check_rate_limit

logger = logging.getLogger(__name__)

_client: DysmsClient | None = None


def _get_client() -> DysmsClient:
    global _client
    if _client is None:
        config = open_api_models.Config(
            access_key_id=settings.SMS_ACCESS_KEY_ID,
            access_key_secret=settings.SMS_ACCESS_KEY_SECRET,
        )
        config.endpoint = "dysmsapi.aliyuncs.com"
        _client = DysmsClient(config)
    return _client


def _generate_code() -> str:
    return f"{random.randint(0, 999999):06d}"


async def send_verification_code(phone: str) -> tuple[bool, str]:
    if not await check_rate_limit(phone):
        return False, "发送过于频繁，请稍后再试"

    code = _generate_code()
    await store_code(phone, code)

    if not settings.SMS_ACCESS_KEY_ID:
        logger.info(f"[DEV MODE] phone={phone}, code={code}")
        return True, "验证码已发送（开发模式）"

    try:
        client = _get_client()
        request = sms_models.SendSmsRequest(
            phone_numbers=phone,
            sign_name=settings.SMS_SIGN_NAME,
            template_code=settings.SMS_TEMPLATE_CODE,
            template_param=f'{{"code":"{code}"}}',
        )
        response = client.send_sms(request)
        if response.body.code == "OK":
            return True, "验证码已发送"
        else:
            logger.error(f"SMS send failed: {response.body.code} - {response.body.message}")
            return False, f"短信发送失败: {response.body.message}"
    except Exception as e:
        logger.error(f"SMS send error: {e}")
        return False, "短信发送失败，请稍后再试"
