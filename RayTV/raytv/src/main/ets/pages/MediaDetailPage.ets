import { useState, useEffect, onMounted, onUnmounted } from '@ohos/base';
import { ScrollView, Image, Text, Button, List, ListItem, Divider, LoadingProgress, Tag, SearchBar } from '@ohos/base/ui';
import { Router, ParamRouter } from '@ohos.router';
import { mediaService } from '../service/media/MediaService';
import { favoriteService } from '../service/media/FavoriteService';
import { historyService } from '../service/media/HistoryService';
import Logger from '@ohos/base/Logger';

/**
 * 媒体详情页组件
 * 展示媒体详细信息、集数列表和操作按钮
 */
@Component
struct MediaDetailPage {
  private readonly TAG: string = 'MediaDetailPage';
  
  // 路由参数
  private mediaId: string = '';
  private siteKey: string = '';
  
  // 状态管理
  @State mediaDetail: MediaDetail | null = null;
  @State episodes: Episode[] = [];
  @State playSources: PlaySource[] = [];
  @State filteredSources: PlaySource[] = [];
  @State relatedMedia: MediaItem[] = [];
  @State isLoading: boolean = true;
  @State isFavorite: boolean = false;
  @State selectedTab: string = 'episodes'; // 'episodes' or 'sources'
  @State currentPage: number = 1;
  @State hasMoreEpisodes: boolean = true;
  @State errorMessage: string = '';
  @State selectedEpisodeIndex: number = 0;
  @State selectedSeason: number = 1;
  @State seasons: number[] = [1]; // 默认只有第1季
  @State searchText: string = '';
  
  // 每页显示的剧集数量
  private episodesPageSize: number = 50;
  
  // 初始化
  onMounted(() => {
    Logger.info(this.TAG, 'MediaDetailPage mounted');
    
    // 获取路由参数
    const params = Router.getParams();
    this.mediaId = params?.['mediaId'] || '';
    this.siteKey = params?.['siteKey'] || '';
    
    Logger.info(this.TAG, `Loading media detail for: ${this.siteKey}:${this.mediaId}`);
    
    // 加载媒体详情
    this.loadMediaDetail();
  });
  
  // 清理资源
  onUnmounted(() => {
    Logger.info(this.TAG, 'MediaDetailPage unmounted');
  });
  
