import React from 'react';

interface HeaderProps {
  onMenuClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
  return (
    <header className="app-header">
      <button className="menu-button" onClick={onMenuClick}>
        ☰
      </button>
      <h1>OpenPilot Web</h1>
      <div className="header-actions">
        <span className="version">v1.0.0</span>
      </div>
    </header>
  );
};

export default Header;
