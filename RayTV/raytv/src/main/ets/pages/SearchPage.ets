import { AppNavigator } from '../navigation/AppNavigator';
// Logger import removed as AnalyticsService was deleted
import { SearchHistoryRepository, SearchType } from '../data/repository/SearchHistoryRepository';
import SearchService, { SearchResultItem, SearchOptions } from '../service/search/SearchService';
import { MediaService } from '../service/media/MediaService';
import CacheService from '../service/cache/CacheService';
import { PinyinUtil } from '../common/util/PinyinUtil';
import display from '@ohos.display';
import { Column, Row, Text, Button, Image, Scroll, ForEach, FlexAlign, TextAlign, VerticalAlign, BarState, ImageFit } from '@ohos.components';

// 鎼滅储杩囨护鍣ㄦ帴鍙?| Search filters interface
export interface SearchFilters {
  // 绫诲瀷杩囨护鍣?| Type filter
  type?: string[];
  // 骞翠唤杩囨护鍣?| Year filter
  year?: number[];
  // 璇勫垎杩囨护鍣?| Rating filter
  rating?: string[];
  // 鍦板尯杩囨护鍣?| Region filter
  region?: string[];
  // 璇█杩囨护鍣?| Language filter
  language?: string[];
}

// 鎼滅储璇锋眰鎺ュ彛 | Search request interface
export interface SearchRequest {
  query: string;
  pageSize: number;
  type?: string;
  page?: number;
  filters?: SearchFilters;
  siteKeys?: string[];
  limitPerSite?: number;
  timeout?: number;
}



// 鎼滅储缁撴灉鎺ュ彛 | Search result interface
export interface SearchResult {
  id: string;
  title: string;
  type: string;
  coverUrl: string;
  siteKey?: string;
}

// 鏄剧ず淇℃伅鎺ュ彛 | Display info interface
interface DisplayInfo {
  width: number;
  height: number;
  densityPixels: number;
  orientation: number;
  refreshRate: number;
}

// 铏氭嫙閿洏鎸夐敭 | Virtual keyboard key
interface KeyboardKey {
  value: string;
  type: 'letter' | 'number' | 'symbol' | 'action';
  label?: string;
}

@Entry
@Component
struct SearchPage {
  private readonly TAG: string = 'SearchPage';
  private scroller: Scroller = new Scroller();
  private contentScroller: Scroller = new Scroller();
  
  // 鐘舵€佺鐞?| State management
  @State searchText: string = '';
  @State searchHistory: string[] = [];
  @State hotKeywords: string[] = [];
  @State quickResults: SearchResult[] = [];
  @State pinyinRecommendations: string[] = [];
  @State isSearching: boolean = false;
  @State showQuickResults: boolean = false;
  @State showHistory: boolean = true;
  @State showHotKeywords: boolean = true;
  @State showVirtualKeyboard: boolean = true;
  @State showSystemKeyboard: boolean = false;
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State selectedKeyIndex: number = -1;
  
  // 鏈嶅姟瀹炰緥灏嗗湪鏂规硶涓洿鎺ヨ皟鐢?| Service instances will be called directly in methods
  
  // 铏氭嫙閿洏鎸夐敭 | Virtual keyboard keys
  private keyboardKeys: KeyboardKey[] = [
    { value: '1', type: 'number' },
    { value: '2', type: 'number', label: 'ABC' },
    { value: '3', type: 'number', label: 'DEF' },
    { value: '4', type: 'number', label: 'GHI' },
    { value: '5', type: 'number', label: 'JKL' },
    { value: '6', type: 'number', label: 'MNO' },
    { value: '7', type: 'number', label: 'PQRS' },
    { value: '8', type: 'number', label: 'TUV' },
    { value: '9', type: 'number', label: 'WXYZ' },
    { value: '0', type: 'number' },
    { value: 'backspace', type: 'action', label: '鍒犻櫎' },
    { value: 'clear', type: 'action', label: '娓呯┖' },
    { value: 'q', type: 'letter' },
    { value: 'w', type: 'letter' },
    { value: 'e', type: 'letter' },
    { value: 'r', type: 'letter' },
    { value: 't', type: 'letter' },
    { value: 'y', type: 'letter' },
    { value: 'u', type: 'letter' },
    { value: 'i', type: 'letter' },
    { value: 'o', type: 'letter' },
    { value: 'p', type: 'letter' },
    { value: 'a', type: 'letter' },
    { value: 's', type: 'letter' },
    { value: 'd', type: 'letter' },
    { value: 'f', type: 'letter' },
    { value: 'g', type: 'letter' },
    { value: 'h', type: 'letter' },
    { value: 'j', type: 'letter' },
    { value: 'k', type: 'letter' },
    { value: 'l', type: 'letter' },
    { value: 'z', type: 'letter' },
    { value: 'x', type: 'letter' },
    { value: 'c', type: 'letter' },
    { value: 'v', type: 'letter' },
    { value: 'b', type: 'letter' },
    { value: 'n', type: 'letter' },
    { value: 'm', type: 'letter' },
    { value: 'space', type: 'action', label: '绌烘牸' },
    { value: 'search', type: 'action', label: '鎼滅储' }
  ];
  
