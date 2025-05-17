


from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import base64
import numpy as np
from PIL import Image, ImageSequence
from io import BytesIO
from datetime import datetime
import asyncio
from concurrent.futures import ThreadPoolExecutor
import threading
import os
import sys
import cv2

# Local import
from CaptchaEngine import CaptchaEngine

# Create FastAPI app
app = FastAPI()
origins = ['*']
app.add_middleware(CORSMiddleware, allow_origins=origins, allow_credentials=True, allow_methods=['*'], allow_headers=['*'])

# Captcha solver setup
width = 256
height = 256
Solver = CaptchaEngine(width, height)
executor = ThreadPoolExecutor(max_workers=4)
log_queue = []

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

@app.post('/send_api')
async def api_base64(request: Request):
    req = await request.json()
    base64_str = req['data']
    if base64_str.startswith('data:image'):
        base64_str = base64_str.split(',', 1)[1]
    cv_img = merge_gif_preserve_color(base64_str)
    loop = asyncio.get_event_loop()
    text = await loop.run_in_executor(executor, Solver.solve_cv2, cv_img)
    log_event("Captcha received and solved.")
    return JSONResponse(content={'result': text, 'status': '1'})

if __name__ == '__main__':
    uvicorn.run("main:app", host="0.0.0.0", port=5050, reload=False)
