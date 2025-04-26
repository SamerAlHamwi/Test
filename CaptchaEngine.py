
import numpy as np
import cv2
import os
import base64
import threading
import sys

def resource_path(relative_path):
    if getattr(sys, 'frozen', False):
        base_path = sys._MEIPASS
    else:  # inserted
        base_path = os.path.abspath('.')
    path = os.path.join(base_path, relative_path)
    if not os.path.exists(path):
        return os.path.join('attachments', relative_path)
    return path


class CaptchaEngine:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        configPath = resource_path('data.cfg')
        weightPath = resource_path('data.weights')
        labelPath = resource_path('data.nms')
        labelPath = os.path.join(labelPath)
        configPath = os.path.join(configPath)
        weightPath = os.path.join(weightPath)
        self.LABELS_PLATE = open(labelPath).read().strip().split('\n')
        self.net = cv2.dnn_DetectionModel(configPath, weightPath)
        self.net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
        self.net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
        self.net.setInputSize(self.width, self.height)
        self.net.setInputScale(0.00392156862745098)
        self.net.setInputSwapRB(True)
        blank_image = np.zeros((self.width, self.height, 3), np.uint8)
        self.net.detect(blank_image, confThreshold=0.4, nmsThreshold=0.4)
        self.lock = threading.Lock()

    def solve_cv2(self, image):
        def get_key_x(item):
            return item[1]
        H, W, _ = image.shape
        classes, confidences, boxes = self.net.detect(image, confThreshold=0.5, nmsThreshold=0.3)
        info = []
        if not len(classes) == 0:
            for classId, confidence, box in zip(classes.flatten(), confidences.flatten(), boxes):
                x, y, w, h = box
                info.append((self.LABELS_PLATE[classId], x, y, w, h, confidence))
        info = sorted(info, key=get_key_x)
        text = ''
        for d in info:
            lbl, x, y, w, h, _ = d
            if w > 10 and h > 10 and (w < W) and (h < H):
                text = text + lbl.replace(' ', '')
        return text

    def solve(self, sbase64):
        cvimg = self.base64_to_cv2(sbase64)
        return self.solve_cv2(cvimg)

    def base64_to_cv2(self, sbase64):
        base64_str = sbase64
        arr = sbase64.split(',')
        if len(arr) > 1:
            base64_str = arr[1]
        im_bytes = base64.b64decode(base64_str)
        nparr = np.fromstring(im_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
        image = cv2.cvtColor(image, cv2.COLOR_BGRA2RGB)
        return image
  