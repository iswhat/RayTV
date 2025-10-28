// 历史记录页面组件
// 用于展示用户观看历史

import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, List, Image, Scroll, Grid, Loading, Refresh, Empty, SwipeAction } from '@ray-js/components';
import { AppNavigator } from '../navigation/AppNavigator';
import { VideoManagerService, VideoPlayHistory } from '../service/video/VideoManagerService';
import { AnalyticsService } from '../service/analytics/AnalyticsService';
import { CommonUtil } from '../common/util/CommonUtil';
import './HistoryPage.less';

/**
 * 历史记录页面组件
 */
const HistoryPage: React.FC = () => {
  const appNavigator = AppNavigator.getInstance();
  const videoManagerService = VideoManagerService.getInstance();
  const analyticsService = AnalyticsService.getInstance();
  const commonUtil = CommonUtil.getInstance();
  
  // 状态定义
  const [historyList, setHistoryList] = useState<VideoPlayHistory[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<string>('all'); // all, movie, series, live
  const [groupedHistory, setGroupedHistory] = useState<Map<string, VideoPlayHistory[]>>(new Map());
  
  // 初始化
  useEffect(() => {
    loadHistory();
    
    // 页面访问统计
    analyticsService.trackPageView('HistoryPage', {
      title: '观看历史',
      path: '/history'
    });
  }, [activeTab]);
  
  // 加载历史记录
  const loadHistory = async () => {
    try {
      setLoading(true);
      const allHistory = await videoManagerService.getAllPlayHistory();
      
      // 按类型过滤
      let filteredHistory = allHistory;
      if (activeTab !== 'all') {
        filteredHistory = allHistory.filter(item => item.type === activeTab);
      }
      
      // 按日期分组（最近7天按日期，更早的按周/月分组）
      const grouped = groupHistoryByDate(filteredHistory);
      
      setHistoryList(filteredHistory);
      setGroupedHistory(grouped);
    } catch (error) {
      console.error('Failed to load history:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };
  
  // 按日期分组历史记录
  const groupHistoryByDate = (history: VideoPlayHistory[]): Map<string, VideoPlayHistory[]> => {
    const grouped = new Map<string, VideoPlayHistory[]>();
    const today = new Date();
    
    history.forEach(item => {
      const playDate = new Date(item.playTime || 0);
      const diffDays = Math.floor((today.getTime() - playDate.getTime()) / (1000 * 60 * 60 * 24));
      let groupKey = '';
      
      if (diffDays === 0) {
        groupKey = '今天';
      } else if (diffDays === 1) {
        groupKey = '昨天';
      } else if (diffDays < 7) {
        groupKey = `${diffDays}天前`;
      } else if (diffDays < 30) {
        const weeks = Math.floor(diffDays / 7);
        groupKey = `${weeks}周前`;
      } else {
        const months = Math.floor(diffDays / 30);
        groupKey = `${months}个月前`;
      }
      
      if (!grouped.has(groupKey)) {
        grouped.set(groupKey, []);
      }
      grouped.get(groupKey)?.push(item);
    });
    
    // 按日期排序（最近的在前）
    const sortedGroups = new Map<string, VideoPlayHistory[]>();
    const dateOrder = ['今天', '昨天', '3天前', '4天前', '5天前', '6天前', '7天前', 
                       '1周前', '2周前', '3周前', '1个月前', '2个月前', '3个月前', '6个月前', '1年前'];
    
    dateOrder.forEach(date => {
      if (grouped.has(date)) {
        // 每个分组内按播放时间降序排序
        const sortedItems = grouped.get(date)!.sort((a, b) => {
          return (b.playTime || 0) - (a.playTime || 0);
        });
        sortedGroups.set(date, sortedItems);
      }
    });
    
    // 添加不在预定义顺序中的分组
    grouped.forEach((items, key) => {
      if (!sortedGroups.has(key)) {
        const sortedItems = items.sort((a, b) => {
          return (b.playTime || 0) - (a.playTime || 0);
        });
        sortedGroups.set(key, sortedItems);
      }
    });
    
    return sortedGroups;
  };
  
  // 处理刷新
  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadHistory();
  }, [activeTab]);
  
  // 处理删除单条历史
  const handleRemoveHistory = useCallback(async (item: VideoPlayHistory) => {
    try {
      await videoManagerService.removePlayHistory(item.id, item.type);
      
      // 更新列表
      const updatedHistory = historyList.filter(h => !(h.id === item.id && h.type === item.type));
      setHistoryList(updatedHistory);
      
      // 重新分组
      const grouped = groupHistoryByDate(updatedHistory);
      setGroupedHistory(grouped);
      
      // 统计删除历史事件
      analyticsService.trackEvent('history_remove', {
        video_id: item.id,
        video_title: item.title,
        video_type: item.type
      });
    } catch (error) {
      console.error('Failed to remove history:', error);
    }
  }, [historyList]);
  
  // 处理清空历史
  const handleClearHistory = useCallback(async () => {
    try {
      if (activeTab === 'all') {
        await videoManagerService.clearAllPlayHistory();
      } else {
        await videoManagerService.clearPlayHistoryByType(activeTab);
      }
      setHistoryList([]);
      setGroupedHistory(new Map());
      
      // 统计清空历史事件
      analyticsService.trackEvent('history_clear', {
        scope: activeTab
      });
    } catch (error) {
      console.error('Failed to clear history:', error);
    }
  }, [activeTab]);
  
  // 处理历史记录点击
  const handleHistoryClick = useCallback((item: VideoPlayHistory) => {
    // 统计点击事件
    analyticsService.trackEvent('history_click', {
      video_id: item.id,
      video_title: item.title,
      video_type: item.type
    });
    
    // 导航到播放页面，带上播放进度
    appNavigator.navigateTo('VideoPlayPage', {
      videoId: item.id,
      title: item.title,
      siteId: item.siteId || '',
      type: item.type,
      position: item.position // 从上次播放位置继续
    });
  }, []);
  
  // 处理续播
  const handleContinuePlay = useCallback((e: React.MouseEvent, item: VideoPlayHistory) => {
    e.stopPropagation();
    handleHistoryClick(item);
  }, [handleHistoryClick]);
  
  // 渲染标签切换
  const renderTabs = () => (
    <View className="tabs">
      <View
        className={`tab-item ${activeTab === 'all' ? 'active' : ''}`}
        onClick={() => setActiveTab('all')}
      >
        <Text className="tab-text">全部</Text>
      </View>
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
  
  // 渲染历史记录项
  const renderHistoryItem = (item: VideoPlayHistory) => {
    const progress = item.progress || 0;
    const duration = item.duration || 0;
    const remainingTime = duration - (duration * progress / 100);
    
    return (
      <SwipeAction
        key={`${item.id}-${item.type}`}
        rightWidth={80}
        rightAction={[
          {
            text: '删除',
            className: 'swipe-delete',
            onClick: () => handleRemoveHistory(item)
          }
        ]}
      >
        <View className="history-item" onClick={() => handleHistoryClick(item)}>
          <View className="history-cover-wrapper">
            <Image
              src={item.cover || 'https://example.com/default-cover.jpg'}
              className="history-cover"
              mode="aspectFill"
            />
            <View className="progress-bar">
              <View className="progress-fill" style={{ width: `${progress}%` }} />
            </View>
            {item.episode && (
              <View className="episode-badge">
                <Text className="episode-text">第{item.episode}集</Text>
              </View>
            )}
          </View>
          <View className="history-info">
            <Text className="history-title" numberOfLines={2}>
              {item.title}
            </Text>
            <View className="history-meta">
              {item.siteName && (
                <Text className="history-site">{item.siteName}</Text>
              )}
              {item.playTime && (
                <Text className="history-time">
                  {commonUtil.formatDate(item.playTime, 'MM-DD HH:mm')}
                </Text>
              )}
            </View>
            <View className="history-progress">
              <Text className="progress-text">
                已观看 {progress.toFixed(0)}%
                {remainingTime > 0 && (
                  <Text className="remaining-time">
                    · 剩余 {commonUtil.formatDuration(remainingTime)}
                  </Text>
                )}
              </Text>
              <View className="continue-btn" onClick={(e) => handleContinuePlay(e, item)}>
                <Text className="continue-text">继续观看</Text>
              </View>
            </View>
          </View>
        </View>
      </SwipeAction>
    );
  };
  
  // 渲染分组标题
  const renderGroupHeader = (dateLabel: string, count: number) => (
    <View className="group-header">
      <Text className="group-title">{dateLabel}</Text>
      <Text className="group-count">{count} 个记录</Text>
    </View>
  );
  
  return (
    <View className="history-page">
      {/* 标签切换 */}
      {renderTabs()}
      
      {/* 清空按钮 */}
      {historyList.length > 0 && (
        <View className="header-actions">
          <View className="clear-btn" onClick={handleClearHistory}>
            <Text className="clear-btn-text">
              {activeTab === 'all' ? '清空全部' : `清空${activeTab === 'movie' ? '电影' : activeTab === 'series' ? '剧集' : '直播'}历史`}
            </Text>
          </View>
        </View>
      )}
      
      {/* 历史记录内容 */}
      {loading && !refreshing ? (
        <View className="loading-container">
          <Loading size="large" />
        </View>
      ) : historyList.length > 0 ? (
        <Refresh
          refreshing={refreshing}
          onRefresh={handleRefresh}
          className="history-list"
        >
          {Array.from(groupedHistory.entries()).map(([dateLabel, items]) => (
            <View key={dateLabel} className="history-group">
              {renderGroupHeader(dateLabel, items.length)}
              <List
                data={items}
                renderItem={({ item }) => renderHistoryItem(item)}
                className="history-items"
              />
            </View>
          ))}
        </Refresh>
      ) : (
        <Empty
          description={activeTab === 'all' ? '暂无观看历史' : 
                     activeTab === 'movie' ? '暂无电影观看历史' : 
                     activeTab === 'series' ? '暂无剧集观看历史' : '暂无直播观看历史'}
          className="empty-container"
          imageSize={120}
        />
      )}
    </View>
  );
};

export default HistoryPage;