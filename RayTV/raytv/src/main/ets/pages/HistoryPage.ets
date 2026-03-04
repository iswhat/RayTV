import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { HistoryService } from '../service/media/HistoryService';
import { MediaService } from '../service/media/MediaService';
import display from '@ohos.display';
import { ScrollDirection, BarState, FlexAlign, FlexDirection, ImageFit, TextAlign, VerticalAlign } from '@ohos/arkui';
import VirtualList from '../components/VirtualList';
import { VirtualListItem } from '../types/VirtualListTypes';

// 历史记录项 | History item
interface HistoryItem {
  id: string;
  mediaId: string;
  siteKey: string;
  title: string;
  cover?: string;
  type: string;
  episodeId?: string;
  episodeTitle?: string;
  episodeIndex?: number;
  progress: number;
  duration?: number;
  lastPlayTime: number;
}

// 媒体项 | Media item
interface MediaItem {
  id: string;
  siteKey: string;
  title: string;
  coverUrl: string;
  type: string;
  year?: string;
  description?: string;
  score?: string;
}

@Entry
@Component
struct HistoryPage {
  private readonly TAG: string = 'HistoryPage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State histories: HistoryItem[] = [];
  @State mediaItems: Map<string, MediaItem> = new Map();
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '加载失败';
  @State isEditMode: boolean = false;
  @State selectedItems: Set<string> = new Set();
  @State isRefreshing: boolean = false;
  @State autoPlayLast: boolean = true;
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State coverWidth: number = 120;
  @State coverHeight: number = 160;
  
