FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY wyoming/requirements.txt /app/requirements.txt
RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir -r /app/requirements.txt

# Copy your local bridge scripts into the container
COPY wyoming/rk-voice-wyoming.py /app/rk-voice-wyoming.py
COPY wyoming/tts_wyoming.py /app/tts_wyoming.py

EXPOSE 10200

CMD ["python", "/app/tts_wyoming.py", "--uri", "tcp://0.0.0.0:10200"]
