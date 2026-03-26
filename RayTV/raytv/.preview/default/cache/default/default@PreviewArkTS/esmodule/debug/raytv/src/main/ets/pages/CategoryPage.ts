if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface CategoryPage_Params {
    TAG?: string;
    selectedCategory?: string;
    selectedRegion?: string;
    selectedYear?: string;
    selectedSort?: string;
    mediaList?: MediaItem[];
    categories?: string[];
    regions?: string[];
    years?: string[];
    sortOptions?: string[];
    isLoading?: boolean;
    errorMessage?: string;
    currentPage?: number;
    hasMoreResults?: boolean;
    isRefreshing?: boolean;
    hotCategories?: string[];
    breadcrumbs?: BreadcrumbItem[];
    pageSize?: number;
}
import { AppNavigator } from "@bundle:com.raytv.app/raytv/ets/navigation/AppNavigator";
import type { BreadcrumbItem } from "@bundle:com.raytv.app/raytv/ets/navigation/AppNavigator";
import { MediaService } from "@bundle:com.raytv.app/raytv/ets/service/media/MediaService";
import type { MediaItem } from '../data/bean/MediaItem';
import type { VirtualListItem } from '../types/VirtualListTypes';
class CategoryPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.TAG = 'CategoryPage';
        this.__selectedCategory = new ObservedPropertySimplePU('全部', this, "selectedCategory");
        this.__selectedRegion = new ObservedPropertySimplePU('全部', this, "selectedRegion");
        this.__selectedYear = new ObservedPropertySimplePU('全部', this, "selectedYear");
        this.__selectedSort = new ObservedPropertySimplePU('最新', this, "selectedSort");
        this.__mediaList = new ObservedPropertyObjectPU([], this, "mediaList");
        this.__categories = new ObservedPropertyObjectPU(['全部', '电影', '电视剧', '动画', '综艺', '纪录片'], this, "categories");
        this.__regions = new ObservedPropertyObjectPU(['全部', '国内', '香港', '台湾', '美国', '日本', '韩国', '其他'], this, "regions");
        this.__years = new ObservedPropertyObjectPU([], this, "years");
        this.__sortOptions = new ObservedPropertyObjectPU(['最新', '最热', '评分最高'], this, "sortOptions");
        this.__isLoading = new ObservedPropertySimplePU(false, this, "isLoading");
        this.__errorMessage = new ObservedPropertySimplePU('', this, "errorMessage");
        this.__currentPage = new ObservedPropertySimplePU(1, this, "currentPage");
        this.__hasMoreResults = new ObservedPropertySimplePU(true, this, "hasMoreResults");
        this.__isRefreshing = new ObservedPropertySimplePU(false, this, "isRefreshing");
        this.__hotCategories = new ObservedPropertyObjectPU(['热门电影', '热门电视剧', '热门动画', '热门综艺'], this, "hotCategories");
        this.__breadcrumbs = new ObservedPropertyObjectPU([], this, "breadcrumbs");
        this.pageSize = 20;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: CategoryPage_Params) {
        if (params.TAG !== undefined) {
            this.TAG = params.TAG;
        }
        if (params.selectedCategory !== undefined) {
            this.selectedCategory = params.selectedCategory;
        }
        if (params.selectedRegion !== undefined) {
            this.selectedRegion = params.selectedRegion;
        }
        if (params.selectedYear !== undefined) {
            this.selectedYear = params.selectedYear;
        }
        if (params.selectedSort !== undefined) {
            this.selectedSort = params.selectedSort;
        }
        if (params.mediaList !== undefined) {
            this.mediaList = params.mediaList;
        }
        if (params.categories !== undefined) {
            this.categories = params.categories;
        }
        if (params.regions !== undefined) {
            this.regions = params.regions;
        }
        if (params.years !== undefined) {
            this.years = params.years;
        }
        if (params.sortOptions !== undefined) {
            this.sortOptions = params.sortOptions;
        }
        if (params.isLoading !== undefined) {
            this.isLoading = params.isLoading;
        }
        if (params.errorMessage !== undefined) {
            this.errorMessage = params.errorMessage;
        }
        if (params.currentPage !== undefined) {
            this.currentPage = params.currentPage;
        }
        if (params.hasMoreResults !== undefined) {
            this.hasMoreResults = params.hasMoreResults;
        }
        if (params.isRefreshing !== undefined) {
            this.isRefreshing = params.isRefreshing;
        }
        if (params.hotCategories !== undefined) {
            this.hotCategories = params.hotCategories;
        }
        if (params.breadcrumbs !== undefined) {
            this.breadcrumbs = params.breadcrumbs;
        }
        if (params.pageSize !== undefined) {
            this.pageSize = params.pageSize;
        }
    }
    updateStateVars(params: CategoryPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__selectedCategory.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedRegion.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedYear.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedSort.purgeDependencyOnElmtId(rmElmtId);
        this.__mediaList.purgeDependencyOnElmtId(rmElmtId);
        this.__categories.purgeDependencyOnElmtId(rmElmtId);
        this.__regions.purgeDependencyOnElmtId(rmElmtId);
        this.__years.purgeDependencyOnElmtId(rmElmtId);
        this.__sortOptions.purgeDependencyOnElmtId(rmElmtId);
        this.__isLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__errorMessage.purgeDependencyOnElmtId(rmElmtId);
        this.__currentPage.purgeDependencyOnElmtId(rmElmtId);
        this.__hasMoreResults.purgeDependencyOnElmtId(rmElmtId);
        this.__isRefreshing.purgeDependencyOnElmtId(rmElmtId);
        this.__hotCategories.purgeDependencyOnElmtId(rmElmtId);
        this.__breadcrumbs.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__selectedCategory.aboutToBeDeleted();
        this.__selectedRegion.aboutToBeDeleted();
        this.__selectedYear.aboutToBeDeleted();
        this.__selectedSort.aboutToBeDeleted();
        this.__mediaList.aboutToBeDeleted();
        this.__categories.aboutToBeDeleted();
        this.__regions.aboutToBeDeleted();
        this.__years.aboutToBeDeleted();
        this.__sortOptions.aboutToBeDeleted();
        this.__isLoading.aboutToBeDeleted();
        this.__errorMessage.aboutToBeDeleted();
        this.__currentPage.aboutToBeDeleted();
        this.__hasMoreResults.aboutToBeDeleted();
        this.__isRefreshing.aboutToBeDeleted();
        this.__hotCategories.aboutToBeDeleted();
        this.__breadcrumbs.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private readonly TAG: string;
    // 状态管理 | State management
    private __selectedCategory: ObservedPropertySimplePU<string>;
    get selectedCategory() {
        return this.__selectedCategory.get();
    }
    set selectedCategory(newValue: string) {
        this.__selectedCategory.set(newValue);
    }
    private __selectedRegion: ObservedPropertySimplePU<string>;
    get selectedRegion() {
        return this.__selectedRegion.get();
    }
    set selectedRegion(newValue: string) {
        this.__selectedRegion.set(newValue);
    }
    private __selectedYear: ObservedPropertySimplePU<string>;
    get selectedYear() {
        return this.__selectedYear.get();
    }
    set selectedYear(newValue: string) {
        this.__selectedYear.set(newValue);
    }
    private __selectedSort: ObservedPropertySimplePU<string>;
    get selectedSort() {
        return this.__selectedSort.get();
    }
    set selectedSort(newValue: string) {
        this.__selectedSort.set(newValue);
    }
    private __mediaList: ObservedPropertyObjectPU<MediaItem[]>;
    get mediaList() {
        return this.__mediaList.get();
    }
    set mediaList(newValue: MediaItem[]) {
        this.__mediaList.set(newValue);
    }
    private __categories: ObservedPropertyObjectPU<string[]>;
    get categories() {
        return this.__categories.get();
    }
    set categories(newValue: string[]) {
        this.__categories.set(newValue);
    }
    private __regions: ObservedPropertyObjectPU<string[]>;
    get regions() {
        return this.__regions.get();
    }
    set regions(newValue: string[]) {
        this.__regions.set(newValue);
    }
    private __years: ObservedPropertyObjectPU<string[]>;
    get years() {
        return this.__years.get();
    }
    set years(newValue: string[]) {
        this.__years.set(newValue);
    }
    private __sortOptions: ObservedPropertyObjectPU<string[]>;
    get sortOptions() {
        return this.__sortOptions.get();
    }
    set sortOptions(newValue: string[]) {
        this.__sortOptions.set(newValue);
    }
    private __isLoading: ObservedPropertySimplePU<boolean>;
    get isLoading() {
        return this.__isLoading.get();
    }
    set isLoading(newValue: boolean) {
        this.__isLoading.set(newValue);
    }
    private __errorMessage: ObservedPropertySimplePU<string>;
    get errorMessage() {
        return this.__errorMessage.get();
    }
    set errorMessage(newValue: string) {
        this.__errorMessage.set(newValue);
    }
    private __currentPage: ObservedPropertySimplePU<number>;
    get currentPage() {
        return this.__currentPage.get();
    }
    set currentPage(newValue: number) {
        this.__currentPage.set(newValue);
    }
    private __hasMoreResults: ObservedPropertySimplePU<boolean>;
    get hasMoreResults() {
        return this.__hasMoreResults.get();
    }
    set hasMoreResults(newValue: boolean) {
        this.__hasMoreResults.set(newValue);
    }
    private __isRefreshing: ObservedPropertySimplePU<boolean>;
    get isRefreshing() {
        return this.__isRefreshing.get();
    }
    set isRefreshing(newValue: boolean) {
        this.__isRefreshing.set(newValue);
    }
    private __hotCategories: ObservedPropertyObjectPU<string[]>;
    get hotCategories() {
        return this.__hotCategories.get();
    }
    set hotCategories(newValue: string[]) {
        this.__hotCategories.set(newValue);
    }
    private __breadcrumbs: ObservedPropertyObjectPU<BreadcrumbItem[]>;
    get breadcrumbs() {
        return this.__breadcrumbs.get();
    }
    set breadcrumbs(newValue: BreadcrumbItem[]) {
        this.__breadcrumbs.set(newValue);
    }
    // 分页配置 | Pagination configuration
    private pageSize: number;
    // 服务实例将在方法中直接调用 | Service instances will be called directly in methods
    /**
     * 页面加载时调用 | Called when page loads
     */
    async aboutToAppear(): Promise<void> {
        console.info('CategoryPage appeared');
        // 初始化年份选项 | Initialize year options
        const currentYear = new Date().getFullYear();
        // 先构建年份数组，然后添加"全部"选项 | Build year array first, then add "全部" option
        const yearArray: string[] = [];
        yearArray.push('全部');
        for (let i = 0; i < 10; i++) {
            yearArray.push((currentYear - i).toString());
        }
        this.years = yearArray;
        // 获取面包屑导航
        this.breadcrumbs = AppNavigator.getInstance().getBreadcrumbs();
        // 初始化数据 | Initialize data
        await this.loadMediaList(true);
    }
    /**
     * 页面卸载时调用 | Called when page unloads
     */
    aboutToDisappear(): void {
        console.info('CategoryPage disappeared');
    }
    /**
     * 加载媒体列表 | Load media list
     */
    private async loadMediaList(reset: boolean = false): Promise<void> {
        try {
            this.isLoading = true;
            this.errorMessage = '';
            if (reset) {
                this.currentPage = 1;
                this.mediaList = [];
            }
            else if (!this.hasMoreResults) {
                this.isLoading = false;
                return;
            }
            const category = this.selectedCategory === '全部' ? '' : this.selectedCategory;
            const region = this.selectedRegion === '全部' ? '' : this.selectedRegion;
            const year = this.selectedYear === '全部' ? '' : this.selectedYear;
            console.info('Loading media list: category=' + category + ', region=' + region + ', year=' + year + ', sort=' + this.selectedSort + ', page=' + this.currentPage);
            // 调用MediaService获取真实数据 | Call MediaService to get real data
            // 注意：使用getRecommendedContent替代不存在的getCategoryMedia方法 | Note: Using getRecommendedContent instead of non-existent getCategoryMedia method
            const result = await MediaService.getInstance().getRecommendedContent();
            if (result.isSuccess() && result.data) {
                const newMediaItems: MediaItem[] = result.data;
                if (reset) {
                    this.mediaList = newMediaItems;
                }
                else {
                    const mergedList: MediaItem[] = [];
                    for (let i = 0; i < this.mediaList.length; i++) {
                        mergedList.push(this.mediaList[i]);
                    }
                    for (let i = 0; i < newMediaItems.length; i++) {
                        mergedList.push(newMediaItems[i]);
                    }
                    this.mediaList = mergedList;
                }
                // 判断是否还有更多数据 | Determine if there are more results
                this.hasMoreResults = newMediaItems.length === this.pageSize;
                console.info('Media list loaded, total: ' + this.mediaList.length + ', has more: ' + this.hasMoreResults);
            }
            else {
                this.errorMessage = result.message || '加载失败，请稍后重试';
                this.hasMoreResults = false;
                console.warn('Failed to load media list: ' + this.errorMessage);
            }
        }
        catch (error) {
            const errorMsg = error instanceof Error ? error.message : String(error);
            console.error('Failed to load media list: ' + errorMsg);
            this.errorMessage = '加载失败，请稍后重试';
            this.hasMoreResults = false;
        }
        finally {
            this.isLoading = false;
            this.isRefreshing = false;
        }
    }
    /**
     * 处理筛选条件变化 | Handle filter condition changes
     */
    private async handleFilterChange(): Promise<void> {
        this.currentPage = 1;
        this.mediaList = [];
        this.hasMoreResults = true;
        await this.loadMediaList(true);
    }
    /**
     * 处理分类选择 | Handle category selection
     */
    private async handleCategorySelect(category: string): Promise<void> {
        if (this.selectedCategory !== category) {
            this.selectedCategory = category;
            await this.handleFilterChange();
        }
    }
    /**
     * 处理地区选择 | Handle region selection
     */
    private async handleRegionSelect(region: string): Promise<void> {
        if (this.selectedRegion !== region) {
            this.selectedRegion = region;
            await this.handleFilterChange();
        }
    }
    /**
     * 处理年份选择 | Handle year selection
     */
    private async handleYearSelect(year: string): Promise<void> {
        if (this.selectedYear !== year) {
            this.selectedYear = year;
            await this.handleFilterChange();
        }
    }
    /**
     * 处理排序选择 | Handle sort selection
     */
    private async handleSortSelect(sort: string): Promise<void> {
        if (this.selectedSort !== sort) {
            this.selectedSort = sort;
            await this.handleFilterChange();
        }
    }
    /**
     * 处理热门分类选择 | Handle hot category selection
     */
    private async handleHotCategorySelect(hotCategory: string): Promise<void> {
        console.info('Hot category clicked: ' + hotCategory);
        // 根据热门分类设置对应的分类和排序
        switch (hotCategory) {
            case '热门电影':
                this.selectedCategory = '电影';
                this.selectedSort = '最热';
                break;
            case '热门电视剧':
                this.selectedCategory = '电视剧';
                this.selectedSort = '最热';
                break;
            case '热门动画':
                this.selectedCategory = '动画';
                this.selectedSort = '最热';
                break;
            case '热门综艺':
                this.selectedCategory = '综艺';
                this.selectedSort = '最热';
                break;
        }
        await this.handleFilterChange();
    }
    /**
     * 处理媒体项点击 | Handle media item click
     */
    private handleMediaItemClick(media: MediaItem): void {
        console.info('Media item clicked: ' + media.title);
        // 跳转到详情页 | Navigate to detail page
        AppNavigator.getInstance().navigateToDetail({
            id: media.id,
            siteKey: media.siteKey,
            type: 'vod'
        });
    }
    /**
     * 将MediaItem转换为VirtualListItem | Convert MediaItem to VirtualListItem
     */
    private convertToVirtualItems(mediaList: MediaItem[]): VirtualListItem[] {
        return mediaList.map((media: MediaItem, index: number): VirtualListItem => {
            const item: VirtualListItem = {
                id: media.id,
                index: index,
                data: media,
                top: index * 140,
                height: 140,
                visible: false
            };
            return item;
        });
    }
    /**
     * 处理加载更多 | Handle load more
     */
    private async handleLoadMore(): Promise<void> {
        if (!this.isLoading && this.hasMoreResults) {
            this.currentPage++;
            await this.loadMediaList(false);
        }
    }
    /**
     * 处理刷新 | Handle refresh
     */
    private async handleRefresh(): Promise<void> {
        this.isRefreshing = true;
        await this.loadMediaList(true);
    }
    /**
     * 处理返回 | Handle back
     */
    private handleBack(): void {
        // 使用AppNavigator处理返回 | Use AppNavigator to handle back
        AppNavigator.getInstance().navigateToBack();
    }
    /**
     * 处理面包屑导航点击 | Handle breadcrumb navigation click
     */
    private async handleBreadcrumbClick(index: number): Promise<void> {
        await AppNavigator.getInstance().navigateToBreadcrumb(index);
    }
    /**
     * 渲染头部 | Render header
     */
    private renderHeader(parent = null): void {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(285:5)", "raytv");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(286:7)", "raytv");
            Row.justifyContent(FlexAlign.SpaceBetween);
            Row.padding(20);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel("返回");
            Button.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(287:9)", "raytv");
            Button.onClick(() => this.handleBack());
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("分类浏览");
            Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(289:9)", "raytv");
            Text.fontSize(20);
            Text.fontWeight(700);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 使用空的Row作为占位符，类似HTML blank元素 | Use empty Row as placeholder, similar to HTML blank element
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(293:9)", "raytv");
        }, Row);
        // 使用空的Row作为占位符，类似HTML blank元素 | Use empty Row as placeholder, similar to HTML blank element
        Row.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 面包屑导航 | Breadcrumb navigation
            if (this.breadcrumbs.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(300:9)", "raytv");
                        Row.padding({ left: 20, right: 20, bottom: 10 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, index: number) => {
                            const crumb = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(302:13)", "raytv");
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(crumb.title);
                                Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(303:15)", "raytv");
                                Text.fontSize(14);
                                Text.fontColor(index === this.breadcrumbs.length - 1 ? '#333333' : '#666666');
                                Text.fontWeight(index === this.breadcrumbs.length - 1 ? 700 : 400);
                                Text.onClick(() => this.handleBreadcrumbClick(index));
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                If.create();
                                if (index < this.breadcrumbs.length - 1) {
                                    this.ifElseBranchUpdateFunction(0, () => {
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(" > ");
                                            Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(309:17)", "raytv");
                                            Text.fontSize(14);
                                            Text.fontColor('#999999');
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
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.breadcrumbs, forEachItemGenFunction, (crumb: BreadcrumbItem) => crumb.route + crumb.title, true, false);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
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
    /**
     * 渲染分类选择器 | Render category selector
     */
    private renderCategorySelector(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(326:5)", "raytv");
            Row.padding(5);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const category = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel(category);
                    Button.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(328:9)", "raytv");
                    Button.onClick(() => this.handleCategorySelect(category));
                    Button.margin(5);
                }, Button);
                Button.pop();
            };
            this.forEachUpdateFunction(elmtId, this.categories, forEachItemGenFunction, (category: string) => category, false, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
    }
    /**
     * 渲染热门分类快捷入口 | Render hot category quick access
     */
    private renderHotCategories(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(341:5)", "raytv");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("热门分类");
            Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(342:7)", "raytv");
            Text.fontSize(18);
            Text.fontWeight(700);
            Text.margin({ top: 10, bottom: 10, left: 20 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(347:7)", "raytv");
            Row.padding(5);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const hotCategory = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel(hotCategory);
                    Button.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(349:11)", "raytv");
                    Button.onClick(() => this.handleHotCategorySelect(hotCategory));
                    Button.margin(5);
                    Button.backgroundColor('#FF6B35');
                    Button.fontColor('#FFFFFF');
                }, Button);
                Button.pop();
            };
            this.forEachUpdateFunction(elmtId, this.hotCategories, forEachItemGenFunction, (hotCategory: string) => hotCategory, false, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        Column.pop();
    }
    /**
     * 渲染筛选条件 | Render filters
     */
    private renderFilters(parent = null): void {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(365:5)", "raytv");
            Column.margin(20);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 地区筛选 | Region filter
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(367:7)", "raytv");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("地区:");
            Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(368:9)", "raytv");
            Text.fontSize(16);
            Text.fontColor('#333333');
            Text.margin(10);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(372:9)", "raytv");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const region = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel(region);
                    Button.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(374:13)", "raytv");
                    Button.onClick(() => this.handleRegionSelect(region));
                    Button.margin(5);
                }, Button);
                Button.pop();
            };
            this.forEachUpdateFunction(elmtId, this.regions.slice(0, 5), forEachItemGenFunction);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        // 地区筛选 | Region filter
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 年份筛选 | Year filter
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(382:7)", "raytv");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("年份:");
            Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(383:9)", "raytv");
            Text.fontSize(16);
            Text.fontColor('#333333');
            Text.margin(10);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(387:9)", "raytv");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const year = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel(year);
                    Button.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(389:13)", "raytv");
                    Button.onClick(() => this.handleYearSelect(year));
                    Button.margin(5);
                }, Button);
                Button.pop();
            };
            this.forEachUpdateFunction(elmtId, this.years.slice(0, 5), forEachItemGenFunction);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        // 年份筛选 | Year filter
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 排序筛选 | Sort filter
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(397:7)", "raytv");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("排序:");
            Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(398:9)", "raytv");
            Text.fontSize(16);
            Text.fontColor('#333333');
            Text.margin(10);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(402:9)", "raytv");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const sort = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel(sort);
                    Button.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(404:13)", "raytv");
                    Button.onClick(() => this.handleSortSelect(sort));
                    Button.margin(5);
                }, Button);
                Button.pop();
            };
            this.forEachUpdateFunction(elmtId, this.sortOptions.slice(0, 3), forEachItemGenFunction);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        // 排序筛选 | Sort filter
        Row.pop();
        Column.pop();
    }
    /**
     * 渲染媒体项 | Render media item
     */
    private renderMediaItem(media: MediaItem, parent = null): void {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(419:5)", "raytv");
            Row.padding(10);
            Row.backgroundColor('#F5F5F5');
            Row.borderRadius(8);
            Row.margin({ bottom: 10 });
            Row.onClick(() => this.handleMediaItemClick(media));
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create(media.coverUrl || '');
            Image.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(420:7)", "raytv");
            Image.width(80);
            Image.height(120);
            Image.objectFit(ImageFit.Cover);
            Image.borderRadius(4);
            Image.backgroundColor('#F5F5F5');
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(426:7)", "raytv");
            Column.justifyContent(FlexAlign.SpaceBetween);
            Column.height(120);
            Column.margin({ left: 10 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(media.title);
            Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(427:9)", "raytv");
            Text.fontSize(16);
            Text.fontColor('#333333');
            Text.maxLines(2);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (media.year) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(media.year);
                        Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(432:11)", "raytv");
                        Text.fontSize(12);
                        Text.fontColor('#666666');
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
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (media.score) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create("评分: " + media.score);
                        Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(437:11)", "raytv");
                        Text.fontSize(12);
                        Text.fontColor('#FF6B35');
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
        Row.pop();
    }
    /**
     * 组件渲染 | Component render
     */
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(459:5)", "raytv");
        }, Column);
        // 页面头部 | Page header
        this.renderHeader.bind(this)();
        // 热门分类快捷入口 | Hot category quick access
        this.renderHotCategories.bind(this)();
        // 分类选择 | Category selection
        this.renderCategorySelector.bind(this)();
        // 筛选条件 | Filters
        this.renderFilters.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 媒体列表 | Media list
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(473:7)", "raytv");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.isLoading && this.currentPage === 1) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(475:11)", "raytv");
                        Column.alignItems(HorizontalAlign.Center);
                        Column.justifyContent(FlexAlign.Center);
                        Column.padding(20);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create("加载中...");
                        Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(476:13)", "raytv");
                        Text.fontSize(16);
                        Text.fontColor('#333333');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else if (this.errorMessage) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(484:11)", "raytv");
                        Column.alignItems(HorizontalAlign.Center);
                        Column.justifyContent(FlexAlign.Center);
                        Column.padding(20);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create("😔");
                        Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(485:13)", "raytv");
                        Text.fontSize(24);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.errorMessage);
                        Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(487:13)", "raytv");
                        Text.fontSize(16);
                        Text.fontColor('#333333');
                        Text.margin({ top: 10 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel("重试");
                        Button.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(491:13)", "raytv");
                        Button.onClick(() => this.loadMediaList(true));
                        Button.margin({ top: 15 });
                    }, Button);
                    Button.pop();
                    Column.pop();
                });
            }
            else if (this.mediaList.length === 0) {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(499:11)", "raytv");
                        Column.alignItems(HorizontalAlign.Center);
                        Column.justifyContent(FlexAlign.Center);
                        Column.padding(20);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create("暂无相关内容");
                        Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(500:13)", "raytv");
                        Text.fontSize(16);
                        Text.fontColor('#333333');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(3, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 使用 List 优化性能 | Use List for better performance
                        List.create();
                        List.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(509:13)", "raytv");
                        // 使用 List 优化性能 | Use List for better performance
                        List.margin(20);
                        // 使用 List 优化性能 | Use List for better performance
                        List.height('70%');
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, index: number) => {
                            const media = _item;
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
                                    ListItem.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(511:17)", "raytv");
                                };
                                const deepRenderFunction = (elmtId, isInitialRender) => {
                                    itemCreation(elmtId, isInitialRender);
                                    this.renderMediaItem.bind(this)(media);
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.mediaList, forEachItemGenFunction, (media: MediaItem, index: number) => `${media.id}_${index}`, true, true);
                    }, ForEach);
                    ForEach.pop();
                    // 使用 List 优化性能 | Use List for better performance
                    List.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 加载更多 | Load more
            if (this.isLoading && this.currentPage > 1 && this.hasMoreResults) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(522:11)", "raytv");
                        Column.alignItems(HorizontalAlign.Center);
                        Column.justifyContent(FlexAlign.Center);
                        Column.padding(20);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create("加载更多...");
                        Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(523:13)", "raytv");
                        Text.fontSize(16);
                        Text.fontColor('#333333');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else if (!this.hasMoreResults && this.mediaList.length > 0) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create("没有更多内容啦~");
                        Text.debugLine("raytv/src/main/ets/pages/CategoryPage.ets(531:11)", "raytv");
                        Text.fontSize(14);
                        Text.fontColor('#666666');
                        Text.textAlign(TextAlign.Center);
                        Text.padding(20);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                });
            }
        }, If);
        If.pop();
        // 媒体列表 | Media list
        Column.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "CategoryPage";
    }
}
registerNamedRoute(() => new CategoryPage(undefined, {}), "", { bundleName: "com.raytv.app", moduleName: "raytv", pagePath: "pages/CategoryPage", pageFullPath: "raytv/src/main/ets/pages/CategoryPage", integratedHsp: "false", moduleType: "followWithHap" });
