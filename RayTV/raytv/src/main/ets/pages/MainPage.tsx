// 主页面组件
// 整合底部导航栏和各个功能页面

import React, { useState, useEffect } from 'react';
import { View, Text, TabBar } from '@ray-js/components';
import HomePage from './HomePage';
import CategoryPage from './CategoryPage';
import FavoritePage from './FavoritePage';
import HistoryPage from './HistoryPage';
import { AppNavigator } from '../navigation/AppNavigator';
import { AnalyticsService } from '../service/analytics/AnalyticsService';
import './MainPage.less';

/**
 * 主页面组件
 */
const MainPage: React.FC = () => {
  const appNavigator = AppNavigator.getInstance();
  const analyticsService = AnalyticsService.getInstance();
  
  // 状态定义
  const [activeTab, setActiveTab] = useState<string>('home');
  const [showTabBar, setShowTabBar] = useState<boolean>(true);
  
  // 初始化
  useEffect(() => {
    // 监听导航事件，控制TabBar显示
    const unsubscribe = appNavigator.addNavigationListener((event) => {
      if (event.type === 'navigate') {
        // 如果导航到非主页面，隐藏TabBar
        setShowTabBar(['home', 'category', 'favorite', 'history'].includes(event.page));
      }
    });
    
    return () => {
      unsubscribe();
    };
  }, []);
  
  // 处理Tab切换
  const handleTabChange = (tab: string) => {
    setActiveTab(tab);
    
    // 统计Tab切换事件
    analyticsService.trackEvent('tab_switch', {
      tab: tab,
      previous_tab: activeTab
    });
  };
  
  // 渲染Tab图标
  const renderTabIcon = (tab: string, isActive: boolean) => {
    // 这里可以根据需要使用真实的图标组件
    // 暂时使用文本作为图标占位符
    const icons: Record<string, string> = {
      home: '🏠',
      category: '📁',
      favorite: '❤️',
      history: '🕒'
    };
    
    return (
      <View className={`tab-icon ${isActive ? 'active' : ''}`}>
        <Text className="icon-text">{icons[tab] || '📱'}</Text>
      </View>
    );
  };
  
  // 渲染当前页面内容
  const renderContent = () => {
    switch (activeTab) {
      case 'home':
        return <HomePage />;
      case 'category':
        return <CategoryPage />;
      case 'favorite':
        return <FavoritePage />;
      case 'history':
        return <HistoryPage />;
      default:
        return <HomePage />;
    }
  };
  
  // Tab配置
  const tabs = [
    {
      key: 'home',
      title: '首页',
      icon: (props: { active: boolean }) => renderTabIcon('home', props.active)
    },
    {
      key: 'category',
      title: '分类',
      icon: (props: { active: boolean }) => renderTabIcon('category', props.active)
    },
    {
      key: 'favorite',
      title: '收藏',
      icon: (props: { active: boolean }) => renderTabIcon('favorite', props.active)
    },
    {
      key: 'history',
      title: '历史',
      icon: (props: { active: boolean }) => renderTabIcon('history', props.active)
    }
  ];
  
  return (
    <View className="main-page">
      {/* 内容区域 */}
      <View className="content-area">
        {renderContent()}
      </View>
      
      {/* 底部导航栏 */}
      {showTabBar && (
        <TabBar
          activeKey={activeTab}
          onChange={handleTabChange}
          tabs={tabs}
          className="tab-bar"
          activeTextStyle={{ color: 'var(--primary-color)' }}
          inactiveTextStyle={{ color: 'var(--text-color-secondary)' }}
          tabBarStyle={{ backgroundColor: 'var(--card-background)', borderTopColor: 'var(--border-color)' }}
        />
      )}
    </View>
  );
};

export default MainPage;