if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MainPage_Params {
    TAG?: string;
    scroller?: Scroller;
    contentScroller?: Scroller;
    dateUpdateTimer?: number;
    featuredMedia?: FeaturedMediaItem[];
    popularMedia?: FeaturedMediaItem[];
    newMedia?: FeaturedMediaItem[];
    isLoading?: boolean;
    isError?: boolean;
    errorMessage?: string;
    selectedTab?: string;
    selectedCategory?: string;
    isLandscape?: boolean;
    screenWidth?: number;
    screenHeight?: number;
    currentDate?: string;
    lastMinute?: number | null;
    mainMenuItems?: TabItem[];
    contentService?: ContentAccessService;
}
import { AppNavigator } from "@bundle:com.raytv.app/raytv/ets/navigation/AppNavigator";
import type { DetailParams } from "@bundle:com.raytv.app/raytv/ets/navigation/AppNavigator";
import Logger from "@bundle:com.raytv.app/raytv/ets/common/util/Logger";
import ContentAccessServiceInstance from "@bundle:com.raytv.app/raytv/ets/service/content/ContentAccessService";
import type { ContentAccessService } from "@bundle:com.raytv.app/raytv/ets/service/content/ContentAccessService";
import display from "@ohos:display";
import ContentSourceBadge from "@bundle:com.raytv.app/raytv/ets/components/ContentSourceBadge";
import { ImageLazyLoader } from "@bundle:com.raytv.app/raytv/ets/components/ImageLazyLoader";
import { LazyLoadStrategy } from "@bundle:com.raytv.app/raytv/ets/types/LazyLoadTypes";
import Strings from "@bundle:com.raytv.app/raytv/ets/common/resources/Strings";
/**
 * 应用主页面 | Application main page
 * 作为应用的入口页面，显示主要功能区域 | As the application's entry page, display main functional areas
 */
