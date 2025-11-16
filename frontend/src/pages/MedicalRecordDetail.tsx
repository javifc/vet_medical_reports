import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api } from '../services/api';
import { MedicalRecord, UpdateMedicalRecordData } from '../types';
import './MedicalRecordDetail.css';

export const MedicalRecordDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [record, setRecord] = useState<MedicalRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [editing, setEditing] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState<UpdateMedicalRecordData>({});
  const navigate = useNavigate();

  useEffect(() => {
    loadRecord();
  }, [id]);

  const loadRecord = async () => {
    if (!id) return;
    
    try {
      setLoading(true);
      const data = await api.getMedicalRecord(parseInt(id));
      setRecord(data);
      setFormData({
        pet_name: data.pet_name || '',
        species: data.species || '',
        breed: data.breed || '',
        age: data.age || '',
        owner_name: data.owner_name || '',
        diagnosis: data.diagnosis || '',
        treatment: data.treatment || '',
        notes: data.notes || '',
      });
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!id) return;

    try {
      setSaving(true);
      setError('');
      const updated = await api.updateMedicalRecord(parseInt(id), formData);
      setRecord(updated);
      setEditing(false);
      alert('Medical record updated successfully!');
    } catch (err: any) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleCancel = () => {
    if (record) {
      setFormData({
        pet_name: record.pet_name || '',
        species: record.species || '',
        breed: record.breed || '',
        age: record.age || '',
        owner_name: record.owner_name || '',
        diagnosis: record.diagnosis || '',
        treatment: record.treatment || '',
        notes: record.notes || '',
      });
    }
    setEditing(false);
  };

  if (loading) {
    return (
      <div className="page-container">
        <div className="loading">Loading medical record...</div>
      </div>
    );
  }

  if (!record) {
    return (
      <div className="page-container">
        <div className="error-message">Medical record not found</div>
        <button onClick={() => navigate('/records')} className="btn-primary">
          Back to Records
        </button>
      </div>
    );
  }

  return (
    <div className="page-container">
      <div className="detail-header">
        <button onClick={() => navigate('/records')} className="btn-back">
          ← Back to Records
        </button>
        <div className="detail-actions">
          {!editing ? (
            <button onClick={() => setEditing(true)} className="btn-primary">
              Edit
            </button>
          ) : (
            <>
              <button onClick={handleCancel} className="btn-secondary">
                Cancel
              </button>
              <button onClick={handleSave} className="btn-primary" disabled={saving}>
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </>
          )}
        </div>
      </div>

      {error && <div className="error-message">{error}</div>}

      <div className="detail-card">
        <div className="detail-section">
          <h2>Patient Information</h2>
          <div className="detail-grid">
            <div className="detail-field">
              <label>Pet Name</label>
              {editing ? (
                <input
                  type="text"
                  value={formData.pet_name}
                  onChange={(e) => setFormData({ ...formData, pet_name: e.target.value })}
                />
              ) : (
                <p>{record.pet_name || '—'}</p>
              )}
            </div>

            <div className="detail-field">
              <label>Species</label>
              {editing ? (
                <input
                  type="text"
                  value={formData.species}
                  onChange={(e) => setFormData({ ...formData, species: e.target.value })}
                />
              ) : (
                <p>{record.species || '—'}</p>
              )}
            </div>

            <div className="detail-field">
              <label>Breed</label>
              {editing ? (
                <input
                  type="text"
                  value={formData.breed}
                  onChange={(e) => setFormData({ ...formData, breed: e.target.value })}
                />
              ) : (
                <p>{record.breed || '—'}</p>
              )}
            </div>

            <div className="detail-field">
              <label>Age</label>
              {editing ? (
                <input
                  type="text"
                  value={formData.age}
                  onChange={(e) => setFormData({ ...formData, age: e.target.value })}
                />
              ) : (
                <p>{record.age || '—'}</p>
              )}
            </div>

            <div className="detail-field">
              <label>Owner Name</label>
              {editing ? (
                <input
                  type="text"
                  value={formData.owner_name}
                  onChange={(e) => setFormData({ ...formData, owner_name: e.target.value })}
                />
              ) : (
                <p>{record.owner_name || '—'}</p>
              )}
            </div>
          </div>
        </div>

        <div className="detail-section">
          <h2>Medical Information</h2>
          
          <div className="detail-field">
            <label>Diagnosis</label>
            {editing ? (
              <textarea
                rows={4}
                value={formData.diagnosis}
                onChange={(e) => setFormData({ ...formData, diagnosis: e.target.value })}
              />
            ) : (
              <p className="preserve-whitespace">{record.diagnosis || '—'}</p>
            )}
          </div>

          <div className="detail-field">
            <label>Treatment</label>
            {editing ? (
              <textarea
                rows={4}
                value={formData.treatment}
                onChange={(e) => setFormData({ ...formData, treatment: e.target.value })}
              />
            ) : (
              <p className="preserve-whitespace">{record.treatment || '—'}</p>
            )}
          </div>

          <div className="detail-field">
            <label>Additional Notes</label>
            {editing ? (
              <textarea
                rows={3}
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              />
            ) : (
              <p className="preserve-whitespace">{record.notes || '—'}</p>
            )}
          </div>
        </div>

        {record.raw_text && (
          <div className="detail-section">
            <h2>Extracted Text</h2>
            <div className="detail-field">
              <div className="raw-text-container">
                <pre className="raw-text">{record.raw_text}</pre>
              </div>
            </div>
          </div>
        )}

        <div className="detail-section">
          <h2>Document Information</h2>
          <div className="detail-grid">
            <div className="detail-field">
              <label>Status</label>
              <p>
                <span className={`status-badge status-${record.status}`}>
                  {record.status}
                </span>
              </p>
            </div>

            {record.original_filename && (
              <div className="detail-field">
                <label>Original File</label>
                {record.document_url ? (
                  <p>
                    <a 
                      href={`http://localhost:3000${record.document_url}`} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="document-link"
                    >
                      📎 {record.original_filename} ⬇️
                    </a>
                  </p>
                ) : (
                  <p>📎 {record.original_filename}</p>
                )}
              </div>
            )}

            <div className="detail-field">
              <label>Created</label>
              <p>{new Date(record.created_at).toLocaleString()}</p>
            </div>

            <div className="detail-field">
              <label>Last Updated</label>
              <p>{new Date(record.updated_at).toLocaleString()}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

