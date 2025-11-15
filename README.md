# Veterinary Medical Report System

Sistema inteligente de procesamiento de historiales médicos veterinarios.

## 🏗️ Arquitectura

Este proyecto sigue una arquitectura **API + SPA**:
- **Backend**: Ruby on Rails 7.1 (API mode) con PostgreSQL
- **Frontend**: React + TypeScript (próximamente)

## 📂 Estructura del Proyecto

```
vet_medical_report/
├── backend/           # Rails API
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   └── ...
│   ├── config/
│   ├── db/
│   └── Gemfile
└── README.md
```

## 🚀 Stack Tecnológico

### Backend
- Ruby 3.4.5
- Rails 7.1.6 (API mode)
- PostgreSQL
- RSpec (testing)
- Active Storage (file uploads)

## 📋 Requisitos

- Ruby 3.4.5
- PostgreSQL
- Bundler

## ⚙️ Instalación y Configuración

### Backend

1. Navegar al directorio backend:
```bash
cd backend
```

2. Instalar dependencias:
```bash
bundle install
```

3. Configurar la base de datos:
```bash
rails db:create
rails db:migrate
```

4. Iniciar el servidor:
```bash
rails server -p 3001
```

El API estará disponible en: `http://localhost:3001`

## 🧪 Testing

Para ejecutar los tests:
```bash
cd backend
bundle exec rspec
```

## 📡 API Endpoints

### Health Check
- **GET** `/health` - Verifica que el API está funcionando

```bash
curl http://localhost:3001/health
```

Respuesta:
```json
{
  "status": "ok",
  "message": "Veterinary Medical Report API is running",
  "timestamp": "2025-11-15T14:10:11Z",
  "environment": "development"
}
```

### API v1 (en desarrollo)
Base URL: `/api/v1`

## 🎯 Roadmap

- [x] Setup inicial Rails API
- [x] Configuración PostgreSQL
- [x] Health check endpoint
- [x] CORS configurado para frontend
- [ ] Modelo MedicalRecord
- [ ] Active Storage para documentos
- [ ] Extracción de texto (PDF, imágenes)
- [ ] Procesamiento inteligente con IA
- [ ] Frontend React

## 📝 Notas de Desarrollo

### Rails API Mode
Este proyecto usa Rails en modo API (`--api`), lo que significa:
- Solo controladores y modelos, sin vistas
- `ApplicationController` hereda de `ActionController::API`
- Sin assets pipeline, helpers, o sistema de vistas
- Respuestas únicamente en JSON

### CORS
Configurado para permitir peticiones desde:
- `localhost:3000` (Create React App)
- `localhost:5173` (Vite)

## 👥 Contribuir

Este proyecto se desarrolla de manera incremental, siguiendo las mejores prácticas de ingeniería de software y TDD (Test-Driven Development).
