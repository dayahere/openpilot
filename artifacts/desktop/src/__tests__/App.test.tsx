import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from '../App';

// Mock components
jest.mock('../components/ChatInterface', () => {
  return function ChatInterface() {
    return <div data-testid="chat-interface">Chat Interface</div>;
  };
});

jest.mock('../components/Settings', () => {
  return function Settings() {
    return <div data-testid="settings">Settings</div>;
  };
});

jest.mock('../components/Sidebar', () => {
  return function Sidebar({ onNavigate, currentView }: any) {
    return (
      <div data-testid="sidebar">
        <button onClick={() => onNavigate('chat')}>Chat</button>
        <button onClick={() => onNavigate('settings')}>Settings</button>
        <div>Current: {currentView}</div>
      </div>
    );
  };
});

describe('Desktop App', () => {
  it('should render without crashing', () => {
    render(<App />);
    expect(screen.getByTestId('sidebar')).toBeInTheDocument();
  });

  it('should display Chat view by default', () => {
    render(<App />);
    expect(screen.getByTestId('chat-interface')).toBeInTheDocument();
    expect(screen.queryByTestId('settings')).not.toBeInTheDocument();
  });

  it('should switch to Settings view when navigated', () => {
    render(<App />);
    const settingsButton = screen.getByText('Settings');
    fireEvent.click(settingsButton);
    expect(screen.getByTestId('settings')).toBeInTheDocument();
    expect(screen.queryByTestId('chat-interface')).not.toBeInTheDocument();
  });

  it('should switch back to Chat view', () => {
    render(<App />);
    const settingsButton = screen.getByText('Settings');
    fireEvent.click(settingsButton);
    const chatButton = screen.getByText('Chat');
    fireEvent.click(chatButton);
    expect(screen.getByTestId('chat-interface')).toBeInTheDocument();
    expect(screen.queryByTestId('settings')).not.toBeInTheDocument();
  });

  it('should pass currentView to Sidebar', () => {
    render(<App />);
    expect(screen.getByText('Current: chat')).toBeInTheDocument();
  });

  it('should update currentView when navigating', () => {
    render(<App />);
    const settingsButton = screen.getByText('Settings');
    fireEvent.click(settingsButton);
    expect(screen.getByText('Current: settings')).toBeInTheDocument();
  });
});
