if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SearchPage_Params {
    TAG?: string;
    scroller?: Scroller;
    contentScroller?: Scroller;
    searchText?: string;
    searchHistory?: string[];
    hotKeywords?: string[];
    quickResults?: SearchResult[];
    pinyinRecommendations?: string[];
    isSearching?: boolean;
    showQuickResults?: boolean;
    showHistory?: boolean;
    showHotKeywords?: boolean;
    showVirtualKeyboard?: boolean;
    showSystemKeyboard?: boolean;
    isLandscape?: boolean;
    screenWidth?: number;
    screenHeight?: number;
    selectedKeyIndex?: number;
    searchDebounceTimer?: number;
    abortController?: AbortController | null;
    themeChangeListener?: () => void;
    eventBus?;
    keyboardKeys?: KeyboardKey[];
}
import { AppNavigator } from "@bundle:com.raytv.app/raytv/ets/navigation/AppNavigator";
import type { SearchType } from '../data/repository/SearchHistoryRepository';
import SearchService from "@bundle:com.raytv.app/raytv/ets/service/search/SearchService";
import type { SearchResultItem, SearchOptions } from "@bundle:com.raytv.app/raytv/ets/service/search/SearchService";
import CacheService from "@bundle:com.raytv.app/raytv/ets/service/cache/CacheService";
import display from "@ohos:display";
import EventBusUtil from "@bundle:com.raytv.app/raytv/ets/common/util/EventBusUtil";
import ThemeProvider from "@bundle:com.raytv.app/raytv/ets/design/ThemeProvider";
import Logger from "@bundle:com.raytv.app/raytv/ets/common/util/Logger";
// AbortController接口定义 - AbortController interface
interface AbortController {
    abort(): void;
    signal: AbortSignal;
}
// AbortSignal接口定义 - AbortSignal interface
interface AbortSignal {
    aborted: boolean;
}
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
class SearchPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.TAG = 'SearchPage';
        this.scroller = new Scroller();
        this.contentScroller = new Scroller();
        this.__searchText = new ObservedPropertySimplePU('', this, "searchText");
        this.__searchHistory = new ObservedPropertyObjectPU([], this, "searchHistory");
        this.__hotKeywords = new ObservedPropertyObjectPU([], this, "hotKeywords");
        this.__quickResults = new ObservedPropertyObjectPU([], this, "quickResults");
        this.__pinyinRecommendations = new ObservedPropertyObjectPU([], this, "pinyinRecommendations");
        this.__isSearching = new ObservedPropertySimplePU(false, this, "isSearching");
        this.__showQuickResults = new ObservedPropertySimplePU(false, this, "showQuickResults");
        this.__showHistory = new ObservedPropertySimplePU(true, this, "showHistory");
        this.__showHotKeywords = new ObservedPropertySimplePU(true, this, "showHotKeywords");
        this.__showVirtualKeyboard = new ObservedPropertySimplePU(true, this, "showVirtualKeyboard");
        this.__showSystemKeyboard = new ObservedPropertySimplePU(false, this, "showSystemKeyboard");
        this.__isLandscape = new ObservedPropertySimplePU(false, this, "isLandscape");
        this.__screenWidth = new ObservedPropertySimplePU(0, this, "screenWidth");
        this.__screenHeight = new ObservedPropertySimplePU(0, this, "screenHeight");
        this.__selectedKeyIndex = new ObservedPropertySimplePU(-1, this, "selectedKeyIndex");
        this.searchDebounceTimer = -1;
        this.abortController = null;
        this.themeChangeListener = () => { };
        this.eventBus = EventBusUtil;
        this.keyboardKeys = [
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
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SearchPage_Params) {
        if (params.TAG !== undefined) {
            this.TAG = params.TAG;
        }
        if (params.scroller !== undefined) {
            this.scroller = params.scroller;
        }
        if (params.contentScroller !== undefined) {
            this.contentScroller = params.contentScroller;
        }
        if (params.searchText !== undefined) {
            this.searchText = params.searchText;
        }
        if (params.searchHistory !== undefined) {
            this.searchHistory = params.searchHistory;
        }
        if (params.hotKeywords !== undefined) {
            this.hotKeywords = params.hotKeywords;
        }
        if (params.quickResults !== undefined) {
            this.quickResults = params.quickResults;
        }
        if (params.pinyinRecommendations !== undefined) {
            this.pinyinRecommendations = params.pinyinRecommendations;
        }
        if (params.isSearching !== undefined) {
            this.isSearching = params.isSearching;
        }
        if (params.showQuickResults !== undefined) {
            this.showQuickResults = params.showQuickResults;
        }
        if (params.showHistory !== undefined) {
            this.showHistory = params.showHistory;
        }
        if (params.showHotKeywords !== undefined) {
            this.showHotKeywords = params.showHotKeywords;
        }
        if (params.showVirtualKeyboard !== undefined) {
            this.showVirtualKeyboard = params.showVirtualKeyboard;
        }
        if (params.showSystemKeyboard !== undefined) {
            this.showSystemKeyboard = params.showSystemKeyboard;
        }
        if (params.isLandscape !== undefined) {
            this.isLandscape = params.isLandscape;
        }
        if (params.screenWidth !== undefined) {
            this.screenWidth = params.screenWidth;
        }
        if (params.screenHeight !== undefined) {
            this.screenHeight = params.screenHeight;
        }
        if (params.selectedKeyIndex !== undefined) {
            this.selectedKeyIndex = params.selectedKeyIndex;
        }
        if (params.searchDebounceTimer !== undefined) {
            this.searchDebounceTimer = params.searchDebounceTimer;
        }
        if (params.abortController !== undefined) {
            this.abortController = params.abortController;
        }
        if (params.themeChangeListener !== undefined) {
            this.themeChangeListener = params.themeChangeListener;
        }
        if (params.eventBus !== undefined) {
            this.eventBus = params.eventBus;
        }
        if (params.keyboardKeys !== undefined) {
            this.keyboardKeys = params.keyboardKeys;
        }
    }
    updateStateVars(params: SearchPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__searchText.purgeDependencyOnElmtId(rmElmtId);
        this.__searchHistory.purgeDependencyOnElmtId(rmElmtId);
        this.__hotKeywords.purgeDependencyOnElmtId(rmElmtId);
        this.__quickResults.purgeDependencyOnElmtId(rmElmtId);
        this.__pinyinRecommendations.purgeDependencyOnElmtId(rmElmtId);
        this.__isSearching.purgeDependencyOnElmtId(rmElmtId);
        this.__showQuickResults.purgeDependencyOnElmtId(rmElmtId);
        this.__showHistory.purgeDependencyOnElmtId(rmElmtId);
        this.__showHotKeywords.purgeDependencyOnElmtId(rmElmtId);
        this.__showVirtualKeyboard.purgeDependencyOnElmtId(rmElmtId);
        this.__showSystemKeyboard.purgeDependencyOnElmtId(rmElmtId);
        this.__isLandscape.purgeDependencyOnElmtId(rmElmtId);
        this.__screenWidth.purgeDependencyOnElmtId(rmElmtId);
        this.__screenHeight.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedKeyIndex.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__searchText.aboutToBeDeleted();
        this.__searchHistory.aboutToBeDeleted();
        this.__hotKeywords.aboutToBeDeleted();
        this.__quickResults.aboutToBeDeleted();
        this.__pinyinRecommendations.aboutToBeDeleted();
        this.__isSearching.aboutToBeDeleted();
        this.__showQuickResults.aboutToBeDeleted();
        this.__showHistory.aboutToBeDeleted();
        this.__showHotKeywords.aboutToBeDeleted();
        this.__showVirtualKeyboard.aboutToBeDeleted();
        this.__showSystemKeyboard.aboutToBeDeleted();
        this.__isLandscape.aboutToBeDeleted();
        this.__screenWidth.aboutToBeDeleted();
        this.__screenHeight.aboutToBeDeleted();
        this.__selectedKeyIndex.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private readonly TAG: string;
    private scroller: Scroller;
    private contentScroller: Scroller;
    // 鐘舵€佺鐞?| State management
    private __searchText: ObservedPropertySimplePU<string>;
    get searchText() {
        return this.__searchText.get();
    }
    set searchText(newValue: string) {
        this.__searchText.set(newValue);
    }
    private __searchHistory: ObservedPropertyObjectPU<string[]>;
    get searchHistory() {
        return this.__searchHistory.get();
    }
    set searchHistory(newValue: string[]) {
        this.__searchHistory.set(newValue);
    }
    private __hotKeywords: ObservedPropertyObjectPU<string[]>;
    get hotKeywords() {
        return this.__hotKeywords.get();
    }
    set hotKeywords(newValue: string[]) {
        this.__hotKeywords.set(newValue);
    }
    private __quickResults: ObservedPropertyObjectPU<SearchResult[]>;
    get quickResults() {
        return this.__quickResults.get();
    }
    set quickResults(newValue: SearchResult[]) {
        this.__quickResults.set(newValue);
    }
    private __pinyinRecommendations: ObservedPropertyObjectPU<string[]>;
    get pinyinRecommendations() {
        return this.__pinyinRecommendations.get();
    }
    set pinyinRecommendations(newValue: string[]) {
        this.__pinyinRecommendations.set(newValue);
    }
    private __isSearching: ObservedPropertySimplePU<boolean>;
    get isSearching() {
        return this.__isSearching.get();
    }
    set isSearching(newValue: boolean) {
        this.__isSearching.set(newValue);
    }
    private __showQuickResults: ObservedPropertySimplePU<boolean>;
    get showQuickResults() {
        return this.__showQuickResults.get();
    }
    set showQuickResults(newValue: boolean) {
        this.__showQuickResults.set(newValue);
    }
    private __showHistory: ObservedPropertySimplePU<boolean>;
    get showHistory() {
        return this.__showHistory.get();
    }
    set showHistory(newValue: boolean) {
        this.__showHistory.set(newValue);
    }
    private __showHotKeywords: ObservedPropertySimplePU<boolean>;
    get showHotKeywords() {
        return this.__showHotKeywords.get();
    }
    set showHotKeywords(newValue: boolean) {
        this.__showHotKeywords.set(newValue);
    }
    private __showVirtualKeyboard: ObservedPropertySimplePU<boolean>;
    get showVirtualKeyboard() {
        return this.__showVirtualKeyboard.get();
    }
    set showVirtualKeyboard(newValue: boolean) {
        this.__showVirtualKeyboard.set(newValue);
    }
    private __showSystemKeyboard: ObservedPropertySimplePU<boolean>;
    get showSystemKeyboard() {
        return this.__showSystemKeyboard.get();
    }
    set showSystemKeyboard(newValue: boolean) {
        this.__showSystemKeyboard.set(newValue);
    }
    private __isLandscape: ObservedPropertySimplePU<boolean>;
    get isLandscape() {
        return this.__isLandscape.get();
    }
    set isLandscape(newValue: boolean) {
        this.__isLandscape.set(newValue);
    }
    private __screenWidth: ObservedPropertySimplePU<number>;
    get screenWidth() {
        return this.__screenWidth.get();
    }
    set screenWidth(newValue: number) {
        this.__screenWidth.set(newValue);
    }
    private __screenHeight: ObservedPropertySimplePU<number>;
    get screenHeight() {
        return this.__screenHeight.get();
    }
    set screenHeight(newValue: number) {
        this.__screenHeight.set(newValue);
    }
    private __selectedKeyIndex: ObservedPropertySimplePU<number>;
    get selectedKeyIndex() {
        return this.__selectedKeyIndex.get();
    }
    set selectedKeyIndex(newValue: number) {
        this.__selectedKeyIndex.set(newValue);
    }
    // 鏈嶅姟瀹炰緥灏嗗湪鏂规硶涓洿鎺ヨ皟鐢?| Service instances will be called directly in methods
    private searchDebounceTimer: number;
    private abortController: AbortController | null;
    private themeChangeListener: () => void;
    private eventBus;
    // 铏氭嫙閿洏鎸夐敭 | Virtual keyboard keys
    private keyboardKeys: KeyboardKey[];
    // 鐢熷懡鍛ㄦ湡 | Lifecycle
    aboutToAppear() {
        console.info('SearchPage about to appear');
        // 添加主题监听器
        ThemeProvider.addThemeChangeListener(this.themeChangeListener);
        // 鍒濆鍖栧睆骞曚俊鎭?| Initialize screen information
        this.initScreenInfo();
        // 鍔犺浇鐑棬鍏抽敭璇嶅拰鎼滅储鍘嗗彶 | Load hot keywords and search history
        this.loadHotKeywords();
        this.loadSearchHistory();
    }
    aboutToDisappear(): void {
        Logger.info(this.TAG, 'SearchPage about to disappear');
        // 移除事件监听器
        this.eventBus.off('search:result');
        this.eventBus.off('search:error');
        // 清除防抖定时器
        if (this.searchDebounceTimer !== 0) {
            clearTimeout(this.searchDebounceTimer);
            this.searchDebounceTimer = 0;
        }
        // 中止当前搜索请求
        if (this.abortController != null) {
            this.abortController.abort();
            this.abortController = null;
        }
        // 移除主题监听器
        ThemeProvider.removeThemeChangeListener(this.themeChangeListener);
    }
    // 鍒濆鍖栧睆骞曚俊鎭?| Initialize screen information
    private initScreenInfo(): void {
        try {
            const displayInfo = display.getDefaultDisplaySync();
            this.screenWidth = displayInfo.width;
            this.screenHeight = displayInfo.height;
            this.isLandscape = this.screenWidth > this.screenHeight;
            console.info('Screen info: width=' + this.screenWidth + ', height=' + this.screenHeight + ', landscape=' + this.isLandscape);
        }
        catch (error) {
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
            // 使用默认热门关键词 | Use default hot keywords
            this.hotKeywords = ['热门电影', '最新剧集', '经典动画', '科幻大片', '爱情喜剧'];
            // 缂撳瓨缁撴灉 | Cache result
            await CacheService.getInstance().set<string[]>(cacheKey, this.hotKeywords);
            console.info('Loaded ' + this.hotKeywords.length + ' hot keywords');
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            console.error('Failed to load hot keywords: ' + err.message);
            this.hotKeywords = ['热门电影', '最新剧集', '经典动漫', '科幻大片', '爱情喜剧'];
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
        }
        catch (error) {
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
        }
        catch (error) {
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
        }
        else {
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
        }
        catch (error) {
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
                type: 'all' as SearchType,
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
            }
            else {
                this.quickResults = [];
            }
            console.info('Quick search for \'' + keyword + '\' returned ' + this.quickResults.length + ' results from service');
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            console.error('Quick search failed: ' + err.message);
            this.quickResults = [];
        }
        finally {
            this.isSearching = false;
        }
    }
    /**
     * 鎵ц鎼滅储 | Execute search
     */
    private async executeSearch(): Promise<void> {
        if (!this.searchText.trim())
            return;
        try {
            this.isSearching = true;
            this.showQuickResults = false;
            // 淇濆瓨鎼滅储鍘嗗彶 | Save search history
            await this.saveSearchHistory(this.searchText);
            // 瀵艰埅鍒版悳绱㈢粨鏋滈〉 | Navigate to search result page
            AppNavigator.getInstance().navigateToSearchResult(this.searchText);
            console.info(`Executing search for: ${this.searchText}`);
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            console.error(`Search failed: ${err.message}`);
        }
        finally {
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
        }
        catch (error) {
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
        }
        catch (error) {
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
        }
        catch (error) {
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
        }
        catch (error) {
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
        }
        catch (error) {
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
                }
                else if (key.value === 'clear') {
                    this.onSearchTextChange('');
                }
                else if (key.value === 'space') {
                    this.onSearchTextChange(this.searchText + ' ');
                }
                else if (key.value === 'search') {
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
        }
        catch (error) {
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
    renderSearchBar(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(517:5)", "raytv");
            Column.width('100%');
            Column.padding({ top: 24 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(518:7)", "raytv");
            Row.width('100%');
            Row.height(80);
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 杩斿洖鎸夐挳 | Back button
            Button.createWithChild();
            Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(520:9)", "raytv");
            // 杩斿洖鎸夐挳 | Back button
            Button.width(100);
            // 杩斿洖鎸夐挳 | Back button
            Button.height(60);
            // 杩斿洖鎸夐挳 | Back button
            Button.backgroundColor('#007AFF');
            // 杩斿洖鎸夐挳 | Back button
            Button.borderRadius(12);
            // 杩斿洖鎸夐挳 | Back button
            Button.margin({ left: 40 });
            // 杩斿洖鎸夐挳 | Back button
            Button.onClick(() => this.handleBack());
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('杩斿洖');
            Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(521:11)", "raytv");
            Text.fontSize(18);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        // 杩斿洖鎸夐挳 | Back button
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 鎼滅储杈撳叆鍖哄煙 | Search input area
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(533:9)", "raytv");
            // 鎼滅储杈撳叆鍖哄煙 | Search input area
            Column.flexGrow(1);
            // 鎼滅储杈撳叆鍖哄煙 | Search input area
            Column.margin({ left: 24, right: 24 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(534:11)", "raytv");
            Row.width('100%');
            Row.height(70);
            Row.backgroundColor('#2C2C2C');
            Row.borderRadius(12);
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('鎼滅储: ' + this.searchText);
            Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(535:13)", "raytv");
            Text.fontSize(20);
            Text.fontColor('#FFFFFF');
            Text.flexGrow(1);
            Text.margin({ left: 24 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(541:13)", "raytv");
            Button.width(120);
            Button.height(48);
            Button.backgroundColor('#34C759');
            Button.borderRadius(8);
            Button.margin({ right: 16 });
            Button.onClick(() => this.toggleKeyboardType());
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('鍒囨崲閿洏');
            Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(542:15)", "raytv");
            Text.fontSize(16);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        Button.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 蹇€熸悳绱㈢粨鏋?| Quick search results
            if (this.showQuickResults && this.quickResults.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Scroll.create(this.contentScroller);
                        Scroll.debugLine("raytv/src/main/ets/pages/SearchPage.ets(561:13)", "raytv");
                        Scroll.scrollBar(BarState.Auto);
                        Scroll.height(this.isLandscape ? 350 : 300);
                        Scroll.backgroundColor('#1E1E1E');
                        Scroll.borderRadius(12);
                        Scroll.margin({ top: 12 });
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(562:15)", "raytv");
                        Column.padding(20);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const result = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(564:19)", "raytv");
                                Row.width('100%');
                                Row.padding(20);
                                Row.backgroundColor('#1E1E1E');
                                Row.borderRadius(12);
                                Row.margin({ top: 12 });
                                Row.onClick(() => this.handleQuickResultClick(result));
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Image.create(result.coverUrl || '');
                                Image.debugLine("raytv/src/main/ets/pages/SearchPage.ets(565:21)", "raytv");
                                Image.width(100);
                                Image.height(150);
                                Image.objectFit(ImageFit.Cover);
                                Image.borderRadius(8);
                                Image.margin({ right: 20 });
                                Image.backgroundColor('#2C2C2C');
                            }, Image);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Column.create();
                                Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(573:21)", "raytv");
                                Column.flexGrow(1);
                            }, Column);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(result.title);
                                Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(574:23)", "raytv");
                                Text.fontSize(18);
                                Text.fontColor('#FFFFFF');
                                Text.fontWeight(600);
                                Text.maxLines(2);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(result.type);
                                Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(579:23)", "raytv");
                                Text.fontSize(16);
                                Text.fontColor('#8E8E93');
                                Text.margin({ top: 8 });
                            }, Text);
                            Text.pop();
                            Column.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('>');
                                Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(586:21)", "raytv");
                                Text.fontSize(24);
                                Text.fontColor('#8E8E93');
                            }, Text);
                            Text.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.quickResults, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Column.pop();
                    Scroll.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 鎼滅储杈撳叆鍖哄煙 | Search input area
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 鎼滅储鎸夐挳 | Search button
            Button.createWithChild();
            Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(611:9)", "raytv");
            // 鎼滅储鎸夐挳 | Search button
            Button.width(120);
            // 鎼滅储鎸夐挳 | Search button
            Button.height(60);
            // 鎼滅储鎸夐挳 | Search button
            Button.backgroundColor('#007AFF');
            // 鎼滅储鎸夐挳 | Search button
            Button.borderRadius(12);
            // 鎼滅储鎸夐挳 | Search button
            Button.margin({ right: 40 });
            // 鎼滅储鎸夐挳 | Search button
            Button.onClick(() => this.executeSearch());
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('鎼滅储');
            Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(612:11)", "raytv");
            Text.fontSize(20);
            Text.fontColor('#FFFFFF');
            Text.fontWeight(600);
        }, Text);
        Text.pop();
        // 鎼滅储鎸夐挳 | Search button
        Button.pop();
        Row.pop();
        Column.pop();
    }
    // 娓叉煋鎼滅储鍘嗗彶 | Render search history
    renderSearchHistory(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.searchHistory.length > 0 && this.showHistory && !this.searchText) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(636:7)", "raytv");
                        Column.width('100%');
                        Column.margin({ top: 24 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(637:9)", "raytv");
                        Row.width('100%');
                        Row.justifyContent(FlexAlign.SpaceBetween);
                        Row.alignItems(VerticalAlign.Center);
                        Row.margin({ bottom: 20 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('鎼滅储鍘嗗彶');
                        Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(638:11)", "raytv");
                        Text.fontSize(22);
                        Text.fontColor('#FFFFFF');
                        Text.fontWeight(600);
                        Text.margin({ left: 40 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithChild();
                        Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(644:11)", "raytv");
                        Button.backgroundColor('transparent');
                        Button.margin({ right: 40 });
                        Button.onClick(() => this.clearSearchHistory());
                    }, Button);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('娓呯┖');
                        Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(645:13)", "raytv");
                        Text.fontSize(18);
                        Text.fontColor('#8E8E93');
                    }, Text);
                    Text.pop();
                    Button.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Scroll.create(this.scroller);
                        Scroll.debugLine("raytv/src/main/ets/pages/SearchPage.ets(659:9)", "raytv");
                        Scroll.scrollBar(BarState.Auto);
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(660:11)", "raytv");
                        Row.width('100%');
                        Row.padding({ bottom: 24 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const keyword = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Button.createWithChild();
                                Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(662:15)", "raytv");
                                Button.padding({ left: 24, right: 24, top: 12, bottom: 12 });
                                Button.backgroundColor('#2C2C2C');
                                Button.borderRadius(24);
                                Button.margin({ left: 40, right: 16 });
                                Button.onClick(() => this.handleHistoryClick(keyword));
                            }, Button);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(keyword);
                                Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(663:17)", "raytv");
                                Text.fontSize(18);
                                Text.fontColor('#FFFFFF');
                            }, Text);
                            Text.pop();
                            Button.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.searchHistory, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
                    Scroll.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
    }
    // 娓叉煋鐑棬鍏抽敭璇?| Render hot keywords
    renderHotKeywords(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.hotKeywords.length > 0 && this.showHotKeywords && !this.searchText) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(688:7)", "raytv");
                        Column.width('100%');
                        Column.margin({ top: 24 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(689:9)", "raytv");
                        Row.width('100%');
                        Row.margin({ bottom: 20 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('鐑棬鎼滅储');
                        Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(690:11)", "raytv");
                        Text.fontSize(22);
                        Text.fontColor('#FFFFFF');
                        Text.fontWeight(600);
                        Text.margin({ left: 40 });
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Scroll.create(this.scroller);
                        Scroll.debugLine("raytv/src/main/ets/pages/SearchPage.ets(699:9)", "raytv");
                        Scroll.scrollBar(BarState.Auto);
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(700:11)", "raytv");
                        Row.width('100%');
                        Row.padding({ bottom: 24 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const keyword = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Button.createWithChild();
                                Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(702:15)", "raytv");
                                Button.padding({ left: 30, right: 30, top: 14, bottom: 14 });
                                Button.backgroundColor('#FF9500');
                                Button.borderRadius(28);
                                Button.margin({ left: 40, right: 16 });
                                Button.onClick(() => this.handleHotKeywordClick(keyword));
                            }, Button);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(keyword);
                                Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(703:17)", "raytv");
                                Text.fontSize(18);
                                Text.fontColor('#FFFFFF');
                            }, Text);
                            Text.pop();
                            Button.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.hotKeywords, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
                    Scroll.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
    }
    // 娓叉煋鎷奸煶鎺ㄨ崘 | Render pinyin recommendations
    renderPinyinRecommendations(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.pinyinRecommendations.length > 0 && this.searchText) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(728:7)", "raytv");
                        Column.width('100%');
                        Column.margin({ top: 24 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(729:9)", "raytv");
                        Row.width('100%');
                        Row.margin({ bottom: 20 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('鎷奸煶鎺ㄨ崘');
                        Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(730:11)", "raytv");
                        Text.fontSize(20);
                        Text.fontColor('#FFFFFF');
                        Text.fontWeight(600);
                        Text.margin({ left: 40 });
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Scroll.create(this.scroller);
                        Scroll.debugLine("raytv/src/main/ets/pages/SearchPage.ets(739:9)", "raytv");
                        Scroll.scrollBar(BarState.Auto);
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(740:11)", "raytv");
                        Row.width('100%');
                        Row.padding({ bottom: 24 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const recommendation = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Button.createWithChild();
                                Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(742:15)", "raytv");
                                Button.padding({ left: 24, right: 24, top: 12, bottom: 12 });
                                Button.backgroundColor('rgba(0, 122, 255, 0.3)');
                                Button.borderRadius(24);
                                Button.margin({ left: 40, right: 16 });
                                Button.onClick(() => this.handlePinyinRecommendationClick(recommendation));
                            }, Button);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(recommendation);
                                Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(743:17)", "raytv");
                                Text.fontSize(18);
                                Text.fontColor('#FFFFFF');
                            }, Text);
                            Text.pop();
                            Button.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.pinyinRecommendations, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
                    Scroll.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
    }
    // 娓叉煋铏氭嫙閿洏 | Render virtual keyboard
    renderVirtualKeyboard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showVirtualKeyboard) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(768:7)", "raytv");
                        Column.width('100%');
                        Column.padding({ top: 24, bottom: 40 });
                        Column.backgroundColor('#1E1E1E');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(769:9)", "raytv");
                        Row.width('100%');
                        Row.justifyContent(FlexAlign.SpaceBetween);
                        Row.margin({ bottom: 20 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('铏氭嫙閿洏');
                        Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(770:11)", "raytv");
                        Text.fontSize(18);
                        Text.fontColor('#8E8E93');
                        Text.margin({ left: 40 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithChild();
                        Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(775:11)", "raytv");
                        Button.backgroundColor('transparent');
                        Button.margin({ right: 40 });
                        Button.onClick(() => this.toggleKeyboardType());
                    }, Button);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('浣跨敤绯荤粺閿洏');
                        Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(776:13)", "raytv");
                        Text.fontSize(16);
                        Text.fontColor('#007AFF');
                    }, Text);
                    Text.pop();
                    Button.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(788:9)", "raytv");
                        Column.padding({ left: 30, right: 30 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 瀛楁瘝鏁板瓧鎸夐敭 | Letter and number keys
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(790:11)", "raytv");
                        // 瀛楁瘝鏁板瓧鎸夐敭 | Letter and number keys
                        Row.width('100%');
                        // 瀛楁瘝鏁板瓧鎸夐敭 | Letter and number keys
                        Row.margin({ bottom: 12 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const key = _item;
                            this.renderKeyboardKey.bind(this)(key);
                        };
                        this.forEachUpdateFunction(elmtId, this.keyboardKeys.slice(0, 10), forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    // 瀛楁瘝鏁板瓧鎸夐敭 | Letter and number keys
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(798:11)", "raytv");
                        Row.width('100%');
                        Row.margin({ bottom: 12 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const key = _item;
                            this.renderKeyboardKey.bind(this)(key);
                        };
                        this.forEachUpdateFunction(elmtId, this.keyboardKeys.slice(10, 20), forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(806:11)", "raytv");
                        Row.width('100%');
                        Row.margin({ bottom: 12 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const key = _item;
                            this.renderKeyboardKey.bind(this)(key);
                        };
                        this.forEachUpdateFunction(elmtId, this.keyboardKeys.slice(20, 30), forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/SearchPage.ets(814:11)", "raytv");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const key = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                If.create();
                                if (key.value === 'search') {
                                    this.ifElseBranchUpdateFunction(0, () => {
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Button.createWithChild();
                                            Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(817:17)", "raytv");
                                            Button.width(240);
                                            Button.height(72);
                                            Button.backgroundColor('#007AFF');
                                            Button.borderRadius(12);
                                            Button.margin({ left: 40, right: 12 });
                                            Button.onClick(() => this.handleKeyboardKeyClick(key));
                                        }, Button);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(key.label || key.value);
                                            Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(818:19)", "raytv");
                                            Text.fontSize(20);
                                            Text.fontColor('#FFFFFF');
                                            Text.fontWeight(600);
                                        }, Text);
                                        Text.pop();
                                        Button.pop();
                                    });
                                }
                                else {
                                    this.ifElseBranchUpdateFunction(1, () => {
                                        this.renderKeyboardKey.bind(this)(key);
                                    });
                                }
                            }, If);
                            If.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.keyboardKeys.slice(30), forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
                    Column.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
    }
    // 娓叉煋閿洏鎸夐敭 | Render keyboard key
    renderKeyboardKey(key: KeyboardKey, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.debugLine("raytv/src/main/ets/pages/SearchPage.ets(847:5)", "raytv");
            Button.width(96);
            Button.height(72);
            Button.backgroundColor('#2C2C2C');
            Button.borderRadius(12);
            Button.margin({ right: 12 });
            Button.onClick(() => this.handleKeyboardKeyClick(key));
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(848:7)", "raytv");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(key.label || key.value);
            Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(849:9)", "raytv");
            Text.fontSize(key.type === 'action' ? 18 : 20);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (key.label) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(key.value);
                        Text.debugLine("raytv/src/main/ets/pages/SearchPage.ets(853:11)", "raytv");
                        Text.fontSize(14);
                        Text.fontColor('#8E8E93');
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Column.pop();
        Button.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(868:5)", "raytv");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#121212');
        }, Column);
        // 椤堕儴鎼滅储鏍?| Top search bar
        this.renderSearchBar.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 涓诲唴瀹瑰尯鍩?| Main content area
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/SearchPage.ets(873:7)", "raytv");
            // 涓诲唴瀹瑰尯鍩?| Main content area
            Column.flexGrow(1);
            // 涓诲唴瀹瑰尯鍩?| Main content area
            Column.width('100%');
            // 涓诲唴瀹瑰尯鍩?| Main content area
            Column.backgroundColor('#121212');
        }, Column);
        // 鎷奸煶鎺ㄨ崘 | Pinyin recommendations
        this.renderPinyinRecommendations.bind(this)();
        // 鎼滅储鍘嗗彶 | Search history
        this.renderSearchHistory.bind(this)();
        // 鐑棬鍏抽敭璇?| Hot keywords
        this.renderHotKeywords.bind(this)();
        // 涓诲唴瀹瑰尯鍩?| Main content area
        Column.pop();
        // 铏氭嫙閿洏 | Virtual keyboard
        this.renderVirtualKeyboard.bind(this)();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SearchPage";
    }
}
registerNamedRoute(() => new SearchPage(undefined, {}), "", { bundleName: "com.raytv.app", moduleName: "raytv", pagePath: "pages/SearchPage", pageFullPath: "raytv/src/main/ets/pages/SearchPage", integratedHsp: "false", moduleType: "followWithHap" });
