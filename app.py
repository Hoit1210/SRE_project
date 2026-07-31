from flask import Flask, Response
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)

# Prometheus 메트릭 정의 (총 요청 횟수 카운터)
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests')

@app.route('/')
def home():
    REQUEST_COUNT.inc()
    return "Hello, SRE World!"

@app.route('/health')
def health():
    # 헬스 체크용 엔드포인트
    return "OK", 200

@app.route('/metrics')
def metrics():
    # Prometheus가 이 URL을 계속 조회해서 데이터를 가져감
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
