import { ScrollView, Text, Button, List, ListItem, Image, LoadingProgress, Empty, Flex, Tag, Checkbox, Switch, Stack, ProgressBar, Blank, BarState } from '@kit.ArkUI';
import { AppNavigator, PageRoute } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { historyService, HistoryItem } from '../service/media/HistoryService';
import { mediaService, MediaItem, MediaType } from '../service/media/MediaService';

/**
 * 历史记录页面组件
 * 实现播放历史的展示、管理、编辑和清空等功能
 */
@Component
struct HistoryPage {
  private readonly TAG: string = 'HistoryPage';
  
  // 状态管理
  @State histories: HistoryItem[] = [];
  @State mediaItems: Map<string, MediaItem> = new Map();
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State isEditMode: boolean = false;
  @State selectedItems: Set<string> = new Set();
  @State isRefreshing: boolean = false;
  @State autoPlayLast: boolean = true;
  
  // 初始化
  /**
   * 页面加载时调用
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'HistoryPage appeared');
    this.loadHistories();
  }

  /**
   * 页面卸载时调用
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'HistoryPage disappeared');
  }
  
  /**
   * 加载历史记录
   */
  private loadHistories(): void {
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // 从历史服务获取历史记录列表（按播放时间倒序）
      historyService.getHistories(100).then((histories) => {
        this.histories = histories;
        
        // 加载媒体详情
        this.loadMediaDetails(histories);
        
        Logger.info(this.TAG, `Loaded ${this.histories.length} history records`);
        this.isLoading = false;
        this.isRefreshing = false;
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to load histories: ${error}`);
        this.errorMessage = '加载历史记录失败，请稍后重试';
        this.isLoading = false;
        this.isRefreshing = false;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load histories: ${error}`);
      this.errorMessage = '加载历史记录失败，请稍后重试';
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }
  
  /**
   * 加载媒体详情
   */
  private loadMediaDetails(histories: HistoryItem[]): void {
    try {
      // 并行加载媒体详情
      const detailPromises = histories.map((history) => {
        return mediaService.getMediaDetail(history.mediaId, history.siteKey)
          .then((media) => {
            if (media) {
              this.mediaItems.set(history.mediaId, media);
            }
          })
          .catch((error) => {
            Logger.warn(this.TAG, `Failed to load detail for ${history.mediaId}: ${error}`);
            // 如果加载失败，使用历史记录中的基础信息
            const placeholderMedia: MediaItem = {
              id: history.mediaId,
              siteKey: history.siteKey,
              title: history.title,
              coverUrl: history.cover || '',
              type: history.type,
              year: '',
              description: '',
              score: '',
              directors: [],
              actors: [],
              tags: [],
              category: '',
              region: '',
              language: '',
              updateTime: '',
              status: ''
            };
            this.mediaItems.set(history.mediaId, placeholderMedia);
          });
      });
      
      Promise.all(detailPromises).catch((error) => {
        Logger.error(this.TAG, `Failed in Promise.all: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load media details: ${error}`);
    }
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
      AppNavigator.getInstance().back();
    }
  
  /**
   * 处理编辑模式切换
   */
  private toggleEditMode(): void {
    this.isEditMode = !this.isEditMode;
    this.selectedItems.clear();
  }
  
  /**
   * 处理项目选择
   */
  private handleItemSelect(historyId: string): void {
    if (this.selectedItems.has(historyId)) {
      this.selectedItems.delete(historyId);
    } else {
      this.selectedItems.add(historyId);
    }
  }
  
  /**
   * 处理全选/取消全选
   */
  private handleSelectAll(): void {
    if (this.selectedItems.size === this.histories.length) {
      this.selectedItems.clear();
    } else {
      this.selectedItems = new Set(this.histories.map(item => item.id));
    }
  }
  
  /**
   * 处理删除选中项
   */
  private handleDeleteSelected(): void {
    if (this.selectedItems.size === 0) return;
    
    try {
      const idsToDelete = Array.from(this.selectedItems);
      
      // 删除选中的历史记录
      historyService.removeHistories(idsToDelete)
        .then(() => {
          // 更新本地状态
          this.histories = this.histories.filter(history => !idsToDelete.includes(history.id));
          
          // 清除已删除项的媒体详情缓存
          idsToDelete.forEach(id => {
            const history = this.histories.find(h => h.id === id);
            if (history) {
              this.mediaItems.delete(history.mediaId);
            }
            this.selectedItems.delete(id);
          });
          
          Logger.info(this.TAG, `Deleted ${idsToDelete.length} history records`);
          
          // 如果没有历史记录了，退出编辑模式
          if (this.histories.length === 0) {
            this.isEditMode = false;
          }
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to delete histories: ${error}`);
          this.errorMessage = '删除失败，请稍后重试';
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete histories: ${error}`);
      this.errorMessage = '删除失败，请稍后重试';
    }
  }
  
  /**
   * 处理清空所有历史
   */
  private handleClearAll(): void {
    try {
      // 清空所有历史记录
      historyService.clearAllHistories()
        .then(() => {
          // 更新本地状态
          this.histories = [];
          this.mediaItems.clear();
          this.selectedItems.clear();
          this.isEditMode = false;
          
          Logger.info(this.TAG, 'Cleared all history records');
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to clear all histories: ${error}`);
          this.errorMessage = '清空失败，请稍后重试';
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all histories: ${error}`);
      this.errorMessage = '清空失败，请稍后重试';
    }
  }
  
  /**
   * 处理历史项点击
   */
  private handleHistoryClick(history: HistoryItem): void {
    if (this.isEditMode) {
      this.handleItemSelect(history.id);
      return;
    }
    
    Logger.info(this.TAG, `History clicked: ${history.title}, episode: ${history.episodeIndex}`);
    
    try {
      // 更新播放历史时间
      historyService.updateHistoryTime(history.id)
        .then(() => {
          // 跳转到播放页面，带上上次播放的进度
          AppNavigator.getInstance().navigateToVideoPlay({
            mediaId: history.mediaId,
            siteKey: history.siteKey,
            episodeId: history.episodeId,
            playbackPosition: history.progress * 1000,
            title: history.title,
            coverUrl: history.cover || ''
          });
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to update history time: ${error}`);
          // 即使更新失败，也跳转到播放页面
          Router.push({
            uri: 'pages/PlaybackPage',
            params: {
              mediaId: history.mediaId,
              siteKey: history.siteKey,
              episodeId: history.episodeId,
              playbackPosition: history.progress * 1000,
              title: history.title,
              coverUrl: history.cover || ''
            }
          });
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle history click: ${error}`);
      // 错误处理：跳转到播放页面
      AppNavigator.getInstance().navigateToVideoPlay({
        mediaId: history.mediaId,
        siteKey: history.siteKey,
        episodeId: history.episodeId,
        playbackPosition: history.progress * 1000,
        title: history.title,
        coverUrl: history.cover || ''
      });
    }
  }
  
  /**
   * 处理继续播放
   */
  private handleContinuePlay(history: HistoryItem): void {
    Logger.info(this.TAG, `Continue playing: ${history.title} from ${history.playbackPosition}ms`);
    
    // 跳转到播放页面，带上上次播放的进度
    AppNavigator.getInstance().navigateToVideoPlay({
        mediaId: history.mediaId,
        siteKey: history.siteKey,
        episodeId: history.episodeId,
        playbackPosition: history.progress * 1000,
        title: history.title,
        coverUrl: history.cover || ''
      });
  }
  
  /**
   * 处理刷新
   */
  private handleRefresh(): void {
    this.isRefreshing = true;
    this.mediaItems.clear();
    this.loadHistories();
  }
  
  /**
   * 格式化播放进度
   */
  private formatPlaybackProgress(position: number, duration: number): string {
    if (duration === 0) return '00:00';
    
    const positionSec = Math.floor(position / 1000);
    const durationSec = Math.floor(duration / 1000);
    
    const posMin = Math.floor(positionSec / 60);
    const posSec = positionSec % 60;
    const durMin = Math.floor(durationSec / 60);
    const durSec = durationSec % 60;
    
    return `${posMin.toString().padStart(2, '0')}:${posSec.toString().padStart(2, '0')} / ${durMin.toString().padStart(2, '0')}:${durSec.toString().padStart(2, '0')}`;
  }
  
  /**
   * 计算播放进度百分比
   */
  private getProgressPercentage(position: number, duration: number): number {
    if (duration === 0) return 0;
    return Math.min(100, Math.max(0, (position / duration) * 100));
  }
  
  /**
   * 渲染头部
   */
  @Builder
  private renderHeader() {
    Stack.create({ className: "header" });
    Button.create({ className: "back-button", onClick: this.handleBack });
    Button.text("←");
    Button.pop();
    Text.create({ className: "page-title" });
    Text.text("播放历史");
    Text.pop();
    Button.create({ className: "action-button", onClick: this.toggleEditMode });
    Button.text(this.isEditMode ? '取消' : '编辑');
    Button.pop();
    Stack.pop();
  }

  /**
   * 渲染编辑工具栏
   */
  @Builder
  private renderEditToolbar() {
    if (!this.isEditMode || this.histories.length === 0) return;
    
    Flex.create({ className: "edit-toolbar" });
    Flex.create({ className: "select-all" });
    Checkbox.create();
    Checkbox.checked(this.selectedItems.size === this.histories.length && this.histories.length > 0);
    Checkbox.onCheckChange(this.handleSelectAll);
    Checkbox.pop();
    Text.create();
    Text.text("全选");
    Text.pop();
    Flex.pop();
    Text.create({ className: "selected-count" });
    Text.text(`已选择 ${this.selectedItems.size} 项`);
    Text.pop();
    Button.create({ 
      className: "delete-button", 
      onClick: this.handleDeleteSelected,
      disabled: this.selectedItems.size === 0 
    });
    Button.text("删除");
    Button.pop();
    Button.create({ className: "clear-all-button", onClick: this.handleClearAll });
    Button.text("清空");
    Button.pop();
    Flex.pop();
  }

  /**
   * 渲染设置选项
   */
  @Builder
  private renderSettings() {
    if (this.isEditMode || this.histories.length === 0) return;
    
    Flex.create({ className: "settings-container" });
    Text.create({ className: "setting-label" });
    Text.text("自动续播上次内容");
    Text.pop();
    Switch.create();
    Switch.checked(this.autoPlayLast);
    Switch.onValueChange((value) => {
      this.autoPlayLast = value;
      // 这里可以保存设置到配置服务
      Logger.info(this.TAG, `Auto play last content: ${value}`);
    });
    Switch.pop();
    Flex.pop();
  }

  /**
   * 渲染历史记录项
   */
  @Builder
  private renderHistoryItem(history: HistoryItem) {
    const media = this.mediaItems.get(history.mediaId);
    const progressText = this.formatPlaybackProgress(history.progress * 1000, (history.duration || 0) * 1000);
    const progressPercentage = this.getProgressPercentage(history.progress * 1000, (history.duration || 0) * 1000);
    
    ListItem.create({ onClick: () => this.handleHistoryClick(history) });
    Flex.create({ className: "history-item" });
    
    if (this.isEditMode) {
      Checkbox.create();
      Checkbox.checked(this.selectedItems.has(history.id));
      Checkbox.onCheckChange(() => this.handleItemSelect(history.id));
      Checkbox.pop();
    }
    
    Image.create({ 
      src: media?.coverUrl || history.cover || "https://via.placeholder.com/120x160?text=No+Image",
      className: "media-cover",
      objectFit: ImageFit.Cover
    });
    Image.pop();
    
    Flex.create({ className: "media-info", direction: FlexDirection.Column });
    Text.create({ className: "media-title", numberOfLines: 2 });
    Text.text(media?.title || history.title);
    Text.pop();
    
    if (history.episodeTitle) {
      Text.create({ className: "episode-title", numberOfLines: 1 });
      Text.text(history.episodeTitle);
      Text.pop();
    }
    
    Text.create({ className: "play-time" });
    Text.text(`播放时间: ${new Date(history.lastPlayTime).toLocaleString()}`);
    Text.pop();
    
    Stack.create({ className: "progress-container" });
    ProgressBar.create();
    ProgressBar.percent(progressPercentage);
    ProgressBar.strokeWidth(4);
    ProgressBar.color("#FF4500");
    ProgressBar.pop();
    Text.create({ className: "progress-text" });
    Text.text(progressText);
    Text.pop();
    Stack.pop();
    
    if (!this.isEditMode) {
      Button.create({ className: "continue-button", onClick: () => this.handleContinuePlay(history) });
      Button.text("继续观看");
      Button.pop();
    }
    
    Flex.pop();
    ListItem.pop();
  }

  /**
   * 渲染历史记录列表
   */
  @Builder
  private renderHistoryList() {
    if (this.isLoading && !this.isRefreshing) {
      Stack.create({ className: "loading-container" });
      LoadingProgress.create({ className: "loading-progress", color: "#FF4500" });
      LoadingProgress.pop();
      Text.create();
      Text.text("加载中...");
      Text.pop();
      Stack.pop();
      return;
    }
    
    if (this.errorMessage) {
      Stack.create({ className: "error-container" });
      Text.create({ className: "error-icon" });
      Text.text("⚠️");
      Text.pop();
      Text.create({ className: "error-message" });
      Text.text(this.errorMessage);
      Text.pop();
      Button.create({ className: "retry-button", onClick: this.loadHistories });
      Button.text("重试");
      Button.pop();
      Stack.pop();
      return;
    }
    
    if (this.histories.length === 0) {
      Empty.create({ className: "empty-container" });
      Text.create({ className: "empty-icon" });
      Text.text("📺");
      Text.pop();
      Text.create();
      Text.text("暂无播放历史");
      Text.pop();
      Button.create({ className: "explore-button", onClick: () => AppNavigator.getInstance().navigateToHome() });
      Button.text("去探索");
      Button.pop();
      Empty.pop();
      return;
    }
    
    List.create({ 
      className: "history-list",
      itemTemplate: this.renderHistoryItem,
      data: this.histories,
      onRefresh: () => this.handleRefresh(),
      refreshing: this.isRefreshing
    });
    List.pop();
  }

  /**
   * 组件渲染
   */
  build() {
    Stack.create({ className: "history-page" });
    
    // 页面头部
    this.renderHeader();
    
    // 编辑工具栏
    this.renderEditToolbar();
    
    // 设置选项
    this.renderSettings();
    
    // 历史记录列表
    ScrollView.create({ className: "content-scroll", scrollBar: BarState.Auto });
    this.renderHistoryList();
    Blank.create({ className: "bottom-space" });
    Blank.pop();
    ScrollView.pop();
    
    Stack.pop();
  }
}

export default HistoryPage;