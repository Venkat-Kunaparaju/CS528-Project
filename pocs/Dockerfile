FROM python:3.12-alpine AS poc-base

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 22

FROM poc-base AS ext-downgrade-chacha20-poly1305
ENTRYPOINT ["python", "ext-downgrade/ext_downgrade_chacha20_poly1305.py" ]

