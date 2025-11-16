import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { api } from '../services/api';
import { MedicalRecord } from '../types';
import './MedicalRecordsList.css';

export const MedicalRecordsList: React.FC = () => {
  const [records, setRecords] = useState<MedicalRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  useEffect(() => {
    loadRecords();
  }, []);

  const loadRecords = async () => {
    try {
      setLoading(true);
      const data = await api.getMedicalRecords();
      setRecords(data);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const handleUploadClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      setUploading(true);
      setError('');
      const newRecord = await api.uploadDocument(file);
      setRecords([newRecord, ...records]);
      alert('Document uploaded successfully! Processing will start shortly.');
    } catch (err: any) {
      setError(err.message);
    } finally {
      setUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const getStatusBadge = (status: string) => {
    const badges: Record<string, string> = {
      pending: 'status-badge status-pending',
      processing: 'status-badge status-processing',
      completed: 'status-badge status-completed',
      failed: 'status-badge status-failed',
    };
    return badges[status] || 'status-badge';
  };

  if (loading) {
    return (
      <div className="page-container">
        <div className="loading">Loading medical records...</div>
      </div>
    );
  }

  return (
    <div className="page-container">
      <header className="page-header">
        <div>
          <h1>Medical Records</h1>
          <p>Welcome, {user?.name}</p>
        </div>
        <div className="header-actions">
          <button onClick={handleUploadClick} className="btn-primary" disabled={uploading}>
            {uploading ? 'Uploading...' : '📄 Upload Document'}
          </button>
          <button onClick={handleLogout} className="btn-secondary">
            Logout
          </button>
        </div>
      </header>

      <input
        ref={fileInputRef}
        type="file"
        accept=".pdf,.png,.jpg,.jpeg,.doc,.docx"
        onChange={handleFileChange}
        style={{ display: 'none' }}
      />

      {error && <div className="error-message">{error}</div>}

      {records.length === 0 ? (
        <div className="empty-state">
          <h2>No medical records yet</h2>
          <p>Upload your first veterinary document to get started</p>
          <button onClick={handleUploadClick} className="btn-primary">
            Upload Document
          </button>
        </div>
      ) : (
        <div className="records-grid">
          {records.map((record) => (
            <div
              key={record.id}
              className="record-card"
              onClick={() => navigate(`/records/${record.id}`)}
            >
              <div className="record-header">
                <h3>{record.pet_name || 'Unnamed Pet'}</h3>
                <span className={getStatusBadge(record.status)}>{record.status}</span>
              </div>
              <div className="record-body">
                {record.species && (
                  <p>
                    <strong>Species:</strong> {record.species}
                  </p>
                )}
                {record.breed && (
                  <p>
                    <strong>Breed:</strong> {record.breed}
                  </p>
                )}
                {record.owner_name && (
                  <p>
                    <strong>Owner:</strong> {record.owner_name}
                  </p>
                )}
                {record.original_filename && (
                  <p className="filename">📎 {record.original_filename}</p>
                )}
              </div>
              <div className="record-footer">
                <small>
                  Created: {new Date(record.created_at).toLocaleDateString()}
                </small>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

