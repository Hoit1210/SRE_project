from flask import Flask, Response
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests')
is_healthy = True # 서버 상태 플래그

@app.route('/')
def home():
    REQUEST_COUNT.inc()
    return "Hello, SRE World!"

@app.route('/health')
def health():
    if not is_healthy:
        # 장애 발생 시 500 에러를 리턴하여 Auto-Healer가 감지하게 만듦
        return "Internal Server Error", 500
    return "OK", 200

# 💣 장애 주입 전용 엔드포인트!
@app.route('/kill')
def kill():
    global is_healthy
    is_healthy = False
    return "⚠️ Web App Status Set to Down! Auto-Healer will recover this soon...", 500

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
