# Docker Setup

## Services

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
- `GROQ_API_KEY=your_api_key_here` (**REQUIRED** - Get from https://console.groq.com/keys)
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

## Local Development (without Docker)

### Why Tests Don't Work Outside Docker

When you try to run tests outside Docker, you'll likely encounter errors because the local environment is missing critical dependencies and configuration that Docker provides automatically:

**Missing Requirements**:
1. **PostgreSQL** with specific configuration:
   - Database: `vet_medical_report_test`
   - User: `postgres`
   - Password: `postgres`
   - Host: `localhost`
   - Port: `5432`

2. **Redis** running on `localhost:6379` (for Sidekiq background jobs)

3. **Tesseract OCR** installed with language packs:
   - `tesseract-ocr`
   - `tesseract-ocr-eng` (English)
   - `tesseract-ocr-spa` (Spanish)
   - `tesseract-ocr-fra` (French)
   - `tesseract-ocr-por` (Portuguese)
   - `tesseract-ocr-ita` (Italian)

4. **Environment Variables**:
   - `GROQ_API_KEY` (for AI-powered extraction)
   - `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, etc.

5. **Ruby gems** installed locally with `bundle install`

### If You Still Want to Run Locally

1. Install PostgreSQL and create the test database:
   ```bash
   createdb vet_medical_report_test
   ```

2. Install Redis:
   ```bash
   # macOS
   brew install redis
   brew services start redis
   ```

3. Install Tesseract with language packs:
   ```bash
   # macOS
   brew install tesseract tesseract-lang
   ```

4. Install gems:
   ```bash
   cd backend
   bundle install
   ```

5. Set environment variables in `.env` or export them:
   ```bash
   export DATABASE_HOST=localhost
   export DATABASE_PORT=5432
   export DATABASE_NAME=vet_medical_report_development
   export DATABASE_USER=postgres
   export DATABASE_PASSWORD=postgres
   export REDIS_URL=redis://localhost:6379/0
   export GROQ_API_KEY=your_api_key_here
   ```

6. Run migrations:
   ```bash
   cd backend
   RAILS_ENV=test bundle exec rails db:create db:migrate
   ```

7. Run tests:
   ```bash
   cd backend
   RAILS_ENV=test bundle exec rspec
   ```

**Recommendation**: Use Docker for development and testing. It's much simpler and ensures consistency across all environments.

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

# Or with detailed output
docker-compose exec backend bash -c "cd /app && RAILS_ENV=test bundle exec rspec --format documentation"

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
- `storage_data`: Active Storage files (uploaded documents)

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


