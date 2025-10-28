// 首页组件
// 展示推荐内容、热门分类、最近更新等

import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, Image, TouchableOpacity, RefreshControl, StyleSheet } from '@ohos.universal';
import { AppNavigator } from '../navigation/AppNavigator';
import { CrawlerService } from '../service/spider/CrawlerService';
import { AnalyticsService } from '../service/analytics/AnalyticsService';
import { VideoItem } from '../data/bean/Vod.ets';

const HomePage: React.FC = () => {
  const [recommendedVods, setRecommendedVods] = useState<VideoItem[]>([]);
  const [hotVods, setHotVods] = useState<VideoItem[]>([]);
  const [latestVods, setLatestVods] = useState<VideoItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);

  const appNavigator = AppNavigator.getInstance();
  const crawlerService = CrawlerService.getInstance();
  const analyticsService = AnalyticsService.getInstance();

  useEffect(() => {
    analyticsService.trackPageView('HomePage');
    loadHomeData();
  }, []);

  const loadHomeData = async () => {
    try {
      setLoading(true);
      
      // 并行加载数据
      const [recommended, hot, latest, categoryList] = await Promise.all([
        loadRecommendedVods(),
        loadHotVods(),
        loadLatestVods(),
        loadCategories()
      ]);

      setRecommendedVods(recommended);
      setHotVods(hot);
      setLatestVods(latest);
      setCategories(categoryList);
    } catch (error) {
      console.error('Failed to load home data:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const loadRecommendedVods = async (): Promise<VideoItem[]> => {
    try {
      // 从爬虫服务获取推荐内容
      const sites = await crawlerService.getActiveSites();
      const allResults: VideoItem[] = [];

      for (const site of sites.slice(0, 2)) { // 只获取前两个站点的数据
        try {
          const results = await crawlerService.callSiteMethod<any[]>(site.key, 'getRecommendList', []);
          if (results && Array.isArray(results)) {
            const items = results.slice(0, 5).map(item => ({
              id: item.id || `unknown_${Date.now()}_${Math.random()}`,
              title: item.title || '未知标题',
              cover: item.cover || '',
              siteKey: site.key,
              originalUrl: item.url || '',
              rating: item.rating || 0,
              updateInfo: item.updateInfo || ''
            }));
            allResults.push(...items);
          }
        } catch (error) {
          console.warn(`Failed to load recommendations from ${site.name}:`, error);
        }
      }

      return allResults.length > 0 ? allResults : getMockRecommendedVods();
    } catch (error) {
      console.error('Failed to load recommended vods:', error);
      return getMockRecommendedVods();
    }
  };

  const loadHotVods = async (): Promise<VideoItem[]> => {
    try {
      // 从爬虫服务获取热门内容
      const sites = await crawlerService.getActiveSites();
      const allResults: VideoItem[] = [];

      for (const site of sites.slice(0, 2)) {
        try {
          const results = await crawlerService.callSiteMethod<any[]>(site.key, 'getHotList', []);
          if (results && Array.isArray(results)) {
            const items = results.slice(0, 10).map(item => ({
              id: item.id || `unknown_${Date.now()}_${Math.random()}`,
              title: item.title || '未知标题',
              cover: item.cover || '',
              siteKey: site.key,
              originalUrl: item.url || '',
              rating: item.rating || 0,
              updateInfo: item.updateInfo || ''
            }));
            allResults.push(...items);
          }
        } catch (error) {
          console.warn(`Failed to load hot list from ${site.name}:`, error);
        }
      }

      return allResults.length > 0 ? allResults : getMockHotVods();
    } catch (error) {
      console.error('Failed to load hot vods:', error);
      return getMockHotVods();
    }
  };

  const loadLatestVods = async (): Promise<VideoItem[]> => {
    try {
      // 从爬虫服务获取最新更新
      const sites = await crawlerService.getActiveSites();
      const allResults: VideoItem[] = [];

      for (const site of sites.slice(0, 2)) {
        try {
          const results = await crawlerService.callSiteMethod<any[]>(site.key, 'getLatestList', []);
          if (results && Array.isArray(results)) {
            const items = results.slice(0, 10).map(item => ({
              id: item.id || `unknown_${Date.now()}_${Math.random()}`,
              title: item.title || '未知标题',
              cover: item.cover || '',
              siteKey: site.key,
              originalUrl: item.url || '',
              rating: item.rating || 0,
              updateInfo: item.updateInfo || ''
            }));
            allResults.push(...items);
          }
        } catch (error) {
          console.warn(`Failed to load latest list from ${site.name}:`, error);
        }
      }

      return allResults.length > 0 ? allResults : getMockLatestVods();
    } catch (error) {
      console.error('Failed to load latest vods:', error);
      return getMockLatestVods();
    }
  };

  const loadCategories = async (): Promise<Category[]> => {
    try {
      // 从爬虫服务获取分类列表
      const sites = await crawlerService.getActiveSites();
      const allCategories = new Set<string>();

      for (const site of sites.slice(0, 1)) {
        try {
          const categories = await crawlerService.callSiteMethod<string[]>(site.key, 'getCategories', []);
          if (categories && Array.isArray(categories)) {
            categories.forEach(cat => allCategories.add(cat));
          }
        } catch (error) {
          console.warn(`Failed to load categories from ${site.name}:`, error);
        }
      }

      const categoryArray = Array.from(allCategories);
      return categoryArray.length > 0 ? 
        categoryArray.map(cat => ({ id: cat, name: cat })) : 
        getMockCategories();
    } catch (error) {
      console.error('Failed to load categories:', error);
      return getMockCategories();
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadHomeData();
  };

  const navigateToDetail = (item: VideoItem) => {
    appNavigator.navigateToDetail({
      id: item.id,
      siteKey: item.siteKey,
      type: 'vod'
    });
  };

  const navigateToSearch = () => {
    appNavigator.navigateToSearch();
  };

  const navigateToCategory = (category: Category) => {
    appNavigator.navigateToCategory(category);
  };

  const navigateToLive = () => {
    appNavigator.navigateToLive();
  };

  const navigateToSettings = () => {
    appNavigator.navigateToSettings();
  };

  // 模拟数据函数
  const getMockRecommendedVods = (): VideoItem[] => [
    { id: '1', title: '流浪地球2', cover: '', siteKey: 'mock', originalUrl: '', rating: 9.2 },
    { id: '2', title: '满江红', cover: '', siteKey: 'mock', originalUrl: '', rating: 8.7 },
    { id: '3', title: '独行月球', cover: '', siteKey: 'mock', originalUrl: '', rating: 8.5 },
    { id: '4', title: '长津湖', cover: '', siteKey: 'mock', originalUrl: '', rating: 9.0 },
    { id: '5', title: '无名', cover: '', siteKey: 'mock', originalUrl: '', rating: 8.3 }
  ];

  const getMockHotVods = (): VideoItem[] => [
    { id: '101', title: '狂飙', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '全39集' },
    { id: '102', title: '三体', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '全30集' },
    { id: '103', title: '去有风的地方', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '全40集' },
    { id: '104', title: '星落凝成糖', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '更新至20集' },
    { id: '105', title: '显微镜下的大明之丝绢案', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '全36集' },
    { id: '106', title: '君子盟', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '全36集' },
    { id: '107', title: '我的人间烟火', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '更新至12集' },
    { id: '108', title: '重紫', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '全40集' },
    { id: '109', title: '听说你喜欢我', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '全36集' },
    { id: '110', title: '今生也是第一次', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '全30集' }
  ];

  const getMockLatestVods = (): VideoItem[] => [
    { id: '201', title: '新神榜：杨戬', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD国语' },
    { id: '202', title: '阿凡达：水之道', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD英语' },
    { id: '203', title: '熊出没·伴我熊芯', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD国语' },
    { id: '204', title: '深海', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD国语' },
    { id: '205', title: '消失的她', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD国语' },
    { id: '206', title: '保你平安', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD国语' },
    { id: '207', title: '铃芽之旅', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD日语' },
    { id: '208', title: '独行月球', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD国语' },
    { id: '209', title: '中国奇谭', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: '更新至8集' },
    { id: '210', title: '坏蛋联盟', cover: '', siteKey: 'mock', originalUrl: '', updateInfo: 'HD英语' }
  ];

  const getMockCategories = (): Category[] => [
    { id: 'movie', name: '电影' },
    { id: 'tv', name: '电视剧' },
    { id: 'anime', name: '动漫' },
    { id: 'variety', name: '综艺' },
    { id: 'doc', name: '纪录片' },
    { id: 'kids', name: '少儿' },
    { id: 'action', name: '动作' },
    { id: 'comedy', name: '喜剧' },
    { id: 'romance', name: '爱情' },
    { id: 'scifi', name: '科幻' }
  ];

  if (loading && !refreshing) {
    return (
      <View style={styles.loadingContainer}>
        <Text>加载中...</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      {/* 顶部搜索和功能区 */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.searchButton} onPress={navigateToSearch}>
          <Text style={styles.searchButtonText}>搜索电影、电视剧</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.iconButton} onPress={navigateToSettings}>
          <Text style={styles.iconText}>设置</Text>
        </TouchableOpacity>
      </View>

      {/* 功能入口 */}
      <View style={styles.features}>
        <TouchableOpacity style={styles.featureItem} onPress={navigateToLive}>
          <Text style={styles.featureText}>电视直播</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.featureItem}>
          <Text style={styles.featureText}>我的收藏</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.featureItem}>
          <Text style={styles.featureText}>观看历史</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.featureItem}>
          <Text style={styles.featureText}>线路管理</Text>
        </TouchableOpacity>
      </View>

      {/* 推荐内容 */}
      <Section title="为你推荐">
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.horizontalList}>
          {recommendedVods.map((item) => (
            <VideoCard key={item.id} item={item} onPress={() => navigateToDetail(item)} />
          ))}
        </ScrollView>
      </Section>

      {/* 分类导航 */}
      <Section title="热门分类">
        <View style={styles.categoryGrid}>
          {categories.map((category) => (
            <TouchableOpacity
              key={category.id}
              style={styles.categoryItem}
              onPress={() => navigateToCategory(category)}
            >
              <Text style={styles.categoryText}>{category.name}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </Section>

      {/* 热门影视 */}
      <Section title="热门影视">
        <View style={styles.vodGrid}>
          {hotVods.map((item) => (
            <VideoCard
              key={item.id}
              item={item}
              onPress={() => navigateToDetail(item)}
              showUpdateInfo
            />
          ))}
        </View>
      </Section>

      {/* 最新更新 */}
      <Section title="最新更新">
        <View style={styles.vodGrid}>
          {latestVods.map((item) => (
            <VideoCard
              key={item.id}
              item={item}
              onPress={() => navigateToDetail(item)}
              showUpdateInfo
            />
          ))}
        </View>
      </Section>
    </ScrollView>
  );
};

// 分类接口
interface Category {
  id: string;
  name: string;
}

// 视频卡片组件
interface VideoCardProps {
  item: VideoItem;
  onPress: () => void;
  showUpdateInfo?: boolean;
}

const VideoCard: React.FC<VideoCardProps> = ({ item, onPress, showUpdateInfo = false }) => {
  return (
    <TouchableOpacity style={styles.videoCard} onPress={onPress}>
      <View style={styles.coverContainer}>
        {item.cover ? (
          <Image source={{ uri: item.cover }} style={styles.cover} />
        ) : (
          <View style={[styles.cover, styles.coverPlaceholder]}>
            <Text style={styles.coverPlaceholderText}>暂无封面</Text>
          </View>
        )}
        {item.rating > 0 && (
          <View style={styles.ratingBadge}>
            <Text style={styles.ratingText}>{item.rating}</Text>
          </View>
        )}
      </View>
      <Text style={styles.videoTitle} numberOfLines={2}>{item.title}</Text>
      {showUpdateInfo && item.updateInfo && (
        <Text style={styles.updateInfo} numberOfLines={1}>{item.updateInfo}</Text>
      )}
    </TouchableOpacity>
  );
};

// 区块组件
interface SectionProps {
  title: string;
  children: React.ReactNode;
}

const Section: React.FC<SectionProps> = ({ title, children }) => {
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>{title}</Text>
        <TouchableOpacity>
          <Text style={styles.moreText}>更多</Text>
        </TouchableOpacity>
      </View>
      <View style={styles.sectionContent}>
        {children}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#fff',
  },
  searchButton: {
    flex: 1,
    height: 40,
    backgroundColor: '#f0f0f0',
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  searchButtonText: {
    color: '#666',
  },
  iconButton: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  iconText: {
    fontSize: 24,
  },
  features: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    padding: 16,
    backgroundColor: '#fff',
    marginBottom: 8,
  },
  featureItem: {
    width: '25%',
    alignItems: 'center',
    marginBottom: 16,
  },
  featureText: {
    marginTop: 8,
    fontSize: 14,
  },
  section: {
    marginBottom: 8,
    backgroundColor: '#fff',
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  moreText: {
    color: '#007aff',
  },
  sectionContent: {
    padding: 16,
  },
  horizontalList: {
    flexGrow: 0,
  },
  videoCard: {
    width: 120,
    marginRight: 12,
  },
  coverContainer: {
    position: 'relative',
    marginBottom: 8,
  },
  cover: {
    width: 120,
    height: 160,
    borderRadius: 8,
    backgroundColor: '#e0e0e0',
  },
  coverPlaceholder: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  coverPlaceholderText: {
    color: '#999',
  },
  ratingBadge: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  ratingText: {
    color: '#fff',
    fontSize: 12,
  },
  videoTitle: {
    fontSize: 14,
    fontWeight: '500',
    marginBottom: 4,
  },
  updateInfo: {
    fontSize: 12,
    color: '#999',
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginHorizontal: -4,
  },
  categoryItem: {
    width: '20%',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 4,
  },
  categoryText: {
    fontSize: 14,
  },
  vodGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginHorizontal: -4,
  },
});

export default HomePage;