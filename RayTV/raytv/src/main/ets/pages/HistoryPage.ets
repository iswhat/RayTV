import { useState, useEffect, onMounted, onUnmounted } from '@ohos/base';
import { ScrollView, Text, Button, List, ListItem, Image, LoadingProgress, Empty, Flex, Tag, Checkbox, Switch } from '@ohos/base/ui';
import { Router } from '@ohos/router';
import { historyService } from '../service/media/HistoryService';
import { mediaService } from '../service/media/MediaService';
import Logger from '@ohos/base/Logger';

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
  onMounted(() => {
    Logger.info(this.TAG, 'HistoryPage mounted');
    this.loadHistories();
  });
  
  // 清理资源
  onUnmounted(() => {
    Logger.info(this.TAG, 'HistoryPage unmounted');
  });
  
  /**
   * 加载历史记录
   */
  private async loadHistories(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // 从历史服务获取历史记录列表（按播放时间倒序）
      const histories = await historyService.getHistories(100); // 获取最近100条记录
      this.histories = histories;
      
      // 加载媒体详情
      await this.loadMediaDetails(histories);
      
      Logger.info(this.TAG, `Loaded ${this.histories.length} history records`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load histories: ${error}`);
      this.errorMessage = '加载历史记录失败，请稍后重试';
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }
  
  /**
   * 加载媒体详情
   */
  private async loadMediaDetails(histories: HistoryItem[]): Promise<void> {
    try {
      // 并行加载媒体详情
      const detailPromises = histories.map(async (history) => {
        try {
          const media = await mediaService.getMediaDetail(history.mediaId, history.siteKey);
          if (media) {
            this.mediaItems.set(history.mediaId, media);
          }
        } catch (error) {
          Logger.warn(this.TAG, `Failed to load detail for ${history.mediaId}: ${error}`);
          // 如果加载失败，使用历史记录中的基础信息
          const placeholderMedia: MediaItem = {
            id: history.mediaId,
            siteKey: history.siteKey,
            title: history.title,
            coverUrl: history.coverUrl,
            type: history.type,
            year: history.year,
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
        }
      });
      
      await Promise.all(detailPromises);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load media details: ${error}`);
    }
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    Router.back();
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
  private async handleDeleteSelected(): Promise<void> {
    if (this.selectedItems.size === 0) return;
    
    try {
      const idsToDelete = Array.from(this.selectedItems);
      
      // 删除选中的历史记录
      await historyService.removeHistories(idsToDelete);
      
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
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete histories: ${error}`);
      this.errorMessage = '删除失败，请稍后重试';
    }
  }
  
  /**
   * 处理清空所有历史
   */
  private async handleClearAll(): Promise<void> {
    try {
      // 清空所有历史记录
      await historyService.clearAllHistories();
      
      // 更新本地状态
      this.histories = [];
      this.mediaItems.clear();
      this.selectedItems.clear();
      this.isEditMode = false;
      
      Logger.info(this.TAG, 'Cleared all history records');
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
    
    // 跳转到播放页面，带上上次播放的进度
    Router.push({
      url: 'pages/PlaybackPage',
      params: {
        mediaId: history.mediaId,
        siteKey: history.siteKey,
        episodeIndex: history.episodeIndex,
        playSourceIndex: history.playSourceIndex,
        playbackPosition: history.playbackPosition,
        title: history.title,
        coverUrl: history.coverUrl
      }
    });
  }
  
  /**
   * 处理继续播放
   */
  private handleContinuePlay(history: HistoryItem): void {
    Logger.info(this.TAG, `Continue playing: ${history.title} from ${history.playbackPosition}ms`);
    
    // 跳转到播放页面，带上上次播放的进度
    Router.push({
      url: 'pages/PlaybackPage',
      params: {
        mediaId: history.mediaId,
        siteKey: history.siteKey,
        episodeIndex: history.episodeIndex,
        playSourceIndex: history.playSourceIndex,
        playbackPosition: history.playbackPosition,
        title: history.title,
        coverUrl: history.coverUrl
      }
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
  private renderHeader(): void {
    <Stack className="header">
      <Button className="back-button" onClick={this.handleBack}>
        ←
      </Button>
      <Text className="page-title">播放历史</Text>
      <Button className="action-button" onClick={this.toggleEditMode}>
        {this.isEditMode ? '取消' : '编辑'}
      </Button>
    </Stack>
  }
  
  /**
   * 渲染编辑工具栏
   */
  @Builder
  private renderEditToolbar(): void {
    if (!this.isEditMode || this.histories.length === 0) return;
    
    <Flex className="edit-toolbar">
      <Flex className="select-all">
        <Checkbox
          checked={this.selectedItems.size === this.histories.length && this.histories.length > 0}
          onCheckChange={this.handleSelectAll}
        />
        <Text>全选</Text>
      </Flex>
      <Text className="selected-count">
        已选择 {this.selectedItems.size} 项
      </Text>
      <Button
        className="delete-button"
        onClick={this.handleDeleteSelected}
        disabled={this.selectedItems.size === 0}
      >
        删除
      </Button>
      <Button
        className="clear-all-button"
        onClick={this.handleClearAll}
      >
        清空
      </Button>
    </Flex>
  }
  
  /**
   * 渲染设置选项
   */
  @Builder
  private renderSettings(): void {
    if (this.isEditMode || this.histories.length === 0) return;
    
    <Flex className="settings-container">
      <Text className="setting-label">自动续播上次内容</Text>
      <Switch
        checked={this.autoPlayLast}
        onValueChange={(value) => {
          this.autoPlayLast = value;
          // 这里可以保存设置到配置服务
          Logger.info(this.TAG, `Auto play last content: ${value}`);
        }}
      />
    </Flex>
  }
  
  /**
   * 渲染历史记录项
   */
  @Builder
  private renderHistoryItem(history: HistoryItem): void {
    const media = this.mediaItems.get(history.mediaId);
    const progressText = this.formatPlaybackProgress(history.playbackPosition, history.duration);
    const progressPercentage = this.getProgressPercentage(history.playbackPosition, history.duration);
    
    <ListItem onClick={() => this.handleHistoryClick(history)}>
      <Flex className="history-item">
        {this.isEditMode && (
          <Checkbox
            checked={this.selectedItems.has(history.id)}
            onCheckChange={() => this.handleItemSelect(history.id)}
          />
        )}
        <Image
          src={media?.coverUrl || history.coverUrl || 'https://via.placeholder.com/120x160?text=No+Image'}
          className="media-cover"
          objectFit="cover"
        />
        <Flex className="media-info" direction="column">
          <Text className="media-title" numberOfLines={2}>
            {media?.title || history.title}
          </Text>
          {history.episodeTitle && (
            <Text className="episode-title" numberOfLines={1}>
              第{history.episodeIndex + 1}集: {history.episodeTitle}
            </Text>
          )}
          <Text className="play-time">
            播放时间: {new Date(history.playTime).toLocaleString()}
          </Text>
          <Stack className="progress-container">
            <ProgressBar
              percent={progressPercentage}
              style={{ strokeWidth: 4, color: '#FF4500' }}
            />
            <Text className="progress-text">{progressText}</Text>
          </Stack>
          {!this.isEditMode && (
            <Button className="continue-button" onClick={() => this.handleContinuePlay(history)}>
              继续观看
            </Button>
          )}
        </Flex>
      </Flex>
    </ListItem>
  }
  
  /**
   * 渲染历史记录列表
   */
  @Builder
  private renderHistoryList(): void {
    if (this.isLoading && !this.isRefreshing) {
      <Stack className="loading-container">
        <LoadingProgress className="loading-progress" color="#FF4500" />
        <Text>加载中...</Text>
      </Stack>
      return;
    }
    
    if (this.errorMessage) {
      <Stack className="error-container">
        <Text className="error-icon">⚠️</Text>
        <Text className="error-message">{this.errorMessage}</Text>
        <Button className="retry-button" onClick={this.loadHistories}>
          重试
        </Button>
      </Stack>
      return;
    }
    
    if (this.histories.length === 0) {
      <Empty className="empty-container">
        <Text className="empty-icon">📺</Text>
        <Text>暂无播放历史</Text>
        <Button className="explore-button" onClick={() => Router.push({ url: 'pages/HomePage' })}>
          去探索
        </Button>
      </Empty>
      return;
    }
    
    <List
      className="history-list"
      itemTemplate={this.renderHistoryItem}
      data={this.histories}
      onRefresh={() => this.handleRefresh()}
      refreshing={this.isRefreshing}
    />
  }
  
  /**
   * 组件渲染
   */
  build() {
    <Stack className="history-page">
      {/* 页面头部 */}
      {this.renderHeader()}
      
      {/* 编辑工具栏 */}
      {this.renderEditToolbar()}
      
      {/* 设置选项 */}
      {this.renderSettings()}
      
      {/* 历史记录列表 */}
      <ScrollView className="content-scroll" scrollBar="auto">
        {this.renderHistoryList()}
        <Blank className="bottom-space" />
      </ScrollView>
    </Stack>
  }
}

export default HistoryPage;