# Vet Medical Report - Frontend

React + TypeScript frontend for the Veterinary Medical Report system.

## Features

- 🔐 User authentication with JWT Bearer tokens
- 📄 Upload medical documents (PDF, PNG, JPG, DOC, DOCX)
- 📋 View list of all medical records
- 👁️ View detailed information for each record
- ✏️ Edit structured medical data
- 🔄 Real-time status updates (pending, processing, completed, failed)

## Tech Stack

- React 19
- TypeScript
- React Router DOM
- CSS3 (no UI framework for simplicity)

## Getting Started

### Prerequisites

- Node.js 16+
- Backend API running on http://localhost:3000

### Installation

```bash
npm install
```

### Development

Start the development server (runs on port 3001):

```bash
npm start
```

Or explicitly set the port:

```bash
PORT=3001 npm start
```

The app will open automatically in your browser at http://localhost:3001

### Build for Production

```bash
npm run build
```

## Project Structure

```
src/
├── contexts/
│   └── AuthContext.tsx       # Authentication context and hooks
├── pages/
│   ├── Login.tsx             # Login screen
│   ├── MedicalRecordsList.tsx # List all records + upload
│   └── MedicalRecordDetail.tsx # View/edit individual record
├── services/
│   └── api.ts                # API client for backend communication
├── types.ts                  # TypeScript interfaces
├── App.tsx                   # Main app with routing
└── index.tsx                 # Entry point
```

## Usage

### Login

Default credentials:
- **Email**: test@example.com
- **Password**: password123

### Upload Documents

1. Click "Upload Document" button
2. Select a file (PDF, PNG, JPG, DOC, DOCX)
3. Document will be uploaded and processing starts automatically
4. New record appears in the list

### View Records

- All records are displayed in a grid
- Click any card to view details
- Status badge shows current processing state

### Edit Records

1. Open a record detail
2. Click "Edit" button
3. Modify any field
4. Click "Save Changes"

## API Integration

The frontend communicates with the backend API at http://localhost:3000/api/v1

Endpoints used:
- `POST /auth/login` - User login
- `GET /auth/me` - Get current user
- `DELETE /auth/logout` - Logout
- `GET /medical_records` - List all records
- `GET /medical_records/:id` - Get single record
- `POST /medical_records/upload` - Upload document
- `PATCH /medical_records/:id` - Update record

## Authentication

JWT Bearer tokens are used for authentication:
- Stored in localStorage after login
- Sent in Authorization header for protected endpoints
- Cleared on logout

## Notes

- No testing framework included (as per requirements)
- Backend must be running on port 3000
- Frontend runs on port 3001 to avoid conflicts
- CORS is handled by the backend
