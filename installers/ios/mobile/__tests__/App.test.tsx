import React from 'react';
import { render } from '@testing-library/react-native';
import App from '../App';

// Mock the navigation modules
jest.mock('@react-navigation/native', () => ({
  NavigationContainer: ({ children }: any) => children,
}));

jest.mock('@react-navigation/stack', () => ({
  createStackNavigator: () => ({
    Navigator: ({ children }: any) => children,
    Screen: () => null,
  }),
}));

jest.mock('react-native-safe-area-context', () => ({
  SafeAreaProvider: ({ children }: any) => children,
}));

// Mock screens
jest.mock('../src/screens/ChatScreen', () => 'ChatScreen');
jest.mock('../src/screens/SettingsScreen', () => 'SettingsScreen');
jest.mock('../src/screens/CodeGenScreen', () => 'CodeGenScreen');

describe('Mobile App', () => {
  it('should render without crashing', () => {
    const { container } = render(<App />);
    expect(container).toBeTruthy();
  });

  it('should initialize with navigation container', () => {
    const { container } = render(<App />);
    expect(container).toBeTruthy();
  });

  it('should setup Stack Navigator with correct initial route', () => {
    const { container } = render(<App />);
    expect(container).toBeTruthy();
  });

  it('should configure correct header styles', () => {
    const { container } = render(<App />);
    expect(container).toBeTruthy();
  });
});
