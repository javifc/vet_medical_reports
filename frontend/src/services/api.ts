import {
  AuthResponse,
  LoginCredentials,
  MedicalRecord,
  RegisterData,
  UpdateMedicalRecordData,
  User,
} from '../types';

const API_URL = 'http://localhost:3000/api/v1';

class ApiService {
  private getHeaders(authenticated: boolean = false): HeadersInit {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      const token = localStorage.getItem('token');
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
    }

    return headers;
  }

  // Auth endpoints
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const response = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: this.getHeaders(false),
      body: JSON.stringify(credentials),
    });

    if (!response.ok) {
      throw new Error('Invalid email or password');
    }

    return response.json();
  }

  async register(data: RegisterData): Promise<AuthResponse> {
    const response = await fetch(`${API_URL}/auth/register`, {
      method: 'POST',
      headers: this.getHeaders(false),
      body: JSON.stringify({ user: data }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.errors?.join(', ') || 'Registration failed');
    }

    return response.json();
  }

  async getCurrentUser(): Promise<{ user: User }> {
    const response = await fetch(`${API_URL}/auth/me`, {
      method: 'GET',
      headers: this.getHeaders(true),
    });

    if (!response.ok) {
      throw new Error('Failed to get current user');
    }

    return response.json();
  }

  async logout(): Promise<void> {
    const response = await fetch(`${API_URL}/auth/logout`, {
      method: 'DELETE',
      headers: this.getHeaders(true),
    });

    if (!response.ok) {
      throw new Error('Logout failed');
    }
  }

  // Medical Records endpoints
  async getMedicalRecords(): Promise<MedicalRecord[]> {
    const response = await fetch(`${API_URL}/medical_records`, {
      method: 'GET',
      headers: this.getHeaders(true),
    });

    if (!response.ok) {
      throw new Error('Failed to fetch medical records');
    }

    return response.json();
  }

  async getMedicalRecord(id: number): Promise<MedicalRecord> {
    const response = await fetch(`${API_URL}/medical_records/${id}`, {
      method: 'GET',
      headers: this.getHeaders(true),
    });

    if (!response.ok) {
      throw new Error('Failed to fetch medical record');
    }

    const data = await response.json();
    // Blueprinter returns the object directly, not wrapped
    return data;
  }

  async uploadDocument(file: File): Promise<MedicalRecord> {
    const token = localStorage.getItem('token');
    const formData = new FormData();
    formData.append('document', file);

    const response = await fetch(`${API_URL}/medical_records/upload`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Upload failed');
    }

    return response.json();
  }

  async updateMedicalRecord(
    id: number,
    data: UpdateMedicalRecordData
  ): Promise<MedicalRecord> {
    const response = await fetch(`${API_URL}/medical_records/${id}`, {
      method: 'PATCH',
      headers: this.getHeaders(true),
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.errors?.join(', ') || 'Update failed');
    }

    return response.json();
  }
}

export const api = new ApiService();