  // 服务实例 | Service instances
  private historyService: HistoryService = HistoryService.getInstance();
  private mediaService: MediaService = MediaService.getInstance();
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'HistoryPage about to appear');
    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
    // 加载历史记录 | Load history records
    this.loadHistories();
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      
      // 根据屏幕方向调整封面大小 | Adjust cover size based on screen orientation
      if (this.isLandscape) {
        this.coverWidth = 150;
        this.coverHeight = 200;
      } else {
        this.coverWidth = 120;
        this.coverHeight = 160;
      }
      
      Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}, coverSize=${this.coverWidth}x${this.coverHeight}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get screen info: ${error}`);
      // 默认值 | Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
      this.coverWidth = 150;
      this.coverHeight = 200;
    }
  }
  
  /**
   * 加载历史记录 | Load history records
   */
  private async loadHistories(): Promise<void> {
    try {
      this.isLoading = true;
      this.isError = false;
      this.errorMessage = '';
      
      Logger.info(this.TAG, 'Loading history records');
      
      // 调用实际的HistoryService获取历史记录 | Call actual HistoryService to get history records
      const result = await this.historyService.getHistories(100);
      
      if (result.isSuccess() && result.data) {
        // 按最后播放时间倒序排序（最新的在前） | Sort by last play time in reverse order (newest first)
        this.histories = result.data.sort((a, b) => b.lastPlayTime - a.lastPlayTime);
        
        // 加载媒体详情 | Load media details
        await this.loadMediaDetails(this.histories);
        
        Logger.info(this.TAG, `Loaded ${this.histories.length} history records in reverse chronological order`);
      } else {
        this.isError = true;
        this.errorMessage = result.message || '加载失败';
        Logger.warn(this.TAG, `Failed to load histories: ${this.errorMessage}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load histories: ${errorMsg}`);
      this.isError = true;
      this.errorMessage = errorMsg;
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }
  
  /**
   * 加载媒体详情 | Load media details
   */
  private async loadMediaDetails(histories: HistoryItem[]): Promise<void> {
    try {
      // 并行加载媒体详情 | Load media details in parallel
      const detailPromises = histories.map(async (history) => {
        try {
          // 调用实际的MediaService获取媒体详情 | Call actual MediaService to get media details
          const result = await this.mediaService.getMediaDetail(history.mediaId, history.siteKey, history.type);
          
          if (result.isSuccess() && result.data) {
            this.mediaItems.set(history.mediaId, {
              id: result.data.id,
              siteKey: result.data.siteKey || '',
              title: result.data.title,
              coverUrl: result.data.cover || '',
              type: result.data.type || '',
              year: result.data.year,
              description: result.data.description,
              score: result.data.rating
            });
          } else {
            // 如果加载失败，使用历史记录中的基本信息 | If loading fails, use basic information from history records
            this.mediaItems.set(history.mediaId, {
              id: history.mediaId,
              siteKey: history.siteKey,
              title: history.title,
              coverUrl: history.cover || '',
              type: history.type
            });
          }
        } catch (error) {
          Logger.warn(this.TAG, `Failed to load detail for ${history.mediaId}: ${error}`);
          // 使用历史记录中的基本信息 | Use basic information from history records
          this.mediaItems.set(history.mediaId, {
            id: history.mediaId,
            siteKey: history.siteKey,
            title: history.title,
            coverUrl: history.cover || '',
            type: history.type
          });
        }
      });
      
      await Promise.all(detailPromises);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load media details: ${error}`);
    }
  }
  
  /**
   * 处理返回 | Handle back
   */
  private async handleBack(): Promise<void> {
    try {
      await AppNavigator.getInstance().navigateToBack();
      Logger.info(this.TAG, 'Navigating back');
    } catch (error) {
      Logger.error(this.TAG, `Failed to navigate back: ${error}`);
    }
  }
  
  /**
   * 处理编辑模式切换 | Handle edit mode toggle
   */
  private toggleEditMode(): void {
    this.isEditMode = !this.isEditMode;
    this.selectedItems.clear();
    Logger.info(this.TAG, `Edit mode ${this.isEditMode ? 'enabled' : 'disabled'}`);
  }
  
  /**
   * 处理项目选择 | Handle item selection
   */
  private handleItemSelect(historyId: string): void {
    if (this.selectedItems.has(historyId)) {
      this.selectedItems.delete(historyId);
    } else {
      this.selectedItems.add(historyId);
    }
    Logger.info(this.TAG, `Selected items count: ${this.selectedItems.size}`);
  }
  
  /**
   * 处理全选/取消全选 | Handle select all / deselect all
   */
  private handleSelectAll(): void {
    if (this.selectedItems.size === this.histories.length) {
      this.selectedItems.clear();
    } else {
      this.selectedItems = new Set(this.histories.map(item => item.id));
    }
    Logger.info(this.TAG, `Select all: ${this.selectedItems.size === this.histories.length}`);
  }
  
  /**
   * 处理删除选中项 | Handle delete selected items
   */
  private async handleDeleteSelected(): Promise<void> {
    if (this.selectedItems.size === 0) return;
    
    try {
      const idsToDelete = Array.from(this.selectedItems);
      
      Logger.info(this.TAG, `Deleting ${idsToDelete.length} history items`);
      
      // 调用实际的HistoryService删除选中的历史记录 | Call actual HistoryService to delete selected history records
      const result = await this.historyService.removeHistories(idsToDelete);
      
      if (result.isSuccess()) {
        // 更新本地状态 | Update local state
        this.histories = this.histories.filter(history => !idsToDelete.includes(history.id));
        
        // 清理已删除项的媒体信息缓存 | Clean up media information cache for deleted items
        idsToDelete.forEach(id => {
          const history = this.histories.find(h => h.id === id);
          if (history) {
            this.mediaItems.delete(history.mediaId);
          }
        });
        
        // 清空选择 | Clear selection
        this.selectedItems.clear();
        
        Logger.info(this.TAG, `Successfully deleted ${idsToDelete.length} history items`);
      } else {
        Logger.error(this.TAG, `Failed to delete histories: ${result.message}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete histories: ${error}`);
    }
  }
  
  /**
   * 处理清空所有历史 | Handle clear all history
   */
  private async handleClearAll(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Clearing all history records');
      
      // 调用实际的HistoryService清空所有历史记录 | Call actual HistoryService to clear all history records
      const result = await this.historyService.clearAllHistories();
      
      if (result.isSuccess()) {
        // 更新本地状态 | Update local state
        this.histories = [];
        this.mediaItems.clear();
        this.selectedItems.clear();
        this.isEditMode = false;
        
        Logger.info(this.TAG, 'Successfully cleared all history records');
      } else {
        Logger.error(this.TAG, `Failed to clear all histories: ${result.message}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all histories: ${error}`);
    }
  }
  
  /**
   * 处理历史点击 | Handle history click
   */
  private async handleHistoryClick(history: HistoryItem): Promise<void> {
    if (this.isEditMode) {
      this.handleItemSelect(history.id);
      return;
    }
    
    Logger.info(this.TAG, `History clicked: ${history.title}, episode: ${history.episodeIndex}`);
    
    try {
      // 更新播放历史时间 | Update play history time
      const updateResult = await this.historyService.updateHistoryTime(history.id);
      
      if (!updateResult.isSuccess()) {
        Logger.warn(this.TAG, `Failed to update history time: ${updateResult.message}`);
      }
      
      // 跳转到播放页面，带上上次播放的进度 | Jump to playback page with last play progress
      AppNavigator.getInstance().navigateToPlayback({
        id: history.mediaId,
        siteKey: history.siteKey,
        type: history.type,
        episodeId: history.episodeId,
        playbackPosition: history.progress * 1000
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle history click: ${error}`);
      
      // 即使更新失败，也跳转到播放页面 | Even if update fails, still jump to playback page
      AppNavigator.getInstance().navigateToPlayback({
        id: history.mediaId,
        siteKey: history.siteKey,
        type: history.type,
        episodeId: history.episodeId,
        playbackPosition: history.progress * 1000
      });
    }
  }
  
  /**
   * 处理继续播放 | Handle continue play
   */
  private handleContinuePlay(history: HistoryItem): void {
    Logger.info(this.TAG, `Continue playing: ${history.title} from ${history.progress}s`);
    
    // 跳转到播放页面，带上上次播放的进度 | Jump to playback page with last play progress
    AppNavigator.getInstance().navigateToPlayback({
      id: history.mediaId,
      siteKey: history.siteKey,
      type: history.type,
      episodeId: history.episodeId,
      playbackPosition: history.progress * 1000
    });
  }
  
  /**
   * 处理刷新 | Handle refresh
   */
  private handleRefresh(): void {
    this.isRefreshing = true;
    this.mediaItems.clear();
    this.loadHistories();
  }
  
  /**
   * 格式化播放进度 | Format playback progress
   */
  private formatPlaybackProgress(progress: number, duration?: number): string {
    const progressSec = Math.floor(progress);
    const durationSec = Math.floor(duration || 0);
    
    const progMin = Math.floor(progressSec / 60);
    const progSec = progressSec % 60;
    const durMin = Math.floor(durationSec / 60);
    const durSec = durationSec % 60;
    
    return `${progMin.toString().padStart(2, '0')}:${progSec.toString().padStart(2, '0')} / ${durMin.toString().padStart(2, '0')}:${durSec.toString().padStart(2, '0')}`;
  }
  
  /**
   * 计算播放进度百分比 | Calculate playback progress percentage
   */
  private getProgressPercentage(progress: number, duration?: number): number {
    if (!duration || duration === 0) return 0;
    return Math.min(100, Math.max(0, (progress / duration) * 100));
  }
  
  /**
   * 格式化时间 | Format time
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    });
  }
  
  /**
   * 将HistoryItem转换为VirtualListItem | Convert HistoryItem to VirtualListItem
   */
  private convertToVirtualItems(historyList: HistoryItem[]): VirtualListItem[] {
    return historyList.map((history, index) => ({
      id: history.id,
      index: index,
      data: history,
      top: index * (this.isLandscape ? 320 : 280), // 估算的项目高度
      height: this.isLandscape ? 320 : 280,
      visible: false
    }));
  }
  
  // 渲染历史记录项 | Render history item
  @Builder
  renderHistoryItem(history: HistoryItem) {
    const media = this.mediaItems.get(history.mediaId);
    const progressText = this.formatPlaybackProgress(history.progress, history.duration);
    const progressPercentage = this.getProgressPercentage(history.progress, history.duration);
    const isSelected = this.selectedItems.has(history.id);
    
    Column() {
      Row() {
        // 选择框 | Selection checkbox
        if (this.isEditMode) {
          Button() {
            Text(isSelected ? '✓' : '')
              .fontSize(22)
              .fontColor('#FFFFFF')
              .fontWeight(600)
          }
          .width(45)
          .height(45)
          .backgroundColor(isSelected ? '#4CAF50' : '#E0E0E0')
          .borderRadius(22.5)
          .margin({ right: 20 })
          .onClick(() => this.handleItemSelect(history.id))
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, `Selection checkbox focused for ${history.id}`);
          })
        }
        
        // 封面 | Cover
        Image(media?.coverUrl || history.cover || '')
          .width(this.coverWidth)
          .height(this.coverHeight)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .backgroundColor('#F5F5F5')
          .margin({ right: this.isLandscape ? 30 : 20 })
          .onError(() => {
            Logger.warn(this.TAG, `Failed to load cover image: ${media?.coverUrl || history.cover}`);
          })
        
        // 信息 | Info
        Column() {
          Text(media?.title || history.title)
            .fontSize(this.isLandscape ? 22 : 18)
            .fontWeight(600)
            .fontColor('#333333')
            .maxLines(2)
            .margin({ bottom: 10 })
          
          if (history.episodeTitle) {
            Text(history.episodeTitle)
              .fontSize(this.isLandscape ? 16 : 14)
              .fontColor('#666666')
              .margin({ bottom: 10 })
          }
          
          Text(`播放时间: ${this.formatTime(history.lastPlayTime)}`)
            .fontSize(this.isLandscape ? 16 : 14)
            .fontColor('#999999')
            .margin({ bottom: 12 })
          
          // 播放进度条 | Playback progress bar
          Column() {
            Row() {
              Text(progressText)
                .fontSize(this.isLandscape ? 14 : 12)
                .fontColor('#666666')
                .flexGrow(1)
                .textAlign(TextAlign.Start)
              Text(`${Math.round(progressPercentage)}%`)
                .fontSize(this.isLandscape ? 14 : 12)
                .fontColor('#666666')
                .margin({ left: 15 })
            }
            .width('100%')
            .margin({ bottom: 8 })
            
            Row() {
              Column()
                .width(`${progressPercentage}%`)
                .height(6)
                .backgroundColor('#4CAF50')
                .borderRadius(3)
              Column()
                .width(`${100 - progressPercentage}%`)
                .height(6)
                .backgroundColor('#E0E0E0')
                .borderRadius(3)
            }
            .width('100%')
            .borderRadius(3)
            .backgroundColor('#E0E0E0')
          }
          .margin({ bottom: 15 })
          
          // 操作按钮 | Action buttons
          if (!this.isEditMode) {
            Row() {
              Button() {
                Text('继续观看')
                  .fontSize(this.isLandscape ? 16 : 14)
                  .fontColor('#FFFFFF')
                  .fontWeight(500)
              }
              .width(this.isLandscape ? 140 : 120)
              .height(this.isLandscape ? 45 : 40)
              .backgroundColor('#4CAF50')
              .borderRadius(8)
              .onClick(() => this.handleContinuePlay(history))
              .focusable(true)
              .onFocus(() => {
                Logger.info(this.TAG, `Continue play button focused for ${history.id}`);
              })
            }
          }
        }
        .flexGrow(1)
      }
      .width('100%')
      .padding(this.isLandscape ? 25 : 20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ bottom: 20 })
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })
    }
    .width('100%')
    .onClick(() => this.handleHistoryClick(history))
  }
  
  // 渲染历史记录列表 | Render history list
  @Builder
  renderHistoryList() {
    if (this.isLoading && !this.isRefreshing) {
      Column() {
        Text('加载中...')
          .fontSize(24)
          .fontColor('#666666')
          .margin(40)
          .fontWeight(500)
      }
      .justifyContent(FlexAlign.Center)
      .height(this.isLandscape ? '80%' : 500)
    } else if (this.isError) {
      Column() {
        Text('加载失败')
          .fontSize(24)
          .fontColor('#FF5252')
          .margin({ top: 20 })
          .fontWeight(600)
        Text(this.errorMessage)
          .fontSize(18)
          .fontColor('#FF9800')
          .margin({ top: 12, left: 40, right: 40 })
          .textAlign(TextAlign.Center)
        Button('重试')
          .onClick(() => this.loadHistories())
          .backgroundColor('#4CAF50')
          .fontColor('white')
          .borderRadius(12)
          .padding({ left: 30, right: 30, top: 12, bottom: 12 })
          .margin({ top: 25 })
          .fontSize(16)
          .fontWeight(500)
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, 'Retry button focused');
          })
      }
      .justifyContent(FlexAlign.Center)
      .height(this.isLandscape ? '80%' : 500)
    } else if (this.histories.length === 0) {
      Column() {
        Text('📺')
          .fontSize(80)
          .margin({ bottom: 30 })
        Text('暂无播放历史')
          .fontSize(24)
          .fontColor('#999999')
          .margin({ bottom: 15 })
          .fontWeight(500)
        Text('观看视频后会自动记录播放历史')
          .fontSize(18)
          .fontColor('#CCCCCC')
          .margin({ bottom: 40 })
        Button('去探索')
          .onClick(() => AppNavigator.getInstance().navigateToHome())
          .backgroundColor('#4CAF50')
          .fontColor('white')
          .borderRadius(12)
          .padding({ left: 40, right: 40, top: 15, bottom: 15 })
          .fontSize(18)
          .fontWeight(500)
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, 'Explore button focused');
          })
      }
      .justifyContent(FlexAlign.Center)
      .height(this.isLandscape ? '80%' : 500)
    } else {
      // 使用VirtualList优化性能 | Use VirtualList for better performance
      const virtualItems = this.convertToVirtualItems(this.histories);
      
      VirtualList({
        items: virtualItems,
        estimatedItemHeight: this.isLandscape ? 320 : 280,
        bufferSize: 3,
        renderItem: (item: VirtualListItem) => {
          const history = item.data as HistoryItem;
          return this.renderHistoryItem(history);
        }
      })
      .width('100%')
      .padding({ bottom: 40 })
      .height(this.isLandscape ? '80%' : 500)
    }
  }
  
  build() {
    Column() {
      // 顶部导航栏 | Top navigation bar
      Row() {
        // 返回按钮 | Back button
        Button() {
          Text('返回')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .fontWeight(500)
        }
        .width(100)
        .height(60)
        .backgroundColor('#4CAF50')
        .borderRadius(12)
        .margin({ left: this.isLandscape ? 40 : 30 })
        .onClick(() => this.handleBack())
        .focusable(true)
        .onFocus(() => {
          Logger.info(this.TAG, 'Back button focused');
        })
        
        // 标题 | Title
        Text('播放历史')
          .fontSize(26)
          .fontWeight(700)
          .fontColor('#333333')
          .flexGrow(1)
          .margin({ left: this.isLandscape ? 40 : 30 })
          .textAlign(TextAlign.Start)
        
        // 编辑按钮 | Edit button
        Button() {
          Text(this.isEditMode ? '取消' : '编辑')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(500)
        }
        .width(100)
        .height(60)
        .backgroundColor('#2196F3')
        .borderRadius(12)
        .margin({ right: this.isLandscape ? 40 : 30 })
        .onClick(() => this.toggleEditMode())
        .focusable(true)
        .onFocus(() => {
          Logger.info(this.TAG, 'Edit button focused');
        })
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderBottomWidth(2)
      .borderBottomColor('#E0E0E0')
      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
      
      // 编辑工具栏 | Edit toolbar
      if (this.isEditMode && this.histories.length > 0) {
        Row() {
          Button() {
            Text(this.selectedItems.size === this.histories.length ? '取消全选' : '全选')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(500)
          }
          .width(150)
          .height(50)
          .backgroundColor('#2196F3')
          .borderRadius(8)
          .margin({ left: this.isLandscape ? 40 : 30 })
          .onClick(() => this.handleSelectAll())
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, 'Select all button focused');
          })
          
          Text(`已选择 ${this.selectedItems.size} 项`)
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(500)
            .flexGrow(1)
            .margin({ left: this.isLandscape ? 40 : 30 })
          
          Button() {
            Text('删除')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(500)
          }
          .width(100)
          .height(50)
          .backgroundColor('#F44336')
          .borderRadius(8)
          .margin({ right: 15 })
          .onClick(() => this.handleDeleteSelected())
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, 'Delete button focused');
          })
          
          Button() {
            Text('清空')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(500)
          }
          .width(100)
          .height(50)
          .backgroundColor('#9E9E9E')
          .borderRadius(8)
          .margin({ right: this.isLandscape ? 40 : 30 })
          .onClick(() => this.handleClearAll())
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, 'Clear all button focused');
          })
        }
        .width('100%')
        .height(70)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#F5F5F5')
      }
      
      // 设置选项 | Settings options
      if (!this.isEditMode && this.histories.length > 0) {
        Row() {
          Text('自动续播上次内容')
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(500)
            .flexGrow(1)
            .margin({ left: this.isLandscape ? 40 : 30 })
          
          Button() {
            Text(this.autoPlayLast ? '开' : '关')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(500)
          }
          .width(80)
          .height(50)
          .backgroundColor(this.autoPlayLast ? '#4CAF50' : '#9E9E9E')
          .borderRadius(8)
          .margin({ right: this.isLandscape ? 40 : 30 })
          .onClick(() => this.autoPlayLast = !this.autoPlayLast)
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, 'Auto play toggle focused');
          })
        }
        .width('100%')
        .height(70)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#F5F5F5')
      }
      
      // 历史记录列表 | History list
      Scroll(this.scroller) {
        Column() {
          this.renderHistoryList()
        }
        .width('100%')
        .padding({ 
          top: 25, 
          left: this.isLandscape ? 40 : 30, 
          right: this.isLandscape ? 40 : 30 
        })
      }
      .scrollBar(BarState.Auto)
      .flexGrow(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
