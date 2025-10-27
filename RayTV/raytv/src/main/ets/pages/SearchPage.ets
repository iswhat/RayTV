import { useState, useEffect, onMounted, onUnmounted } from '@ohos/base';
import { ScrollView, TextInput, Button, List, ListItem, Image, Text, LoadingProgress, Empty, Flex, Tag } from '@ohos/base/ui';
import { Router } from '@ohos/router';
import { mediaService } from '../service/media/MediaService';
import Logger from '@ohos/base/Logger';

/**
 * 搜索页面组件
 * 实现媒体搜索功能，包括搜索输入、结果展示、历史搜索等
 */
@Component
struct SearchPage {
  private readonly TAG: string = 'SearchPage';
  
  // 状态管理
  @State searchQuery: string = '';
  @State searchResults: MediaItem[] = [];
  @State hotKeywords: string[] = [];
  @State searchHistory: string[] = [];
  @State isLoading: boolean = false;
  @State isSearching: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMoreResults: boolean = true;
  @State showHistory: boolean = true;
  
  // 分页配置
  private pageSize: number = 20;
  private searchDebounceTimer: NodeJS.Timeout | null = null;
  
  // 初始化
  onMounted(() => {
    Logger.info(this.TAG, 'SearchPage mounted');
    
    // 获取路由参数中的搜索词
    const params = Router.getParams();
    if (params?.['query']) {
      this.searchQuery = params['query'];
      this.performSearch();
    } else {
      // 加载热门搜索词
      this.loadHotKeywords();
    }
    
    // 加载搜索历史
    this.loadSearchHistory();
  });
  
  // 清理资源
  onUnmounted(() => {
    Logger.info(this.TAG, 'SearchPage unmounted');
    
    // 清理定时器
    if (this.searchDebounceTimer) {
      clearTimeout(this.searchDebounceTimer);
    }
  });
  
