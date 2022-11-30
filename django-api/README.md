# Consume block data from Erigon with Django REST API

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed
- [Docker Compose](https://docs.docker.com/compose/install/) installed
- [Python 3](https://www.python.org/downloads/) installed
- [Git](https://git-scm.com/downloads) installed

## Step 1. Create a Django project

Create a new Django project and start the development server:

```bash
django-admin startproject erigon_django
cd erigon_django
python manage.py runserver
```

## Step 2. Create a Django app

Create a new Django app called `blocks`:

```bash
python manage.py startapp blocks
```

## Step 3. Create a model

Create a new file called `models.py` in the `blocks` directory and add the following code:

```python
from django.db import models

class Block(models.Model):
    number = models.IntegerField()
    hash = models.CharField(max_length=66)
    parent_hash = models.CharField(max_length=66)
    nonce = models.CharField(max_length=66)
    sha3_uncles = models.CharField(max_length=66)
    logs_bloom = models.CharField(max_length=512)
    transactions_root = models.CharField(max_length=66)
    state_root = models.CharField(max_length=66)
    receipts_root = models.CharField(max_length=66)
    miner = models.CharField(max_length=42)
    difficulty = models.IntegerField()
    total_difficulty = models.IntegerField()
    size = models.IntegerField()
    extra_data = models.CharField(max_length=66)
    gas_limit = models.IntegerField()
    gas_used = models.IntegerField()
    timestamp = models.IntegerField()
    uncles = models.CharField(max_length=66)
```

## Step 4. Register the app

In the `erigon_django` directory, open the `settings.py` file and add the `blocks` app to the `INSTALLED_APPS` list:

```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'blocks.apps.BlocksConfig',
]
```

## Step 5. Create a serializer

Create a new file called `serializers.py` in the `blocks` directory and add the following code:

```python
from rest_framework import serializers
from .models import Block

class BlockSerializer(serializers.ModelSerializer):
    class Meta:
        model = Block
        fields = '__all__'
```

## Step 6. Create a view

Create a new file called `views.py` in the `blocks` directory and add the following code:

```python
from rest_framework import viewsets
from .serializers import BlockSerializer
from .models import Block

class BlockViewSet(viewsets.ModelViewSet):
    queryset = Block.objects.all().order_by('number')
    serializer_class = BlockSerializer
```

## Step 7. Create a URL

In the `erigon_django` directory, open the `urls.py` file and add the following code:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('blocks.urls')),
]
```

Create a new file called `urls.py` in the `blocks` directory and add the following code:

```python
from rest_framework import routers
from .views import BlockViewSet

router = routers.DefaultRouter()
router.register('api/blocks', BlockViewSet, 'blocks')

urlpatterns = router.urls
```

## Step 8. Install dependencies

Install the following dependencies:

```bash
pip install django djangorestframework
```

## Step 9. Run migrations

Run the following command to create the database tables:

```bash
python manage.py makemigrations
python manage.py migrate
```

## Step 10. Create a superuser

Create a superuser account to access the admin panel:

```bash
python manage.py createsuperuser
```

## Step 11. Start the development server

Start the development server:

```bash
python manage.py runserver
```

## Step 12. Access the admin panel OR Django Shell

Open the following URL in your browser to access the admin panel:

```bash
http://localhost:8000/admin
```

OR 

```bash
python manage.py shell
```

## Step 13. Add a block

Add a new block to the database:

```python
from blocks.models import Block

Block.objects.create(
    number=1,
    hash='0x1',
    parent_hash='0x1',
    nonce='0x1',
    sha3_uncles='0x1',
    logs_bloom='0x1',
    transactions_root='0x1',
    state_root='0x1',
    receipts_root='0x1',
    miner='0x1',
    difficulty=1,
    total_difficulty=1,
    size=1,
    extra_data='0x1',
    gas_limit=1,
    gas_used=1,
    timestamp=1,
    uncles='0x1',
)
```

## Step 14. Access the API

Open the following URL in your browser to access the API:

```bash
http://localhost:8000/api/blocks
```

## Step 15. Stop the development server

Stop the development server:

```bash
CTRL + C
```

## Step 16. Create a Dockerfile

Create a new file called `Dockerfile` in the `erigon_django` directory and add the following code:

```dockerfile
FROM python:3.9.5-slim-buster

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "manage.py", "runserver", "localhost:8000"]
```

## Step 17. Create a requirements.txt file

Create a new file called `requirements.txt` in the `erigon_django` directory and add the following code:

```bash
django
djangorestframework
```

## Step 18. Build the Docker image

Build the Docker image:

```bash
docker build -t erigon_django .
```

## Step 19. Run the Docker container

Run the Docker container:

```bash
docker run -p 8000:8000 erigon_django
```

## Step 20. Access the admin panel

Open the following URL in your browser to access the admin panel:

```bash
http://localhost:8000/admin
```

## Step 21. Access the API

Open the following URL in your browser to access the API:

```bash
http://localhost:8000/api/blocks
```

## Step 22. Stop the Docker container

Stop the Docker container:

```bash
CTRL + C
```

## Step 23. Create a docker-compose.yml file

Create a new file called `docker-compose.yml` in the `erigon_django` directory and add the following code:

```yaml
version: '3.8'

services:
  erigon:
    image: erigon
    container_name: erigon
    restart: unless-stopped
    ports:
      - 8545:8545
      - 8546:8546
      - 30303:30303
      - 30303:30303/udp
    volumes:
      - erigon:/var/lib/erigon
      - erigon:/root/.local/share/erigon
      - erigon:/root/.local/share/erigon.ipc
    command: erigon
    
  erigon_django:
    image: erigon_django
    container_name: erigon_django
    restart: unless-stopped
    ports:
      - 8000:8000
    depends_on:
      - erigon
    volumes:
      - erigon_django:/app
    command: python manage.py runserver localhost:8000

volumes:
    erigon:
    erigon_django:
```

## Step 24. Run the Docker containers

Run the Docker containers:

```bash
docker-compose up
```

## Step 25. Access the admin panel

Open the following URL in your browser to access the admin panel:

```bash
http://localhost:8000/admin
```

## Step 26. Access the API

Open the following URL in your browser to access the API:

```bash
http://localhost:8000/api/blocks
```

## Step 27. Stop the Docker containers

Stop the Docker containers:

```bash
CTRL + C
```
