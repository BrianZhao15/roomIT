import cv2
import numpy as np

width = 720
height = 1280

with open("replace_w/_path_to_file_for_analysis", "rb") as f:
    yuv_data = f.read()

yuv = np.frombuffer(yuv_data, dtype=np.uint8)
yuv = yuv[:int(width * height * 1.5)]

yuv = yuv.reshape((height * 3) // 2, width)
rgb = cv2.cvtColor(yuv, cv2.COLOR_YUV2RGB_I420)

cv2.imwrite("replace_w/_path_to_desired_file_saving_location", rgb)