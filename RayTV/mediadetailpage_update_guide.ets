/**
 * MediaDetailPage集成MediaDataFetcherService的更新指南
 * 
 * 使用以下代码更新MediaDetailPage.ets，集成真实的媒体数据获取功能
 */

// 1. 在文件顶部添加导入
import MediaDataFetcherService from '../service/media/MediaDataFetcherService';
import EventBusUtil from '../common/util/EventBusUtil';

// 2. 替换私有服务实例
// 原代码:
// private contentService: ContentAccessService = ContentAccessService.getInstance();

// 新代码:
private contentService: ContentAccessService = ContentAccessService.getInstance();
private mediaDataFetcher: MediaDataFetcherService = MediaDataFetcherService.getInstance();

// 3. 添加状态变量
@State mediaDetail: MediaDetail | null = null;
@State playSources: PlaySource[] = [];
@State selectedPlaySource: PlaySource | null = null;
@State isParsing: boolean = false;
@State parseError: string = '';

// 4. 更新aboutToAppear方法
aboutToAppear(): void {
  this.mediaId = this.getMediaIdFromParams() || '';
  
  // 添加主题变更监听器
  ThemeProvider.addThemeChangeListener((theme) => {
    this.currentTheme = theme;
  });
  
  // 监听播放状态变化
  EventBusUtil.getInstance().on('playback:progressUpdated', (data: Record<string, unknown>) => {
    // 记录播放进度
    if (data.videoId && data.progress) {
      this.recordPlaybackProgress(data.videoId as string, data.progress as number);
    }
  });
  
  this.loadMediaDetail();
  this.loadEpisodes();
  this.loadSources();
  this.loadRelatedMedia();
}

// 5. 替换loadMediaDetail方法
private async loadMediaDetail(): Promise<void> {
  try {
    this.isLoading = true;
    this.isError = false;
    
    if (!this.mediaId) {
      throw new Error('Media ID not found');
    }
    
    // 使用MediaDataFetcherService获取媒体详情
    const detail = await this.mediaDataFetcher.getMediaDetail(this.mediaId);
    
    if (!detail) {
      throw new Error('Failed to fetch media detail');
    }
    
    // 转换为Vod格式
    this.media = {
      id: detail.id,
      name: detail.title,
      type: detail.type,
      area: detail.area,
      lang: detail.lang,
      year: detail.year,
      score: detail.score,
      status: detail.status,
      desc: detail.desc,
      cover: detail.cover,
      tag: detail.tags.join(','),
      url: '',
      sourceKey: '',
      createdAt: detail.releaseDate || Date.now(),
      updatedAt: Date.now()
    };
    
    this.mediaDetail = detail;
    
    // 发布媒体加载事件
    EventBusUtil.getInstance().publish('media:detailLoaded', {
      mediaId: detail.id,
      title: detail.title,
      type: detail.type
    });
    
    Logger.info(this.TAG, `Media detail loaded: ${detail.title}`);
  } catch (error) {
    const err = error instanceof Error ? error : new Error(String(error));
    this.isError = true;
    this.errorMessage = err.message;
    Logger.error(this.TAG, `Failed to load media detail: ${err.message}`);
  } finally {
    this.isLoading = false;
  }
}

// 6. 替换loadEpisodes方法
private async loadEpisodes(): Promise<void> {
  try {
    if (!this.mediaId) {
      this.episodes = [];
      return;
    }
    
    // 使用MediaDataFetcherService获取剧集列表
    const episodeInfos = await this.mediaDataFetcher.getEpisodes(this.mediaId);
    
    // 转换为Episode格式
    this.episodes = episodeInfos.map(ep => ({
      id: ep.id,
      name: ep.name,
      url: ep.url
    }));
    
    Logger.info(this.TAG, `Loaded ${this.episodes.length} episodes`);
  } catch (error) {
    Logger.error(this.TAG, 'Failed to load episodes', error as Error);
    this.episodes = [];
  }
}

// 7. 替换loadSources方法
private async loadSources(): Promise<void> {
  try {
    if (!this.mediaId || !this.currentEpisodeId) {
      this.filteredSources = [];
      return;
    }
    
    // 使用MediaDataFetcherService获取播放源
    const sources = await this.mediaDataFetcher.getPlaySources(
      this.mediaId,
      this.currentEpisodeId
    );
    
    // 转换为PlaySource格式
    this.filteredSources = sources.map(src => ({
      name: src.name,
      quality: src.quality
    }));
    
    // 默认选择第一个
    if (sources.length > 0 && !this.selectedPlaySource) {
      this.selectedPlaySource = sources[0];
    }
    
    Logger.info(this.TAG, `Loaded ${this.filteredSources.length} play sources`);
  } catch (error) {
    Logger.error(this.TAG, 'Failed to load play sources', error as Error);
    this.filteredSources = [];
  }
}

// 8. 替换loadRelatedMedia方法
private async loadRelatedMedia(): Promise<void> {
  try {
    if (!this.mediaId) {
      this.relatedMedia = [];
      return;
    }
    
    // 使用MediaDataFetcherService获取相关媒体
    const related = await this.mediaDataFetcher.getRelatedMedia(this.mediaId, 10);
    
    // 转换为MediaItem格式
    this.relatedMedia = related.map(item => ({
      title: item.title,
      cover: item.cover,
      url: item.id,  // 使用ID作为URL，实际播放时会重新获取
      sourceId: item.sourceId,
      sourceName: item.sourceName
    }));
    
    Logger.info(this.TAG, `Loaded ${this.relatedMedia.length} related media`);
  } catch (error) {
    Logger.error(this.TAG, 'Failed to load related media', error as Error);
    this.relatedMedia = [];
  }
}

