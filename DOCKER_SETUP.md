# Docker Setup

## Services

The docker-compose configuration includes:

- **PostgreSQL 14**: Database server (port 5432)
- **Redis 7**: Queue backend for Sidekiq (port 6379)
- **Ollama**: Local LLM server (port 11434)
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
- `OLLAMA_URL=http://ollama:11434` (currently disabled)
- `GROQ_API_KEY=your_api_key_here` (**REQUIRED** - Get from https://console.groq.com/keys)
- `GROQ_API_URL=https://api.groq.com/openai/v1/chat/completions`

### Setting up Groq API

The application now uses Groq for fast AI-powered data extraction:

1. Sign up for a free account at https://console.groq.com
2. Get your API key from https://console.groq.com/keys
3. Add it to `docker-compose.yml` in the `backend` service environment:
   ```yaml
   environment:
     - GROQ_API_KEY=your_actual_api_key_here
   ```
4. Restart the backend service:
   ```bash
   docker-compose restart backend sidekiq
   ```

**Note**: Ollama code is kept for reference but currently disabled in favor of Groq for better performance.

## Local Development (without Docker)

If you prefer to run services locally:

1. Install PostgreSQL, Redis locally
2. Set environment variables or use defaults (localhost)
3. Start Rails: `bundle exec rails s`
4. Start Sidekiq: `bundle exec sidekiq`

The configuration in `database.yml` and `sidekiq.rb` will fall back to localhost defaults.

## Ollama Models

After starting Ollama container, you need to pull a model:

```bash
docker exec -it vet_medical_report_ollama ollama pull llama3
```

Or use any other model available in Ollama registry.

## Useful Commands

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f sidekiq
docker-compose logs -f ollama
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

```bash
docker-compose exec backend rspec
```

### Access PostgreSQL

```bash
docker-compose exec postgres psql -U postgres -d vet_medical_report_development
```

### Access Redis CLI

```bash
docker-compose exec redis redis-cli
```

## Volumes

The following volumes are created to persist data:

- `postgres_data`: PostgreSQL database files
- `redis_data`: Redis persistence files
- `ollama_data`: Ollama models and configuration
- `bundle_cache`: Ruby gems cache

## Troubleshooting

### Port already in use

If ports 3000, 5432, 6379, or 11434 are already in use, you can modify them in `docker-compose.yml`.

### Permission issues

If you encounter permission issues with volumes, ensure Docker has proper access to the project directory.

### Rebuilding containers

If you make changes to Gemfile or Dockerfile:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up
```


