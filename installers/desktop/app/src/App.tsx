import React, { useState } from 'react';
import './App.css';
import ChatInterface from './components/ChatInterface';
import Settings from './components/Settings';
import Sidebar from './components/Sidebar';

function App() {
  const [currentView, setCurrentView] = useState<'chat' | 'settings'>('chat');

  return (
    <div className="app">
      <Sidebar onNavigate={setCurrentView} currentView={currentView} />
      <div className="main-content">
        {currentView === 'chat' && <ChatInterface />}
        {currentView === 'settings' && <Settings />}
      </div>
    </div>
  );
}

export default App;