interface TabItem {
    key: string;
    name: string;
    icon?: string;
}
interface FeaturedMediaItem {
    id: string;
    title: string;
    cover: string;
    type: string;
    siteKey?: string;
    rating?: string;
    sourceId?: string;
    sourceName?: string;
}
interface CategoryTab {
    id: string;
    name: string;
}
class MainPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.TAG = 'MainPage';
        this.scroller = new Scroller();
        this.contentScroller = new Scroller();
        this.dateUpdateTimer = -1;
        this.__featuredMedia = new ObservedPropertyObjectPU([], this, "featuredMedia");
        this.__popularMedia = new ObservedPropertyObjectPU([], this, "popularMedia");
        this.__newMedia = new ObservedPropertyObjectPU([], this, "newMedia");
        this.__isLoading = new ObservedPropertySimplePU(true, this, "isLoading");
        this.__isError = new ObservedPropertySimplePU(false, this, "isError");
        this.__errorMessage = new ObservedPropertySimplePU(Strings.mainPage.loadFailed, this, "errorMessage");
        this.__selectedTab = new ObservedPropertySimplePU('vod', this, "selectedTab");
        this.__selectedCategory = new ObservedPropertySimplePU(Strings.mainPage.categories.all, this, "selectedCategory");
        this.__isLandscape = new ObservedPropertySimplePU(false, this, "isLandscape");
        this.__screenWidth = new ObservedPropertySimplePU(0, this, "screenWidth");
        this.__screenHeight = new ObservedPropertySimplePU(0, this, "screenHeight");
        this.__currentDate = new ObservedPropertySimplePU('', this, "currentDate");
        this.lastMinute = null;
        this.mainMenuItems = [
            { key: 'vod', name: Strings.mainPage.tabs.vod },
            { key: 'live', name: Strings.mainPage.tabs.live },
            { key: 'search', name: Strings.mainPage.tabs.search },
            { key: 'history', name: Strings.mainPage.tabs.history },
            { key: 'settings', name: Strings.mainPage.tabs.settings }
        ];
        this.contentService = ContentAccessServiceInstance;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MainPage_Params) {
        if (params.TAG !== undefined) {
            this.TAG = params.TAG;
        }
        if (params.scroller !== undefined) {
            this.scroller = params.scroller;
        }
        if (params.contentScroller !== undefined) {
            this.contentScroller = params.contentScroller;
        }
        if (params.dateUpdateTimer !== undefined) {
            this.dateUpdateTimer = params.dateUpdateTimer;
        }
        if (params.featuredMedia !== undefined) {
            this.featuredMedia = params.featuredMedia;
        }
        if (params.popularMedia !== undefined) {
            this.popularMedia = params.popularMedia;
        }
        if (params.newMedia !== undefined) {
            this.newMedia = params.newMedia;
        }
        if (params.isLoading !== undefined) {
            this.isLoading = params.isLoading;
        }
        if (params.isError !== undefined) {
            this.isError = params.isError;
        }
        if (params.errorMessage !== undefined) {
            this.errorMessage = params.errorMessage;
        }
        if (params.selectedTab !== undefined) {
            this.selectedTab = params.selectedTab;
        }
        if (params.selectedCategory !== undefined) {
            this.selectedCategory = params.selectedCategory;
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
        if (params.currentDate !== undefined) {
            this.currentDate = params.currentDate;
        }
        if (params.lastMinute !== undefined) {
            this.lastMinute = params.lastMinute;
        }
        if (params.mainMenuItems !== undefined) {
            this.mainMenuItems = params.mainMenuItems;
        }
        if (params.contentService !== undefined) {
            this.contentService = params.contentService;
        }
    }
    updateStateVars(params: MainPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__featuredMedia.purgeDependencyOnElmtId(rmElmtId);
        this.__popularMedia.purgeDependencyOnElmtId(rmElmtId);
        this.__newMedia.purgeDependencyOnElmtId(rmElmtId);
        this.__isLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__isError.purgeDependencyOnElmtId(rmElmtId);
        this.__errorMessage.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedTab.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedCategory.purgeDependencyOnElmtId(rmElmtId);
        this.__isLandscape.purgeDependencyOnElmtId(rmElmtId);
        this.__screenWidth.purgeDependencyOnElmtId(rmElmtId);
        this.__screenHeight.purgeDependencyOnElmtId(rmElmtId);
        this.__currentDate.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__featuredMedia.aboutToBeDeleted();
        this.__popularMedia.aboutToBeDeleted();
        this.__newMedia.aboutToBeDeleted();
        this.__isLoading.aboutToBeDeleted();
        this.__isError.aboutToBeDeleted();
        this.__errorMessage.aboutToBeDeleted();
        this.__selectedTab.aboutToBeDeleted();
        this.__selectedCategory.aboutToBeDeleted();
        this.__isLandscape.aboutToBeDeleted();
        this.__screenWidth.aboutToBeDeleted();
        this.__screenHeight.aboutToBeDeleted();
        this.__currentDate.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private readonly TAG: string;
    private scroller: Scroller;
    private contentScroller: Scroller;
    // 定时器ID，用于在组件销毁时清理 | Timer ID for cleanup on component destroy
    private dateUpdateTimer: number;
    // 状态管理 | State management
    private __featuredMedia: ObservedPropertyObjectPU<FeaturedMediaItem[]>;
    get featuredMedia() {
        return this.__featuredMedia.get();
    }
    set featuredMedia(newValue: FeaturedMediaItem[]) {
        this.__featuredMedia.set(newValue);
    }
    private __popularMedia: ObservedPropertyObjectPU<FeaturedMediaItem[]>;
    get popularMedia() {
        return this.__popularMedia.get();
    }
    set popularMedia(newValue: FeaturedMediaItem[]) {
        this.__popularMedia.set(newValue);
    }
    private __newMedia: ObservedPropertyObjectPU<FeaturedMediaItem[]>;
    get newMedia() {
        return this.__newMedia.get();
    }
    set newMedia(newValue: FeaturedMediaItem[]) {
        this.__newMedia.set(newValue);
    }
    private __isLoading: ObservedPropertySimplePU<boolean>;
    get isLoading() {
        return this.__isLoading.get();
    }
    set isLoading(newValue: boolean) {
        this.__isLoading.set(newValue);
    }
    private __isError: ObservedPropertySimplePU<boolean>;
    get isError() {
        return this.__isError.get();
    }
    set isError(newValue: boolean) {
        this.__isError.set(newValue);
    }
    private __errorMessage: ObservedPropertySimplePU<string>;
    get errorMessage() {
        return this.__errorMessage.get();
    }
    set errorMessage(newValue: string) {
        this.__errorMessage.set(newValue);
    }
    private __selectedTab: ObservedPropertySimplePU<string>;
    get selectedTab() {
        return this.__selectedTab.get();
    }
    set selectedTab(newValue: string) {
        this.__selectedTab.set(newValue);
    }
    private __selectedCategory: ObservedPropertySimplePU<string>;
    get selectedCategory() {
        return this.__selectedCategory.get();
    }
    set selectedCategory(newValue: string) {
        this.__selectedCategory.set(newValue);
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
    private __currentDate: ObservedPropertySimplePU<string>;
    get currentDate() {
        return this.__currentDate.get();
    }
    set currentDate(newValue: string) {
        this.__currentDate.set(newValue);
    }
    // 日期更新优化 | Date update optimization
    private lastMinute: number | null;
    // 导航标签数据 | Navigation tab data
    private mainMenuItems: TabItem[];
    // 服务实例 | Service instances
    private contentService: ContentAccessService;
    // 生命周期 | Lifecycle
    aboutToAppear() {
        Logger.info(this.TAG, 'MainPage about to appear');
        // 初始化屏幕信息 | Initialize screen information
        this.initScreenInfo();
        // 初始化日期 | Initialize date
        this.updateCurrentDate();
        // 使用requestAnimationFrame实现更高效的日期更新
        // 只在分钟变化时更新，减少不必要的渲染
        this.updateDateEfficiently();
        // 加载推荐内容 | Load recommended content
        this.loadFeaturedMedia();
    }
    // 组件销毁时清理 | Clean up on component destroy
    aboutToDisappear() {
        if (this.dateUpdateTimer !== -1) {
            // 使用 setInterval 清理机制
            clearInterval(this.dateUpdateTimer);
            this.dateUpdateTimer = -1;
        }
    }
    // 高效的日期更新方法 | Efficient date update method
    private updateDateEfficiently(): void {
        // 使用 setInterval 每秒检查一次分钟变化
        this.dateUpdateTimer = setInterval(() => {
            const now = new Date();
            const currentMinute = now.getMinutes();
            // 只在分钟变化时更新，减少渲染次数
            if (!this.lastMinute || this.lastMinute !== currentMinute) {
                this.updateCurrentDate();
                this.lastMinute = currentMinute;
            }
        }, 1000) as number;
    }
    // 更新当前日期 | Update current date
    private updateCurrentDate(): void {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        this.currentDate = year + '年' + month + '月' + day + '日 ' + hours + ':' + minutes;
    }
    // 初始化屏幕信息 | Initialize screen information
    private initScreenInfo(): void {
        try {
            const displayInfo = display.getDefaultDisplaySync();
            this.screenWidth = displayInfo.width;
            this.screenHeight = displayInfo.height;
            this.isLandscape = this.screenWidth > this.screenHeight;
            Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            Logger.error(this.TAG, `Failed to get screen info: ${err.message}`);
            // 默认值 | Default values
            this.screenWidth = 1920;
            this.screenHeight = 1080;
            this.isLandscape = true;
        }
    }
    // 加载推荐内容 | Load featured media
    private async loadFeaturedMedia(): Promise<void> {
        try {
            this.isLoading = true;
            this.isError = false;
            // 确保ContentAccessService已初始化 | Ensure ContentAccessService is initialized
            if (!this.contentService.isInitialized()) {
                await this.contentService.initialize();
            }
            // 从ContentAccessService获取真实的点播站点数据 | Get real VOD site data from ContentAccessService
            const allVodSites = this.contentService.getAllVodSites();
            if (allVodSites.length > 0) {
                // 将VodSiteWithSource转换为FeaturedMediaItem
                const toMediaItem = (site: import('../service/pool/SourcePoolManager').VodSiteWithSource, idx: number): FeaturedMediaItem => ({
                    id: `${site.siteKey}_${idx}`,
                    title: site.name,
                    cover: '',
                    type: 'vod',
                    siteKey: site.siteKey,
                    sourceId: site.sourceId,
                    sourceName: site.sourceName
                });
                // 推荐内容：取前5个站点 | Featured: first 5 sites
                this.featuredMedia = allVodSites.slice(0, 5).map(toMediaItem);
                // 热门内容：取5-10个站点 | Popular: sites 5-10
                this.popularMedia = allVodSites.slice(5, 10).map(toMediaItem);
                // 最新内容：取最后一批站点（最多5个）| New: last batch of sites (up to 5)
                const newStart = Math.max(10, allVodSites.length - 5);
                this.newMedia = allVodSites.slice(newStart).map(toMediaItem);
                Logger.info(this.TAG, `Loaded ${allVodSites.length} VOD sites from ContentAccessService`);
            }
            else {
                // 无数据时提示用户配置源 | No data: prompt user to configure sources
                this.featuredMedia = [];
                this.popularMedia = [];
                this.newMedia = [];
                Logger.warn(this.TAG, 'No VOD sites available. Please configure network sources in Settings.');
            }
            this.isLoading = false;
        }
        catch (error) {
            const errorMsg = error instanceof Error ? error.message : String(error);
            Logger.error(this.TAG, `Failed to load featured media: ${errorMsg}`);
            this.isError = true;
            this.errorMessage = `推荐内容加载失败: ${errorMsg}`;
            this.isLoading = false;
        }
    }
    // 处理主菜单点击 | Handle main menu click
    private handleMainMenuClick(key: string): void {
        try {
            Logger.info(this.TAG, `Main menu clicked: ${key}`);
            // 验证菜单键值 | Validate menu key
            if (!key) {
                Logger.error(this.TAG, 'Invalid menu key');
                return;
            }
            switch (key) {
                case 'vod':
                    // 只在切换到 vod tab 时才加载（已在 vod tab 则不重复加载）| Only load when switching to vod tab
                    if (this.selectedTab !== 'vod') {
                        this.selectedTab = 'vod';
                        this.loadFeaturedMedia();
                    }
                    break;
                case 'live':
                    AppNavigator.getInstance().navigateToLive();
                    break;
                case 'search':
                    AppNavigator.getInstance().navigateToSearch('');
                    break;
                case 'history':
                    AppNavigator.getInstance().navigateToHistory();
                    break;
                case 'settings':
                    AppNavigator.getInstance().navigateToSettings();
                    break;
                default:
                    Logger.warn(this.TAG, `Unknown menu key: ${key}`);
                    break;
            }
        }
        catch (error) {
            Logger.error(this.TAG, `Failed to handle main menu click: ${error}`);
        }
    }
    // 处理分类标签点击 | Handle category tab click
    private handleCategoryClick(categoryId: string): void {
        try {
            Logger.info(this.TAG, `Category clicked: ${categoryId}`);
            // 验证分类ID | Validate category ID
            if (!categoryId) {
                Logger.error(this.TAG, 'Invalid category ID');
                return;
            }
            // 只在分类真正变化时才重新加载，避免重复请求 | Only reload when category actually changes
            if (this.selectedCategory === categoryId) {
                return;
            }
            this.selectedCategory = categoryId;
            // 根据分类筛选已加载的内容，无需重新请求全部数据 | Filter loaded content by category, no need to re-fetch all
            // 如果是"全部"分类则直接刷新 | If "全部" category, do a full refresh
            if (categoryId === '全部') {
                this.loadFeaturedMedia();
            }
            // 其他分类在 build 中通过 selectedCategory 状态自动过滤展示
        }
        catch (error) {
            Logger.error(this.TAG, `Failed to handle category click: ${error}`);
        }
    }
    // 处理影视点击 | Handle media click
    private handleMediaClick(media: FeaturedMediaItem): void {
        try {
            Logger.info(this.TAG, `Media clicked: ${media.title}, Source: ${media.sourceName}`);
            // 验证媒体数据完整性 | Validate media data integrity
            if (!media.id || !media.siteKey) {
                Logger.error(this.TAG, 'Invalid media data: missing required fields');
                return;
            }
            const params: DetailParams = {
                id: media.id,
                siteKey: media.siteKey || '',
                type: 'vod'
            };
            AppNavigator.getInstance().navigateToDetail(params);
        }
        catch (error) {
            Logger.error(this.TAG, `Failed to handle media click: ${error}`);
        }
    }
    // 渲染媒体项 | Render media item
    private renderMediaItem(media: FeaturedMediaItem, parent = null): void {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(296:5)", "raytv");
            Column.padding(12);
            Column.backgroundColor('#2C2C2C');
            Column.borderRadius(16);
            Column.shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.4)', offsetY: 6 });
            Column.onClick(() => this.handleMediaClick(media));
            Column.width(this.isLandscape ? 260 : 200);
            Column.height(this.isLandscape ? 440 : 370);
            Column.focusable(true);
            Gesture.create(GesturePriority.Low);
            TapGesture.create();
            TapGesture.onAction(() => {
                console.info('Media item tapped: ' + media.title);
            });
            TapGesture.pop();
            Gesture.pop();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.debugLine("raytv/src/main/ets/pages/MainPage.ets(297:7)", "raytv");
            Stack.margin({ bottom: 12 });
        }, Stack);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new ImageLazyLoader(this, {
                        src: media.cover || '',
                        imgWidth: '100%',
                        imgHeight: this.isLandscape ? 320 : 240,
                        imgRadius: 12,
                        placeholder: '',
                        lazyStrategy: LazyLoadStrategy.VISIBLE
                    }, undefined, elmtId, () => { }, { page: "raytv/src/main/ets/pages/MainPage.ets", line: 298, col: 9 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            src: media.cover || '',
                            imgWidth: '100%',
                            imgHeight: this.isLandscape ? 320 : 240,
                            imgRadius: 12,
                            placeholder: '',
                            lazyStrategy: LazyLoadStrategy.VISIBLE
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        src: media.cover || '',
                        imgWidth: '100%',
                        imgHeight: this.isLandscape ? 320 : 240,
                        imgRadius: 12,
                        placeholder: '',
                        lazyStrategy: LazyLoadStrategy.VISIBLE
                    });
                }
            }, { name: "ImageLazyLoader" });
        }
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 来源标识 | Source badge
            if (media.sourceName) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        __Common__.create();
                        __Common__.position({ top: 8, right: 8 });
                    }, __Common__);
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new ContentSourceBadge(this, {
                                    sourceName: media.sourceName
                                }, undefined, elmtId, () => { }, { page: "raytv/src/main/ets/pages/MainPage.ets", line: 309, col: 11 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        sourceName: media.sourceName
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {});
                            }
                        }, { name: "ContentSourceBadge" });
                    }
                    __Common__.pop();
                });
            }
            // 评分标识 | Rating badge
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 评分标识 | Rating badge
            if (media.rating) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/MainPage.ets(317:11)", "raytv");
                        Row.backgroundColor('#FF6B35');
                        Row.padding({ left: 8, right: 8, top: 4, bottom: 4 });
                        Row.borderRadius(8);
                        Row.position({ bottom: 8, right: 8 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(media.rating);
                        Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(318:13)", "raytv");
                        Text.fontSize(14);
                        Text.fontWeight(600);
                        Text.fontColor('#FFFFFF');
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(media.title);
            Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(331:7)", "raytv");
            Text.fontSize(16);
            Text.fontWeight(600);
            Text.maxLines(2);
            Text.margin({ left: 8, right: 8 });
            Text.textAlign(TextAlign.Center);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        Column.pop();
    }
    // 渲染内容区域 | Render content section
    private renderContentSection(title: string, mediaList: FeaturedMediaItem[], parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(359:5)", "raytv");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 内容标题 | Content title
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/MainPage.ets(361:7)", "raytv");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(title);
            Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(362:9)", "raytv");
            Text.fontSize(20);
            Text.fontWeight(700);
            Text.fontColor('#FFFFFF');
            Text.margin({ left: 30, top: 24, bottom: 16 });
        }, Text);
        Text.pop();
        // 内容标题 | Content title
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 内容区域 | Content area - 使用List实现虚拟列表
            List.create({
                scroller: this.contentScroller,
                initialIndex: 0,
                space: 20
            });
            List.debugLine("raytv/src/main/ets/pages/MainPage.ets(370:7)", "raytv");
            // 内容区域 | Content area - 使用List实现虚拟列表
            List.listDirection(Axis.Horizontal);
            // 内容区域 | Content area - 使用List实现虚拟列表
            List.scrollBar(BarState.Auto);
            // 内容区域 | Content area - 使用List实现虚拟列表
            List.height(this.isLandscape ? 500 : 400);
            // 内容区域 | Content area - 使用List实现虚拟列表
            List.padding({ left: 30, right: 30, bottom: 30 });
        }, List);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const item = _item;
                {
                    const itemCreation = (elmtId, isInitialRender) => {
                        ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                        itemCreation2(elmtId, isInitialRender);
                        if (!isInitialRender) {
                            ListItem.pop();
                        }
                        ViewStackProcessor.StopGetAccessRecording();
                    };
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        ListItem.create(deepRenderFunction, true);
                        ListItem.width(this.isLandscape ? 260 : 200);
                        ListItem.height(this.isLandscape ? 440 : 370);
                        ListItem.debugLine("raytv/src/main/ets/pages/MainPage.ets(376:11)", "raytv");
                    };
                    const deepRenderFunction = (elmtId, isInitialRender) => {
                        itemCreation(elmtId, isInitialRender);
                        this.renderMediaItem.bind(this)(item);
                        ListItem.pop();
                    };
                    this.observeComponentCreation2(itemCreation2, ListItem);
                    ListItem.pop();
                }
            };
            this.forEachUpdateFunction(elmtId, mediaList, forEachItemGenFunction, (item: FeaturedMediaItem) => `${item.id}_${item.sourceId || 'default'}`, false, false);
        }, ForEach);
        ForEach.pop();
        // 内容区域 | Content area - 使用List实现虚拟列表
        List.pop();
        Column.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(391:5)", "raytv");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#121212');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部区域 | Top area
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(393:7)", "raytv");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部信息栏 | Top info bar
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/MainPage.ets(395:9)", "raytv");
            // 顶部信息栏 | Top info bar
            Row.width('100%');
            // 顶部信息栏 | Top info bar
            Row.justifyContent(FlexAlign.SpaceBetween);
            // 顶部信息栏 | Top info bar
            Row.alignItems(VerticalAlign.Center);
            // 顶部信息栏 | Top info bar
            Row.height(80);
            // 顶部信息栏 | Top info bar
            Row.backgroundColor('#007AFF');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 应用标题 | App title
            Text.create('RayTV');
            Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(397:11)", "raytv");
            // 应用标题 | App title
            Text.fontSize(24);
            // 应用标题 | App title
            Text.fontWeight(700);
            // 应用标题 | App title
            Text.fontColor('#FFFFFF');
            // 应用标题 | App title
            Text.margin({ left: 40 });
        }, Text);
        // 应用标题 | App title
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 日期显示 | Date display
            Text.create(this.currentDate);
            Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(404:11)", "raytv");
            // 日期显示 | Date display
            Text.fontSize(16);
            // 日期显示 | Date display
            Text.fontColor('#E0E0E0');
            // 日期显示 | Date display
            Text.margin({ right: 40 });
        }, Text);
        // 日期显示 | Date display
        Text.pop();
        // 顶部信息栏 | Top info bar
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 主功能菜单 | Main function menu
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/MainPage.ets(416:9)", "raytv");
            // 主功能菜单 | Main function menu
            Row.width('100%');
            // 主功能菜单 | Main function menu
            Row.justifyContent(FlexAlign.Start);
            // 主功能菜单 | Main function menu
            Row.alignItems(VerticalAlign.Center);
            // 主功能菜单 | Main function menu
            Row.backgroundColor('#1E1E1E');
            // 主功能菜单 | Main function menu
            Row.padding({ left: 30 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const item = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(418:13)", "raytv");
                    Context.animation({
                        duration: 200,
                        curve: Curve.EaseOut
                    });
                    Column.onClick(() => this.handleMainMenuClick(item.key));
                    Column.focusable(true);
                    Column.backgroundColor(this.selectedTab === item.key ? 'rgba(255, 255, 255, 0.1)' : 'transparent');
                    Context.animation(null);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(item.name);
                    Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(419:13)", "raytv");
                    Text.fontSize(18);
                    Text.fontWeight(this.selectedTab === item.key ? 700 : 400);
                    Text.fontColor(this.selectedTab === item.key ? '#007AFF' : '#FFFFFF');
                    Text.padding({ left: 30, right: 30, top: 16, bottom: 16 });
                    Text.border(this.selectedTab === item.key ? { width: { bottom: 3 }, color: '#007AFF' } : { width: { bottom: 0 }, color: 'transparent' });
                }, Text);
                Text.pop();
                Column.pop();
            };
            this.forEachUpdateFunction(elmtId, this.mainMenuItems, forEachItemGenFunction, (item: TabItem) => item.key, false, false);
        }, ForEach);
        ForEach.pop();
        // 主功能菜单 | Main function menu
        Row.pop();
        // 顶部区域 | Top area
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 主内容区域 | Main content area
            if (this.selectedTab === 'vod') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Scroll.create(this.contentScroller);
                        Scroll.debugLine("raytv/src/main/ets/pages/MainPage.ets(444:9)", "raytv");
                        Scroll.scrollable(ScrollDirection.Vertical);
                        Scroll.scrollBar(BarState.Auto);
                        Scroll.flexGrow(1);
                        Scroll.backgroundColor('#121212');
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(445:11)", "raytv");
                        Column.width('100%');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.isLoading) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create();
                                    Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(447:11)", "raytv");
                                    Column.justifyContent(FlexAlign.Start);
                                    Column.height(this.isLandscape ? 500 : 400);
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(Strings.mainPage.loadingContent);
                                    Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(448:13)", "raytv");
                                    Text.fontSize(18);
                                    Text.fontColor('#8E8E93');
                                    Text.margin({ top: 30, bottom: 20 });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    // 骨架屏 | Skeleton screen
                                    Row.create();
                                    Row.debugLine("raytv/src/main/ets/pages/MainPage.ets(454:17)", "raytv");
                                    // 骨架屏 | Skeleton screen
                                    Row.padding({ left: 30, right: 30, bottom: 30 });
                                }, Row);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const item = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Column.create();
                                            Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(456:21)", "raytv");
                                            Column.padding(12);
                                            Column.width(this.isLandscape ? 260 : 200);
                                            Column.height(this.isLandscape ? 440 : 370);
                                        }, Column);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            // 图片骨架 | Image skeleton
                                            Column.create();
                                            Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(458:23)", "raytv");
                                            Context.animation({
                                                duration: 1000,
                                                tempo: 1,
                                                curve: Curve.EaseInOut,
                                                iterations: -1,
                                                delay: item * 100
                                            });
                                            // 图片骨架 | Image skeleton
                                            Column.width(this.isLandscape ? 234 : 176);
                                            // 图片骨架 | Image skeleton
                                            Column.height(this.isLandscape ? 320 : 240);
                                            // 图片骨架 | Image skeleton
                                            Column.backgroundColor('#2C2C2C');
                                            // 图片骨架 | Image skeleton
                                            Column.borderRadius(12);
                                            Context.animation(null);
                                        }, Column);
                                        // 图片骨架 | Image skeleton
                                        Column.pop();
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            // 标题骨架 | Title skeleton
                                            Column.create();
                                            Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(472:23)", "raytv");
                                            Context.animation({
                                                duration: 1000,
                                                tempo: 1,
                                                curve: Curve.EaseInOut,
                                                iterations: -1,
                                                delay: item * 150
                                            });
                                            // 标题骨架 | Title skeleton
                                            Column.width(this.isLandscape ? 216 : 168);
                                            // 标题骨架 | Title skeleton
                                            Column.height(40);
                                            // 标题骨架 | Title skeleton
                                            Column.backgroundColor('#2C2C2C');
                                            // 标题骨架 | Title skeleton
                                            Column.borderRadius(4);
                                            // 标题骨架 | Title skeleton
                                            Column.margin({ top: 12 });
                                            Context.animation(null);
                                        }, Column);
                                        // 标题骨架 | Title skeleton
                                        Column.pop();
                                        Column.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, [1, 2, 3, 4, 5], forEachItemGenFunction);
                                }, ForEach);
                                ForEach.pop();
                                // 骨架屏 | Skeleton screen
                                Row.pop();
                                Column.pop();
                            });
                        }
                        else if (this.isError) {
                            this.ifElseBranchUpdateFunction(1, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create();
                                    Column.debugLine("raytv/src/main/ets/pages/MainPage.ets(496:15)", "raytv");
                                    Column.justifyContent(FlexAlign.Center);
                                    Column.height(this.isLandscape ? 500 : 400);
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(Strings.mainPage.loadFailed);
                                    Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(497:17)", "raytv");
                                    Text.fontSize(18);
                                    Text.fontColor('#FF5252');
                                    Text.margin({ top: 20 });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.errorMessage);
                                    Text.debugLine("raytv/src/main/ets/pages/MainPage.ets(501:17)", "raytv");
                                    Text.fontSize(16);
                                    Text.fontColor('#FF9800');
                                    Text.margin({ top: 12 });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Button.createWithLabel(Strings.common.retry);
                                    Button.debugLine("raytv/src/main/ets/pages/MainPage.ets(505:17)", "raytv");
                                    Button.onClick(() => this.loadFeaturedMedia());
                                    Button.backgroundColor('#007AFF');
                                    Button.fontColor('white');
                                    Button.borderRadius(20);
                                    Button.padding({ left: 30, right: 30, top: 14, bottom: 14 });
                                    Button.margin({ top: 20 });
                                    Button.fontSize(16);
                                    Button.focusable(true);
                                }, Button);
                                Button.pop();
                                Column.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(2, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    If.create();
                                    // 推荐内容 | Recommended content
                                    if (this.featuredMedia.length > 0) {
                                        this.ifElseBranchUpdateFunction(0, () => {
                                            this.renderContentSection.bind(this)(Strings.mainPage.categories.featured, ObservedObject.GetRawObject(this.featuredMedia));
                                        });
                                    }
                                    // 热门内容 | Popular content
                                    else {
                                        this.ifElseBranchUpdateFunction(1, () => {
                                        });
                                    }
                                }, If);
                                If.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    If.create();
                                    // 热门内容 | Popular content
                                    if (this.popularMedia.length > 0) {
                                        this.ifElseBranchUpdateFunction(0, () => {
                                            this.renderContentSection.bind(this)(Strings.mainPage.categories.popular, ObservedObject.GetRawObject(this.popularMedia));
                                        });
                                    }
                                    // 最新内容 | New content
                                    else {
                                        this.ifElseBranchUpdateFunction(1, () => {
                                        });
                                    }
                                }, If);
                                If.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    If.create();
                                    // 最新内容 | New content
                                    if (this.newMedia.length > 0) {
                                        this.ifElseBranchUpdateFunction(0, () => {
                                            this.renderContentSection.bind(this)(Strings.mainPage.categories.new, ObservedObject.GetRawObject(this.newMedia));
                                        });
                                    }
                                    else {
                                        this.ifElseBranchUpdateFunction(1, () => {
                                        });
                                    }
                                }, If);
                                If.pop();
                            });
                        }
                    }, If);
                    If.pop();
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
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "MainPage";
    }
}
registerNamedRoute(() => new MainPage(undefined, {}), "", { bundleName: "com.raytv.app", moduleName: "raytv", pagePath: "pages/MainPage", pageFullPath: "raytv/src/main/ets/pages/MainPage", integratedHsp: "false", moduleType: "followWithHap" });
