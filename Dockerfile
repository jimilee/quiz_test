ARG PYTHON_VERSION=3.8-slim-buster
FROM python:${PYTHON_VERSION}

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SUPERUSER_USERNAME 'admin'
ENV DJANGO_SUPERUSER_EMAIL 'admin@example.com'
ENV DJANGO_SUPERUSER_PASSWORD 'admin1234'

RUN mkdir -p /code

WORKDIR /code

COPY requirements.txt /tmp/requirements.txt
RUN set -ex && \
    pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt && \
    rm -rf /root/.cache/
COPY . /code

ENV SECRET_KEY "Ijmy386DOgAoz6cgFbvUnYqysQThfKtQ6qEsYhmFkPEZOD7XQe"
RUN python manage.py collectstatic --noinput
RUN python manage.py makemigrations
RUN python manage.py createcachetable

# Run Django management commands to create the superuser
RUN python manage.py migrate && \
    echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists() or \
    User.objects.create_superuser('$DJANGO_SUPERUSER_USERNAME', '$DJANGO_SUPERUSER_EMAIL', '$DJANGO_SUPERUSER_PASSWORD')" | python manage.py shell

EXPOSE 8000

CMD ["gunicorn", "--bind", ":8000", "--workers", "2", "myapi.wsgi"]
# CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]