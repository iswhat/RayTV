import { useState, useEffect, onMounted, onUnmounted } from '@kit.ArkUI';
import { ScrollView, TextInput, Button, List, ListItem, Image, Text, LoadingProgress, Empty, Flex, Tag } from '@kit.ArkUI';
import { Router } from '@kit.AbilityKit';
import Logger from '../common/util/Logger.ets';
import { MediaItem } from '../data/bean/MediaItem';
import { SearchHistoryItem } from '../data/repository/SearchHistoryRepository';
import { mediaService } from '../service/media/MediaService';
import { SearchType, SearchFilter, SearchSort } from '../data/dto/SearchDto';
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
  @State searchHistory: SearchHistoryItem[] = [];
  @State isLoading: boolean = false;
  @State isSearching: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMoreResults: boolean = true;
  @State showHistory: boolean = true;
  @State displayMode: 'list' | 'grid' = 'list'; // 显示模式：列表或网格
  @State showFilterPanel: boolean = false; // 是否显示筛选面板
  @State filters: SearchFilter = {}; // 当前筛选条件
  
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
      
      // 执行搜索，传递筛选条件
      Logger.info(this.TAG, `Searching for: ${query} with filters:`, JSON.stringify(this.filters));
      
      // 构建搜索参数，包含筛选条件
      const searchParams = {
        keyword: query,
        type: SearchType.All,
        page: this.currentPage,
        pageSize: this.pageSize,
        ...this.filters // 合并筛选条件
      };
      
      const result = await mediaService.searchMedia(searchParams);
      
      // 处理搜索结果
      this.searchResults = result.items || [];
      this.hasMoreResults = result.hasMore || false;
      
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
      
      // 构建搜索参数，包含筛选条件
      const searchParams = {
        keyword: query,
        type: SearchType.All,
        page: this.currentPage,
        pageSize: this.pageSize,
        ...this.filters // 合并筛选条件
      };
      
      const result = await mediaService.searchMedia(searchParams);
      
      if (result && result.items && result.items.length > 0) {
        this.searchResults = [...this.searchResults, ...result.items];
        this.hasMoreResults = result.hasMore || false;
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
   * 切换显示模式
   */
  private toggleDisplayMode(): void {
    this.displayMode = this.displayMode === 'list' ? 'grid' : 'list';
    // 可以保存用户的显示模式偏好到配置服务
    // ConfigService.getInstance().setDisplayMode(this.displayMode);
  }

  /**
   * 渲染显示模式切换按钮
   */
  @Builder
  private renderDisplayModeToggle(): void {
    <Button
      className="display-mode-toggle"
      icon={this.displayMode === 'list' ? 'grid' : 'list'}
      onClick={this.toggleDisplayMode}
      type="circle"
      size="small"
    >
      {this.displayMode === 'list' ? '网格' : '列表'}
    </Button>
  }

  /**
   * 切换筛选面板显示
   */
  private toggleFilterPanel(): void {
    this.showFilterPanel = !this.showFilterPanel;
  }

  /**
   * 渲染筛选按钮
   */
  @Builder
  private renderFilterButton(): void {
    <Button
      className="filter-button"
      icon="filter"
      onClick={this.toggleFilterPanel}
      type="text"
      size="small"
    >
      筛选
    </Button>
  }

  /**
   * 应用筛选条件
   */
  private applyFilters(): void {
    this.currentPage = 1;
    this.performSearch();
    this.showFilterPanel = false;
  }

  /**
   * 重置筛选条件
   */
  private resetFilters(): void {
    this.filters = {};
  }

  /**
   * 渲染筛选面板
   */
  @Builder
  private renderFilterPanel(): void {
    if (!this.showFilterPanel) return;
    
    <Stack className="filter-panel-overlay" onClick={this.toggleFilterPanel}>
      <Stack className="filter-panel" onClick={(e) => e.stopPropagation()}>
        <Stack className="filter-header">
          <Text className="filter-title">筛选条件</Text>
          <Button
            icon="close"
            onClick={this.toggleFilterPanel}
            type="text"
            size="small"
          />
        </Stack>
        
        <ScrollView className="filter-content">
          {/* 媒体类型筛选 */}
          <Stack className="filter-section">
            <Text className="filter-section-title">媒体类型</Text>
            <Flex className="filter-options">
              <CheckboxGroup>
                <Checkbox value="movie" onChange={(value) => this.updateMediaTypeFilter('movie', value)}>电影</Checkbox>
                <Checkbox value="tv" onChange={(value) => this.updateMediaTypeFilter('tv', value)}>电视剧</Checkbox>
                <Checkbox value="anime" onChange={(value) => this.updateMediaTypeFilter('anime', value)}>动漫</Checkbox>
                <Checkbox value="variety" onChange={(value) => this.updateMediaTypeFilter('variety', value)}>综艺</Checkbox>
              </CheckboxGroup>
            </Flex>
          </Stack>
          
          {/* 排序方式 */}
          <Stack className="filter-section">
            <Text className="filter-section-title">排序方式</Text>
            <RadioGroup onChange={(value) => {
              this.filters.sortBy = value;
            }}>
              <Radio value="time">最新</Radio>
              <Radio value="score">评分</Radio>
              <Radio value="hot">热度</Radio>
            </RadioGroup>
          </Stack>
        </ScrollView>
        
        <Stack className="filter-actions">
          <Button onClick={this.resetFilters} type="text">重置</Button>
          <Button onClick={this.applyFilters} type="capsule">应用筛选</Button>
        </Stack>
      </Stack>
    </Stack>
  }

  /**
   * 更新媒体类型筛选
   */
  private updateMediaTypeFilter(type: string, checked: boolean): void {
    if (!this.filters.types) {
      this.filters.types = [];
    }
    
    if (checked) {
      if (!this.filters.types.includes(type)) {
        this.filters.types.push(type);
      }
    } else {
      const index = this.filters.types.indexOf(type);
      if (index > -1) {
        this.filters.types.splice(index, 1);
      }
    }
  }

  /**
   * 渲染网格模式的搜索结果项
   */
  @Builder
  private renderGridItem(item: MediaItem): void {
    <GridItem className="grid-item">
      <Stack className="grid-item-content">
        <Image
          className="grid-item-image"
          src={item.coverUrl || item.posterUrl || 'https://via.placeholder.com/100x150?text=No+Image'}
          objectFit="cover"
        />
        <Stack className="grid-item-overlay">
          <Text className="grid-item-title" numberOfLines={2}>
            {item.title}
          </Text>
          {item.year && (
            <Text className="grid-item-year">{item.year}</Text>
          )}
        </Stack>
      </Stack>
    </GridItem>
  }

  /**
   * 渲染搜索结果
   */
  @Builder
  private renderSearchResults(): void {
    <Stack className="search-results-section">
      <Flex className="results-header">
        <Text className="results-count">
          找到 {this.searchResults.length} 个结果
        </Text>
        <Flex className="header-actions">
          {this.searchResults.length > 0 && this.renderFilterButton()}
          {this.searchResults.length > 0 && this.renderDisplayModeToggle()}
        </Flex>
      </Flex>
      
      {/* 筛选面板 */}
      {this.renderFilterPanel()}
      
      {this.searchResults.length > 0 ? (
        this.displayMode === 'list' ? (
          // 列表模式
          <List
            className="search-results-list"
            itemTemplate={this.renderSearchResultItem}
            data={this.searchResults}
            onScrollBottom={() => this.loadMoreResults()}
          />
        ) : (
          // 网格模式
          <Grid
            className="search-results-grid"
            columnsTemplate="1fr 1fr"
            rowsTemplate="auto"
            rowsGap={10}
            columnsGap={10}
            onScrollBottom={() => this.loadMoreResults()}
          >
            {this.searchResults.map((item) => this.renderGridItem(item))}
          </Grid>
        )
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