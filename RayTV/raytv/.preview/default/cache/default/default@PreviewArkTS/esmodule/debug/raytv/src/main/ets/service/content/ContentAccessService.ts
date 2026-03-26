import Logger from "@bundle:com.raytv.app/raytv/ets/common/util/Logger";
import SourcePoolManagerInstance from "@bundle:com.raytv.app/raytv/ets/service/pool/SourcePoolManager";
import type { SourcePoolManager, VodSiteWithSource, LiveChannelWithSource, WallpaperWithSource, AdBlockRule, DecoderConfig, LiveCategory } from "@bundle:com.raytv.app/raytv/ets/service/pool/SourcePoolManager";
import type { ParserConfig } from '../interfaces/IConfigSourceService';
// ========================================
// 接口定义
// ========================================
/**
 * 源统计信息接口
 */
export interface SourceStats {
    sourceId: string;
    sourceName: string;
    count: number;
}
/**
 * 整体统计信息接口
 */
export interface OverallStats {
    vodSources: number;
    vodSites: number;
    vodCategories: number;
    liveSources: number;
    liveChannels: number;
    liveCategories: number;
    wallpaperSources: number;
    wallpapers: number;
    adBlockRules: number;
    decoderConfigs: number;
}
/**
 * 内容筛选选项
 */
export interface ContentFilterOptions {
    sourceIds?: string[]; // 按源筛选
    categories?: string[]; // 按分类筛选
    keywords?: string[]; // 按关键词筛选
    flags?: string[]; // 按标记筛选
    tags?: string[]; // 按标签筛选
    minPriority?: number; // 最小优先级
}
/**
 * 分页参数
 */
export interface PaginationParams {
    page: number;
    pageSize: number;
}
/**
 * 分页结果
 */
export interface PagedResult<T> {
    items: T[];
    total: number;
    page: number;
    pageSize: number;
    hasMore: boolean;
}
/**
 * 内容访问服务类
 */
