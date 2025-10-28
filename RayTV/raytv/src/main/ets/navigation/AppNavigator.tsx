import React, { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { View, Text, Button } from '@ray-js/components';
import Logger from '../common/util/Logger';
import { subscriptionManager } from '../service/config/SubscriptionManager';
import SubscriptionManagerPage from '../pages/subscription/SubscriptionManagerPage';

// 假设的主页面组件类型定义
interface MainScreenProps {
  navigation: any;
}

// 示例主页面组件
const MainScreen: React.FC<MainScreenProps> = ({ navigation }) => {
  return (
    <View className="main-screen">
      <Text className="title">RayTV 主页面</Text>
      <Button 
        title="配置源管理"
        onPress={() => navigation.navigate('SubscriptionManager')}
      />
      
      <style>
        {
          `.main-screen {
            flex: 1;
            justifyContent: center;
            alignItems: center;
            padding: 20px;
          }
          
          .title {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 40px;
          }
          `
        }
      </style>
    </View>
  );
};

const Stack = createStackNavigator();

// 应用导航组件
const AppNavigator = () => {
  // 初始化订阅管理器
  useEffect(() => {
    const initializeApp = async () => {
      try {
        Logger.info('AppNavigator', 'Initializing application...');
        // 初始化订阅管理器
        await subscriptionManager.initialize();
        Logger.info('AppNavigator', 'Application initialized successfully');
      } catch (error) {
        Logger.error('AppNavigator', `Failed to initialize application: ${error}`);
      }
    };

    initializeApp();
  }, []);

  return (
    <NavigationContainer>
      <Stack.Navigator
        initialRouteName="Main"
        screenOptions={{
          headerStyle: {
            backgroundColor: '#f4511e',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        <Stack.Screen 
          name="Main" 
          component={MainScreen} 
          options={{ title: 'RayTV' }}
        />
        <Stack.Screen 
          name="SubscriptionManager" 
          component={SubscriptionManagerPage} 
          options={{ title: '配置源管理' }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
