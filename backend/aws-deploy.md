# Deploying the backend to AWS

This backend is containerized for AWS. The steps below push an image to Amazon ECR and run it on AWS App Runner (fully managed, no servers to manage). Replace placeholder values where noted.

## Prerequisites
- AWS CLI already configured on this Mac.
- Docker installed and running.
- PostgreSQL available (RDS/Aurora). Build the `DATABASE_URL` as `postgres://USER:PASSWORD@HOST:PORT/DBNAME`.

## Build and push the image to ECR
```bash
cd backend
export AWS_REGION=ap-south-1                     # adjust if different
export ECR_REPO=bpclpos-backend

# Create the repo if it does not exist
aws ecr create-repository --repository-name "$ECR_REPO" --region "$AWS_REGION" || true

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

docker build -t "$ECR_REPO:latest" .
docker tag "$ECR_REPO:latest" "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest"
docker push "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest"

export IMAGE_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest"
```

## Create or update the App Runner service
```bash
# Set your database connection string
export DATABASE_URL="postgres://USER:PASSWORD@HOST:PORT/DBNAME"

aws apprunner create-service \
  --service-name bpclpos-backend \
  --source-configuration "ImageRepository={ImageIdentifier=\"$IMAGE_URI\",ImageRepositoryType=\"ECR\",ImageConfiguration={Port=\"3001\",RuntimeEnvironmentVariables=[{Name=\"DATABASE_URL\",Value=\"$DATABASE_URL\"},{Name=\"NODE_ENV\",Value=\"production\"}]},AutoDeploymentsEnabled=true}" \
  --instance-configuration Cpu=1024,Memory=2048 \
  --health-check-configuration Protocol=HTTP,Path=\"/api/health\",Interval=30,Timeout=5,HealthyThreshold=3,UnhealthyThreshold=5 \
  --region "$AWS_REGION"
```
Notes:
- If the service already exists, use `aws apprunner update-service --service-arn <arn> --source-configuration ...` with the same payload to redeploy a new image.
- App Runner uses the container’s `/api/health` for health checks (see `backend/Dockerfile`).

## Initialize the database once
After the service can reach the database, run the schema/seed scripts against it:
```bash
docker run --rm -e DATABASE_URL="$DATABASE_URL" "$IMAGE_URI" node src/init.js
```

## Environment variables
- `DATABASE_URL` (required): Postgres connection string (use TLS parameters if your RDS instance requires it, e.g. append `?sslmode=require`).
- `PORT` (optional): Defaults to `3001`, but App Runner uses `3001` by default via the image config.
- `NODE_ENV`: set to `production`.

## RDS quick-create (optional)
Example for a small Postgres instance:
```bash
aws rds create-db-instance \
  --db-instance-identifier bpclpos \
  --engine postgres --engine-version 16 \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --master-username bpclpos --master-user-password '<STRONG_PASSWORD>' \
  --publicly-accessible \
  --backup-retention-period 1 \
  --region "$AWS_REGION"
```
Once available, build `DATABASE_URL` with the endpoint returned by RDS.
