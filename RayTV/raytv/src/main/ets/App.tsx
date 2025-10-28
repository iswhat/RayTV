// 应用入口文件
// 初始化应用、配置路由和全局状态管理

import React, { useState, useEffect } from 'react';
import { StatusBar, SafeAreaView } from '@tarojs/components';
import { useRouter } from '@tarojs/taro';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import { AppNavigator } from './navigation/AppNavigator';
import MainPage from './pages/MainPage';
import VideoPlayPage from './pages/VideoPlayPage';
import SearchPage from './pages/SearchPage';
import SettingsPage from './pages/SettingsPage';
import { ConfigService } from './service/config/ConfigService';
import { CrawlerService } from './service/spider/CrawlerService';
import { HttpService } from './service/HttpService';
import { AnalyticsService } from './service/analytics/AnalyticsService';
import './styles/global.less';

// 应用状态类型定义
interface AppState {
  isInitialized: boolean;
  theme: string;
  language: string;
  userInfo: any | null;
}

// 初始状态
const initialState: AppState = {
  isInitialized: false,
  theme: 'system',
  language: 'auto',
  userInfo: null
};

// Action类型
type AppAction =
  | { type: 'SET_INITIALIZED'; payload: boolean }
  | { type: 'SET_THEME'; payload: string }
  | { type: 'SET_LANGUAGE'; payload: string }
  | { type: 'SET_USER_INFO'; payload: any };

// Reducer
function appReducer(state: AppState = initialState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_INITIALIZED':
      return { ...state, isInitialized: action.payload };
    case 'SET_THEME':
      return { ...state, theme: action.payload };
    case 'SET_LANGUAGE':
      return { ...state, language: action.payload };
    case 'SET_USER_INFO':
      return { ...state, userInfo: action.payload };
    default:
      return state;
  }
}

// 创建Redux Store
const store = createStore(appReducer);

// 应用初始化服务
async function initializeApp(): Promise<void> {
  try {
    // 初始化配置服务
    const configService = ConfigService.getInstance();
    await configService.initialize();
    
    // 初始化HTTP服务
    const httpService = HttpService.getInstance();
    await httpService.initialize();
    
    // 初始化爬虫服务
    const crawlerService = CrawlerService.getInstance();
    await crawlerService.initialize();
    
    // 初始化统计服务
    const analyticsService = AnalyticsService.getInstance();
    await analyticsService.initialize();
    
    console.log('Application initialized successfully');
  } catch (error) {
    console.error('Failed to initialize application:', error);
    // 初始化失败时记录错误，但继续启动应用
    const analyticsService = AnalyticsService.getInstance();
    await analyticsService.recordError('app_initialize', error as Error);
  }
}

