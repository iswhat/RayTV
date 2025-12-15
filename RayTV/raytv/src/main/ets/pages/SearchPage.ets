// SearchPage.ets
// 搜索页面组件

import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';

@Entry
@Component
struct SearchPage {
  private readonly TAG: string = 'SearchPage';
  @State searchText: string = '';
  @State searchHistory: string[] = [];
  @State hotKeywords: string[] = [];
  @State searchResults: any[] = [];
  @State isSearching: boolean = false;
  @State showQuickResults: boolean = false;
  @State quickResults: any[] = [];
  @State showHistory: boolean = true;
  @State showHotKeywords: boolean = true;
  private searchHistoryRepo: any;
  private mediaService: any;

  aboutToAppear() {
    // 这里应该注入真实的SearchHistoryRepository和mediaService，暂时用模拟实现
    this.searchHistoryRepo = {
      getHistory: () => Promise.resolve([]),
      saveHistory: () => Promise.resolve(),
      clearHistory: () => Promise.resolve()
    };
    this.mediaService = {};
    
    this.loadHotKeywords();
    this.loadSearchHistory();
  }

  /**
   * 加载热门关键词
   */
  private loadHotKeywords(): void {
    try {
      // 这里应该调用真实的mediaService获取热门关键词
      // 暂时使用模拟数据
      this.hotKeywords = ['热门电影', '最新剧集', '经典动漫', '科幻大片', '爱情喜剧'];
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
  private async loadSearchHistory(): Promise<void> {
    try {
      // 使用SearchHistoryRepository从本地存储中读取搜索历史
      const history = await this.searchHistoryRepo.getHistory();
      
      // 确保history是数组类型
      if (Array.isArray(history)) {
        this.searchHistory = history;
        Logger.info(this.TAG, `Loaded ${this.searchHistory.length} search history items from repository`);
      } else {
        Logger.warn(this.TAG, `Invalid history data format, using empty array`);
        this.searchHistory = [];
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load search history: ${error}`);
      this.searchHistory = [];
    }
  }

  /**
   * 保存搜索历史
   */
  private async saveSearchHistory(keyword: string): Promise<void> {
    try {
      // 去重并限制数量
      let history = this.searchHistory.filter(item => item !== keyword);
      history.unshift(keyword);
      history = history.slice(0, 10); // 最多保存10条
      this.searchHistory = history;
      
      // 使用SearchHistoryRepository保存到本地存储
      await this.searchHistoryRepo.saveHistory(history);
      
      Logger.info(this.TAG, `Search history saved: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save search history: ${error}`);
    }
  }

  /**
   * 处理搜索输入变化
   */
  private onSearchTextChange(text: string): void {
    this.searchText = text;
    if (text.length > 0) {
      this.showQuickResults = true;
      // 这里应该调用真实的mediaService获取快速搜索结果
      this.quickSearch(text);
    } else {
      this.showQuickResults = false;
      this.quickResults = [];
    }
  }

  /**
   * 快速搜索
   */
  private quickSearch(keyword: string): void {
    try {
      // 这里应该调用真实的mediaService获取快速搜索结果
      // 暂时使用模拟数据
      this.quickResults = [
        { id: '1', title: `快速搜索结果 - ${keyword}`, type: 'movie', coverUrl: '' },
        { id: '2', title: `快速搜索结果 - ${keyword}`, type: 'tv', coverUrl: '' },
        { id: '3', title: `快速搜索结果 - ${keyword}`, type: 'anime', coverUrl: '' }
      ];
      Logger.info(this.TAG, `Quick search for '${keyword}' returned ${this.quickResults.length} results`);
    } catch (error) {
      Logger.error(this.TAG, `Quick search failed: ${error}`);
      this.quickResults = [];
    }
  }

  /**
   * 执行搜索
   */
  private async executeSearch(): Promise<void> {
    if (!this.searchText.trim()) return;
    
    try {
      this.isSearching = true;
      this.showQuickResults = false;
      
      // 保存搜索历史
      await this.saveSearchHistory(this.searchText);
      
      // 这里应该调用真实的mediaService执行搜索
      // 暂时使用模拟数据
      this.searchResults = [
        { id: '1', title: `搜索结果1 - ${this.searchText}`, type: 'movie', coverUrl: '' },
        { id: '2', title: `搜索结果2 - ${this.searchText}`, type: 'tv', coverUrl: '' },
        { id: '3', title: `搜索结果3 - ${this.searchText}`, type: 'anime', coverUrl: '' },
        { id: '4', title: `搜索结果4 - ${this.searchText}`, type: 'movie', coverUrl: '' },
        { id: '5', title: `搜索结果5 - ${this.searchText}`, type: 'tv', coverUrl: '' }
      ];
      
      Logger.info(this.TAG, `Search for '${this.searchText}' returned ${this.searchResults.length} results`);
    } catch (error) {
      Logger.error(this.TAG, `Search failed: ${error}`);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  /**
   * 处理快速搜索结果点击
   */
  private async handleQuickResultClick(result: any): Promise<void> {
    try {
      // 保存搜索历史
      await this.saveSearchHistory(this.searchText);
      
      // 跳转到详情页
      await AppNavigator.getInstance().navigateToDetail({
        id: result.id,
        siteKey: 'default',
        type: result.type
      });
      
      Logger.info(this.TAG, `Navigating to detail for ${result.title}`);
    } catch (error) {
      Logger.error(this.TAG, `Error handling quick search result click: ${error}`);
    }
  }

  /**
   * 处理搜索结果点击
   */
  private async handleSearchResultClick(result: any): Promise<void> {
    try {
      // 跳转到详情页
      await AppNavigator.getInstance().navigateToDetail({
        id: result.id,
        siteKey: 'default',
        type: result.type
      });
      
      Logger.info(this.TAG, `Navigating to detail for ${result.title}`);
    } catch (error) {
      Logger.error(this.TAG, `Error handling search result click: ${error}`);
    }
  }

  /**
   * 处理热门关键词点击
   */
  private async handleHotKeywordClick(keyword: string): Promise<void> {
    try {
      this.searchText = keyword;
      await this.executeSearch();
      Logger.info(this.TAG, `Searching for hot keyword: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, `Error handling hot keyword click: ${error}`);
    }
  }

  /**
   * 处理搜索历史点击
   */
  private async handleHistoryClick(keyword: string): Promise<void> {
    try {
      this.searchText = keyword;
      await this.executeSearch();
      Logger.info(this.TAG, `Searching for history keyword: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, `Error handling history click: ${error}`);
    }
  }

  /**
   * 清空搜索历史
   */
  private async clearSearchHistory(): Promise<void> {
    try {
      this.searchHistory = [];
      // 使用SearchHistoryRepository清空本地存储
      await this.searchHistoryRepo.clearHistory();
      Logger.info(this.TAG, 'Search history cleared');
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear search history: ${error}`);
    }
  }

  /**
   * 返回上一页
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
   * 构建搜索栏
   */
  @Builder
  buildSearchBar(): void {
    Column() {
      Row() {
        // 返回按钮
        Button()
          .onClick(() => this.handleBack()) {
          Text('返回')
            .fontSize(24)
            .fontColor('#FFFFFF')
        }

        // 搜索输入区域
        Column() {
          Button() {
            Text('搜索框')
          }

          // 快速搜索结果
          if (this.showQuickResults && this.quickResults.length > 0) {
            Column() {
              ForEach(this.quickResults, (result) => {
                Row()
                  .onClick(() => this.handleQuickResultClick(result)) {
                  Column() {
                    Text(result.title)
                      .fontSize(16)
                      .fontColor('#333333')
                    Text(result.type)
                      .fontSize(14)
                      .fontColor('#666666')
                  }
                  Text('>')
                    .fontSize(18)
                    .fontColor('#999999')
                }
              })
            }
          }
        }

        // 搜索按钮
        Button()
          .onClick(() => this.executeSearch()) {
          Text('搜索')
            .fontSize(16)
            .fontColor('#4CAF50')
            .fontWeight(600)
        }
      }
    }
  }

  /**
   * 构建搜索历史
   */
  @Builder
  buildSearchHistory(): void {
    if (this.searchHistory.length > 0 && this.showHistory) {
      Column() {
        Row() {
          Text('搜索历史')
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(600)
          Button()
            .onClick(() => this.clearSearchHistory()) {
            Text('清空')
              .fontSize(14)
              .fontColor('#666666')
          }
        }

        Flex() {
          ForEach(this.searchHistory, (keyword) => {
            Button()
              .onClick(() => this.handleHistoryClick(keyword)) {
              Text(keyword)
                .fontSize(14)
                .fontColor('#333333')
            }
          })
        }
      }
    }
  }

  /**
   * 构建热门关键词
   */
  @Builder
  buildHotKeywords(): void {
    if (this.hotKeywords.length > 0 && this.showHotKeywords) {
      Column() {
        Row() {
          Text('热门搜索')
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(600)
        }

        Flex() {
          ForEach(this.hotKeywords, (keyword) => {
            Button()
              .onClick(() => this.handleHotKeywordClick(keyword)) {
              Text(keyword)
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
          })
        }
      }
    }
  }

  /**
   * 构建搜索结果
   */
  @Builder
  buildSearchResults(): void {
    if (this.isSearching) {
      Column() {
        Text('搜索中..')
          .fontSize(18)
          .fontColor('#666666')
      }
    } else if (this.searchResults.length > 0) {
      Column() {
        Text(`搜索结果 (${this.searchResults.length})`)
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)

        ForEach(this.searchResults, (result) => {
          Row()
            .onClick(() => this.handleSearchResultClick(result)) {
            // 占位封面
            Column() {
              Text('封面')
                .fontSize(14)
                .fontColor('#999999')
            }

            Column() {
              Text(result.title)
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(600)
              Text(result.type)
                .fontSize(14)
                .fontColor('#666666')
            }
            Text('>')
              .fontSize(20)
              .fontColor('#999999')
          }
        })
      }
    } else if (this.searchText.trim()) {
      Column() {
        Text('未找到相关结果')
          .fontSize(18)
          .fontColor('#666666')
        Text('请尝试其他关键词')
          .fontSize(16)
          .fontColor('#999999')
      }
    }
  }

  build() {
    Column() {
      // 搜索栏
      this.buildSearchBar();

      // 主体内容
      if (this.searchText.trim()) {
        // 显示搜索结果
        this.buildSearchResults();
      } else {
        // 显示搜索历史和热门关键词
        Scroll() {
          Column() {
            this.buildSearchHistory();
            this.buildHotKeywords();
          }
        }
      }
    }
  }
}