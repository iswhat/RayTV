// SearchPage.ets
// 搜索页面组件

import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { SearchHistoryRepository } from '../repository/SearchHistoryRepository';

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
  private searchHistoryRepo: SearchHistoryRepository;
  private mediaService: any;

  constructor() {
    this.searchHistoryRepo = new SearchHistoryRepository();
    // 这里应该注入真实的mediaService，暂时用空对象代�?    this.mediaService = {};
  }

  aboutToAppear() {
    this.loadHotKeywords();
    this.loadSearchHistory();
  }

  /**
   * 加载热门关键�?   */
  private loadHotKeywords(): void {
    try {
      // 这里应该调用真实的mediaService获取热门关键�?      // 暂时使用模拟数据
      this.hotKeywords = ['热门电影', '最新剧�?, '经典动漫', '科幻大片', '爱情喜剧'];
      Logger.info(this.TAG, `Loaded ${this.hotKeywords.length} hot keywords`);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to load hot keywords', error as Error);
      // 使用默认热门关键�?      this.hotKeywords = ['热门电影', '最新剧�?, '经典动漫', '科幻大片', '爱情喜剧'];
    }
  }

  /**
   * 加载搜索历史
   */
  private async loadSearchHistory(): Promise<void> {
    try {
      // 使用SearchHistoryRepository从本地存储中读取搜索历史
      const searchHistoryRepo = new SearchHistoryRepository();
      const history = await searchHistoryRepo.getHistory();
      
      // 确保history是数组类�?      if (Array.isArray(history)) {
        this.searchHistory = history;
        Logger.info(this.TAG, `Loaded ${this.searchHistory.length} search history items from repository`);
      } else {
        Logger.warn(this.TAG, `Invalid history data format, using empty array`);
        this.searchHistory = [];
      }
    } catch (error) {
      Logger.error(this.TAG, 'Failed to load search history', error as Error);
      this.searchHistory = [];
    }
  }

  /**
   * 保存搜索历史
   */
  private async saveSearchHistory(keyword: string): Promise<void> {
    try {
      // 去重并限制数�?      let history = this.searchHistory.filter(item => item !== keyword);
      history.unshift(keyword);
      history = history.slice(0, 10); // 最多保�?0�?      this.searchHistory = history;
      
      // 使用SearchHistoryRepository保存到本地存�?      const searchHistoryRepo = new SearchHistoryRepository();
      await searchHistoryRepo.saveHistory(history);
      
      Logger.info(this.TAG, `Search history saved: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to save search history', error as Error);
    }
  }

  /**
   * 处理搜索输入变化
   */
  private onSearchTextChange(text: string): void {
    this.searchText = text;
    if (text.length > 0) {
      this.showQuickResults = true;
      // 这里应该调用真实的mediaService获取快速搜索结�?      this.quickSearch(text);
    } else {
      this.showQuickResults = false;
      this.quickResults = [];
    }
  }

  /**
   * 快速搜�?   */
  private quickSearch(keyword: string): void {
    try {
      // 这里应该调用真实的mediaService获取快速搜索结�?      // 暂时使用模拟数据
      this.quickResults = [
        { id: '1', title: `快速搜索结�? - ${keyword}`, type: 'movie', coverUrl: '' },
        { id: '2', title: `快速搜索结�? - ${keyword}`, type: 'tv', coverUrl: '' },
        { id: '3', title: `快速搜索结�? - ${keyword}`, type: 'anime', coverUrl: '' }
      ];
      Logger.info(this.TAG, `Quick search for '${keyword}' returned ${this.quickResults.length} results`);
    } catch (error) {
      Logger.error(this.TAG, 'Quick search failed', error as Error);
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
      Logger.error(this.TAG, 'Search failed', error as Error);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  /**
   * 处理快速搜索结果点�?   */
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
      Logger.error(this.TAG, 'Error handling quick search result click', error as Error);
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
      Logger.error(this.TAG, 'Error handling search result click', error as Error);
    }
  }

  /**
   * 处理热门关键词点�?   */
  private async handleHotKeywordClick(keyword: string): Promise<void> {
    try {
      this.searchText = keyword;
      await this.executeSearch();
      Logger.info(this.TAG, `Searching for hot keyword: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, 'Error handling hot keyword click', error as Error);
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
      Logger.error(this.TAG, 'Error handling history click', error as Error);
    }
  }

  /**
   * 清空搜索历史
   */
  private async clearSearchHistory(): Promise<void> {
    try {
      this.searchHistory = [];
      // 使用SearchHistoryRepository清空本地存储
      const searchHistoryRepo = new SearchHistoryRepository();
      await searchHistoryRepo.clearHistory();
      Logger.info(this.TAG, 'Search history cleared');
    } catch (error) {
      Logger.error(this.TAG, 'Failed to clear search history', error as Error);
    }
  }

  /**
   * 返回上一�?   */
  private async handleBack(): Promise<void> {
    try {
      await AppNavigator.getInstance().navigateToBack();
      Logger.info(this.TAG, 'Navigating back');
    } catch (error) {
      Logger.error(this.TAG, 'Failed to navigate back', error as Error);
    }
  }

  /**
   * 构建搜索�?   */
  @Builder
  buildSearchBar(): void {
    Row({
      style: {
        alignItems: 'center',
        padding: { left: 20, right: 20, top: 10, bottom: 10 },
        backgroundColor: '#4CAF50'
      }
    }) {
      // 返回按钮
      Button({
        style: {
          backgroundColor: 'transparent',
          width: 40,
          height: 40,
          justifyContent: 'center',
          alignItems: 'center'
        },
        onClick: () => this.handleBack()
      }) {
        Text('�?)
          .fontSize(24)
          .fontColor('#FFFFFF')
      }

      // 搜索输入�?      Column({
        style: {
          flex: 1,
          marginLeft: 10,
          marginRight: 10
        }
      }) {
        SearchInput({
          placeholder: '搜索电影、剧集、动�?..',
          style: {
            backgroundColor: '#FFFFFF',
            borderRadius: 20,
            paddingHorizontal: 20,
            height: 40,
            fontSize: 16
          },
          value: this.searchText,
          onSubmit: () => this.executeSearch(),
          onChange: (text) => this.onSearchTextChange(text),
          onClear: () => this.searchText = ''
        })

        // 快速搜索结�?        if (this.showQuickResults && this.quickResults.length > 0) {
          Column({
            style: {
              backgroundColor: '#FFFFFF',
              borderRadius: 10,
              marginTop: 5,
              padding: 10,
              shadowColor: '#000000',
              shadowOffsetX: 0,
              shadowOffsetY: 2,
              shadowBlurRadius: 5
            }
          }) {
            ForEach(this.quickResults, (result) => {
              Row({
                style: {
                  padding: 10,
                  borderRadius: 8,
                  backgroundColor: '#F5F5F5',
                  marginBottom: 5,
                  alignItems: 'center'
                },
                onClick: () => this.handleQuickResultClick(result)
              }) {
                Column({
                  style: {
                    marginLeft: 10,
                    flex: 1
                  }
                }) {
                  Text(result.title)
                    .fontSize(16)
                    .fontColor('#333333')
                  Text(result.type)
                    .fontSize(14)
                    .fontColor('#666666')
                    .marginTop(2)
                }
                Text('�?)
                  .fontSize(18)
                  .fontColor('#999999')
              }
            })
          }
        }
      }

      // 搜索按钮
      Button({
        style: {
          backgroundColor: '#FFFFFF',
          paddingHorizontal: 20,
          paddingVertical: 10,
          borderRadius: 20
        },
        onClick: () => this.executeSearch()
      }) {
        Text('搜索')
          .fontSize(16)
          .fontColor('#4CAF50')
          .fontWeight(600)
      }
    }
  }

  /**
   * 构建搜索历史
   */
  @Builder
  buildSearchHistory(): void {
    if (this.searchHistory.length > 0 && this.showHistory) {
      Column({
        style: {
          padding: 20
        }
      }) {
        Row({
          style: {
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 15
          }
        }) {
          Text('搜索历史')
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(600)
          Button({
            style: {
              backgroundColor: '#FFFFFF',
              paddingHorizontal: 15,
              paddingVertical: 5,
              borderRadius: 15
            },
            onClick: () => this.clearSearchHistory()
          }) {
            Text('清空')
              .fontSize(14)
              .fontColor('#666666')
          }
        }

        Wrap({
          style: {
            gap: 10
          }
        }) {
          ForEach(this.searchHistory, (keyword) => {
            Button({
              style: {
                backgroundColor: '#FFFFFF',
                paddingHorizontal: 20,
                paddingVertical: 10,
                borderRadius: 20
              },
              onClick: () => this.handleHistoryClick(keyword)
            }) {
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
   * 构建热门关键�?   */
  @Builder
  buildHotKeywords(): void {
    if (this.hotKeywords.length > 0 && this.showHotKeywords) {
      Column({
        style: {
          padding: 20
        }
      }) {
        Row({
          style: {
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 15
          }
        }) {
          Text('热门搜索')
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(600)
        }

        Wrap({
          style: {
            gap: 10
          }
        }) {
          ForEach(this.hotKeywords, (keyword) => {
            Button({
              style: {
                backgroundColor: '#66BB6A',
                paddingHorizontal: 20,
                paddingVertical: 10,
                borderRadius: 20
              },
              onClick: () => this.handleHotKeywordClick(keyword)
            }) {
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
      Column({
        style: {
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center'
        }
      }) {
        Text('搜索�?..')
          .fontSize(18)
          .fontColor('#666666')
      }
    } else if (this.searchResults.length > 0) {
      Column({
        style: {
          flex: 1,
          padding: 20
        }
      }) {
        Text(`搜索结果 (${this.searchResults.length})`)
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .marginBottom(15)

        ForEach(this.searchResults, (result) => {
          Row({
            style: {
              padding: 15,
              backgroundColor: '#FFFFFF',
              borderRadius: 10,
              marginBottom: 15,
              alignItems: 'center',
              shadowColor: '#000000',
              shadowOffsetX: 0,
              shadowOffsetY: 2,
              shadowBlurRadius: 5
            },
            onClick: () => this.handleSearchResultClick(result)
          }) {
            // 占位封面
            Column({
              style: {
                width: 80,
                height: 120,
                backgroundColor: '#E0E0E0',
                borderRadius: 5,
                justifyContent: 'center',
                alignItems: 'center'
              }
            }) {
              Text('封面')
                .fontSize(14)
                .fontColor('#999999')
            }

            Column({
              style: {
                marginLeft: 15,
                flex: 1
              }
            }) {
              Text(result.title)
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(600)
              Text(result.type)
                .fontSize(14)
                .fontColor('#666666')
                .marginTop(5)
            }
            Text('�?)
              .fontSize(20)
              .fontColor('#999999')
          }
        })
      }
    } else if (this.searchText.trim()) {
      Column({
        style: {
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center',
          padding: 20
        }
      }) {
        Text('未找到相关结�?)
          .fontSize(18)
          .fontColor('#666666')
        Text('请尝试其他关键词')
          .fontSize(16)
          .fontColor('#999999')
          .marginTop(10)
      }
    }
  }

  build() {
    Column({
      style: {
        flex: 1,
        backgroundColor: '#F5F5F5'
      }
    }) {
      // 搜索�?      this.buildSearchBar();

      // 主体内容
      if (this.searchText.trim()) {
        // 显示搜索结果
        this.buildSearchResults();
      } else {
        // 显示搜索历史和热门关键词
        Scroll({
          style: {
            flex: 1
          }
        }) {
          Column({
            style: {
              backgroundColor: '#F5F5F5'
            }
          }) {
            this.buildSearchHistory();
            this.buildHotKeywords();
          }
        }
      }
    }
  }
}
