import React from 'react';
import { Link, useLocation } from 'react-router-dom';

interface NavigationProps {
  isOpen: boolean;
}

const Navigation: React.FC<NavigationProps> = ({ isOpen }) => {
  const location = useLocation();

  const navItems = [
    { path: '/chat', label: 'Chat', icon: '💬' },
    { path: '/codegen', label: 'Code Generation', icon: '⚙️' },
    { path: '/settings', label: 'Settings', icon: '⚙️' },
  ];

  return (
    <nav className={`navigation ${isOpen ? 'open' : 'closed'}`}>
      <ul>
        {navItems.map((item) => (
          <li key={item.path} className={location.pathname === item.path ? 'active' : ''}>
            <Link to={item.path}>
              <span className="icon">{item.icon}</span>
              <span className="label">{item.label}</span>
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
};

export default Navigation;