// 主应用组件
export default function App() {
  const [isReady, setIsReady] = useState(false);
  const router = useRouter();
  
  useEffect(() => {
    // 应用初始化
    async function init() {
      try {
        // 执行初始化
        await initializeApp();
        
        // 初始化完成，更新状态
        store.dispatch({ type: 'SET_INITIALIZED', payload: true });
        
        // 获取应用配置
        const configService = ConfigService.getInstance();
        const appConfig = await configService.getAppConfig();
        
        // 设置主题和语言
        store.dispatch({ type: 'SET_THEME', payload: appConfig.theme });
        store.dispatch({ type: 'SET_LANGUAGE', payload: appConfig.language });
        
        // 配置主题
        configureTheme(appConfig.theme);
        
        // 延迟一小段时间以确保UI渲染正常
        setTimeout(() => {
          setIsReady(true);
        }, 100);
        
        // 记录应用启动事件
        const analyticsService = AnalyticsService.getInstance();
        await analyticsService.recordAppStart();
      } catch (error) {
        console.error('Error during app initialization:', error);
        // 即使出错，也设置为已准备好，让应用能够启动
        setIsReady(true);
      }
    }
    
    init();
    
    // 监听应用生命周期事件
    const onShow = () => {
      console.log('App show');
      // 记录应用前台事件
      const analyticsService = AnalyticsService.getInstance();
      analyticsService.recordAppActive();
    };
    
    const onHide = () => {
      console.log('App hide');
      // 记录应用后台事件
      const analyticsService = AnalyticsService.getInstance();
      analyticsService.recordAppBackground();
    };
    
    // 注册事件监听器
    try {
      // 根据不同平台使用不同的事件注册方式
      if (typeof window !== 'undefined' && window.document) {
        // Web平台
        window.addEventListener('focus', onShow);
        window.addEventListener('blur', onHide);
      } else {
        // 小程序/鸿蒙平台
        // @ts-ignore
        if (typeof Taro !== 'undefined') {
          // @ts-ignore
          Taro.onAppShow(onShow);
          // @ts-ignore
          Taro.onAppHide(onHide);
        }
      }
    } catch (error) {
      console.log('Failed to register lifecycle listeners:', error);
    }
    
    // 清理函数
    return () => {
      try {
        if (typeof window !== 'undefined' && window.document) {
          window.removeEventListener('focus', onShow);
          window.removeEventListener('blur', onHide);
        } else {
          // @ts-ignore
          if (typeof Taro !== 'undefined') {
            // @ts-ignore
            Taro.offAppShow(onShow);
            // @ts-ignore
            Taro.offAppHide(onHide);
          }
        }
      } catch (error) {
        console.log('Failed to unregister lifecycle listeners:', error);
      }
    };
  }, []);
  
  // 配置应用主题
  const configureTheme = (theme: string) => {
    try {
      const root = document.documentElement;
      
      if (theme === 'system') {
        // 跟随系统主题
        const isDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
        applyTheme(isDarkMode ? 'dark' : 'light');
        
        // 监听系统主题变化
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
          applyTheme(e.matches ? 'dark' : 'light');
        });
      } else {
        // 应用指定主题
        applyTheme(theme);
      }
    } catch (error) {
      console.error('Failed to configure theme:', error);
    }
  };
  
  // 应用主题样式
  const applyTheme = (theme: string) => {
    try {
      const root = document.documentElement;
      
      if (theme === 'dark') {
        root.classList.add('dark-theme');
        root.classList.remove('light-theme');
      } else {
        root.classList.add('light-theme');
        root.classList.remove('dark-theme');
      }
    } catch (error) {
      console.error('Failed to apply theme:', error);
    }
  };
  
  // 渲染加载界面
  const renderLoading = () => {
    return (
      <SafeAreaView className="app-loading-container">
        <div className="app-loading">
          <div className="loading-spinner"></div>
          <div className="loading-text">正在加载RayTV...</div>
        </div>
      </SafeAreaView>
    );
  };
  
  // 渲染主应用界面
  const renderApp = () => {
    return (
      <Provider store={store}>
        <StatusBar backgroundColor="transparent" translucent />
        {/* 主应用容器 */}
        <SafeAreaView className="app-container">
          <MainPage />
        </SafeAreaView>
      </Provider>
    );
  };
  
  // 根据准备状态渲染不同内容
  return (
    <AppErrorBoundary>
      {isReady ? renderApp() : renderLoading()}
    </AppErrorBoundary>
  );
}

// 应用错误边界组件
// 应用全局样式定义

export class AppErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback?: React.ReactNode },
  { hasError: boolean; error: Error | null }
> {
  constructor(props: { children: React.ReactNode; fallback?: React.ReactNode }) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }
  
  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('App error caught:', error, errorInfo);
    
    // 记录错误到统计服务
    const analyticsService = AnalyticsService.getInstance();
    analyticsService.recordError('app_runtime', error);
  }
  
  render() {
    if (this.state.hasError) {
      // 自定义错误界面
      if (this.props.fallback) {
        return this.props.fallback;
      }
      
      return (
        <SafeAreaView className="app-error-container">
          <div className="error-content">
            <div className="error-icon">⚠️</div>
            <div className="error-title">应用发生错误</div>
            <div className="error-message">{this.state.error?.message || '未知错误'}</div>
            <button 
              className="error-button"
              onClick={() => window.location.reload()}
            >
              重新加载
            </button>
          </div>
        </SafeAreaView>
      );
    }
    
    return this.props.children;
  }
}