// 9. 添加播放剧集方法
private async playEpisode(episode: Episode): Promise<void> {
  try {
    this.currentEpisodeId = episode.id;
    
    Logger.info(this.TAG, `Playing episode: ${episode.name}`);
    
    // 加载播放源
    await this.loadSources();
    
    if (this.selectedPlaySource) {
      // 解析播放地址
      await this.parseAndPlay(this.selectedPlaySource);
    }
    
    // 记录播放事件
    EventBusUtil.getInstance().publish('media:episodePlayed', {
      mediaId: this.mediaId,
      episodeId: episode.id,
      episodeName: episode.name
    });
  } catch (error) {
    Logger.error(this.TAG, 'Failed to play episode', error as Error);
  }
}

// 10. 添加解析和播放方法
private async parseAndPlay(playSource: PlaySource): Promise<void> {
  try {
    this.isParsing = true;
    this.parseError = '';
    
    Logger.info(this.TAG, `Parsing play source: ${playSource.name}`);
    
    // 解析播放地址
    const result = await this.mediaDataFetcher.parsePlayUrl(playSource);
    
    if (result.success && result.playSources.length > 0) {
      // 使用解析后的播放源
      const actualPlaySource = result.playSources[0];
      
      // 播放视频
      await this.playVideo(actualPlaySource.url);
      
      Logger.info(this.TAG, `Playing with URL: ${actualPlaySource.url}`);
    } else {
      this.parseError = result.error || '解析失败';
      Logger.error(this.TAG, `Parse failed: ${this.parseError}`);
    }
  } catch (error) {
    this.parseError = error instanceof Error ? error.message : String(error);
    Logger.error(this.TAG, 'Failed to parse and play', error as Error);
  } finally {
    this.isParsing = false;
  }
}

// 11. 添加播放视频方法
private async playVideo(url: string): Promise<void> {
  try {
    Logger.info(this.TAG, `Playing video: ${url}`);
    
    // 使用播放器服务播放
    const PlayerService = (await import('../service/player/PlayerService')).default;
    const playerService = PlayerService.getInstance();
    
    await playerService.playMedia(this.mediaId, url, {
      autoPlay: true,
      volume: 1.0
    });
    
    // 导航到播放器页面
    // AppNavigator.push({ url: 'pages/PlayerPage', params: { mediaId: this.mediaId, url } });
    
  } catch (error) {
    Logger.error(this.TAG, 'Failed to play video', error as Error);
  }
}

// 12. 添加记录播放进度方法
private recordPlaybackProgress(mediaId: string, progress: number): void {
  Logger.debug(this.TAG, `Recording progress for ${mediaId}: ${progress}s`);
  // TODO: 保存播放进度到本地存储
}

// 13. 添加切换播放源方法
private async switchPlaySource(source: PlaySource): Promise<void> {
  try {
    this.selectedPlaySource = source;
    
    Logger.info(this.TAG, `Switching to play source: ${source.name}`);
    
    // 解析并播放
    await this.parseAndPlay(source);
    
    // 发布切换事件
    EventBusUtil.getInstance().publish('media:playSourceSwitched', {
      mediaId: this.mediaId,
      sourceId: source.id,
      sourceName: source.name
    });
  } catch (error) {
    Logger.error(this.TAG, 'Failed to switch play source', error as Error);
  }
}

// 14. 添加UI组件显示解析状态
// 在build()方法中添加：

if (this.isParsing) {
  Column() {
    LoadingProgress()
      .width(50)
      .height(50)
    Text('正在解析播放地址...')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .margin({ top: 10 })
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .backgroundColor('rgba(0, 0, 0, 0.8)')
}

if (this.parseError) {
  Column() {
    Text('解析失败')
      .fontSize(18)
      .fontColor('#FFFFFF')
      .fontWeight(FontWeight.Bold)
    Text(this.parseError)
      .fontSize(14)
      .fontColor('#FF0000')
      .margin({ top: 10 })
    Button('重试')
      .margin({ top: 20 })
      .onClick(() => {
        if (this.selectedPlaySource) {
          this.parseAndPlay(this.selectedPlaySource);
        }
      })
  }
  .width('80%')
  .padding(20)
  .borderRadius(10)
  .backgroundColor('rgba(0, 0, 0, 0.9)')
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}

// 15. 添加播放源选择器UI
if (this.filteredSources.length > 0) {
  Column() {
    Text('播放源')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .margin({ bottom: 10 })
    
    ForEach(this.filteredSources, (source: PlaySource, index: number) => {
      Row() {
        Text(source.name)
          .fontSize(14)
          .fontColor(source.quality === '1080p' ? '#00FF00' : '#FFFFFF')
        
        if (source.quality) {
          Text(source.quality)
            .fontSize(12)
            .fontColor('#FFFF00')
            .margin({ left: 10 })
        }
      }
      .width('100%')
      .padding(10)
      .borderRadius(5)
      .backgroundColor(this.selectedPlaySource?.name === source.name ? '#333333' : 'transparent')
      .onClick(() => {
        this.switchPlaySource(source);
      })
    })
  }
  .width('100%')
  .padding(15)
  .margin({ top: 20 })
  .borderRadius(10)
  .backgroundColor('rgba(255, 255, 255, 0.1)')
}

// 16. 在aboutToDisappear中添加清理
aboutToDisappear(): void {
  // 移除事件监听
  EventBusUtil.getInstance().off('playback:progressUpdated');
  
  // 清理播放器
  // PlayerService.getInstance().stop();
}

// 使用说明:
// 1. 将上述代码逐步应用到MediaDetailPage.ets中
// 2. 根据实际UI布局调整组件位置和样式
// 3. 可以添加更多功能，如弹幕、收藏、分享等
// 4. 记住导入所需的类型和接口
