import numpy as np
import cv2

width = 1080
height = 1920
frame_size = width * height * 3 // 2

input_path = "replace_w/_path_to_the_file_to_be_assessed"
output_image = "output.png"

def extract_yuv_data(filepath, frame_size):
    with open(filepath, 'rb') as f:
        raw = f.read()

    candidates = []
    for i in range(len(raw) - frame_size):
        chunk = raw[i:i + frame_size]
        if all(0 <= b <= 255 for b in chunk):  # basic check
            candidates.append(chunk)

    if not candidates:
        raise ValueError("No valid YUV frame found in file.")

    # use the first valid candidate
    return candidates[0]

def decode_yuv420p_to_image(yuv_bytes, width, height):
    frame_size = width * height
    uv_size = frame_size // 4

    y = yuv_bytes[0:frame_size].reshape((height, width))
    u = yuv_bytes[frame_size:frame_size + uv_size].reshape((height // 2, width // 2))
    v = yuv_bytes[frame_size + uv_size:].reshape((height // 2, width // 2))

    u_up = cv2.resize(u, (width, height), interpolation=cv2.INTER_LINEAR)
    v_up = cv2.resize(v, (width, height), interpolation=cv2.INTER_LINEAR)

    yuv = cv2.merge((y, u_up, v_up))
    bgr = cv2.cvtColor(yuv, cv2.COLOR_YUV2BGR)

    return bgr

yuv_frame = extract_yuv_data(input_path, frame_size)

image = decode_yuv420p_to_image(np.frombuffer(yuv_frame, dtype=np.uint8), width, height)

cv2.imwrite(output_image, image)
print(f"Image saved to {output_image}")
