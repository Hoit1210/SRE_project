import requests
import os
import time

TARGET_URL = "http://web:5000/health"

while True:
    try:
        response = requests.get(TARGET_URL, timeout=3)
        if response.status_code != 200:
            raise Exception("Unhealthy status code")
        print("[Health Check] Normal operation.")
    except Exception as e:
        print(f"[ALERT] Web App Down! Triggering Auto-Healing... ({e})")
        # Docker 명령어로 죽은 웹 컨테이너를 강제 재시작
        os.system("docker restart web")
    time.sleep(10)
