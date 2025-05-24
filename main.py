from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import uvicorn
import base64
import numpy as np
from PIL import Image, ImageSequence
from io import BytesIO
from datetime import datetime, timedelta
import asyncio
from concurrent.futures import ThreadPoolExecutor
import threading
import os
import sys
import cv2

# Local import
from CaptchaEngine import CaptchaEngine

app = FastAPI()
origins = ['*']
app.add_middleware(CORSMiddleware, allow_origins=origins, allow_credentials=True, allow_methods=['*'], allow_headers=['*'])

# Captcha solver setup
width = 256
height = 256
Solver = CaptchaEngine(width, height)
executor = ThreadPoolExecutor(max_workers=25)
log_queue = []

# 🔐 مفاتيح API وصلاحياتها
valid_keys = {
    "x9MfNLR0YaV2Ub3gTHFClEBAw": [],
    "ZvT8rcIJKj5E27y4BuV06mhHX": [],
    "sUFOC5MxetAp2VRGZybJTH73P": [],
    "AKdiWY4JE6HPCl2QwzMfgv9nT": [],
    "vNSupRIB3AY8WgLt5Z2J1FoKM": [],
    "UjY0sHtPBMdR3XL89yTeAxGVF": [],
    "9ThPbd8FgAErmRCN3OZy20Wvx": [],
    "74EZMW3vfKn1LQOgYx0dPRAuB": [],
    "K6O8Y2LuGzNDqVyUmIJ3RM1wB": [],
    "qrA9oIjFcZ4EMvPXY10glkWbn": [],
    "hOxL0yWCBsJAZqGKrp5EvfN2m": [],
    "Wj19HmUxqr7vcIepKZTBOnYLF": [],
    "iPJCN62RgLk3qvEAoyrZDMwUt": [],
    "toEMAZvHqg05X98YLRKnJu7IB": [],
    "UrYCBmFwNoLqEzIJHKPXAG5v8": [],
    "JzYqrTKP3uBv0FgmWI2CExAon": [],
    "gA59PXOBIUEzLrqJvCmYTn2Kw": [],
    "wC5RBt9IOuAKzvJLFxPYMNq3g": [],
    "dPXUYEHoAwLgC9Fmrv3BZtKJ2": [],
    "zK0CNqgpF3uYvB6XtoJMIAWER": [],
    "BmJPuTgCOK9XzArFLYNM0q8eV": [],
    "KqxA3rPBLYvFzuJTIg9EOCWM0": [],
    "9ZIOvCB5FKgpwXNJMtYuArqLE": [],
    "FoYKuPqgILBXrEvWACZTN839M": [],
    "JvXPwoUgLMN9YzEKFAB3tqrCI": [],
    "mPNKrLOXuwACFyEgT93IBvYZq": [],
    "MJK0zgpOYvwXICFB9ANqEruTL": [],
    "YLNOtKFBXgMwAqrJzv3CPIuE9": [],
    "qpzYWUK3rC0vOXIMJNEtLAgFB": [],
    "qvXJmZ3FBLPtAgY9wKINuOErC": [],
    "0ZXPuCtMwBFLYKONgqvJ3IAEr": [],
    "XZOKrFLqJAvBYgmI9PtCEN3uW": [],
    "vAgP9FYXOEtZCqILwJMrBKUN3": [],
    "3CNwqAvFZJtI9OLgYXpMKUERB": [],
    "ZPwOYqCNAJrKXtMBLFg3uE9Iv": [],
    "IKgOYJPZF9XvCBrMwAqTL3uEN": [],
    "IBP9ZgtJXYvLONwqCEMuAFK3r": [],
    "rFOuCvYXAgPt9MJqIZKNBEL3W": [],
    "tMBYFZPwOXgqCNvKJLA9rEI3u": [],
    "EAJPXFqKONr9vLCYZIB3MtgWu": [],
    "rLtXPZ9OYICNgFKBuAwJvEM3q": [],
    "YK9IvCrF3JMtLgqZXONPWAEuB": [],
    "ArP9FJYZvBXNgKOCEMLtqW3uI": [],
    "9BZKvLOgqXFCPtYMNEIwArJU3": [],
    "P9ErBCZJqYOvNtXIKFALWg3uM": [],
    "gZJYXErCqLOvBPMKNtFAWIU93": [],
    "KP3rCgOXvBLZMtFAEwYIN9JQU": [],
    "JYXwCqLPvFtZBOAgINK39EMUr": [],
    "uPtCg9FZJAXKqOYILv3BNEWMr": [],
}

RATE_LIMIT = 3  # عدد الاستخدامات المسموح بها
TIME_WINDOW = timedelta(hours=3)  # النافذة الزمنية

lock = threading.Lock()

def log_event(message):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_queue.append(f"[{timestamp}] {message}")

def merge_gif_preserve_color(base64_gif_str):
    gif_data = base64.b64decode(base64_gif_str)
    gif_io = BytesIO(gif_data)
    gif = Image.open(gif_io)
    frames = []
    for frame in ImageSequence.Iterator(gif):
        rgb_frame = frame.convert('RGB')
        np_frame = np.array(rgb_frame)
        frames.append(np_frame)
    merged = np.minimum.reduce(frames)
    return merged

def is_key_allowed(key: str):
    now = datetime.now()
    with lock:
        if key not in valid_keys:
            return False, "Invalid key"

        # تنظيف الاستخدامات القديمة
        recent_times = [t for t in valid_keys[key] if now - t < TIME_WINDOW]
        valid_keys[key] = recent_times

        if len(recent_times) >= RATE_LIMIT:
            return False, "Rate limit exceeded. Try again later."

        # تسجيل الاستخدام الجديد
        valid_keys[key].append(now)
    return True, None

@app.post('/send_api')
async def api_base64(request: Request):
    req = await request.json()

    api_key = req.get('key')
    if not api_key:
        return JSONResponse(content={'status': '0', 'error': 'Missing API key'}, status_code=400)

    allowed, message = is_key_allowed(api_key)
    if not allowed:
        return JSONResponse(content={'status': '0', 'error': message}, status_code=403)

    base64_str = req.get('data')
    if not base64_str:
        return JSONResponse(content={'status': '0', 'error': 'Missing data'}, status_code=400)

    if base64_str.startswith('data:image'):
        base64_str = base64_str.split(',', 1)[1]

    cv_img = merge_gif_preserve_color(base64_str)
    loop = asyncio.get_event_loop()
    text = await loop.run_in_executor(executor, Solver.solve_cv2, cv_img)
    log_event(f"Captcha received and solved by key: {api_key}")
    return JSONResponse(content={'result': text, 'status': '1'})

if __name__ == '__main__':
    uvicorn.run("main:app", host="0.0.0.0", port=5050, reload=False)
