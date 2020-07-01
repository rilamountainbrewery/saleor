### Build and install packages
FROM python:3.8 as build-python

RUN apt-get -y update \
  && apt-get install -y gettext \
  # Cleanup apt cache
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements_dev.txt /app/
WORKDIR /app
RUN pip3 install -r requirements_dev.txt

### Final image
FROM python:3.8-slim

ARG STATIC_URL
ENV STATIC_URL ${STATIC_URL:-/static/}

RUN groupadd -r saleor && useradd -r -g saleor saleor

RUN apt-get update \
  && apt-get install -y \
    libxml2 \
    libssl1.1 \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    shared-mime-info \
    mime-support \
    libmagic-dev \
    python-django-cors-headers \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN pip3 install django-cors-headers

COPY . /app
COPY --from=build-python /usr/local/lib/python3.8/site-packages/ /usr/local/lib/python3.8/site-packages/
COPY --from=build-python /usr/local/bin/ /usr/local/bin/
WORKDIR /app

RUN mkdir -p /app/media /app/static /app/saleor /app/saleor/static/images \
  && chown -R saleor:saleor /app/

# RUN SECRET_KEY=dummy STATIC_URL=${STATIC_URL} python3 manage.py collectstatic --no-input
RUN SECRET_KEY=dWgb0F62vZPKj2UUplXMnDJ1Yf1f5NfjJrZK5sYIo5YDBOEJyNLjT9TRrb4KQIgde82mm6pBI7fE1aqJE8ZtFdZy2wBWqdvbf0O STATIC_URL='/static/' python3 manage.py collectstatic --no-input


EXPOSE 8000
ENV PORT 8000
ENV PYTHONUNBUFFERED 1
ENV PROCESSES 4

CMD ["uwsgi", "--ini", "/app/saleor/wsgi/uwsgi.ini"]
