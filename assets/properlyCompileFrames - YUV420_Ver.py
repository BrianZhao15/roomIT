import os
import math
import cv2
import numpy as np

# md, specs, and path
width = 720
height = 1280
frame_size = width * height * 3 // 2
input_file = "replace_w/_path_to_the_file_for_analysis"

# params
entropy_threshold = 7.0
step = 500
max_frames = 10

# helper functions, idk what it means though but it sounds cool
def entropy(data):
    counts = [0]*256
    for b in data:
        counts[b] += 1
    ent = 0
    length = len(data)
    for c in counts:
        if c == 0:
            continue
        p = c / length
        ent -= p * math.log2(p)
    return ent

def try_decode_and_save(chunk, frame_index):
    try:
        yuv = np.frombuffer(chunk, dtype=np.uint8).reshape((height * 3) // 2, width)
        rgb = cv2.cvtColor(yuv, cv2.COLOR_YUV2RGB_I420)
        filename = f"frame_{frame_index:03d}.png"
        cv2.imwrite(filename, rgb)
        print(f"Saved {filename}")
        return True
    except Exception as e:
        print(f"Frame {frame_index} failed: {e}")
        return False

# main/entry point
def extract_frames():
    if not os.path.exists(input_file):
        print("File was not found:", input_file)
        return

    with open(input_file, "rb") as f:
        data = f.read()

    print(f"File loaded: {len(data)} bytes")

    i = 0
    found = 0
    total = len(data)

    while i + frame_size <= total and found < max_frames:
        chunk = data[i:i + frame_size]
        e = entropy(chunk)

        if e > entropy_threshold:
            print(f"Entropy {e:.2f} at offset {i}. Trying to decode...")
            if try_decode_and_save(chunk, found):
                found += 1
                i += frame_size
                continue
        i += step

    print(f"Done. Total frames extracted: {found}")

if __name__ == "__main__":
    extract_frames()

'''
import math
import cv2
import numpy as np

width = 720
height = 1280

frame_size = width * height * 3 // 2

def entropy(data):
    """Calculate entropy of a byte array."""
    counts = [0]*256
    for b in data:
        counts[b] += 1
    entropy = 0
    length = len(data)
    for c in counts:
        if c == 0:
            continue
        p = c / length
        entropy -= p * math.log2(p)
    return entropy

def is_valid_frame(chunk):
    """Check if chunk size matches frame size."""
    return len(chunk) == frame_size

def save_frame(chunk, frame_index):
    """Convert YUV420 to RGB and save the frame as PNG."""
    try:
        yuv = np.frombuffer(chunk, dtype=np.uint8)
        yuv = yuv.reshape((height * 3) // 2, width)
        rgb = cv2.cvtColor(yuv, cv2.COLOR_YUV2RGB_I420)
        filename = f"frame_{frame_index:03d}.png"
        cv2.imwrite(filename, rgb)
        print(f"Saved {filename}")
    except Exception as e:
        print(f"Skipping frame {frame_index} due to error: {e}")

def extract_frames(filename):
    with open(filename, "rb") as f:
        data = f.read()

    window_size = frame_size
    step = 500 or 1000
    entropy_threshold = 7.0
    
    frames_found = 0
    i = 0
    while i + window_size <= len(data):
        if frames_found >= 10:
            break

        window = data[i:i+window_size]
        e = entropy(window)
        if e > entropy_threshold:
            chunk = window
            
            if is_valid_frame(chunk):
                save_frame(chunk, frames_found)
                frames_found += 1
                i += window_size
                continue

            if i % 10000 == 0:
                print(f"Scanning byte offset {i}...")
            
        i += step

    print(f"Total frames extracted: {frames_found}")

if __name__ == "__main__":
    input_file = "C:/Users/brian/StudioProjects/room_it/frames/frames"
    extract_frames(input_file)
'''