  /**
   * 加载媒体详情
   */
  private async loadMediaDetail(): Promise<void> {
    if (!this.mediaId || !this.siteKey) {
      this.errorMessage = '缺少必要参数';
      this.isLoading = false;
      return;
    }
    
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // 并行加载所有数据
      const [detail, isFav] = await Promise.all([
        this.fetchMediaDetail(),
        favoriteService.isFavorite(this.mediaId, this.siteKey)
      ]);
      
      this.mediaDetail = detail;
      this.isFavorite = isFav;
      
      // 加载相关推荐
      this.loadRelatedMedia();
    } catch (error) {
      Logger.error(this.TAG, `Failed to load media detail: ${error}`);
      this.errorMessage = '加载失败，请稍后重试';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 获取媒体详情
   */
  private async fetchMediaDetail(): Promise<MediaDetail> {
    try {
      const detail = await mediaService.getMediaDetail(this.mediaId, this.siteKey);
      
      // 初始化剧集列表
      if (detail.episodes && detail.episodes.length > 0) {
        this.episodes = detail.episodes;
        
        // 提取所有季数
        this.seasons = [...new Set(detail.episodes.map(ep => ep.season || 1))].sort((a, b) => a - b);
        
        // 检查是否有更多剧集
        this.hasMoreEpisodes = detail.episodes.length >= this.episodesPageSize;
      }
      
      return detail;
    } catch (error) {
      Logger.error(this.TAG, `Failed to fetch media detail: ${error}`);
      throw error;
    }
  }
  
  /**
   * 加载更多剧集
   */
  private async loadMoreEpisodes(): Promise<void> {
    if (!this.hasMoreEpisodes || !this.mediaId || !this.siteKey) return;
    
    try {
      this.currentPage++;
      const moreEpisodes = await mediaService.getEpisodes(
        this.mediaId, 
        this.siteKey, 
        this.currentPage, 
        this.episodesPageSize
      );
      
      if (moreEpisodes && moreEpisodes.length > 0) {
        this.episodes = [...this.episodes, ...moreEpisodes];
        this.hasMoreEpisodes = moreEpisodes.length === this.episodesPageSize;
      } else {
        this.hasMoreEpisodes = false;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load more episodes: ${error}`);
    }
  }
  
  /**
   * 加载播放源
   */
  private async loadPlaySources(episodeId?: string): Promise<void> {
    if (!this.mediaId || !this.siteKey) return;
    
    try {
      this.playSources = await mediaService.getPlaySources(
        this.mediaId, 
        this.siteKey,
        episodeId
      );
      this.filteredSources = [...this.playSources]; // 初始化过滤后的列表
    } catch (error) {
      Logger.error(this.TAG, `Failed to load play sources: ${error}`);
      this.errorMessage = '加载播放源失败';
    }
  }
  
  /**
   * 处理搜索文本变化
   */
  private handleSearchChange(text: string) {
    this.searchText = text;
    
    // 根据搜索文本过滤片源
    if (text.trim()) {
      const searchLower = text.toLowerCase();
      this.filteredSources = this.playSources.filter(source => 
        source.name.toLowerCase().includes(searchLower) ||
        (source.description && source.description.toLowerCase().includes(searchLower))
      );
    } else {
      // 如果搜索文本为空，显示所有片源
      this.filteredSources = [...this.playSources];
    }
  }
  
  /**
   * 加载相关推荐
   */
  private async loadRelatedMedia(): Promise<void> {
    if (!this.mediaId || !this.siteKey) return;
    
    try {
      this.relatedMedia = await mediaService.getRelatedMedia(
        this.mediaId, 
        this.siteKey,
        10
      );
    } catch (error) {
      Logger.error(this.TAG, `Failed to load related media: ${error}`);
    }
  }
  
  /**
   * 处理收藏/取消收藏
   */
  private async handleToggleFavorite(): Promise<void> {
    if (!this.mediaId || !this.siteKey || !this.mediaDetail) return;
    
    try {
      if (this.isFavorite) {
        // 取消收藏
        await favoriteService.removeFavorite(this.mediaId, this.siteKey);
        Logger.info(this.TAG, `Removed from favorites: ${this.mediaId}`);
      } else {
        // 添加收藏
        const favoriteItem: FavoriteItem = {
          id: `${this.siteKey}_${this.mediaId}`,
          mediaId: this.mediaId,
          siteKey: this.siteKey,
          title: this.mediaDetail.title,
          coverUrl: this.mediaDetail.coverUrl,
          type: this.mediaDetail.type,
          favoriteTime: Date.now()
        };
        await favoriteService.addFavorite(favoriteItem);
        Logger.info(this.TAG, `Added to favorites: ${this.mediaId}`);
      }
      
      this.isFavorite = !this.isFavorite;
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle favorite: ${error}`);
      this.errorMessage = '操作失败，请稍后重试';
    }
  }
  
  /**
   * 处理播放剧集
   */
  private async handlePlayEpisode(episode: Episode): Promise<void> {
    if (!this.mediaId || !this.siteKey || !this.mediaDetail) return;
    
    try {
      // 记录播放历史
      const historyItem: HistoryItem = {
        id: `${this.siteKey}_${this.mediaId}_${episode.id}`,
        mediaId: this.mediaId,
        siteKey: this.siteKey,
        episodeId: episode.id,
        title: this.mediaDetail.title,
        coverUrl: this.mediaDetail.coverUrl,
        episodeName: episode.name,
        currentTime: 0,
        duration: 0,
        lastPlayTime: Date.now()
      };
      await historyService.addHistory(historyItem);
      
      // 加载播放源并播放
      await this.loadPlaySources(episode.id);
      
      if (this.playSources.length > 0) {
        // 跳转到播放页面
        Router.push({
          url: 'pages/PlaybackPage',
          params: {
            mediaId: this.mediaId,
            siteKey: this.siteKey,
            episodeId: episode.id,
            playSourceIndex: 0,
            mediaTitle: this.mediaDetail.title,
            episodeName: episode.name
          }
        });
      } else {
        this.errorMessage = '暂无可用播放源';
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to play episode: ${error}`);
      this.errorMessage = '播放失败，请稍后重试';
    }
  }
  
  /**
   * 处理播放源点击
   */
  private async handlePlaySourceClick(source: PlaySource): void {
    if (!this.mediaId || !this.siteKey || !this.mediaDetail) return;
    
    try {
      let episodeId: string | undefined;
      let episodeName: string | undefined;
      let currentPlayPosition = 0;
      
      // 获取选中剧集信息
      if (this.selectedEpisodeIndex >= 0 && this.episodes[this.selectedEpisodeIndex]) {
        episodeId = this.episodes[this.selectedEpisodeIndex].id;
        episodeName = this.episodes[this.selectedEpisodeIndex].name;
        
        // 尝试获取上次观看进度
        if (episodeId) {
          const watchHistory = await historyService.getWatchHistory(
            this.mediaId,
            this.siteKey,
            episodeId
          );
          if (watchHistory && watchHistory.position > 0) {
            currentPlayPosition = watchHistory.position;
          }
        }
      }
      
      // 跳转到播放页面
      Router.push({
        url: 'pages/PlaybackPage',
        params: {
          mediaId: this.mediaId,
          siteKey: this.siteKey,
          episodeId: episodeId,
          playSource: source,
          playSources: this.filteredSources,
          mediaTitle: this.mediaDetail.title,
          episodeName: episodeName,
          startPosition: currentPlayPosition,
          autoSwitchSourceOnError: true
        }
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle play source click: ${error}`);
      this.errorMessage = '播放失败';
    }
  }
  
  /**
   * 保存当前播放进度
   */
  private async saveCurrentPlayProgress(episodeId: string): Promise<void> {
    try {
      const position = await playbackService.getCurrentPosition();
      const duration = await playbackService.getDuration();
      
      if (position > 0 && this.mediaId && this.siteKey) {
        await historyService.saveWatchProgress(
          this.mediaId,
          this.siteKey,
          episodeId,
          position,
          duration
        );
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to save play progress: ${error}`);
    }
  }
  
  /**
   * 处理相关媒体点击
   */
  private handleRelatedMediaClick(media: MediaItem): void {
    // 跳转到对应媒体详情页
    Router.push({
      url: 'pages/MediaDetailPage',
      params: {
        mediaId: media.id,
        siteKey: media.siteKey
      }
    });
  }
  
  /**
   * 处理季切换
   */
  private handleSeasonChange(season: number): void {
    this.selectedSeason = season;
    // 重置选中的集数
    this.selectedEpisodeIndex = -1;
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    Router.back();
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    <Stack className="loading-container">
      <LoadingProgress className="loading-progress" color="#FF4500" />
      <Text className="loading-text">加载中...</Text>
    </Stack>
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    <Stack className="error-container">
      <Text className="error-icon">⚠️</Text>
      <Text className="error-message">{this.errorMessage}</Text>
      <Button className="retry-button" onClick={() => this.loadMediaDetail()}>
        重试
      </Button>
    </Stack>
  }
  
  /**
   * 渲染媒体信息头部
   */
  @Builder
  private renderHeader(): void {
    if (!this.mediaDetail) return;
    
    <Stack className="media-header">
      <Flex className="media-info">
        <Image
          src={this.mediaDetail.coverUrl || 'https://via.placeholder.com/200x300?text=No+Image'}
          className="media-cover"
          objectFit="cover"
        />
        <Flex className="media-details" direction="column">
          <Text className="media-title">{this.mediaDetail.title}</Text>
          <Flex className="media-meta">
            {this.mediaDetail.year && <Tag className="meta-tag">{this.mediaDetail.year}</Tag>}
            {this.mediaDetail.score && <Tag className="meta-tag score">{this.mediaDetail.score}</Tag>}
            {this.mediaDetail.type && <Tag className="meta-tag">{this.mediaDetail.type}</Tag>}
            {this.mediaDetail.status && <Tag className="meta-tag">{this.mediaDetail.status}</Tag>}
          </Flex>
          {this.mediaDetail.directors && this.mediaDetail.directors.length > 0 && (
            <Text className="media-directors">导演: {this.mediaDetail.directors.join(', ')}</Text>
          )}
          {this.mediaDetail.actors && this.mediaDetail.actors.length > 0 && (
            <Text className="media-actors">演员: {this.mediaDetail.actors.slice(0, 5).join(', ')}
              {this.mediaDetail.actors.length > 5 ? '...' : ''}</Text>
          )}
          {this.mediaDetail.genres && this.mediaDetail.genres.length > 0 && (
            <Text className="media-genres">类型: {this.mediaDetail.genres.join(', ')}</Text>
          )}
          {this.mediaDetail.regions && this.mediaDetail.regions.length > 0 && (
            <Text className="media-regions">地区: {this.mediaDetail.regions.join(', ')}</Text>
          )}
        </Flex>
      </Flex>
      
      <Stack className="action-buttons">
        <Button className="primary-button" onClick={() => {
          if (this.episodes.length > 0) {
            this.handlePlayEpisode(this.episodes[0]);
          }
        }}>
          立即播放
        </Button>
        <Button 
          className={`secondary-button ${this.isFavorite ? 'favorite-active' : ''}`} 
          onClick={this.handleToggleFavorite}
        >
          {this.isFavorite ? '已收藏' : '收藏'}
        </Button>
      </Stack>
    </Stack>
  }
  
  /**
   * 渲染剧情简介
   */
  @Builder
  private renderDescription(): void {
    if (!this.mediaDetail || !this.mediaDetail.description) return;
    
    <Stack className="description-section">
      <Text className="section-title">剧情简介</Text>
      <Text className="description-text">{this.mediaDetail.description}</Text>
    </Stack>
  }
  
  /**
   * 渲染标签页切换
   */
  @Builder
  private renderTabs(): void {
    <Stack className="tabs">
      <Button 
        className={`tab-button ${this.selectedTab === 'episodes' ? 'active' : ''}`} 
        onClick={() => { this.selectedTab = 'episodes'; }}
      >
        剧集列表
      </Button>
      <Button 
        className={`tab-button ${this.selectedTab === 'sources' ? 'active' : ''}`} 
        onClick={() => { this.selectedTab = 'sources'; }}
      >
        播放源
      </Button>
    </Stack>
  }
  
  /**
   * 渲染季选择器
   */
  @Builder
  private renderSeasonSelector(): void {
    if (this.seasons.length <= 1) return;
    
    <ScrollView className="season-selector" scrollable="horizontal">
      <Flex>
        {this.seasons.map((season) => (
          <Button
            key={`season-${season}`}
            className={`season-button ${this.selectedSeason === season ? 'active' : ''}`}
            onClick={() => this.handleSeasonChange(season)}
          >
            第{season}季
          </Button>
        ))}
      </Flex>
    </ScrollView>
  }
  
  /**
   * 渲染剧集列表
   */
  @Builder
  private renderEpisodes(): void {
    if (this.episodes.length === 0) {
      <Text className="empty-text">暂无剧集信息</Text>
      return;
    }
    
    // 筛选当前季的剧集
    const currentSeasonEpisodes = this.episodes.filter(ep => ep.season === this.selectedSeason);
    
    <Stack>
      {this.renderSeasonSelector()}
      <Flex className="episodes-grid" wrap="wrap">
        {currentSeasonEpisodes.map((episode, index) => (
          <Button
            key={episode.id || index}
            className={`episode-button ${this.selectedEpisodeIndex === index ? 'selected' : ''}`}
            onClick={async () => {
              // 保存上一集的进度
              const lastEpisodeId = this.episodes[this.selectedEpisodeIndex]?.id;
              if (lastEpisodeId) {
                await this.saveCurrentPlayProgress(lastEpisodeId);
              }
              
              this.selectedEpisodeIndex = index;
              // 加载该集的播放源
              this.loadPlaySources(episode.id);
              this.currentPlayPosition = 0; // 重置播放位置
            }}
          >
            {episode.name || `第${episode.number || index + 1}集`}
          </Button>
        ))}
      </Flex>
      
      {this.hasMoreEpisodes && (
        <Button className="load-more-button" onClick={this.loadMoreEpisodes}>
          加载更多
        </Button>
      )}
    </Stack>
  }
  
  /**
   * 渲染播放源列表
   */
  @Builder
  private renderPlaySources(): void {
    <Stack className="sources-container">
      {/* 搜索栏 */}
      <SearchBar
        className="search-bar"
        placeholder="搜索片源"
        value={this.searchText}
        onChange={(text: string) => this.handleSearchChange(text)}
        onClear={() => this.handleSearchChange('')}
      />
      
      {/* 片源列表 */}
      {this.filteredSources.length === 0 ? (
        <Text className="empty-text">
          {this.selectedEpisodeIndex >= 0 ? '暂无匹配的片源' : '请先选择剧集'}
        </Text>
      ) : (
        <List className="sources-list">
          {this.filteredSources.map((source, index) => (
            <ListItem key={index} onClick={() => this.handlePlaySourceClick(source)}>
              <Flex className="source-item">
                <Text className="source-name">{source.name || `播放源${index + 1}`}</Text>
                {source.quality && <Tag className="source-quality">{source.quality}</Tag>}
                <Text className="play-icon">▶</Text>
              </Flex>
            </ListItem>
          ))}
        </List>
      )}
    </Stack>
  }
  
  /**
   * 渲染相关推荐
   */
  @Builder
  private renderRelatedMedia(): void {
    if (this.relatedMedia.length === 0) return;
    
    <Stack className="related-section">
      <Text className="section-title">相关推荐</Text>
      <ScrollView scrollable="horizontal" className="related-scroll">
        <Flex>
          {this.relatedMedia.map((media) => (
            <Stack key={`${media.siteKey}-${media.id}`} className="related-item" onClick={() => this.handleRelatedMediaClick(media)}>
              <Image
                src={media.coverUrl || 'https://via.placeholder.com/150x200?text=No+Image'}
                className="related-cover"
                objectFit="cover"
              />
              <Text className="related-title" numberOfLines={2}>{media.title}</Text>
            </Stack>
          ))}
        </Flex>
      </ScrollView>
    </Stack>
  }
  
  /**
   * 组件渲染
   */
  build() {
    <Stack className="media-detail-page">
      {/* 顶部导航栏 */}
      <Stack className="nav-header">
        <Button className="back-button" onClick={this.handleBack}>
          ← 返回
        </Button>
        <Text className="page-title">详情</Text>
        <Blank />
      </Stack>
      
      {/* 主内容区域 */}
      {this.isLoading ? (
        this.renderLoading()
      ) : this.errorMessage ? (
        this.renderError()
      ) : (
        <ScrollView className="content-scroll" scrollBar="auto">
          {this.renderHeader()}
          {this.renderDescription()}
          {this.renderTabs()}
          
          <Stack className="tab-content">
            {this.selectedTab === 'episodes' ? this.renderEpisodes() : this.renderPlaySources()}
          </Stack>
          
          {this.renderRelatedMedia()}
          <Blank className="bottom-space" />
        </ScrollView>
      )}
    </Stack>
  }
}

export default MediaDetailPage;