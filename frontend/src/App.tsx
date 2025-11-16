import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { Login } from './pages/Login';
import { MedicalRecordsList } from './pages/MedicalRecordsList';
import { MedicalRecordDetail } from './pages/MedicalRecordDetail';
import './App.css';

const PrivateRoute: React.FC<{ children: React.ReactElement }> = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return <div className="loading-screen">Loading...</div>;
  }

  return isAuthenticated ? children : <Navigate to="/login" replace />;
};

const PublicRoute: React.FC<{ children: React.ReactElement }> = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return <div className="loading-screen">Loading...</div>;
  }

  return !isAuthenticated ? children : <Navigate to="/records" replace />;
};

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route
            path="/login"
            element={
              <PublicRoute>
                <Login />
              </PublicRoute>
            }
          />
          <Route
            path="/records"
            element={
              <PrivateRoute>
                <MedicalRecordsList />
              </PrivateRoute>
            }
          />
          <Route
            path="/records/:id"
            element={
              <PrivateRoute>
                <MedicalRecordDetail />
              </PrivateRoute>
            }
          />
          <Route path="/" element={<Navigate to="/records" replace />} />
          <Route path="*" element={<Navigate to="/records" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
