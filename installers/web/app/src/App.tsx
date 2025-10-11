import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './App.css';
import ChatPage from './pages/ChatPage';
import SettingsPage from './pages/SettingsPage';
import CodeGenPage from './pages/CodeGenPage';
import Header from './components/Header';
import Navigation from './components/Navigation';

function App() {
  const [sidebarOpen, setSidebarOpen] = useState(true);

  return (
    <Router>
      <div className="app">
        <Header onMenuClick={() => setSidebarOpen(!sidebarOpen)} />
        <div className="app-body">
          <Navigation isOpen={sidebarOpen} />
          <main className="main-content">
            <Routes>
              <Route path="/" element={<Navigate to="/chat" replace />} />
              <Route path="/chat" element={<ChatPage />} />
              <Route path="/codegen" element={<CodeGenPage />} />
              <Route path="/settings" element={<SettingsPage />} />
            </Routes>
          </main>
        </div>
      </div>
    </Router>
  );
}

export default App;
