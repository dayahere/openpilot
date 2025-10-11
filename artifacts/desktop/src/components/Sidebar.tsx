import React from 'react';
import './Sidebar.css';

interface SidebarProps {
  onNavigate: (view: 'chat' | 'settings') => void;
  currentView: string;
}

const Sidebar: React.FC<SidebarProps> = ({ onNavigate, currentView }) => {
  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <h1>OpenPilot</h1>
      </div>
      
      <nav className="sidebar-nav">
        <button
          className={`nav-item ${currentView === 'chat' ? 'active' : ''}`}
          onClick={() => onNavigate('chat')}
        >
          💬 Chat
        </button>
        <button
          className={`nav-item ${currentView === 'settings' ? 'active' : ''}`}
          onClick={() => onNavigate('settings')}
        >
          ⚙️ Settings
        </button>
      </nav>
    </div>
  );
};

export default Sidebar;
