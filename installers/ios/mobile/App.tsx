import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import ChatScreen from './src/screens/ChatScreen';
import SettingsScreen from './src/screens/SettingsScreen';
import CodeGenScreen from './src/screens/CodeGenScreen';

const Stack = createStackNavigator();

const App = () => {
  return (
    <SafeAreaProvider>
      <NavigationContainer>
        <Stack.Navigator
          initialRouteName="Chat"
          screenOptions={{
            headerStyle: {
              backgroundColor: '#252526',
            },
            headerTintColor: '#d4d4d4',
            headerTitleStyle: {
              fontWeight: 'bold',
            },
          }}
        >
          <Stack.Screen 
            name="Chat" 
            component={ChatScreen}
            options={{ title: 'OpenPilot Chat' }}
          />
          <Stack.Screen 
            name="CodeGen" 
            component={CodeGenScreen}
            options={{ title: 'Code Generator' }}
          />
          <Stack.Screen 
            name="Settings" 
            component={SettingsScreen}
            options={{ title: 'Settings' }}
          />
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
};

export default App;
