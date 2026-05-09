FROM python:3.11-alpine

RUN apk add --no-cache docker-cli curl bash

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

WORKDIR /app

EXPOSE 8000

CMD ["python3", "platform/api.py"]