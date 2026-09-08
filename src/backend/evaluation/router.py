"""Bounded same-origin HTTP boundary for final study submissions."""
import asyncio
import json
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from starlette.concurrency import run_in_threadpool
from .service import MAX_BODY, StudyError


def router(service):
    api = APIRouter()

    @api.get('/api/study/content')
    def content():
        return JSONResponse(service.content(), headers={'Cache-Control': 'no-store'})

    @api.post('/api/study/submissions')
    async def submit(request: Request):
        try:
            if request.headers.get('origin') != service.config.origin or request.headers.get('sec-fetch-site', 'same-origin') not in ('same-origin', 'none'):
                raise StudyError(403, 'invalid_origin', 'Submission must come from the configured study origin.')
            if request.headers.get('content-type', '').split(';')[0].strip().lower() != 'application/json':
                raise StudyError(415, 'invalid_content_type', 'Send JSON content.')
            body = bytearray()
            async def read():
                async for chunk in request.stream():
                    body.extend(chunk)
                    if len(body) > MAX_BODY:
                        raise StudyError(413, 'request_too_large', 'Responses exceed the 128 KiB submission limit. Shorten free text before submitting.')
            await asyncio.wait_for(read(), timeout=15)
            def pairs(items):
                result = {}
                for k, v in items:
                    if k in result:
                        raise ValueError('Duplicate key')
                    result[k] = v
                return result
            payload = json.loads(body, object_pairs_hook=pairs, parse_constant=lambda _: (_ for _ in ()).throw(ValueError()))
            receipt, created = await run_in_threadpool(service.submit, payload)
            return JSONResponse(receipt, status_code=201 if created else 200, headers={'Cache-Control': 'no-store'})
        except (ValueError, UnicodeError, RecursionError):
            error = StudyError(422, 'invalid_json', 'Invalid submission JSON.')
        except asyncio.TimeoutError:
            error = StudyError(408, 'request_timeout', 'Submission timed out. Retry the same submission.')
        except StudyError as exc:
            error = exc
        return JSONResponse({'error': {'code': error.code, 'message': error.message}}, status_code=error.status, headers={'Cache-Control': 'no-store'})
    return api
