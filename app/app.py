from flask import Flask
import os

app = Flask(__name__)
SECRET = os.getenv("APP_SECRET", "not set")

@app.route('/')
def hello():
    return f"Hello, World! Secret: {SECRET}"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
