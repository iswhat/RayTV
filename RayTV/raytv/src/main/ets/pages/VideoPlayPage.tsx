// 视频播放页面
// 提供视频播放、弹幕、清晰度切换等功能

import React, { useState, useEffect, useRef } from 'react';
import { View, Text, TouchableOpacity, ScrollView, Image, StyleSheet, Dimensions, BackHandler } from '@ohos.universal';
import { AppNavigator } from '../navigation/AppNavigator';
import { ConfigService } from '../service/config/ConfigService';
import { DanmakuService } from '../service/danmaku/DanmakuService';
import { AnalyticsService } from '../service/analytics/AnalyticsService';
import { HttpService } from '../service/HttpService';
import { StorageUtil } from '../common/util/StorageUtil';
import { Vod } from '../data/bean/Vod.ets';
import { LiveStream } from '../data/bean/Live.ets';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

type PlayParams = {
  id: string;
  siteKey: string;
  type: 'vod' | 'live';
  episodeId?: string;
  title?: string;
};

const VideoPlayPage: React.FC<{ params: PlayParams }> = ({ params }) => {
  const [videoInfo, setVideoInfo] = useState<Vod | LiveStream | null>(null);
  const [playUrl, setPlayUrl] = useState('');
  const [playSources, setPlaySources] = useState<Array<{ name: string; url: string }>>([]);
  const [selectedSourceIndex, setSelectedSourceIndex] = useState(0);
  const [episodes, setEpisodes] = useState<Array<{ id: string; name: string }>>([]);
  const [selectedEpisodeIndex, setSelectedEpisodeIndex] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showDanmaku, setShowDanmaku] = useState(true);
  const [danmakuOpacity, setDanmakuOpacity] = useState(0.8);
  const [danmakuFontSize, setDanmakuFontSize] = useState(16);
  const [danmakuSpeed, setDanmakuSpeed] = useState(1);
  const [showControl, setShowControl] = useState(true);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [showSourceSelect, setShowSourceSelect] = useState(false);
  const [showEpisodeList, setShowEpisodeList] = useState(false);
  const [showDanmakuSettings, setShowDanmakuSettings] = useState(false);
  
  const videoRef = useRef<any>(null);
  const danmakuContainerRef = useRef<View>(null);
  const controlTimeoutRef = useRef<number>(0);
  const appNavigator = AppNavigator.getInstance();
  const configService = ConfigService.getInstance();
  const danmakuService = DanmakuService.getInstance();
  const analyticsService = AnalyticsService.getInstance();
  const httpService = HttpService.getInstance();
  const storageUtil = StorageUtil.getInstance();

  useEffect(() => {
    analyticsService.trackVideoPlay({
      videoId: params.id,
      siteKey: params.siteKey,
      type: params.type,
      title: params.title || '未知标题'
    });
    
    loadVideoData();
    loadDanmakuConfig();
    setupDanmaku();
    
    // 监听返回键
    const backHandler = BackHandler.addEventListener('hardwareBackPress', handleBackPress);
    
    return () => {
      backHandler.remove();
      clearTimeout(controlTimeoutRef.current);
      danmakuService.stop();
      savePlayHistory();
    };
  }, [params]);

  const loadVideoData = async () => {
    try {
      setLoading(true);
      setError('');
      
      if (params.type === 'vod') {
        await loadVodData();
      } else {
        await loadLiveData();
      }
    } catch (err) {
      console.error('Failed to load video data:', err);
      setError('加载失败，请稍后重试');
    } finally {
      setLoading(false);
    }
  };

  const loadVodData = async () => {
    // 在实际项目中，这里会调用爬虫服务获取视频详情和播放地址
    // 这里提供模拟数据
    const mockVod: Vod = {
      id: params.id,
      title: params.title || '模拟视频标题',
      cover: '',
      description: '这是一段模拟的视频描述，在实际应用中会显示真实的视频详情信息。',
      category: '电影',
      tags: ['动作', '冒险'],
      rating: 9.2,
      year: '2023',
      region: '中国大陆',
      director: '张艺谋',
      actors: ['演员1', '演员2'],
      updateTime: new Date().toISOString(),
      playSources: [
        { name: '线路1', url: 'https://example.com/player1.mp4' },
        { name: '线路2', url: 'https://example.com/player2.mp4' },
        { name: '线路3', url: 'https://example.com/player3.mp4' }
      ],
      episodes: [
        { id: 'ep1', name: '第1集' },
        { id: 'ep2', name: '第2集' },
        { id: 'ep3', name: '第3集' },
        { id: 'ep4', name: '第4集' },
        { id: 'ep5', name: '第5集' },
        { id: 'ep6', name: '第6集' },
        { id: 'ep7', name: '第7集' },
        { id: 'ep8', name: '第8集' },
        { id: 'ep9', name: '第9集' },
        { id: 'ep10', name: '第10集' }
      ]
    };
    
    setVideoInfo(mockVod);
    setPlaySources(mockVod.playSources);
    setEpisodes(mockVod.episodes);
    
    if (mockVod.playSources.length > 0) {
      setPlayUrl(mockVod.playSources[0].url);
    }
    
    // 尝试加载历史播放记录
    loadPlayHistory();
  };

  const loadLiveData = async () => {
    // 模拟直播数据
    const mockLive: LiveStream = {
      id: params.id,
      title: params.title || '模拟直播频道',
      cover: '',
      description: '这是一段模拟的直播描述',
      url: 'https://example.com/live.m3u8',
      category: '新闻',
      source: '模拟源',
      quality: '高清',
      onlineCount: 1234,
      startTime: new Date().toISOString(),
      isLive: true
    };
    
    setVideoInfo(mockLive);
    setPlayUrl(mockLive.url);
    setIsPlaying(true);
  };

  const loadDanmakuConfig = async () => {
    try {
      const config = await configService.getDanmakuConfig();
      setShowDanmaku(config.enabled);
      setDanmakuOpacity(config.opacity);
      setDanmakuFontSize(config.fontSize);
      setDanmakuSpeed(config.speed);
    } catch (error) {
      console.warn('Failed to load danmaku config:', error);
    }
  };

  const setupDanmaku = () => {
    danmakuService.initialize({
      container: danmakuContainerRef.current,
      width: SCREEN_WIDTH,
      height: 200,
      fontSize: danmakuFontSize,
      opacity: danmakuOpacity,
      speed: danmakuSpeed
    });
    
    if (showDanmaku) {
      danmakuService.start();
      // 模拟加载弹幕数据
      danmakuService.loadDanmakus([
        { text: '太精彩了！', type: 'scroll', color: '#ffffff', timestamp: 0 },
        { text: '这个演员演得真好', type: 'scroll', color: '#ffffff', timestamp: 1000 },
        { text: '画面太震撼了', type: 'top', color: '#ff0000', timestamp: 2000 },
        { text: '期待下一集', type: 'scroll', color: '#ffff00', timestamp: 3000 },
        { text: '点赞！', type: 'bottom', color: '#00ff00', timestamp: 4000 }
      ]);
    }
  };

  const loadPlayHistory = async () => {
    try {
      const history = await storageUtil.getPlayHistory(params.id);
      if (history) {
        setCurrentTime(history.currentTime || 0);
        setSelectedEpisodeIndex(history.episodeIndex || 0);
        setSelectedSourceIndex(history.sourceIndex || 0);
      }
    } catch (error) {
      console.warn('Failed to load play history:', error);
    }
  };

  const savePlayHistory = async () => {
    if (params.type === 'vod' && videoInfo) {
      try {
        await storageUtil.savePlayHistory({
          videoId: params.id,
          siteKey: params.siteKey,
          title: videoInfo.title,
          currentTime,
          duration,
          episodeIndex: selectedEpisodeIndex,
          sourceIndex: selectedSourceIndex,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.warn('Failed to save play history:', error);
      }
    }
  };

  const handleBackPress = () => {
    if (isFullscreen) {
      exitFullscreen();
      return true;
    }
    if (showControl) {
      appNavigator.goBack();
      return true;
    }
    showControls();
    return true;
  };

  const showControls = () => {
    setShowControl(true);
    clearTimeout(controlTimeoutRef.current);
    controlTimeoutRef.current = setTimeout(() => {
      if (isPlaying && !isFullscreen) {
        setShowControl(false);
      }
    }, 3000) as unknown as number;
  };

  const togglePlayPause = () => {
    const newPlayingState = !isPlaying;
    setIsPlaying(newPlayingState);
    
    if (newPlayingState) {
      // 模拟播放
      analyticsService.trackVideoPlayStart(params.id, params.siteKey);
    } else {
      // 模拟暂停
      analyticsService.trackVideoPause(params.id, params.siteKey, currentTime);
    }
    
    showControls();
  };

  const toggleFullscreen = () => {
    if (isFullscreen) {
      exitFullscreen();
    } else {
      enterFullscreen();
    }
  };

  const enterFullscreen = () => {
    setIsFullscreen(true);
    setShowControl(true);
    // 在实际项目中，这里会调用系统的全屏API
  };

  const exitFullscreen = () => {
    setIsFullscreen(false);
    // 在实际项目中，这里会调用系统的退出全屏API
  };

  const handleProgressChange = (time: number) => {
    setCurrentTime(time);
  };

  const handleDurationChange = (newDuration: number) => {
    setDuration(newDuration);
  };

  const handleSourceChange = (index: number) => {
    if (index >= 0 && index < playSources.length) {
      setSelectedSourceIndex(index);
      setPlayUrl(playSources[index].url);
      setShowSourceSelect(false);
      analyticsService.trackSourceChange(params.id, playSources[index].name);
    }
  };

  const handleEpisodeChange = (index: number) => {
    if (index >= 0 && index < episodes.length) {
      setSelectedEpisodeIndex(index);
      setShowEpisodeList(false);
      // 在实际项目中，这里会加载对应集数的视频
      analyticsService.trackEpisodeChange(params.id, episodes[index].name);
    }
  };

  const toggleDanmaku = () => {
    setShowDanmaku(!showDanmaku);
    if (showDanmaku) {
      danmakuService.stop();
    } else {
      danmakuService.start();
    }
  };

  const sendDanmaku = (text: string, type: 'scroll' | 'top' | 'bottom' = 'scroll') => {
    if (text && showDanmaku) {
      const danmaku = {
        text,
        type,
        color: '#ffffff',
        timestamp: Date.now()
      };
      danmakuService.sendDanmaku(danmaku);
      analyticsService.trackDanmakuSend(params.id, text);
    }
  };

  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const renderVideoPlayer = () => {
    if (loading) {
      return (
        <View style={styles.loadingContainer}>
          <Text>加载中...</Text>
        </View>
      );
    }
    
    if (error) {
      return (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={loadVideoData}>
            <Text style={styles.retryButtonText}>重试</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return (
      <View style={[styles.playerContainer, isFullscreen && styles.fullscreenPlayer]}>
        {/* 视频播放区域 */}
        <View style={styles.videoWrapper} onTouch={showControls}>
          {/* 在实际项目中，这里会使用真正的视频组件 */}
          <View style={styles.videoPlaceholder}>
            <Text style={styles.videoPlaceholderText}>视频播放区域</Text>
            <Text style={styles.videoTitleSmall}>{videoInfo?.title}</Text>
          </View>
          
          {/* 弹幕容器 */}
          {showDanmaku && (
            <View 
              ref={danmakuContainerRef}
              style={styles.danmakuContainer}
            />
          )}
          
          {/* 控制层 */}
          {showControl && (
            <View style={styles.controlOverlay}>
              <View style={styles.topControls}>
                <TouchableOpacity onPress={handleBackPress} style={styles.backButton}>
                  <Text style={styles.backButtonText}>←</Text>
                </TouchableOpacity>
                <Text style={styles.videoTitleInControl} numberOfLines={1}>
                  {videoInfo?.title}
                </Text>
              </View>
              
              <View style={styles.centerControls}>
                <TouchableOpacity onPress={togglePlayPause} style={styles.playPauseButton}>
                  <Text style={styles.playPauseIcon}>{isPlaying ? '⏸' : '▶'}</Text>
                </TouchableOpacity>
              </View>
              
              <View style={styles.bottomControls}>
                <Text style={styles.timeText}>{formatTime(currentTime)}</Text>
                {/* 进度条 */}
                <View style={styles.progressBarContainer}>
                  <View style={styles.progressBar}>
                    <View style={[styles.progress, { width: `${(currentTime / duration) * 100 || 0}%` }]} />
                  </View>
                </View>
                <Text style={styles.timeText}>{formatTime(duration)}</Text>
                
                <TouchableOpacity onPress={toggleDanmaku} style={styles.controlButton}>
                  <Text style={styles.controlButtonText}>{showDanmaku ? '弹幕' : '弹幕'}</Text>
                </TouchableOpacity>
                
                <TouchableOpacity onPress={toggleFullscreen} style={styles.controlButton}>
                  <Text style={styles.controlButtonText}>{isFullscreen ? '⤢' : '⤡'}</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
        </View>
      </View>
    );
  };

  const renderSourceSelector = () => {
    if (!showSourceSelect || playSources.length === 0) return null;
    
    return (
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          <Text style={styles.modalTitle}>选择播放源</Text>
          <ScrollView style={styles.modalList}>
            {playSources.map((source, index) => (
              <TouchableOpacity
                key={index}
                style={[
                  styles.modalItem,
                  index === selectedSourceIndex && styles.modalItemSelected
                ]}
                onPress={() => handleSourceChange(index)}
              >
                <Text style={[
                  styles.modalItemText,
                  index === selectedSourceIndex && styles.modalItemTextSelected
                ]}>
                  {source.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
          <TouchableOpacity
            style={styles.modalCloseButton}
            onPress={() => setShowSourceSelect(false)}
          >
            <Text style={styles.modalCloseButtonText}>关闭</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const renderEpisodeList = () => {
    if (!showEpisodeList || episodes.length === 0) return null;
    
    return (
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          <Text style={styles.modalTitle}>选集</Text>
          <ScrollView style={styles.modalList}>
            <View style={styles.episodeGrid}>
              {episodes.map((episode, index) => (
                <TouchableOpacity
                  key={episode.id}
                  style={[
                    styles.episodeItem,
                    index === selectedEpisodeIndex && styles.episodeItemSelected
                  ]}
                  onPress={() => handleEpisodeChange(index)}
                >
                  <Text style={[
                    styles.episodeItemText,
                    index === selectedEpisodeIndex && styles.episodeItemTextSelected
                  ]}>
                    {episode.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </ScrollView>
          <TouchableOpacity
            style={styles.modalCloseButton}
            onPress={() => setShowEpisodeList(false)}
          >
            <Text style={styles.modalCloseButtonText}>关闭</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const renderInfoSection = () => {
    if (!videoInfo || isFullscreen) return null;
    
    return (
      <ScrollView style={styles.infoSection}>
        <Text style={styles.videoTitle}>{videoInfo.title}</Text>
        
        {videoInfo.rating !== undefined && (
          <Text style={styles.rating}>评分: {videoInfo.rating}</Text>
        )}
        
        <View style={styles.metaInfo}>
          {videoInfo.category && <Text style={styles.metaItem}>{videoInfo.category}</Text>}
          {videoInfo.year && <Text style={styles.metaItem}>{videoInfo.year}</Text>}
          {videoInfo.region && <Text style={styles.metaItem}>{videoInfo.region}</Text>}
        </View>
        
        <Text style={styles.descriptionTitle}>剧情简介</Text>
        <Text style={styles.description}>{videoInfo.description}</Text>
        
        {playSources.length > 0 && (
          <View style={styles.sourceSection}>
            <Text style={styles.sectionTitle}>播放源</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              {playSources.map((source, index) => (
                <TouchableOpacity
                  key={index}
                  style={[
                    styles.sourceItem,
                    index === selectedSourceIndex && styles.sourceItemSelected
                  ]}
                  onPress={() => handleSourceChange(index)}
                >
                  <Text style={[
                    styles.sourceItemText,
                    index === selectedSourceIndex && styles.sourceItemTextSelected
                  ]}>
                    {source.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        )}
        
        {episodes.length > 0 && (
          <View style={styles.episodeSection}>
            <Text style={styles.sectionTitle}>选集</Text>
            <ScrollView>
              <View style={styles.episodeGrid}>
                {episodes.map((episode, index) => (
                  <TouchableOpacity
                    key={episode.id}
                    style={[
                      styles.episodeItemSmall,
                      index === selectedEpisodeIndex && styles.episodeItemSelected
                    ]}
                    onPress={() => handleEpisodeChange(index)}
                  >
                    <Text style={[
                      styles.episodeItemText,
                      index === selectedEpisodeIndex && styles.episodeItemTextSelected
                    ]}>
                      {episode.name}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </ScrollView>
          </View>
        )}
        
        {/* 相关推荐 */}
        <View style={styles.recommendSection}>
          <Text style={styles.sectionTitle}>相关推荐</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {Array.from({ length: 6 }).map((_, index) => (
              <TouchableOpacity key={index} style={styles.recommendItem}>
                <View style={styles.recommendCover}>
                  <Text style={styles.recommendCoverText}>推荐{index + 1}</Text>
                </View>
                <Text style={styles.recommendTitle} numberOfLines={2}>相关推荐视频标题</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      </ScrollView>
    );
  };

  return (
    <View style={[styles.container, isFullscreen && styles.fullscreenContainer]}>
      {renderVideoPlayer()}
      {renderInfoSection()}
      {renderSourceSelector()}
      {renderEpisodeList()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  fullscreenContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 9999,
  },
  playerContainer: {
    width: SCREEN_WIDTH,
    height: 200,
    backgroundColor: '#000',
  },
  fullscreenPlayer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    width: SCREEN_WIDTH,
    height: SCREEN_HEIGHT,
  },
  videoWrapper: {
    flex: 1,
    position: 'relative',
  },
  videoPlaceholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#111',
  },
  videoPlaceholderText: {
    color: '#fff',
    fontSize: 18,
    marginBottom: 8,
  },
  videoTitleSmall: {
    color: '#999',
    fontSize: 14,
  },
  danmakuContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    pointerEvents: 'none',
  },
  controlOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    justifyContent: 'space-between',
  },
  topControls: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 8,
  },
  backButton: {
    marginRight: 12,
  },
  backButtonText: {
    color: '#fff',
    fontSize: 24,
  },
  videoTitleInControl: {
    flex: 1,
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  centerControls: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  playPauseButton: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  playPauseIcon: {
    color: '#fff',
    fontSize: 32,
  },
  bottomControls: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingBottom: 16,
    paddingTop: 8,
  },
  timeText: {
    color: '#fff',
    fontSize: 12,
    marginRight: 8,
  },
  progressBarContainer: {
    flex: 1,
    height: 30,
    justifyContent: 'center',
    marginRight: 8,
  },
  progressBar: {
    height: 2,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 1,
  },
  progress: {
    height: '100%',
    backgroundColor: '#007aff',
  },
  controlButton: {
    marginLeft: 16,
  },
  controlButtonText: {
    color: '#fff',
    fontSize: 18,
  },
  infoSection: {
    flex: 1,
    backgroundColor: '#fff',
  },
  videoTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    padding: 16,
    paddingBottom: 8,
  },
  rating: {
    fontSize: 16,
    color: '#ff6b00',
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  metaInfo: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  metaItem: {
    fontSize: 14,
    color: '#666',
    marginRight: 16,
    marginBottom: 8,
  },
  descriptionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    paddingHorizontal: 16,
    paddingBottom: 8,
  },
  description: {
    fontSize: 14,
    color: '#333',
    lineHeight: 20,
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    paddingHorizontal: 16,
    paddingBottom: 8,
  },
  sourceSection: {
    paddingVertical: 16,
    borderTopWidth: 8,
    borderTopColor: '#f5f5f5',
  },
  sourceItem: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: '#f0f0f0',
    borderRadius: 4,
    marginLeft: 16,
  },
  sourceItemSelected: {
    backgroundColor: '#007aff',
  },
  sourceItemText: {
    color: '#333',
  },
  sourceItemTextSelected: {
    color: '#fff',
  },
  episodeSection: {
    paddingVertical: 16,
    borderTopWidth: 8,
    borderTopColor: '#f5f5f5',
  },
  episodeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 12,
  },
  episodeItem: {
    width: 60,
    height: 40,
    backgroundColor: '#f0f0f0',
    borderRadius: 4,
    justifyContent: 'center',
    alignItems: 'center',
    margin: 4,
  },
  episodeItemSmall: {
    width: 60,
    height: 32,
    backgroundColor: '#f0f0f0',
    borderRadius: 4,
    justifyContent: 'center',
    alignItems: 'center',
    margin: 4,
  },
  episodeItemSelected: {
    backgroundColor: '#007aff',
  },
  episodeItemText: {
    color: '#333',
    fontSize: 14,
  },
  episodeItemTextSelected: {
    color: '#fff',
  },
  recommendSection: {
    paddingVertical: 16,
    borderTopWidth: 8,
    borderTopColor: '#f5f5f5',
  },
  recommendItem: {
    width: 120,
    marginLeft: 16,
  },
  recommendCover: {
    width: 120,
    height: 160,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  recommendCoverText: {
    color: '#999',
  },
  recommendTitle: {
    fontSize: 14,
    lineHeight: 20,
  },
  modalOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
  },
  modalContent: {
    width: '80%',
    maxHeight: '70%',
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 16,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 16,
    textAlign: 'center',
  },
  modalList: {
    maxHeight: 400,
  },
  modalItem: {
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  modalItemSelected: {
    backgroundColor: '#f0f0f0',
  },
  modalItemText: {
    fontSize: 16,
  },
  modalItemTextSelected: {
    color: '#007aff',
    fontWeight: 'bold',
  },
  modalCloseButton: {
    marginTop: 16,
    paddingVertical: 12,
    backgroundColor: '#007aff',
    borderRadius: 4,
    alignItems: 'center',
  },
  modalCloseButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000',
    padding: 16,
  },
  errorText: {
    color: '#fff',
    fontSize: 16,
    marginBottom: 16,
    textAlign: 'center',
  },
  retryButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    backgroundColor: '#007aff',
    borderRadius: 4,
  },
  retryButtonText: {
    color: '#fff',
    fontSize: 16,
  },
});

export default VideoPlayPage;