  /**
   * 加载热门搜索词
   */
  private async loadHotKeywords(): Promise<void> {
    try {
      this.hotKeywords = await mediaService.getHotSearchKeywords(10);
      Logger.info(this.TAG, `Loaded ${this.hotKeywords.length} hot keywords`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load hot keywords: ${error}`);
      // 使用默认热门关键词
      this.hotKeywords = ['热门电影', '最新剧集', '经典动漫', '科幻大片', '爱情喜剧'];
    }
  }
  
  /**
   * 加载搜索历史
   */
  private loadSearchHistory(): Promise<void> {
    return new Promise((resolve) => {
      try {
        // 这里应该从本地存储中读取搜索历史
        // 暂时使用模拟数据
        const history = ['复仇者联盟', '海贼王', '星际穿越'];
        this.searchHistory = history;
        Logger.info(this.TAG, `Loaded ${this.searchHistory.length} search history items`);
      } catch (error) {
        Logger.error(this.TAG, `Failed to load search history: ${error}`);
        this.searchHistory = [];
      }
      resolve();
    });
  }
  
  /**
   * 保存搜索历史
   */
  private saveSearchHistory(keyword: string): Promise<void> {
    return new Promise((resolve) => {
      try {
        // 去重并限制数量
        let history = this.searchHistory.filter(item => item !== keyword);
        history.unshift(keyword);
        history = history.slice(0, 10); // 最多保存10条
        
        this.searchHistory = history;
        
        // 这里应该保存到本地存储
        Logger.info(this.TAG, `Search history saved: ${keyword}`);
      } catch (error) {
        Logger.error(this.TAG, `Failed to save search history: ${error}`);
      }
      resolve();
    });
  }
  
  /**
   * 清除搜索历史
   */
  private clearSearchHistory(): Promise<void> {
    return new Promise((resolve) => {
      try {
        this.searchHistory = [];
        // 这里应该清除本地存储中的搜索历史
        Logger.info(this.TAG, 'Search history cleared');
      } catch (error) {
        Logger.error(this.TAG, `Failed to clear search history: ${error}`);
      }
      resolve();
    });
  }
  
  /**
   * 处理搜索输入变化
   */
  private handleSearchInputChange(value: string): void {
    this.searchQuery = value;
    
    // 防抖处理
    if (this.searchDebounceTimer) {
      clearTimeout(this.searchDebounceTimer);
    }
    
    // 输入停止300ms后执行搜索
    this.searchDebounceTimer = setTimeout(() => {
      if (value.trim().length >= 2) {
        this.performSearch();
      } else if (value.trim().length === 0) {
        this.resetSearchState();
      }
    }, 300);
  }
  
  /**
   * 执行搜索
   */
  private async performSearch(): Promise<void> {
    const query = this.searchQuery.trim();
    if (!query) return;
    
    this.isSearching = true;
    this.isLoading = true;
    this.errorMessage = '';
    this.showHistory = false;
    this.currentPage = 1;
    
    try {
      // 保存搜索历史
      await this.saveSearchHistory(query);
      
      // 执行搜索
      Logger.info(this.TAG, `Searching for: ${query}`);
      this.searchResults = await mediaService.searchMedia(query, this.currentPage, this.pageSize);
      
      // 检查是否有更多结果
      this.hasMoreResults = this.searchResults.length >= this.pageSize;
      
      Logger.info(this.TAG, `Search completed, found ${this.searchResults.length} results`);
    } catch (error) {
      Logger.error(this.TAG, `Search failed: ${error}`);
      this.errorMessage = '搜索失败，请稍后重试';
      this.searchResults = [];
      this.hasMoreResults = false;
    } finally {
      this.isLoading = false;
      this.isSearching = false;
    }
  }
  
  /**
   * 加载更多搜索结果
   */
  private async loadMoreResults(): Promise<void> {
    if (!this.hasMoreResults || this.isLoading || !this.searchQuery.trim()) return;
    
    this.isLoading = true;
    this.currentPage++;
    
    try {
      const query = this.searchQuery.trim();
      Logger.info(this.TAG, `Loading more results for: ${query}, page ${this.currentPage}`);
      
      const moreResults = await mediaService.searchMedia(query, this.currentPage, this.pageSize);
      
      if (moreResults && moreResults.length > 0) {
        this.searchResults = [...this.searchResults, ...moreResults];
        this.hasMoreResults = moreResults.length === this.pageSize;
      } else {
        this.hasMoreResults = false;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load more results: ${error}`);
      this.errorMessage = '加载更多结果失败';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 重置搜索状态
   */
  private resetSearchState(): void {
    this.searchResults = [];
    this.showHistory = true;
    this.errorMessage = '';
    this.currentPage = 1;
    this.hasMoreResults = true;
  }
  
  /**
   * 处理关键词点击
   */
  private handleKeywordClick(keyword: string): void {
    this.searchQuery = keyword;
    this.performSearch();
  }
  
  /**
   * 处理搜索结果项点击
   */
  private handleSearchResultClick(media: MediaItem): void {
    Logger.info(this.TAG, `Search result clicked: ${media.title}`);
    // 跳转到详情页
    Router.push({
      url: 'pages/MediaDetailPage',
      params: {
        mediaId: media.id,
        siteKey: media.siteKey
      }
    });
  }
  
  /**
   * 处理清除按钮点击
   */
  private handleClearInput(): void {
    this.searchQuery = '';
    this.resetSearchState();
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    Router.back();
  }
  
  /**
   * 渲染搜索输入框
   */
  @Builder
  private renderSearchInput(): void {
    <Stack className="search-input-container">
      <Button className="back-button" onClick={this.handleBack}>
        ←
      </Button>
      <Flex className="search-input-wrapper">
        <Text className="search-icon">🔍</Text>
        <TextInput
          className="search-input"
          value={this.searchQuery}
          onChange={this.handleSearchInputChange}
          onSubmit={this.performSearch}
          placeholder="搜索电影、电视剧、动漫..."
          enterKeyType="search"
          autoFocus={true}
        />
        {this.searchQuery && (
          <Button className="clear-button" onClick={this.handleClearInput}>
            ✕
          </Button>
        )}
      </Flex>
      <Button className="search-button" onClick={this.performSearch}>
        搜索
      </Button>
    </Stack>
  }
  
  /**
   * 渲染热门搜索
   */
  @Builder
  private renderHotKeywords(): void {
    <Stack className="hot-keywords-section">
      <Flex className="section-header">
        <Text className="section-title">热门搜索</Text>
      </Flex>
      <Flex className="keywords-container" wrap="wrap">
        {this.hotKeywords.map((keyword, index) => (
          <Tag
            key={`hot-${index}`}
            className="keyword-tag hot"
            onClick={() => this.handleKeywordClick(keyword)}
          >
            <Text className="keyword-rank">{index + 1}</Text>
            <Text>{keyword}</Text>
          </Tag>
        ))}
      </Flex>
    </Stack>
  }
  
  /**
   * 渲染搜索历史
   */
  @Builder
  private renderSearchHistory(): void {
    if (this.searchHistory.length === 0) return;
    
    <Stack className="search-history-section">
      <Flex className="section-header">
        <Text className="section-title">搜索历史</Text>
        <Button className="clear-history-button" onClick={this.clearSearchHistory}>
          清除
        </Button>
      </Flex>
      <Flex className="keywords-container" wrap="wrap">
        {this.searchHistory.map((keyword, index) => (
          <Tag
            key={`history-${index}`}
            className="keyword-tag history"
            onClick={() => this.handleKeywordClick(keyword)}
          >
            <Text className="history-icon">🕐</Text>
            <Text>{keyword}</Text>
          </Tag>
        ))}
      </Flex>
    </Stack>
  }
  
  /**
   * 渲染搜索结果项
   */
  @Builder
  private renderSearchResultItem(media: MediaItem): void {
    <ListItem onClick={() => this.handleSearchResultClick(media)}>
      <Flex className="search-result-item">
        <Image
          src={media.coverUrl || 'https://via.placeholder.com/100x150?text=No+Image'}
          className="result-cover"
          objectFit="cover"
        />
        <Flex className="result-info" direction="column">
          <Text className="result-title" numberOfLines={2}>{media.title}</Text>
          <Flex className="result-meta">
            {media.year && <Tag className="meta-tag">{media.year}</Tag>}
            {media.type && <Tag className="meta-tag">{media.type}</Tag>}
            {media.score && <Tag className="meta-tag score">{media.score}</Tag>}
          </Flex>
          {media.description && (
            <Text className="result-description" numberOfLines={2}>
              {media.description}
            </Text>
          )}
          {media.directors && media.directors.length > 0 && (
            <Text className="result-directors" numberOfLines={1}>
              导演: {media.directors.slice(0, 3).join(', ')}
            </Text>
          )}
          {media.actors && media.actors.length > 0 && (
            <Text className="result-actors" numberOfLines={1}>
              主演: {media.actors.slice(0, 3).join(', ')}
            </Text>
          )}
        </Flex>
      </Flex>
    </ListItem>
  }
  
  /**
   * 渲染搜索结果
   */
  @Builder
  private renderSearchResults(): void {
    <Stack className="search-results-section">
      <Text className="results-count">
        找到 {this.searchResults.length} 个结果
      </Text>
      
      {this.searchResults.length > 0 ? (
        <List
          className="search-results-list"
          itemTemplate={this.renderSearchResultItem}
          data={this.searchResults}
          onScrollBottom={() => this.loadMoreResults()}
        />
      ) : (
        <Empty className="empty-results">
          <Text>暂无搜索结果</Text>
        </Empty>
      )}
      
      {this.isLoading && this.currentPage > 1 && (
        <Stack className="loading-more">
          <LoadingProgress className="loading-progress" color="#FF4500" />
          <Text>加载更多...</Text>
        </Stack>
      )}
    </Stack>
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    <Stack className="loading-container">
      <LoadingProgress className="loading-progress" color="#FF4500" />
      <Text>搜索中...</Text>
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
      <Button className="retry-button" onClick={this.performSearch}>
        重试
      </Button>
    </Stack>
  }
  
  /**
   * 组件渲染
   */
  build() {
    <Stack className="search-page">
      {/* 搜索输入区域 */}
      {this.renderSearchInput()}
      
      {/* 主内容区域 */}
      <ScrollView className="content-scroll" scrollBar="auto">
        {this.isSearching && this.isLoading && this.currentPage === 1 ? (
          this.renderLoading()
        ) : this.errorMessage ? (
          this.renderError()
        ) : this.showHistory ? (
          <Stack>
            {this.renderHotKeywords()}
            {this.renderSearchHistory()}
          </Stack>
        ) : (
          this.renderSearchResults()
        )}
        
        <Blank className="bottom-space" />
      </ScrollView>
    </Stack>
  }
}

export default SearchPage;