# Veterinary Medical Report System

Intelligent processing system for veterinary medical records.

## 🏗️ Architecture

This project follows an **API + SPA** architecture:
- **Backend**: Ruby on Rails 7.1 (API mode) with PostgreSQL
- **Frontend**: React + TypeScript

## 📂 Project Structure

```
vet_medical_report/
├── backend/           # Rails API + Docker setup
├── frontend/          # React SPA
├── README.md          # This file
└── FUTURE_IMPROVEMENTS.md
```

## 📚 Documentation

- **[Backend Documentation](backend/README.md)** - Ruby on Rails API setup and usage
- **[Frontend Documentation](frontend/README.md)** - React application setup and usage
- **[Docker Setup Guide](backend/DOCKER_SETUP.md)** - Full Docker configuration for the backend

## 🚀 Quick Start

### Option 1: Docker (Recommended)

The easiest way to run this project is using Docker. Follow the **[Docker Setup Guide](backend/DOCKER_SETUP.md)** for complete instructions.

Quick start:

```bash
# 1. Set up Groq API key (get it from https://console.groq.com/keys)
export GROQ_API_KEY=your_api_key_here

# 2. Start backend services (PostgreSQL, Redis, Rails, Sidekiq)
cd backend
docker-compose up --build

# 3. In a new terminal, start the frontend
cd frontend
npm install
npm start
```

- Backend API: http://localhost:3000
- Frontend App: http://localhost:3001

### Option 2: Local Development

See individual documentation:
- [Backend Setup](backend/README.md) - Install Ruby, PostgreSQL, Redis
- [Frontend Setup](frontend/README.md) - Install Node.js and dependencies

## 🧪 Testing

### Unit Tests (76 tests)

# Docker (Recommended)
```bash
cd backend
docker-compose exec backend bash -c "cd /app && RAILS_ENV=test bundle exec rspec"
```

# Local
```bash
cd backend
bundle exec rspec

```

### Integration Tests (2 end-to-end tests)


# Docker (Recommended)
```bash
cd backend

# Without Groq (rule-based parsing only) 
docker-compose exec backend ruby script/integration_test_png_without_groq.rb

# With Groq (AI-powered parsing)  
docker-compose exec backend bash -c "GROQ_ENABLED=true ruby script/integration_test_png_with_groq.rb"
```

# Local
```bash
cd backend
ruby script/integration_test_png_without_groq.rb
GROQ_ENABLED=true ruby script/integration_test_png_with_groq.rb
```

## 🔑 Default Credentials

- **Email**: test@example.com
- **Password**: password123

## 🛠️ Tech Stack

### Backend
- Ruby 3.4.5
- Rails 7.1.6 (API mode)
- PostgreSQL 14
- Redis 7
- Sidekiq (background jobs)
- Active Storage (file uploads)
- RSpec (testing)
- Groq AI (intelligent data extraction)

### Frontend
- React 19
- TypeScript
- React Router DOM
- Axios

## 📋 Features

- 🔐 User authentication with JWT Bearer tokens
- 📄 Document upload (PDF, PNG, JPG)
- 🤖 AI-powered data extraction (Groq) with rule-based fallback
- 🔍 OCR support for scanned documents (Tesseract)
- 📋 Structured medical record visualization
- ✏️ Edit and update medical records
- 🔄 Real-time processing status
- 📥 Download original documents

## 📖 API Endpoints

Base URL: `http://localhost:3000/api/v1`

### Authentication
- `POST /auth/register` - Create new user
- `POST /auth/login` - User login
- `GET /auth/me` - Get current user
- `DELETE /auth/logout` - Logout

### Medical Records
- `GET /medical_records` - List all records
- `GET /medical_records/:id` - Get single record
- `POST /medical_records/upload` - Upload document
- `PATCH /medical_records/:id` - Update record

## 🎯 Future Improvements

See [FUTURE_IMPROVEMENTS.md](FUTURE_IMPROVEMENTS.md) for the complete roadmap.

## 📄 License

This project is part of a technical assessment.