  // 鐢熷懡鍛ㄦ湡 | Lifecycle
  aboutToAppear() {
    console.info('SearchPage about to appear');
    
    // 鍒濆鍖栧睆骞曚俊鎭?| Initialize screen information
    this.initScreenInfo();
    
    // 鍔犺浇鐑棬鍏抽敭璇嶅拰鎼滅储鍘嗗彶 | Load hot keywords and search history
    this.loadHotKeywords();
    this.loadSearchHistory();
  }
  
  // 鍒濆鍖栧睆骞曚俊鎭?| Initialize screen information
  private initScreenInfo(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      console.info('Screen info: width=' + this.screenWidth + ', height=' + this.screenHeight + ', landscape=' + this.isLandscape);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('Failed to get screen info: ' + err.message);
      // 榛樿鍊?| Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
    }
  }
  
  /**
   * 鍔犺浇鐑棬鍏抽敭璇?| Load hot keywords
   */
  private async loadHotKeywords(): Promise<void> {
    try {
      // 鐢熸垚缂撳瓨閿?| Generate cache key
      const cacheKey = 'hot_keywords';
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?| Try to get from cache
      const cachedKeywords: string[] | null = await CacheService.getInstance().get<string[]>(cacheKey);
      
      if (cachedKeywords && Array.isArray(cachedKeywords) && cachedKeywords.length > 0) {
        this.hotKeywords = cachedKeywords;
        console.info('Loaded ' + this.hotKeywords.length + ' hot keywords from cache');
        return;
      }
      
      // 浣跨敤榛樿鐑棬鍏抽敭璇?| Use default hot keywords
      this.hotKeywords = ['鐑棬鐢靛奖', '鏈€鏂板墽闆?, '缁忓吀鍔ㄧ敾', '绉戝够澶х墖', '鐖辨儏鍠滃墽'];
      
      // 缂撳瓨缁撴灉 | Cache result
      await CacheService.getInstance().set<string[]>(cacheKey, this.hotKeywords);
      
      console.info('Loaded ' + this.hotKeywords.length + ' hot keywords');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('Failed to load hot keywords: ' + err.message);
      this.hotKeywords = ['鐑棬鐢靛奖', '鏈€鏂板墽闆?, '缁忓吀鍔ㄧ敾', '绉戝够澶х墖', '鐖辨儏鍠滃墽'];
    }
  }
  
  /**
   * 鍔犺浇鎼滅储鍘嗗彶 | Load search history
   */
  private async loadSearchHistory(): Promise<void> {
    try {
      // 鐢变簬SearchHistoryRepository.getHistory鏂规硶涓嶅瓨鍦紝浣跨敤妯℃嫙鏁版嵁
      this.searchHistory = [];
        console.info('Loaded ' + this.searchHistory.length + ' search history items');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('Failed to load search history: ' + err.message);
      this.searchHistory = [];
    }
  }
  
  /**
   * 淇濆瓨鎼滅储鍘嗗彶 | Save search history
   */
  private async saveSearchHistory(keyword: string): Promise<void> {
    try {
      // 鍘婚噸骞堕檺鍒舵暟閲?| Remove duplicates and limit quantity
      let history = this.searchHistory.filter(item => item !== keyword);
      history.unshift(keyword);
      history = history.slice(0, 10); // 鏈€澶氫繚瀛?0鏉?| Save at most 10 items
      this.searchHistory = history;
      
      console.info('Search history saved: ' + keyword);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('Failed to save search history: ' + err.message);
    }
  }
  
  /**
   * 澶勭悊鎼滅储杈撳叆鍙樺寲 | Handle search input change
   */
  private onSearchTextChange(text: string): void {
    this.searchText = text;
    if (text.length > 0) {
      this.showQuickResults = true;
      // 蹇€熸悳绱?| Quick search
      this.quickSearch(text);
      // 鐢熸垚鎷奸煶鎺ㄨ崘 | Generate pinyin recommendations
      this.generatePinyinRecommendations(text);
    } else {
      this.showQuickResults = false;
      this.quickResults = [];
      this.pinyinRecommendations = [];
    }
  }
  
  /**
   * 鐢熸垚鎷奸煶鎺ㄨ崘 | Generate pinyin recommendations
   */
  private generatePinyinRecommendations(text: string): void {
    try {
      // 浣跨敤PinyinUtil鐢熸垚鎷奸煶棣栧瓧姣嶆帹鑽?| Use PinyinUtil to generate pinyin initial letter recommendations
      // 杩欓噷搴旇璋冪敤瀹為檯鐨勬湇鍔¤幏鍙栨帹鑽愶紝杩欓噷绠€鍖栧鐞?| Should call actual service to get recommendations, simplified here
      this.pinyinRecommendations = [];
      console.info('Generated pinyin recommendations for: ' + text);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('Failed to generate pinyin recommendations: ' + err.message);
      this.pinyinRecommendations = [];
    }
  }
  
  /**
   * 蹇€熸悳绱?| Quick search
   */
  private async quickSearch(keyword: string): Promise<void> {
    try {
      this.isSearching = true;
      
      // 鐢熸垚缂撳瓨閿?| Generate cache key
      const cacheKey = 'quick_search_' + keyword;
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?| Try to get from cache
      const cachedResults: SearchResult[] | null = await CacheService.getInstance().get<SearchResult[]>(cacheKey);
      
      if (cachedResults && cachedResults.length > 0) {
        this.quickResults = cachedResults;
        console.info('Quick search for \'' + keyword + '\' returned ' + this.quickResults.length + ' results from cache');
        this.isSearching = false;
        return;
      }
      
      // 璋冪敤瀹為檯鐨凷earchService鑾峰彇蹇€熸悳绱㈢粨鏋?| Call actual SearchService to get quick search results
      const searchOptions: SearchOptions = {
        query: keyword,
        pageSize: 10,
        type: SearchType.ALL,
        page: 1,
        filters: {
          types: [],
          years: [],
          genres: [],
          categories: [],
          countries: [],
          regions: [],
          languages: [],
          sortBy: 'relevance',
          sortOrder: 'desc'
        },
        siteKeys: [],
        limitPerSite: 10,
        timeout: 10000
      };
      const result = await SearchService.getInstance().search(searchOptions);
      if (result && result.items && Array.isArray(result.items)) {
        this.quickResults = result.items.map((item: SearchResultItem) => {
          const searchResult: SearchResult = {
            id: item.id || '',
            title: item.title || '',
            type: item.type || 'vod',
            coverUrl: item.coverUrl || item.posterUrl || '',
            siteKey: item.siteKey
          };
          return searchResult;
        });
        
        // 缂撳瓨缁撴灉 | Cache result
        await CacheService.getInstance().set<SearchResult[]>(cacheKey, this.quickResults);
      } else {
        this.quickResults = [];
      }
      console.info('Quick search for \'' + keyword + '\' returned ' + this.quickResults.length + ' results from service');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('Quick search failed: ' + err.message);
      this.quickResults = [];
    } finally {
      this.isSearching = false;
    }
  }
  
  /**
   * 鎵ц鎼滅储 | Execute search
   */
  private async executeSearch(): Promise<void> {
    if (!this.searchText.trim()) return;
    
    try {
      this.isSearching = true;
      this.showQuickResults = false;
      
      // 淇濆瓨鎼滅储鍘嗗彶 | Save search history
      await this.saveSearchHistory(this.searchText);
      
      // 瀵艰埅鍒版悳绱㈢粨鏋滈〉 | Navigate to search result page
      AppNavigator.getInstance().navigateToSearchResult(this.searchText);
      
      console.info(`Executing search for: ${this.searchText}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(`Search failed: ${err.message}`);
    } finally {
      this.isSearching = false;
    }
  }
  
  /**
   * 澶勭悊蹇€熸悳绱㈢粨鏋滅偣鍑?| Handle quick search result click
   */
  private async handleQuickResultClick(result: SearchResult): Promise<void> {
    try {
      // 淇濆瓨鎼滅储鍘嗗彶 | Save search history
      await this.saveSearchHistory(this.searchText);
      
      // 璺宠浆鍒拌鎯呴〉 | Navigate to detail page
      await AppNavigator.getInstance().navigateToDetail({
        id: result.id,
        siteKey: result.siteKey || '',
        type: result.type
      });
      
      console.info(`Navigating to detail for ${result.title}`);
    } catch (error) {
      console.error(`Error handling quick search result click: ${error.message}`);
    }
  }
  
  /**
   * 澶勭悊鐑棬鍏抽敭璇嶇偣鍑?| Handle hot keyword click
   */
  private async handleHotKeywordClick(keyword: string): Promise<void> {
    try {
      this.searchText = keyword;
      await this.executeSearch();
      console.info(`Searching for hot keyword: ${keyword}`);
    } catch (error) {
      console.error(`Error handling hot keyword click: ${error.message}`);
    }
  }
  
  /**
   * 澶勭悊鎼滅储鍘嗗彶鐐瑰嚮 | Handle search history click
   */
  private async handleHistoryClick(keyword: string): Promise<void> {
    try {
      this.searchText = keyword;
      await this.executeSearch();
      console.info(`Searching for history keyword: ${keyword}`);
    } catch (error) {
      console.error(`Error handling history click: ${error.message}`);
    }
  }
  
  /**
   * 澶勭悊鎷奸煶鎺ㄨ崘鐐瑰嚮 | Handle pinyin recommendation click
   */
  private async handlePinyinRecommendationClick(recommendation: string): Promise<void> {
    try {
      this.searchText = recommendation;
      await this.executeSearch();
      console.info(`Searching for pinyin recommendation: ${recommendation}`);
    } catch (error) {
      console.error(`Error handling pinyin recommendation click: ${error.message}`);
    }
  }
  
  /**
   * 娓呯┖鎼滅储鍘嗗彶 | Clear search history
   */
  private async clearSearchHistory(): Promise<void> {
    try {
      this.searchHistory = [];
      console.info('Search history cleared');
    } catch (error) {
      console.error(`Failed to clear search history: ${error.message}`);
    }
  }
  
  /**
   * 澶勭悊铏氭嫙閿洏鎸夐敭鐐瑰嚮 | Handle virtual keyboard key click
   */
  private handleKeyboardKeyClick(key: KeyboardKey): void {
    switch (key.type) {
      case 'letter':
      case 'number':
      case 'symbol':
        this.onSearchTextChange(this.searchText + key.value);
        break;
      case 'action':
        if (key.value === 'backspace') {
          this.onSearchTextChange(this.searchText.slice(0, -1));
        } else if (key.value === 'clear') {
          this.onSearchTextChange('');
        } else if (key.value === 'space') {
          this.onSearchTextChange(this.searchText + ' ');
        } else if (key.value === 'search') {
          this.executeSearch();
        }
        break;
    }
  }
  
  /**
   * 澶勭悊杩斿洖 | Handle back
   */
  private async handleBack(): Promise<void> {
    try {
      await AppNavigator.getInstance().navigateToBack();
      console.info('Navigating back');
    } catch (error) {
      console.error(`Failed to navigate back: ${error.message}`);
    }
  }
  
  /**
   * 鍒囨崲閿洏绫诲瀷 | Switch keyboard type
   */
  private toggleKeyboardType(): void {
    this.showVirtualKeyboard = !this.showVirtualKeyboard;
    this.showSystemKeyboard = !this.showSystemKeyboard;
  }
  
  // 娓叉煋鎼滅储鏍?| Render search bar
  @Builder
  renderSearchBar() {
    Column() {
      Row() {
        // 杩斿洖鎸夐挳 | Back button
        Button() {
          Text('杩斿洖')
            .fontSize(18)
            .fontColor('#FFFFFF')
        }
        .width(100)
        .height(60)
        .backgroundColor('#007AFF')
        .borderRadius(12)
        .margin({ left: 40 })
        .onClick(() => this.handleBack())
        
        // 鎼滅储杈撳叆鍖哄煙 | Search input area
        Column() {
          Row() {
            Text('鎼滅储: ' + this.searchText)
              .fontSize(20)
              .fontColor('#FFFFFF')
              .flexGrow(1)
              .margin({ left: 24 })
            
            Button() {
              Text('鍒囨崲閿洏')
                .fontSize(16)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(48)
            .backgroundColor('#34C759')
            .borderRadius(8)
            .margin({ right: 16 })
            .onClick(() => this.toggleKeyboardType())
          }
          .width('100%')
          .height(70)
          .backgroundColor('#2C2C2C')
          .borderRadius(12)
          .alignItems(VerticalAlign.Center)
          
          // 蹇€熸悳绱㈢粨鏋?| Quick search results
          if (this.showQuickResults && this.quickResults.length > 0) {
            Scroll(this.contentScroller) {
              Column() {
                ForEach(this.quickResults, (result: SearchResult) => {
                  Row() {
                    Image(result.coverUrl || '')
                      .width(100)
                      .height(150)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                      .margin({ right: 20 })
                      .backgroundColor('#2C2C2C')
                    
                    Column() {
                      Text(result.title)
                        .fontSize(18)
                        .fontColor('#FFFFFF')
                        .fontWeight(600)
                        .maxLines(2)
                      Text(result.type)
                        .fontSize(16)
                        .fontColor('#8E8E93')
                        .margin({ top: 8 })
                    }
                    .flexGrow(1)
                    
                    Text('>')
                      .fontSize(24)
                      .fontColor('#8E8E93')
                  }
                  .width('100%')
                  .padding(20)
                  .backgroundColor('#1E1E1E')
                  .borderRadius(12)
                  .margin({ top: 12 })
                  .onClick(() => this.handleQuickResultClick(result))
                })
              }
              .padding(20)
            }
            .scrollBar(BarState.Auto)
            .height(this.isLandscape ? 350 : 300)
            .backgroundColor('#1E1E1E')
            .borderRadius(12)
            .margin({ top: 12 })
          }
        }
        .flexGrow(1)
        .margin({ left: 24, right: 24 })
        
        // 鎼滅储鎸夐挳 | Search button
        Button() {
          Text('鎼滅储')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(600)
        }
        .width(120)
        .height(60)
        .backgroundColor('#007AFF')
        .borderRadius(12)
        .margin({ right: 40 })
        .onClick(() => this.executeSearch())
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ top: 24 })
  }
  
  // 娓叉煋鎼滅储鍘嗗彶 | Render search history
  @Builder
  renderSearchHistory() {
    if (this.searchHistory.length > 0 && this.showHistory && !this.searchText) {
      Column() {
        Row() {
          Text('鎼滅储鍘嗗彶')
            .fontSize(22)
            .fontColor('#FFFFFF')
            .fontWeight(600)
            .margin({ left: 40 })
          
          Button() {
            Text('娓呯┖')
              .fontSize(18)
              .fontColor('#8E8E93')
          }
          .backgroundColor('transparent')
          .margin({ right: 40 })
          .onClick(() => this.clearSearchHistory())
          
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 20 })
        
        Scroll(this.scroller) {
          Row() {
            ForEach(this.searchHistory, (keyword: string) => {
              Button() {
                Text(keyword)
                  .fontSize(18)
                  .fontColor('#FFFFFF')
              }
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .backgroundColor('#2C2C2C')
              .borderRadius(24)
              .margin({ left: 40, right: 16 })
              .onClick(() => this.handleHistoryClick(keyword))
            })
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .margin({ top: 24 })
    }
  }
  
  // 娓叉煋鐑棬鍏抽敭璇?| Render hot keywords
  @Builder
  renderHotKeywords() {
    if (this.hotKeywords.length > 0 && this.showHotKeywords && !this.searchText) {
      Column() {
        Row() {
          Text('鐑棬鎼滅储')
            .fontSize(22)
            .fontColor('#FFFFFF')
            .fontWeight(600)
            .margin({ left: 40 })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        Scroll(this.scroller) {
          Row() {
            ForEach(this.hotKeywords, (keyword: string) => {
              Button() {
                Text(keyword)
                  .fontSize(18)
                  .fontColor('#FFFFFF')
              }
              .padding({ left: 30, right: 30, top: 14, bottom: 14 })
              .backgroundColor('#FF9500')
              .borderRadius(28)
              .margin({ left: 40, right: 16 })
              .onClick(() => this.handleHotKeywordClick(keyword))
            })
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .margin({ top: 24 })
    }
  }
  
  // 娓叉煋鎷奸煶鎺ㄨ崘 | Render pinyin recommendations
  @Builder
  renderPinyinRecommendations() {
    if (this.pinyinRecommendations.length > 0 && this.searchText) {
      Column() {
        Row() {
          Text('鎷奸煶鎺ㄨ崘')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(600)
            .margin({ left: 40 })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        Scroll(this.scroller) {
          Row() {
            ForEach(this.pinyinRecommendations, (recommendation: string) => {
              Button() {
                Text(recommendation)
                  .fontSize(18)
                  .fontColor('#FFFFFF')
              }
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .backgroundColor('rgba(0, 122, 255, 0.3)')
              .borderRadius(24)
              .margin({ left: 40, right: 16 })
              .onClick(() => this.handlePinyinRecommendationClick(recommendation))
            })
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .margin({ top: 24 })
    }
  }
  
  // 娓叉煋铏氭嫙閿洏 | Render virtual keyboard
  @Builder
  renderVirtualKeyboard() {
    if (this.showVirtualKeyboard) {
      Column() {
        Row() {
          Text('铏氭嫙閿洏')
            .fontSize(18)
            .fontColor('#8E8E93')
            .margin({ left: 40 })
          
          Button() {
            Text('浣跨敤绯荤粺閿洏')
              .fontSize(16)
              .fontColor('#007AFF')
          }
          .backgroundColor('transparent')
          .margin({ right: 40 })
          .onClick(() => this.toggleKeyboardType())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 20 })
        
        Column() {
          // 瀛楁瘝鏁板瓧鎸夐敭 | Letter and number keys
          Row() {
            ForEach(this.keyboardKeys.slice(0, 10), (key: KeyboardKey) => {
              this.renderKeyboardKey(key);
            })
          }
          .width('100%')
          .margin({ bottom: 12 })
          
          Row() {
            ForEach(this.keyboardKeys.slice(10, 20), (key: KeyboardKey) => {
              this.renderKeyboardKey(key);
            })
          }
          .width('100%')
          .margin({ bottom: 12 })
          
          Row() {
            ForEach(this.keyboardKeys.slice(20, 30), (key: KeyboardKey) => {
              this.renderKeyboardKey(key);
            })
          }
          .width('100%')
          .margin({ bottom: 12 })
          
          Row() {
            ForEach(this.keyboardKeys.slice(30), (key: KeyboardKey) => {
              if (key.value === 'search') {
                Button() {
                  Text(key.label || key.value)
                    .fontSize(20)
                    .fontColor('#FFFFFF')
                    .fontWeight(600)
                }
                .width(240)
                .height(72)
                .backgroundColor('#007AFF')
                .borderRadius(12)
                .margin({ left: 40, right: 12 })
                .onClick(() => this.handleKeyboardKeyClick(key))
              } else {
                this.renderKeyboardKey(key);
              }
            })
          }
          .width('100%')
        }
        .padding({ left: 30, right: 30 })
      }
      .width('100%')
      .padding({ top: 24, bottom: 40 })
      .backgroundColor('#1E1E1E')
    }
  }
  
  // 娓叉煋閿洏鎸夐敭 | Render keyboard key
  @Builder
  renderKeyboardKey(key: KeyboardKey) {
    Button() {
      Column() {
        Text(key.label || key.value)
          .fontSize(key.type === 'action' ? 18 : 20)
          .fontColor('#FFFFFF')
        if (key.label) {
          Text(key.value)
            .fontSize(14)
            .fontColor('#8E8E93')
        }
      }
    }
    .width(96)
    .height(72)
    .backgroundColor('#2C2C2C')
    .borderRadius(12)
    .margin({ right: 12 })
    .onClick(() => this.handleKeyboardKeyClick(key))
  }
  
  build() {
    Column() {
      // 椤堕儴鎼滅储鏍?| Top search bar
      this.renderSearchBar();
      
      // 涓诲唴瀹瑰尯鍩?| Main content area
      Column() {
        // 鎷奸煶鎺ㄨ崘 | Pinyin recommendations
        this.renderPinyinRecommendations();
        
        // 鎼滅储鍘嗗彶 | Search history
        this.renderSearchHistory();
        
        // 鐑棬鍏抽敭璇?| Hot keywords
        this.renderHotKeywords();
      }
      .flexGrow(1)
      .width('100%')
      .backgroundColor('#121212')
      
      // 铏氭嫙閿洏 | Virtual keyboard
      this.renderVirtualKeyboard();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }
}
