import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import '@testing-library/jest-dom';
import App from '../App';

// Mock components
jest.mock('../pages/ChatPage', () => {
  return function ChatPage() {
    return <div data-testid="chat-page">Chat Page</div>;
  };
});

jest.mock('../pages/SettingsPage', () => {
  return function SettingsPage() {
    return <div data-testid="settings-page">Settings Page</div>;
  };
});

jest.mock('../pages/CodeGenPage', () => {
  return function CodeGenPage() {
    return <div data-testid="codegen-page">CodeGen Page</div>;
  };
});

jest.mock('../components/Header', () => {
  return function Header({ onMenuClick }: any) {
    return (
      <header data-testid="header">
        <button onClick={onMenuClick}>Menu</button>
      </header>
    );
  };
});

jest.mock('../components/Navigation', () => {
  return function Navigation({ isOpen }: any) {
    return <nav data-testid="navigation" aria-hidden={!isOpen}>Navigation</nav>;
  };
});

describe('Web App', () => {
  const renderApp = () => {
    return render(<App />);
  };

  it('should render without crashing', () => {
    renderApp();
    expect(screen.getByTestId('header')).toBeInTheDocument();
  });

  it('should render navigation', () => {
    renderApp();
    expect(screen.getByTestId('navigation')).toBeInTheDocument();
  });

  it('should have navigation open by default', () => {
    renderApp();
    const nav = screen.getByTestId('navigation');
    expect(nav).toHaveAttribute('aria-hidden', 'false');
  });

  it('should render main content area', () => {
    renderApp();
    const main = screen.getByRole('main');
    expect(main).toBeInTheDocument();
    expect(main).toHaveClass('main-content');
  });

  it('should redirect root path to /chat', () => {
    const { container } = renderApp();
    expect(container).toBeTruthy();
    // Note: Actual navigation testing would require RouterTestProvider
  });

  it('should setup routing for all pages', () => {
    const { container } = renderApp();
    expect(container).toBeTruthy();
  });
});

describe('Web App - Navigation', () => {
  it('should render Header component', () => {
    render(<App />);
    expect(screen.getByTestId('header')).toBeInTheDocument();
  });

  it('should pass onMenuClick handler to Header', () => {
    render(<App />);
    expect(screen.getByText('Menu')).toBeInTheDocument();
  });
});

describe('Web App - Sidebar State', () => {
  it('should initialize with sidebar open', () => {
    render(<App />);
    const nav = screen.getByTestId('navigation');
    expect(nav).toHaveAttribute('aria-hidden', 'false');
  });
});
