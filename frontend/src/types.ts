export interface User {
  id: number;
  name: string;
  email: string;
  created_at: string;
}

export interface AuthResponse {
  user: User;
  token: string;
  token_type: string;
  expires_in: number;
}

export interface MedicalRecord {
  id: number;
  pet_name: string | null;
  species: string | null;
  breed: string | null;
  age: string | null;
  owner_name: string | null;
  diagnosis: string | null;
  treatment: string | null;
  notes: string | null;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  original_filename: string | null;
  document_url: string | null;
  raw_text: string | null;
  structured_data: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  name: string;
  email: string;
  password: string;
  password_confirmation: string;
}

export interface UpdateMedicalRecordData {
  pet_name?: string;
  species?: string;
  breed?: string;
  age?: string;
  owner_name?: string;
  diagnosis?: string;
  treatment?: string;
  notes?: string;
}

