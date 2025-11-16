# Docker Setup

## Backend Services only

The docker-compose configuration includes:

- **PostgreSQL 14**: Database server (port 5432)
- **Redis 7**: Queue backend for Sidekiq (port 6379)
- **Rails Backend**: API server (port 3000)
- **Sidekiq**: Background job processor

## Quick Start

### 1. Build and start all services

```bash
docker-compose up --build
```

### 2. Access the API

The API will be available at `http://localhost:3000`

Health check endpoint: `http://localhost:3000/health`

### 3. Stop all services

```bash
docker-compose down
```

### 4. Stop and remove volumes (reset data)

```bash
docker-compose down -v
```

## Environment Variables

All services are configured via environment variables in `docker-compose.yml`:

- `DATABASE_HOST=postgres`
- `DATABASE_PORT=5432`
- `DATABASE_NAME=vet_medical_report_development`
- `DATABASE_USER=postgres`
- `DATABASE_PASSWORD=postgres`
- `REDIS_URL=redis://redis:6379/0`
- `GROQ_ENABLED=true`
- `GROQ_API_KEY=your_api_key_here` (**REQUIRED** - Get it from https://console.groq.com/keys)
- `GROQ_API_URL=https://api.groq.com/openai/v1/chat/completions`

### Setting up Groq API

The application uses Groq for fast AI-powered data extraction:

1. Sign up for a free account at https://console.groq.com
2. Get your API key from https://console.groq.com/keys
3. Export it as an environment variable before starting Docker:
   ```bash
   export GROQ_API_KEY=your_actual_api_key_here
   ```
4. Start the services:
   ```bash
   docker-compose up -d
   ```

**Note**: If Groq API is not available or configured, the system automatically falls back to rule-based parsing.

## Useful Commands

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f sidekiq
```

### Access Rails console

```bash
docker-compose exec backend rails console
```

### Run migrations

```bash
docker-compose exec backend rails db:migrate
```

### Run tests

**IMPORTANT**: Tests must be run with `RAILS_ENV=test` and `bundle exec` to ensure:
1. Rails loads in test mode (initializes test configurations including Shoulda::Matchers)
2. Correct gem versions from Gemfile.lock are used
3. Test database is used instead of development database

```bash
# From outside the container (recommended)
docker-compose exec backend bash -c "cd /app && RAILS_ENV=test bundle exec rspec"


# From inside the container
docker exec -it vet_medical_report_backend bash
cd /app
RAILS_ENV=test bundle exec rspec
```

**Common error** ❌: Running just `rspec` or `rspec spec` will fail with:
```
NameError: uninitialized constant Shoulda
```
This happens because Rails is not initialized in test mode.


## Troubleshooting

### Port already in use

If ports 3000, 5432, or 6379 are already in use, you can modify them in `docker-compose.yml`.

### Permission issues

If you encounter permission issues with volumes, ensure Docker has proper access to the project directory.

### Rebuilding containers

If you make changes to Gemfile or Dockerfile:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up
```


