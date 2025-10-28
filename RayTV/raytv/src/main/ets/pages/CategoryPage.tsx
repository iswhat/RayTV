// 分类页面组件
// 用于展示和筛选视频分类内容

import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, List, Image, Scroll, Grid, Loading, Refresh, Empty } from '@ray-js/components';
import { AppNavigator } from '../navigation/AppNavigator';
import { CrawlerService, VodInfo } from '../service/spider/CrawlerService';
import { AnalyticsService } from '../service/analytics/AnalyticsService';
import { VideoManagerService } from '../service/video/VideoManagerService';
import { CommonUtil } from '../common/util/CommonUtil';
import './CategoryPage.less';

/**
 * 分类页面组件
 */
const CategoryPage: React.FC = () => {
  const appNavigator = AppNavigator.getInstance();
  const crawlerService = CrawlerService.getInstance();
  const analyticsService = AnalyticsService.getInstance();
  const videoManagerService = VideoManagerService.getInstance();
  const commonUtil = CommonUtil.getInstance();
  
  // 状态定义
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [categories, setCategories] = useState<Array<{ id: string; name: string }>>([]);
  const [videos, setVideos] = useState<VodInfo[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [page, setPage] = useState<number>(1);
  const [hasMore, setHasMore] = useState<boolean>(true);
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [sortBy, setSortBy] = useState<string>('default');
  const [showFilterPanel, setShowFilterPanel] = useState<boolean>(false);
  const [activeSiteId, setActiveSiteId] = useState<string>('');
  const [sites, setSites] = useState<Array<{ id: string; name: string }>>([]);
  
  // 初始化
  useEffect(() => {
    initializePage();
    
    // 页面访问统计
    analyticsService.trackPageView('CategoryPage', {
      title: '视频分类',
      path: '/category'
    });
  }, []);
  
  // 初始化页面
  const initializePage = async () => {
    try {
      // 获取可用站点
      const availableSites = await crawlerService.getAvailableSites();
      setSites(availableSites);
      
      if (availableSites.length > 0) {
        setActiveSiteId(availableSites[0].id);
        // 获取分类列表
        await loadCategories(availableSites[0].id);
      }
    } catch (error) {
      console.error('Failed to initialize category page:', error);
    } finally {
      setLoading(false);
    }
  };
  
  // 加载分类列表
  const loadCategories = async (siteId: string) => {
    try {
      setLoading(true);
      const categoryList = await crawlerService.getCategories(siteId);
      setCategories(categoryList);
      
      if (categoryList.length > 0 && !selectedCategory) {
        setSelectedCategory(categoryList[0].id);
        // 自动加载第一个分类的内容
        await loadCategoryVideos(categoryList[0].id, siteId, 1);
      }
    } catch (error) {
      console.error('Failed to load categories:', error);
    } finally {
      setLoading(false);
    }
  };
  
  // 加载分类视频内容
  const loadCategoryVideos = async (categoryId: string, siteId: string, pageNum: number = 1, isLoadMore: boolean = false) => {
    try {
      if (!isLoadMore) {
        setLoading(true);
      }
      
      const result = await crawlerService.getCategoryVideos(siteId, categoryId, {
        page: pageNum,
        sort: sortBy,
        ...filters
      });
      
      if (result && result.list) {
        if (isLoadMore) {
          setVideos(prev => [...prev, ...result.list]);
        } else {
          setVideos(result.list);
        }
        
        setHasMore(result.list.length >= 20); // 假设每页20条
      } else {
        setHasMore(false);
        if (!isLoadMore) {
          setVideos([]);
        }
      }
    } catch (error) {
      console.error('Failed to load category videos:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };
  
  // 处理分类切换
  const handleCategoryChange = useCallback(async (categoryId: string) => {
    setSelectedCategory(categoryId);
    setPage(1);
    setHasMore(true);
    await loadCategoryVideos(categoryId, activeSiteId, 1);
    
    // 统计分类点击
    analyticsService.trackEvent('category_select', {
      category_id: categoryId,
      site_id: activeSiteId
    });
  }, [activeSiteId]);
  
  // 处理站点切换
  const handleSiteChange = useCallback(async (siteId: string) => {
    setActiveSiteId(siteId);
    setSelectedCategory('');
    setVideos([]);
    setPage(1);
    setHasMore(true);
    await loadCategories(siteId);
    
    // 统计站点切换
    analyticsService.trackEvent('site_switch', {
      site_id: siteId
    });
  }, []);
  
  // 处理排序切换
  const handleSortChange = useCallback(async (sort: string) => {
    setSortBy(sort);
    setPage(1);
    setHasMore(true);
    if (selectedCategory) {
      await loadCategoryVideos(selectedCategory, activeSiteId, 1);
    }
  }, [selectedCategory, activeSiteId]);
  
  // 处理筛选变化
  const handleFilterChange = useCallback((key: string, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  }, []);
  
  // 应用筛选
  const applyFilters = useCallback(async () => {
    setShowFilterPanel(false);
    setPage(1);
    setHasMore(true);
    if (selectedCategory) {
      await loadCategoryVideos(selectedCategory, activeSiteId, 1);
    }
    
    // 统计筛选应用
    analyticsService.trackEvent('filter_apply', {
      filters,
      category_id: selectedCategory,
      site_id: activeSiteId
    });
  }, [selectedCategory, activeSiteId, filters]);
  
  // 重置筛选
  const resetFilters = useCallback(() => {
    setFilters({});
  }, []);
  
  // 处理刷新
  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    setPage(1);
    setHasMore(true);
    if (selectedCategory) {
      await loadCategoryVideos(selectedCategory, activeSiteId, 1);
    }
  }, [selectedCategory, activeSiteId]);
  
  // 处理加载更多
  const handleLoadMore = useCallback(async () => {
    if (!loading && hasMore && selectedCategory) {
      const nextPage = page + 1;
      setPage(nextPage);
      await loadCategoryVideos(selectedCategory, activeSiteId, nextPage, true);
    }
  }, [loading, hasMore, selectedCategory, activeSiteId, page]);
  
  // 处理视频点击
  const handleVideoClick = useCallback(async (video: VodInfo) => {
    // 统计视频点击
    analyticsService.trackEvent('video_click', {
      video_id: video.id,
      video_title: video.title,
      category_id: selectedCategory,
      site_id: activeSiteId
    });
    
    // 导航到播放页面
    appNavigator.navigateTo('VideoPlayPage', {
      videoId: video.id,
      title: video.title,
      siteId: activeSiteId
    });
  }, [selectedCategory, activeSiteId]);
  
  // 处理收藏
  const handleFavoriteToggle = useCallback(async (e: React.MouseEvent, video: VodInfo) => {
    e.stopPropagation();
    
    try {
      // 检查是否已收藏
      const isFavorited = await videoManagerService.isFavorite(video.id, 'movie');
      
      if (isFavorited) {
        // 取消收藏
        await videoManagerService.removeFavorite(video.id, 'movie');
        analyticsService.trackEvent('favorite_remove', {
          video_id: video.id,
          video_title: video.title
        });
      } else {
        // 添加收藏
        await videoManagerService.addFavorite({
          id: video.id,
          type: 'movie',
          title: video.title,
          cover: video.cover || ''
        });
        analyticsService.trackEvent('favorite_add', {
          video_id: video.id,
          video_title: video.title
        });
      }
    } catch (error) {
      console.error('Failed to toggle favorite:', error);
    }
  }, []);
  
  // 渲染分类项
  const renderCategoryItem = (category: { id: string; name: string }) => (
    <View
      key={category.id}
      className={`category-item ${selectedCategory === category.id ? 'active' : ''}`}
      onClick={() => handleCategoryChange(category.id)}
    >
      <Text className="category-name">{category.name}</Text>
    </View>
  );
  
  // 渲染视频项
  const renderVideoItem = (video: VodInfo) => {
    const progress = video.progress || 0;
    
    return (
      <View key={video.id} className="video-item" onClick={() => handleVideoClick(video)}>
        <View className="video-cover-wrapper">
          <Image
            src={video.cover || 'https://example.com/default-cover.jpg'}
            className="video-cover"
            mode="aspectFill"
          />
          {progress > 0 && (
            <View className="progress-bar">
              <View className="progress-fill" style={{ width: `${progress}%` }} />
            </View>
          )}
          {video.duration && (
            <View className="duration-badge">
              <Text className="duration-text">{commonUtil.formatDuration(video.duration)}</Text>
            </View>
          )}
          <View className="favorite-btn" onClick={(e) => handleFavoriteToggle(e, video)}>
            <Text className="favorite-icon">★</Text>
          </View>
        </View>
        <View className="video-info">
          <Text className="video-title" numberOfLines={2}>
            {video.title}
          </Text>
          {video.actors && video.actors.length > 0 && (
            <Text className="video-actors" numberOfLines={1}>
              演员: {video.actors.join('、')}
            </Text>
          )}
          {video.year && (
            <Text className="video-year">{video.year}</Text>
          )}
          {video.rating && (
            <View className="rating-wrapper">
              <Text className="rating">{video.rating}</Text>
            </View>
          )}
        </View>
      </View>
    );
  };
  
  // 渲染筛选面板
  const renderFilterPanel = () => (
    <View className={`filter-panel ${showFilterPanel ? 'visible' : ''}`}>
      <View className="filter-header">
        <Text className="filter-title">筛选</Text>
        <Text className="filter-close" onClick={() => setShowFilterPanel(false)}>关闭</Text>
      </View>
      <Scroll className="filter-content">
        {/* 这里可以根据实际需求添加筛选条件 */}
        <View className="filter-group">
          <Text className="filter-label">年份</Text>
          <View className="filter-options">
            {['全部', '2024', '2023', '2022', '2021', '2020'].map(year => (
              <View
                key={year}
                className={`filter-option ${filters.year === year && year !== '全部' ? 'active' : ''}`}
                onClick={() => handleFilterChange('year', year === '全部' ? '' : year)}
              >
                <Text>{year}</Text>
              </View>
            ))}
          </View>
        </View>
        
        <View className="filter-group">
          <Text className="filter-label">地区</Text>
          <View className="filter-options">
            {['全部', '中国大陆', '中国香港', '中国台湾', '美国', '韩国', '日本', '其他'].map(region => (
              <View
                key={region}
                className={`filter-option ${filters.region === region && region !== '全部' ? 'active' : ''}`}
                onClick={() => handleFilterChange('region', region === '全部' ? '' : region)}
              >
                <Text>{region}</Text>
              </View>
            ))}
          </View>
        </View>
        
        <View className="filter-group">
          <Text className="filter-label">类型</Text>
          <View className="filter-options">
            {['全部', '动作', '喜剧', '爱情', '科幻', '悬疑', '恐怖', '动画'].map(type => (
              <View
                key={type}
                className={`filter-option ${filters.type === type && type !== '全部' ? 'active' : ''}`}
                onClick={() => handleFilterChange('type', type === '全部' ? '' : type)}
              >
                <Text>{type}</Text>
              </View>
            ))}
          </View>
        </View>
      </Scroll>
      <View className="filter-footer">
        <View className="filter-btn reset" onClick={resetFilters}>
          <Text>重置</Text>
        </View>
        <View className="filter-btn apply" onClick={applyFilters}>
          <Text>确定</Text>
        </View>
      </View>
    </View>
  );
  
  // 渲染排序选项
  const renderSortOptions = () => (
    <View className="sort-options">
      <View
        className={`sort-option ${sortBy === 'default' ? 'active' : ''}`}
        onClick={() => handleSortChange('default')}
      >
        <Text>默认</Text>
      </View>
      <View
        className={`sort-option ${sortBy === 'update' ? 'active' : ''}`}
        onClick={() => handleSortChange('update')}
      >
        <Text>最新更新</Text>
      </View>
      <View
        className={`sort-option ${sortBy === 'popular' ? 'active' : ''}`}
        onClick={() => handleSortChange('popular')}
      >
        <Text>最受欢迎</Text>
      </View>
      <View
        className={`sort-option filter-btn`}
        onClick={() => setShowFilterPanel(true)}
      >
        <Text>筛选</Text>
      </View>
    </View>
  );
  
  // 渲染站点切换器
  const renderSiteSwitcher = () => (
    <Scroll className="site-switcher" horizontal>
      {sites.map(site => (
        <View
          key={site.id}
          className={`site-item ${activeSiteId === site.id ? 'active' : ''}`}
          onClick={() => handleSiteChange(site.id)}
        >
          <Text>{site.name}</Text>
        </View>
      ))}
    </Scroll>
  );
  
  return (
    <View className="category-page">
      {/* 站点切换器 */}
      {renderSiteSwitcher()}
      
      <View className="content-wrapper">
        {/* 分类列表 */}
        <Scroll className="category-list" vertical>
          {categories.map(renderCategoryItem)}
        </Scroll>
        
        {/* 视频内容 */}
        <View className="video-content">
          {/* 排序选项 */}
          {renderSortOptions()}
          
          {/* 视频网格 */}
          {loading && !refreshing ? (
            <View className="loading-container">
              <Loading size="large" />
            </View>
          ) : videos.length > 0 ? (
            <Refresh
              refreshing={refreshing}
              onRefresh={handleRefresh}
              onEndReached={handleLoadMore}
              onEndReachedThreshold={0.1}
            >
              <Grid
                data={videos}
                columns={3}
                columnGap={12}
                rowGap={16}
                className="video-grid"
              >
                {videos.map(renderVideoItem)}
              </Grid>
              {hasMore && (
                <View className="load-more">
                  <Loading size="small" />
                  <Text>加载更多...</Text>
                </View>
              )}
            </Refresh>
          ) : (
            <Empty
              description="暂无内容"
              className="empty-container"
              imageSize={100}
            />
          )}
        </View>
      </View>
      
      {/* 筛选面板 */}
      {renderFilterPanel()}
    </View>
  );
};

export default CategoryPage;