export class ContentAccessService {
    private static instance: ContentAccessService | null = null;
    private logTag: string = 'ContentAccessService';
    private poolManager: SourcePoolManager;
    private initialized: boolean = false;
    /**
     * 获取单例实例
     */
    public static getInstance(): ContentAccessService {
        if (!ContentAccessService.instance) {
            ContentAccessService.instance = new ContentAccessService();
        }
        return ContentAccessService.instance;
    }
    /**
     * 私有构造函数
     */
    private constructor() {
        this.poolManager = SourcePoolManagerInstance as SourcePoolManager;
    }
    /**
     * 初始化服务
     */
    public async initialize(): Promise<void> {
        if (this.initialized) {
            return;
        }
        try {
            // 初始化源池管理器
            await this.poolManager.initialize();
            this.initialized = true;
            Logger.info(this.logTag, 'ContentAccessService initialized successfully');
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            Logger.error(this.logTag, 'Failed to initialize ContentAccessService', err);
            throw err;
        }
    }
    /**
     * 检查服务是否已初始化
     *
     * @returns 是否已初始化
     */
    public isInitialized(): boolean {
        return this.initialized;
    }
    /**
     * 强制重新初始化服务
     *
     * @returns 初始化结果
     */
    public async reinitialize(): Promise<void> {
        this.initialized = false;
        await this.initialize();
    }
    // ========================================
    // 点播内容访问
    // ========================================
    /**
     * 获取所有点播站点
     */
    public getAllVodSites(): VodSiteWithSource[] {
        const pool = this.poolManager.getVodPool();
        return pool.getAllSites();
    }
    /**
     * 按源获取点播站点
     */
    public getVodSitesBySource(sourceId: string): VodSiteWithSource[] {
        const pool = this.poolManager.getVodPool();
        return pool.getSiteBySource(sourceId);
    }
    /**
     * 按分类获取点播站点
     */
    public getVodSitesByCategory(category: string): VodSiteWithSource[] {
        const allSites = this.getAllVodSites();
        return allSites.filter(site => site.categories && site.categories.includes(category));
    }
    /**
     * 搜索点播站点
     */
    public searchVodSites(keyword: string, options?: ContentFilterOptions): VodSiteWithSource[] {
        let sites = this.getAllVodSites();
        // 应用筛选条件
        if (options) {
            sites = this.applyVodSiteFilters(sites, options);
        }
        // 关键词搜索
        if (keyword.trim()) {
            const lowerKeyword = keyword.toLowerCase().trim();
            sites = sites.filter(site => site.name.toLowerCase().includes(lowerKeyword) ||
                site.siteKey.toLowerCase().includes(lowerKeyword) ||
                site.sourceName.toLowerCase().includes(lowerKeyword));
        }
        return sites;
    }
    /**
     * 获取分页的点播站点
     */
    public getVodSitesPaged(pagination: PaginationParams, options: ContentFilterOptions | undefined): PagedResult<VodSiteWithSource> {
        let sites = this.getAllVodSites();
        // 应用筛选条件
        if (options) {
            sites = this.applyVodSiteFilters(sites, options);
        }
        const total = sites.length;
        const startIndex = (pagination.page - 1) * pagination.pageSize;
        const endIndex = startIndex + pagination.pageSize;
        const items = sites.slice(startIndex, endIndex);
        return {
            items,
            total,
            page: pagination.page,
            pageSize: pagination.pageSize,
            hasMore: endIndex < total
        };
    }
    /**
     * 获取点播站点分类列表
     */
    public getVodSiteCategories(): string[] {
        const allSites = this.getAllVodSites();
        const categorySet = new Set<string>();
        allSites.forEach(site => {
            if (site.categories) {
                site.categories.forEach(cat => categorySet.add(cat));
            }
        });
        return Array.from(categorySet).sort();
    }
    /**
     * 获取源统计信息
     */
    public getVodSourceStats(): Array<SourceStats> {
        const allSites = this.getAllVodSites();
        const statsMap = new Map<string, number>();
        allSites.forEach(site => {
            const count = statsMap.get(site.sourceId) || 0;
            statsMap.set(site.sourceId, count + 1);
        });
        // 获取源名称
        const result: Array<SourceStats> = [];
        const entries = statsMap.entries();
        for (const entry of entries) {
            const sourceId: string = entry[0];
            const count: number = entry[1];
            const site = allSites.find(s => s.sourceId === sourceId);
            if (site) {
                const stat: SourceStats = {
                    sourceId,
                    sourceName: site.sourceName,
                    count
                };
                result.push(stat);
            }
        }
        // 按数量降序排序
        return result.sort((a, b) => b.count - a.count);
    }
    // ========================================
    // 直播内容访问
    // ========================================
    /**
     * 获取所有直播频道
     */
    public getAllLiveChannels(): LiveChannelWithSource[] {
        const pool = this.poolManager.getLivePool();
        return pool.getAllChannels();
    }
    /**
     * 获取直播分类
     */
    public getLiveCategories(): LiveCategory[] {
        const pool = this.poolManager.getLivePool();
        return pool.categories;
    }
    /**
     * 按分类获取直播频道
     */
    public getLiveChannelsByCategory(category: string): LiveChannelWithSource[] {
        const pool = this.poolManager.getLivePool();
        return pool.getChannelsByCategory(category);
    }
    /**
     * 按源获取直播频道
     */
    public getLiveChannelsBySource(sourceId: string): LiveChannelWithSource[] {
        const pool = this.poolManager.getLivePool();
        return pool.getChannelsBySource(sourceId);
    }
    /**
     * 搜索直播频道
     */
    public searchLiveChannels(keyword: string, options: ContentFilterOptions | undefined): LiveChannelWithSource[] {
        let channels: LiveChannelWithSource[] = this.getAllLiveChannels();
        // 应用筛选条件
        if (options) {
            channels = this.applyLiveChannelFilters(channels, options);
        }
        // 关键词搜索
        if (keyword.trim()) {
            const lowerKeyword = keyword.toLowerCase().trim();
            channels = channels.filter(channel => channel.name.toLowerCase().includes(lowerKeyword) ||
                channel.group.toLowerCase().includes(lowerKeyword) ||
                channel.sourceName.toLowerCase().includes(lowerKeyword));
        }
        return channels;
    }
    /**
     * 获取分页的直播频道
     */
    public getLiveChannelsPaged(pagination: PaginationParams, options: ContentFilterOptions | undefined): PagedResult<LiveChannelWithSource> {
        let channels: LiveChannelWithSource[] = this.getAllLiveChannels();
        // 应用筛选条件
        if (options) {
            channels = this.applyLiveChannelFilters(channels, options);
        }
        const total = channels.length;
        const startIndex = (pagination.page - 1) * pagination.pageSize;
        const endIndex = startIndex + pagination.pageSize;
        const items = channels.slice(startIndex, endIndex);
        return {
            items,
            total,
            page: pagination.page,
            pageSize: pagination.pageSize,
            hasMore: endIndex < total
        };
    }
    /**
     * 获取直播源统计信息
     */
    public getLiveSourceStats(): Array<SourceStats> {
        const allChannels = this.getAllLiveChannels();
        const statsMap = new Map<string, number>();
        allChannels.forEach(channel => {
            const count = statsMap.get(channel.sourceId) || 0;
            statsMap.set(channel.sourceId, count + 1);
        });
        // 获取源名称
        const result: Array<SourceStats> = [];
        const entries = statsMap.entries();
        for (const entry of entries) {
            const sourceId: string = entry[0];
            const count: number = entry[1];
            const channel = allChannels.find(ch => ch.sourceId === sourceId);
            if (channel) {
                const stat: SourceStats = {
                    sourceId,
                    sourceName: channel.sourceName,
                    count
                };
                result.push(stat);
            }
        }
        // 按数量降序排序
        return result.sort((a, b) => b.count - a.count);
    }
    // ========================================
    // 壁纸内容访问
    // ========================================
    /**
     * 获取随机壁纸
     */
    public getRandomWallpaper(): WallpaperWithSource | null {
        const pool = this.poolManager.getWallpaperPool();
        return pool.getRandomWallpaper();
    }
    /**
     * 按源获取壁纸
     */
    public getWallpapersBySource(sourceId: string): WallpaperWithSource[] {
        const pool = this.poolManager.getWallpaperPool();
        return pool.getWallpapersBySource(sourceId);
    }
    /**
     * 获取所有壁纸
     */
    public getAllWallpapers(): WallpaperWithSource[] {
        const pool = this.poolManager.getWallpaperPool();
        return pool.getAllWallpapers();
    }
    /**
     * 搜索壁纸
     */
    public searchWallpapers(keyword: string): WallpaperWithSource[] {
        const allWallpapers = this.getAllWallpapers();
        if (!keyword.trim()) {
            return allWallpapers;
        }
        const lowerKeyword = keyword.toLowerCase().trim();
        return allWallpapers.filter(wallpaper => wallpaper.name.toLowerCase().includes(lowerKeyword) ||
            wallpaper.sourceName.toLowerCase().includes(lowerKeyword));
    }
    /**
     * 获取壁纸源统计信息
     */
    public getWallpaperSourceStats(): Array<SourceStats> {
        const allWallpapers = this.getAllWallpapers();
        const statsMap = new Map<string, number>();
        allWallpapers.forEach(wallpaper => {
            const count = statsMap.get(wallpaper.sourceId) || 0;
            statsMap.set(wallpaper.sourceId, count + 1);
        });
        // 获取源名称
        const result: Array<SourceStats> = [];
        const entries = statsMap.entries();
        for (const entry of entries) {
            const sourceId: string = entry[0];
            const count: number = entry[1];
            const wallpaper = allWallpapers.find(wp => wp.sourceId === sourceId);
            if (wallpaper) {
                const stat: SourceStats = {
                    sourceId,
                    sourceName: wallpaper.sourceName,
                    count
                };
                result.push(stat);
            }
        }
        // 按数量降序排序
        return result.sort((a, b) => b.count - a.count);
    }
    // ========================================
    // 全局配置访问
    // ========================================
    /**
     * 获取所有广告过滤规则 (合并所有启用源)
     */
    public getAdBlockRules(): AdBlockRule[] {
        const rules: AdBlockRule[] = this.poolManager.getAdBlockRules().getRules();
        // 按类型分组并去重
        const uniqueRules: Map<string, AdBlockRule> = new Map<string, AdBlockRule>();
        rules.forEach((rule: AdBlockRule) => {
            const key: string = `${rule.type}_${rule.pattern}`;
            if (!uniqueRules.has(key)) {
                uniqueRules.set(key, rule);
            }
        });
        return Array.from(uniqueRules.values());
    }
    /**
     * 获取所有解码配置 (合并所有启用源)
     */
    public getDecoderConfigs(type?: string): DecoderConfig[] {
        return this.poolManager.getDecoderConfigs().getConfigs(type);
    }
    /**
     * 获取所有解析器配置
     */
    public getParserConfigs(): ParserConfig[] {
        return this.poolManager.getParserConfigs();
    }
    // ========================================
    // 私有辅助方法
    // ========================================
    /**
     * 应用点播站点筛选条件
     */
    private applyVodSiteFilters(sites: VodSiteWithSource[], options: ContentFilterOptions): VodSiteWithSource[] {
        let filtered = sites;
        // 按源筛选
        if (options.sourceIds && options.sourceIds.length > 0) {
            filtered = filtered.filter(site => options.sourceIds!.includes(site.sourceId));
        }
        // 按分类筛选
        if (options.categories && options.categories.length > 0) {
            filtered = filtered.filter(site => site.categories && site.categories.some(cat => options.categories!.includes(cat)));
        }
        // 按标记筛选
        if (options.flags && options.flags.length > 0) {
            filtered = filtered.filter(site => site.flags && site.flags.some(flag => options.flags!.includes(flag)));
        }
        // 按标签筛选
        if (options.tags && options.tags.length > 0) {
            filtered = filtered.filter(site => site.sourceTags && site.sourceTags.some(tag => options.tags!.includes(tag)));
        }
        // 按优先级筛选
        if (options.minPriority !== undefined) {
            filtered = filtered.filter(site => site.sourcePriority >= options.minPriority!);
        }
        return filtered;
    }
    /**
     * 应用直播频道筛选条件
     */
    private applyLiveChannelFilters(channels: LiveChannelWithSource[], options: ContentFilterOptions): LiveChannelWithSource[] {
        let filtered = channels;
        // 按源筛选
        if (options.sourceIds && options.sourceIds.length > 0) {
            filtered = filtered.filter(channel => options.sourceIds!.includes(channel.sourceId));
        }
        // 按分类筛选
        if (options.categories && options.categories.length > 0) {
            filtered = filtered.filter(channel => options.categories!.includes(channel.group));
        }
        // 按优先级筛选
        if (options.minPriority !== undefined) {
            // 直播频道没有优先级,这里可以通过源优先级筛选
            // 暂时不实现
        }
        return filtered;
    }
    // ========================================
    // 统计信息
    // ========================================
    /**
     * 获取整体统计信息
     */
    public getOverallStats(): OverallStats {
        const stats: OverallStats = {
            vodSources: this.getVodSourceStats().length,
            vodSites: this.getAllVodSites().length,
            vodCategories: this.getVodSiteCategories().length,
            liveSources: this.getLiveSourceStats().length,
            liveChannels: this.getAllLiveChannels().length,
            liveCategories: this.getLiveCategories().length,
            wallpaperSources: this.getWallpaperSourceStats().length,
            wallpapers: this.getAllWallpapers().length,
            adBlockRules: this.getAdBlockRules().length,
            decoderConfigs: this.getDecoderConfigs().length
        };
        return stats;
    }
}
// 导出单例实例
export default ContentAccessService.getInstance();
