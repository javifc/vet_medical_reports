# Veterinary Medical Report System - Backend

Ruby on Rails API for intelligent processing of veterinary medical records.

## 🏗️ Architecture

This is a **Rails API-only application** that:
- Accepts document uploads (PDF, images, Word)
- Extracts text using PDF parsers and OCR (Tesseract)
- Structures medical data using AI (Groq) or rule-based parsing
- Processes documents asynchronously using Sidekiq
- Provides a RESTful API for frontend consumption

## 🚀 Tech Stack

- **Ruby** 3.4.5
- **Rails** 7.1.6 (API mode)
- **PostgreSQL** 14 - Database
- **Redis** 7 - Queue backend
- **Sidekiq** - Background job processing
- **Active Storage** - File uploads
- **Doorkeeper** - OAuth2 authentication
- **Groq AI** - Intelligent data extraction
- **Tesseract OCR** - Text extraction from images
- **RSpec** - Testing framework
- **RuboCop** - Code linter

## 📋 Requirements

### Local Development
- Ruby 3.4.5
- PostgreSQL 14+
- Redis 7+
- Tesseract OCR
- Bundler

### Docker (Recommended)
- Docker Desktop or OrbStack
- Docker Compose

## ⚙️ Installation

### Option 1: Docker (Recommended)

See **[DOCKER_SETUP.md](DOCKER_SETUP.md)** for complete Docker instructions.

Quick start:

```bash
# Set up environment variables
export GROQ_API_KEY=your_api_key_here

# Start all services
docker-compose up --build

# Run migrations (first time only)
docker-compose exec backend rails db:migrate
docker-compose exec backend rails db:seed
```

### Option 2: Local Development

1. Install dependencies:
```bash
bundle install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env and add your GROQ_API_KEY
```

3. Create and configure database:
```bash
rails db:create
rails db:migrate
rails db:seed
```

4. Start Redis (required for Sidekiq):
```bash
redis-server
```

5. Start Sidekiq (in a separate terminal):
```bash
bundle exec sidekiq
```

6. Start the Rails server:
```bash
rails server
```

The API will be available at: `http://localhost:3000`

## 🧪 Testing

### Run all tests

```bash
bundle exec rspec
```

### Run specific test files

```bash
bundle exec rspec spec/models/medical_record_spec.rb
bundle exec rspec spec/services/medical_data_parser_service_spec.rb
```

### Run integration tests

```bash
# Without Groq (rule-based only)
ruby script/integration_test_png_without_groq.rb

# With Groq (AI-powered)
GROQ_ENABLED=true ruby script/integration_test_png_with_groq.rb
```

### Test Coverage

- **76 unit tests** (models, services, controllers)
- **2 integration tests** (end-to-end document processing)

### Testing with Docker

```bash
docker-compose exec backend bash -c "cd /app && RAILS_ENV=test bundle exec rspec"
```

## 📡 API Endpoints

### Health Check

**GET** `/health`

```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "ok",
  "message": "Veterinary Medical Report API is running",
  "timestamp": "2025-11-16T10:30:00Z",
  "environment": "development"
}
```

### Authentication

Base URL: `/api/v1/auth`

- **POST** `/register` - Create new user
- **POST** `/login` - User login (returns Bearer token)
- **GET** `/me` - Get current user (protected)
- **DELETE** `/logout` - Logout (protected)

### Medical Records

Base URL: `/api/v1/medical_records`

All endpoints require Bearer token authentication.

- **GET** `/` - List all medical records for current user
- **GET** `/:id` - Get single medical record
- **POST** `/upload` - Upload a document and create a medical record
- **PATCH** `/:id` - Update medical record fields

### Example: Upload Document

```bash
curl -X POST http://localhost:3000/api/v1/medical_records/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "document=@path/to/medical_record.pdf"
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file (see `.env.example`):

```bash
# Groq AI Configuration
GROQ_ENABLED=true
GROQ_API_KEY=your_api_key_here
GROQ_API_URL=https://api.groq.com/openai/v1/chat/completions

# Database (only for local development)
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=vet_medical_report_development
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres

