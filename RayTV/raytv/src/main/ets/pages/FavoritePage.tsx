// 收藏页面组件
// 用于展示用户收藏的视频内容

import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, List, Image, Scroll, Grid, Loading, Refresh, Empty, SwipeAction } from '@ray-js/components';
import { AppNavigator } from '../navigation/AppNavigator';
import { VideoManagerService, FavoriteItem } from '../service/video/VideoManagerService';
import { AnalyticsService } from '../service/analytics/AnalyticsService';
import { CommonUtil } from '../common/util/CommonUtil';
import './FavoritePage.less';

/**
 * 收藏页面组件
 */
const FavoritePage: React.FC = () => {
  const appNavigator = AppNavigator.getInstance();
  const videoManagerService = VideoManagerService.getInstance();
  const analyticsService = AnalyticsService.getInstance();
  const commonUtil = CommonUtil.getInstance();
  
  // 状态定义
  const [favorites, setFavorites] = useState<FavoriteItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<string>('movie'); // movie, series, live
  const [groupedFavorites, setGroupedFavorites] = useState<Map<string, FavoriteItem[]>>(new Map());
  
  // 初始化
  useEffect(() => {
    loadFavorites();
    
    // 页面访问统计
    analyticsService.trackPageView('FavoritePage', {
      title: '我的收藏',
      path: '/favorite'
    });
  }, [activeTab]);
  
  // 加载收藏数据
  const loadFavorites = async () => {
    try {
      setLoading(true);
      const allFavorites = await videoManagerService.getAllFavorites();
      
      // 按类型过滤
      const filteredFavorites = allFavorites.filter(item => item.type === activeTab);
      
      // 按站点分组
      const grouped = new Map<string, FavoriteItem[]>();
      filteredFavorites.forEach(item => {
        const siteName = item.siteName || '未知站点';
        if (!grouped.has(siteName)) {
          grouped.set(siteName, []);
        }
        grouped.get(siteName)?.push(item);
      });
      
      setFavorites(filteredFavorites);
      setGroupedFavorites(grouped);
    } catch (error) {
      console.error('Failed to load favorites:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };
  
  // 处理刷新
  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadFavorites();
  }, [activeTab]);
  
  // 处理收藏删除
  const handleRemoveFavorite = useCallback(async (item: FavoriteItem) => {
    try {
      await videoManagerService.removeFavorite(item.id, item.type);
      
      // 更新列表
      const updatedFavorites = favorites.filter(fav => !(fav.id === item.id && fav.type === item.type));
      setFavorites(updatedFavorites);
      
      // 重新分组
      const grouped = new Map<string, FavoriteItem[]>();
      updatedFavorites.forEach(fav => {
        const siteName = fav.siteName || '未知站点';
        if (!grouped.has(siteName)) {
          grouped.set(siteName, []);
        }
        grouped.get(siteName)?.push(fav);
      });
      setGroupedFavorites(grouped);
      
      // 统计删除收藏事件
      analyticsService.trackEvent('favorite_remove', {
        video_id: item.id,
        video_title: item.title,
        video_type: item.type
      });
    } catch (error) {
      console.error('Failed to remove favorite:', error);
    }
  }, [favorites]);
  
  // 处理视频点击
  const handleVideoClick = useCallback((item: FavoriteItem) => {
    // 统计点击事件
    analyticsService.trackEvent('favorite_click', {
      video_id: item.id,
      video_title: item.title,
      video_type: item.type
    });
    
    // 导航到播放页面
    appNavigator.navigateTo('VideoPlayPage', {
      videoId: item.id,
      title: item.title,
      siteId: item.siteId || '',
      type: item.type
    });
  }, []);
  
  // 处理清空收藏
  const handleClearAllFavorites = useCallback(async () => {
    try {
      await videoManagerService.clearFavoritesByType(activeTab);
      setFavorites([]);
      setGroupedFavorites(new Map());
      
      // 统计清空收藏事件
      analyticsService.trackEvent('favorite_clear_all', {
        video_type: activeTab
      });
    } catch (error) {
      console.error('Failed to clear favorites:', error);
    }
  }, [activeTab]);
  
  // 处理分享
  const handleShare = useCallback((item: FavoriteItem) => {
    // 统计分享事件
    analyticsService.trackEvent('favorite_share', {
      video_id: item.id,
      video_title: item.title,
      video_type: item.type
    });
    
    // 这里可以实现分享逻辑
    console.log('Share video:', item);
    // 在实际应用中，这里会调用系统分享API
  }, []);
  
  // 渲染标签切换
  const renderTabs = () => (
    <View className="tabs">
      <View
        className={`tab-item ${activeTab === 'movie' ? 'active' : ''}`}
        onClick={() => setActiveTab('movie')}
      >
        <Text className="tab-text">电影</Text>
      </View>
      <View
        className={`tab-item ${activeTab === 'series' ? 'active' : ''}`}
        onClick={() => setActiveTab('series')}
      >
        <Text className="tab-text">剧集</Text>
      </View>
      <View
        className={`tab-item ${activeTab === 'live' ? 'active' : ''}`}
        onClick={() => setActiveTab('live')}
      >
        <Text className="tab-text">直播</Text>
      </View>
    </View>
  );
  
  // 渲染收藏项
  const renderFavoriteItem = (item: FavoriteItem) => {
    return (
      <SwipeAction
        key={`${item.id}-${item.type}`}
        rightWidth={120}
        rightAction={[
          {
            text: '分享',
            className: 'swipe-share',
            onClick: () => handleShare(item)
          },
          {
            text: '删除',
            className: 'swipe-delete',
            onClick: () => handleRemoveFavorite(item)
          }
        ]}
      >
        <View className="favorite-item" onClick={() => handleVideoClick(item)}>
          <View className="favorite-cover-wrapper">
            <Image
              src={item.cover || 'https://example.com/default-cover.jpg'}
              className="favorite-cover"
              mode="aspectFill"
            />
            {item.progress && item.progress > 0 && (
              <View className="progress-bar">
                <View className="progress-fill" style={{ width: `${item.progress}%` }} />
              </View>
            )}
          </View>
          <View className="favorite-info">
            <Text className="favorite-title" numberOfLines={2}>
              {item.title}
            </Text>
            {item.description && (
              <Text className="favorite-description" numberOfLines={2}>
                {item.description}
              </Text>
            )}
            <View className="favorite-meta">
              {item.siteName && (
                <Text className="favorite-site">{item.siteName}</Text>
              )}
              {item.addTime && (
                <Text className="favorite-time">
                  {commonUtil.formatDate(item.addTime, 'YYYY-MM-DD')}
                </Text>
              )}
            </View>
          </View>
        </View>
      </SwipeAction>
    );
  };
  
  // 渲染分组标题
  const renderGroupHeader = (siteName: string, count: number) => (
    <View className="group-header">
      <Text className="group-title">{siteName}</Text>
      <Text className="group-count">{count} 个收藏</Text>
    </View>
  );
  
  return (
    <View className="favorite-page">
      {/* 标签切换 */}
      {renderTabs()}
      
      {/* 清空按钮 */}
      {favorites.length > 0 && (
        <View className="header-actions">
          <View className="clear-btn" onClick={handleClearAllFavorites}>
            <Text className="clear-btn-text">清空全部</Text>
          </View>
        </View>
      )}
      
      {/* 收藏内容 */}
      {loading && !refreshing ? (
        <View className="loading-container">
          <Loading size="large" />
        </View>
      ) : favorites.length > 0 ? (
        <Refresh
          refreshing={refreshing}
          onRefresh={handleRefresh}
          className="favorite-list"
        >
          {Array.from(groupedFavorites.entries()).map(([siteName, items]) => (
            <View key={siteName} className="favorite-group">
              {renderGroupHeader(siteName, items.length)}
              <List
                data={items}
                renderItem={({ item }) => renderFavoriteItem(item)}
                className="favorite-items"
              />
            </View>
          ))}
        </Refresh>
      ) : (
        <Empty
          description={activeTab === 'movie' ? '暂无收藏的电影' : 
                     activeTab === 'series' ? '暂无收藏的剧集' : '暂无收藏的直播'}
          className="empty-container"
          imageSize={120}
        />
      )}
    </View>
  );
};

export default FavoritePage;