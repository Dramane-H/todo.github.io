Deploying a production-ready Django application with Docker on Google Cloud Platform (GCP) involves several steps. Here’s a comprehensive guide to achieve this:

1. Prepare Your Django Application
Ensure your Django application is production-ready by setting appropriate settings and handling static files.

Update settings.py
Security Settings: Ensure that the following settings are properly configured:
python
Copier le code
DEBUG = False
ALLOWED_HOSTS = ['your-domain.com', 'your-external-ip']
Static Files: Configure static files storage:
python
Copier le code
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
2. Create Dockerfiles
Create Dockerfiles for your Django application and PostgreSQL database.

Dockerfile for Django
Create a Dockerfile in the root directory of your Django application:

Dockerfile
Copier le code
# Dockerfile
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy project
COPY . /app/

# Collect static files
RUN python manage.py collectstatic --noinput

# Expose the port the app runs on
EXPOSE 8000

# Command to run the app
CMD ["gunicorn", "--workers", "3", "--bind", "0.0.0.0:8000", "todolistapi.wsgi:application"]
Dockerfile for PostgreSQL (optional if using GCP managed services)
If you prefer using a managed PostgreSQL service on GCP, you can skip this step.

Dockerfile
Copier le code
# Dockerfile for PostgreSQL (optional)
FROM postgres:13
ENV POSTGRES_DB dramzy_db
ENV POSTGRES_USER dramzy
ENV POSTGRES_PASSWORD dramzy
3. Create a docker-compose.yml
Create a docker-compose.yml file to define your services:

yaml
Copier le code
version: '3.8'

services:
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: dramzy_db
      POSTGRES_USER: dramzy
      POSTGRES_PASSWORD: dramzy
    ports:
      - "5432:5432"

  web:
    build: .
    command: gunicorn --workers 3 --bind 0.0.0.0:8000 todolistapi.wsgi:application
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      SECRET_KEY: 'your-generated-secret-key'
      DB_NAME: dramzy_db
      DB_USER: dramzy
      DB_PASSWORD: dramzy
      DB_HOST: db
      DB_PORT: 5432
4. Push Your Docker Images to Google Container Registry (GCR)
Tag and push your Docker images to GCR.

Authenticate Docker to GCP
bash
Copier le code
gcloud auth configure-docker
Build, Tag, and Push Your Images
bash
Copier le code
# Build your Django image
docker build -t gcr.io/your-project-id/todolist-app:latest .

# Tag your image
docker tag gcr.io/your-project-id/todolist-app:latest gcr.io/your-project-id/todolist-app:latest

# Push your image
docker push gcr.io/your-project-id/todolist-app:latest
5. Deploy to Google Kubernetes Engine (GKE)
Create a GKE Cluster
bash
Copier le code
gcloud container clusters create todolist-cluster --num-nodes=3
Create Kubernetes Deployment and Service Files
Create a deployment YAML file (deployment.yaml):

yaml
Copier le code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todolist-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: todolist-app
  template:
    metadata:
      labels:
        app: todolist-app
    spec:
      containers:
      - name: todolist-app
        image: gcr.io/your-project-id/todolist-app:latest
        ports:
        - containerPort: 8000
        env:
        - name: SECRET_KEY
          value: "your-generated-secret-key"
        - name: DB_NAME
          value: "dramzy_db"
        - name: DB_USER
          value: "dramzy"
        - name: DB_PASSWORD
          value: "dramzy"
        - name: DB_HOST
          value: "db"
        - name: DB_PORT
          value: "5432"

---
apiVersion: v1
kind: Service
metadata:
  name: todolist-app
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8000
  selector:
    app: todolist-app
Create a deployment YAML file for PostgreSQL (postgres-deployment.yaml):

yaml
Copier le code
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "dramzy_db"
        - name: POSTGRES_USER
          value: "dramzy"
        - name: POSTGRES_PASSWORD
          value: "dramzy"

---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  type: ClusterIP
  ports:
  - port: 5432
  selector:
    app: postgres
Deploy to GKE
bash
Copier le code
# Deploy the application
kubectl apply -f deployment.yaml

# Deploy PostgreSQL (if not using managed services)
kubectl apply -f postgres-deployment.yaml
6. Configure a Domain and HTTPS
Configure DNS
Point your domain to the external IP of the LoadBalancer created by GKE.

Set Up HTTPS with Let's Encrypt
Use a tool like Cert-Manager to manage your SSL certificates.

bash
Copier le code
# Install Cert-Manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml

# Create a ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-key
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
Update the Deployment to Use HTTPS
Create an Ingress resource to handle HTTPS:

yaml
Copier le code
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todolist-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  tls:
  - hosts:
    - your-domain.com
    secretName: todolist-tls
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: todolist-app
            port:
              number: 80
Apply the Ingress resource:

bash
Copier le code
kubectl apply -f ingress.yaml