# Redis (only for local development)
REDIS_URL=redis://localhost:6379/0
```

### Groq API Setup

1. Sign up at https://console.groq.com
2. Get your API key from https://console.groq.com/keys
3. Add it to your `.env` file or export it:
   ```bash
   export GROQ_API_KEY=your_api_key_here
   ```

**Note**: If Groq is not available, the system automatically falls back to rule-based parsing.

## 📂 Project Structure

```
backend/
├── app/
│   ├── blueprints/          # JSON serializers
│   ├── controllers/         # API controllers
│   ├── jobs/                # Background jobs
│   ├── models/              # ActiveRecord models
│   └── services/            # Business logic
│       ├── groq_structuring_service.rb
│       ├── rule_based_parser_service.rb
│       ├── medical_data_parser_service.rb
│       └── text_extraction_service.rb
├── config/
│   ├── database.yml
│   ├── routes.rb
│   └── initializers/
├── db/
│   ├── migrate/
│   └── seeds.rb
├── lib/
│   └── groq_client.rb       # Reusable Groq API client
├── spec/                    # RSpec tests
│   ├── models/
│   ├── services/
│   ├── requests/
│   └── factories/
├── script/                  # Integration test scripts
├── docker-compose.yml
├── Dockerfile
└── Gemfile
```

## 🔄 Background Processing

Documents are processed asynchronously using **Sidekiq**:

1. User uploads document → `MedicalRecord` created (status: `pending`)
2. `ProcessMedicalRecordJob` is enqueued
3. Job extracts text from document (PDF parser or OCR)
4. Job structures data (Groq AI or rule-based parser)
5. `MedicalRecord` updated (status: `completed` or `failed`)

### Monitor Sidekiq

If running locally with Redis:
```bash
bundle exec sidekiq
```

If using Docker, Sidekiq is already running as a separate service.

## 🤖 AI-Powered Data Extraction

The system uses **Groq AI** (ultra-fast LLM inference) for intelligent data extraction:

- **Primary**: Groq AI with `llama-3.1-8b-instant` model
- **Fallback**: Rule-based parser with regex patterns
- **OCR Support**: Handles scanned documents with Tesseract

### Data Extraction Flow

```
Document Upload
    ↓
Text Extraction (PDF/OCR)
    ↓
MedicalDataParserService (Orchestrator)
    ↓
    ├── Groq available? → GroqStructuringService → Structured Data
    │   └── Insufficient fields? → RuleBasedParserService → Structured Data
    └── Groq unavailable? → RuleBasedParserService → Structured Data
```

## 🧹 Code Quality

### RuboCop

Run RuboCop to check code style:

```bash
bundle exec rubocop

# Auto-fix offenses
bundle exec rubocop -A
```

### Linting

```bash
bundle exec rubocop -a
```

## 🐛 Debugging

### View logs

**Docker**:
```bash
docker-compose logs -f backend
docker-compose logs -f sidekiq
```

**Local**:
```bash
tail -f log/development.log
```

### Rails console

**Docker**:
```bash
docker-compose exec backend rails console
```

**Local**:
```bash
rails console
```

## 📊 Database

### Migrations

```bash
rails db:migrate
```

### Seed data

```bash
rails db:seed
```

This creates a default user:
- **Email**: test@example.com
- **Password**: password123

### Reset database

```bash
rails db:reset
```

## 🔐 Authentication

The API uses **Doorkeeper** for OAuth2 Bearer token authentication:

1. Register or login → Receive Bearer token
2. Include token in `Authorization` header for protected endpoints
3. Token is stored in `oauth_access_tokens` table
4. Logout revokes the token

## 🌍 CORS Configuration

CORS is configured in `config/initializers/cors.rb`:

- Allowed origins: `localhost:3001`, `127.0.0.1:3001` (frontend)
- Allowed methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
- Allowed headers: All

## 📖 Additional Documentation

- **[DOCKER_SETUP.md](DOCKER_SETUP.md)** - Comprehensive Docker setup guide
- **[FUTURE_IMPROVEMENTS.md](../FUTURE_IMPROVEMENTS.md)** - Roadmap for future enhancements

## 🤝 Contributing

This project follows:
- TDD (Test-Driven Development)
- Clean Architecture principles
- SOLID principles
- Rails best practices

All code is written in English, including:
- Variable names
- Comments
- Commit messages
- Documentation
