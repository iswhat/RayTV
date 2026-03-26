import ApiResponse from "@bundle:com.raytv.app/raytv/ets/data/dto/ApiResponse";
import type { SiteService } from '../spider/SiteService_fixed';
import { CrawlerService } from "@bundle:com.raytv.app/raytv/ets/service/spider/CrawlerService";
import { Inject } from "@bundle:com.raytv.app/raytv/ets/common/di/Container";
import CacheService from "@bundle:com.raytv.app/raytv/ets/service/cache/CacheService";
import { CachePriority } from "@bundle:com.raytv.app/raytv/ets/service/cache/CacheService";
// 常量定义 | Constant definition
const TAG = 'MediaService';
// 播放记录接口 | Playback record interface
export interface PlaybackRecord {
    mediaId: string;
    title: string;
    episodeName?: string;
    position: number;
    duration: number;
    lastPlayedAt: number;
    completed: boolean;
}
// 媒体信息接口 | Media info interface
export interface MediaInfo {
    mediaId: string;
    title: string;
    type: string;
    cover?: string;
    siteKey: string;
    addedAt: number;
}
// 站点返回的推荐内容接口 | Site returned recommended content interface
export interface SiteRecommendedItem {
    id: string;
    title: string;
    cover?: string;
    type: string;
    rating?: string;
}
// 推荐内容接口 | Recommended content interface
export interface RecommendedContent {
    id: string;
    title: string;
    cover?: string;
    type: string;
    siteKey: string;
    rating?: string;
    score?: number; // 推荐分数
}
// 用户行为接口 | User behavior interface
export interface UserBehavior {
    mediaId: string;
    type: 'play' | 'collect' | 'click' | 'search';
    timestamp: number;
    duration?: number; // 观看时长
    completed?: boolean; // 是否完成观看
}
// 用户偏好接口 | User preference interface
export interface UserPreference {
    mediaType: string;
    weight: number;
}
// 推荐算法配置接口 | Recommendation algorithm config interface
export interface RecommendationConfig {
    popularWeight: number;
    recentWeight: number;
    personalWeight: number;
    diversityWeight: number;
    maxRecommendations: number;
}
// 站点接口 | Site interface
export interface Site {
    key: string;
    name: string;
    enabled: boolean;
}
/**
 * 媒体服务类 | Media service class
 * 实现媒体管理功能，包括播放记录、收藏管理等 | Implement media management functions, including playback records, collection management, etc.
 */
export class MediaService {
    private static instance: MediaService | null = null;
    private playbackRecords: Map<string, PlaybackRecord> = new Map();
    private collections: Map<string, MediaInfo> = new Map();
    private userBehaviors: UserBehavior[] = [];
    private userPreferences: UserPreference[] = [];
    private recommendationConfig: RecommendationConfig = {
        popularWeight: 0.3,
        recentWeight: 0.2,
        personalWeight: 0.4,
        diversityWeight: 0.1,
        maxRecommendations: 20
    };
    private isInitialized: boolean = false;
    private progressSyncInterval: number | null = null;
    private cacheService: CacheService = CacheService.getInstance();
    @Inject('SiteService')
    private siteService!: SiteService;
    /**
     * 获取单例实例 | Get singleton instance
     */
    public static getInstance(): MediaService {
        if (!MediaService.instance) {
            MediaService.instance = new MediaService();
        }
        return MediaService.instance;
    }
    /**
     * 构造函数 | Constructor
     */
    private constructor() {
        // 直接初始化，不依赖ConfigService | Initialize directly, not dependent on ConfigService
    }
    /**
     * 初始化服务实例 | Initialize service instance
     */
    public async initialize(): Promise<void> {
        if (this.isInitialized) {
            return;
        }
        try {
            console.info(TAG + ': Initializing media service...');
            // 初始化数据结构 | Initialize data structure
            this.playbackRecords = new Map();
            this.collections = new Map();
            this.userBehaviors = [];
            this.userPreferences = [];
            // 启动进度同步 | Start progress sync
            this.startProgressSync();
            this.isInitialized = true;
            console.info(TAG + ': Media service initialized successfully');
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            console.error(error.message);
            throw err;
        }
    }
    /**
     * 开始进度同步 | Start progress sync
     */
    private startProgressSync(): void {
        // 实现进度同步逻辑 | Implement progress sync logic
        this.progressSyncInterval = setInterval(() => {
            // 简单的进度同步日志，不持久化存储 | Simple progress sync log, not persistent storage
            console.info(TAG + `: Progress sync completed at ${new Date().toISOString()}`);
        }, 30000); // 每30秒同步一次 | Sync every 30 seconds
    }
    /**
     * 停止进度同步 | Stop progress sync
     */
    private stopProgressSync(): void {
        if (this.progressSyncInterval) {
            clearInterval(this.progressSyncInterval);
            this.progressSyncInterval = null;
        }
    }
    /**
     * 更新播放记录 | Update playback record
     */
    public updatePlaybackRecord(mediaId: string, record: PlaybackRecord): void {
        this.playbackRecords.set(mediaId, record);
    }
    /**
     * 获取播放记录 | Get playback record
     */
    public getPlaybackRecord(mediaId: string): PlaybackRecord | undefined {
        return this.playbackRecords.get(mediaId);
    }
    /**
     * 删除播放记录 | Delete playback record
     */
    public deletePlaybackRecord(mediaId: string): void {
        this.playbackRecords.delete(mediaId);
    }
    /**
     * 获取所有播放记录 | Get all playback records
     */
    public getAllPlaybackRecords(): Map<string, PlaybackRecord> {
        return this.playbackRecords;
    }
    /**
     * 添加到收藏 | Add to collection
     */
    public addToCollection(mediaId: string, mediaInfo: MediaInfo): void {
        this.collections.set(mediaId, mediaInfo);
    }
    /**
     * 从收藏中删除 | Remove from collection
     */
    public removeFromCollection(mediaId: string): void {
        this.collections.delete(mediaId);
    }
    /**
     * 检查是否已收藏 | Check if collected
     */
    public isCollected(mediaId: string): boolean {
        return this.collections.has(mediaId);
    }
    /**
     * 获取所有收藏 | Get all collections
     */
    public getAllCollections(): Map<string, MediaInfo> {
        return this.collections;
    }
    /**
     * 获取推荐内容 | Get recommended content
     */
    /**
     * 通用内容获取方法
     */
    private async fetchContent(contentType: string, cacheKey: string, siteMethod: string, cacheExpiry: number, cacheTags: string[], successMessage: string, errorMessage: string): Promise<ApiResponse<RecommendedContent[]>> {
        try {
            console.info(TAG + `: Getting ${contentType} content...`);
            // 验证依赖服务是否可用
            if (!this.cacheService) {
                console.error(TAG + ': Cache service not available');
                return ApiResponse.error(500, '缓存服务不可用');
            }
            if (!this.siteService) {
                console.error(TAG + ': Site service not available');
                return ApiResponse.error(500, '站点服务不可用');
            }
            // 尝试从缓存获取
            try {
                const cachedData = await this.cacheService.get<RecommendedContent[]>(cacheKey);
                if (cachedData && Array.isArray(cachedData) && cachedData.length > 0) {
                    console.info(TAG + `: Loaded ${contentType} content from cache`);
                    return ApiResponse.success(cachedData, successMessage);
                }
            }
            catch (cacheError) {
                const err = cacheError instanceof Error ? cacheError : new Error(String(cacheError));
                console.warn(TAG + ': Failed to get cached content:', err);
                // 缓存失败不影响主流程，继续从站点获取
            }
            // 从实际站点获取内容
            // 1. 获取所有启用的站点
            let enabledSites: Site[] = [];
            try {
                enabledSites = await this.siteService.getEnabledSites();
            }
            catch (siteError) {
                const err = siteError instanceof Error ? siteError : new Error(String(siteError));
                console.error(TAG + ': Failed to get enabled sites:', err);
                return ApiResponse.success([], successMessage);
            }
            // 2. 如果没有启用的站点，返回空列表
            if (!Array.isArray(enabledSites) || enabledSites.length === 0) {
                console.warn(TAG + ': No enabled sites found');
                return ApiResponse.success([], successMessage);
            }
            // 3. 从每个启用的站点获取内容（并行请求）
            const sitePromises = enabledSites.map(async (site) => {
                try {
                    // 验证站点数据完整性
                    if (!site || !site.key || !site.name) {
                        console.warn(TAG + ': Invalid site data');
                        return [];
                    }
                    // 调用站点的内容方法
                    const siteContent = await CrawlerService.getInstance().callSiteMethod<SiteRecommendedItem[]>(site.key, siteMethod, [], { timeout: 10000 }) as SiteRecommendedItem[];
                    if (Array.isArray(siteContent) && siteContent.length > 0) {
                        // 添加站点标识并处理结果
                        return siteContent
                            .filter(item => item && typeof item === 'object')
                            .map(item => {
                            const recommendedItem: RecommendedContent = {
                                id: item.id || '',
                                title: item.title || '',
                                cover: item.cover,
                                type: item.type || '',
                                siteKey: site.key,
                                rating: item.rating
                            };
                            return recommendedItem;
                        });
                    }
                    return [];
                }
                catch (error) {
                    const errorMessage = error instanceof Error ? error.message : String(error);
                    console.warn(TAG + `: Failed to get ${contentType} content from site ${site?.name || 'unknown'}: ${errorMessage}`);
                    return [];
                }
            });
            // 等待所有请求完成
            let siteResults: Array<Array<RecommendedContent>> = [];
            try {
                siteResults = await Promise.all(sitePromises);
            }
            catch (promiseError) {
                const err = promiseError instanceof Error ? promiseError : new Error(String(promiseError));
                console.error(TAG + `: Failed to get site ${contentType} content:`, err);
                return ApiResponse.success([], successMessage);
            }
            // 合并结果
            const content = Array.isArray(siteResults) ? siteResults.flat() : [];
            // 4. 如果没有获取到内容，返回空数据
            if (!Array.isArray(content) || content.length === 0) {
                console.warn(TAG + `: No ${contentType} content found from any site`);
                return ApiResponse.success([], successMessage);
            }
            // 缓存结果
            try {
                await this.cacheService.set(cacheKey, content, {
                    expiry: cacheExpiry,
                    priority: CachePriority.HIGH,
                    tags: cacheTags
                });
            }
            catch (cacheError) {
                const err = cacheError instanceof Error ? cacheError : new Error(String(cacheError));
                console.error(TAG + `: Failed to cache ${contentType} content:`, err);
                // 缓存失败不影响主流程
            }
            console.info(TAG + `: Retrieved ${content.length} ${contentType} content items from ${enabledSites.length} sites`);
            return ApiResponse.success(content, successMessage);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            console.error(TAG + `: Failed to get ${contentType} content: ${errorMessage}`);
            return ApiResponse.error(500, errorMessage);
        }
    }
    /**
     * 获取推荐内容 | Get recommended content
     */
    public async getRecommendedContent(): Promise<ApiResponse<RecommendedContent[]>> {
        return this.fetchContent('recommended', 'recommended_content', 'getRecommendations', 300000, // 5分钟缓存
        ['recommended', 'content'], '获取推荐内容成功', '获取推荐内容失败');
    }
    /**
     * 获取热门内容 | Get popular content
     */
    public async getPopularContent(): Promise<ApiResponse<RecommendedContent[]>> {
        return this.fetchContent('popular', 'popular_content', 'getPopularContent', 600000, // 10分钟缓存
        ['popular', 'content'], '获取热门内容成功', '获取热门内容失败');
    }
    /**
     * 获取最新上线内容 | Get new content
     */
    public async getNewContent(): Promise<ApiResponse<RecommendedContent[]>> {
        return this.fetchContent('new', 'new_content', 'getNewContent', 1800000, // 30分钟缓存
        ['new', 'content'], '获取最新上线内容成功', '获取最新上线内容失败');
    }
    /**
     * 记录用户行为 | Record user behavior
     */
    public recordUserBehavior(behavior: UserBehavior): void {
        this.userBehaviors.push(behavior);
        // 限制行为记录数量，防止内存占用过大
        if (this.userBehaviors.length > 1000) {
            this.userBehaviors = this.userBehaviors.slice(-1000);
        }
        // 分析用户偏好
        this.analyzeUserPreferences();
    }
    /**
     * 分析用户偏好 | Analyze user preferences
     */
    private analyzeUserPreferences(): void {
        const typeCount: Map<string, number> = new Map();
        let totalInteractions = 0;
        // 统计各类型媒体的交互次数
        for (const behavior of this.userBehaviors) {
            // 这里简化处理，假设行为中包含类型信息
            // 实际应用中可能需要从媒体信息中获取类型
            const mediaType = 'movie'; // 临时值，实际应该从媒体信息中获取
            typeCount.set(mediaType, (typeCount.get(mediaType) || 0) + 1);
            totalInteractions++;
        }
        // 计算各类型的权重
        this.userPreferences = [];
        const types: string[] = Array.from(typeCount.keys());
        for (let i = 0; i < types.length; i++) {
            const type = types[i];
            const count = typeCount.get(type);
            if (count) {
                const weight = totalInteractions > 0 ? count / totalInteractions : 0;
                this.userPreferences.push({ mediaType: type, weight });
            }
        }
        // 按权重排序
        this.userPreferences.sort((a, b) => b.weight - a.weight);
    }
    /**
     * 计算推荐分数 | Calculate recommendation score
     */
    private calculateRecommendationScore(content: RecommendedContent): number {
        let score = 0;
        // 基础分数：基于评分
        if (content.rating) {
            const rating = parseFloat(content.rating);
            if (!isNaN(rating)) {
                score += rating * 0.2;
            }
        }
        // 个性化分数：基于用户偏好
        const userPreference = this.userPreferences.find(pref => pref.mediaType === content.type);
        if (userPreference) {
            score += userPreference.weight * 0.4;
        }
        // 多样性分数：确保推荐内容多样化
        score += 0.1; // 基础多样性分数
        return score;
    }
    /**
     * 优化推荐内容 | Optimize recommended content
     */
    private optimizeRecommendations(contentList: RecommendedContent[]): RecommendedContent[] {
        // 计算每个内容的推荐分数
        interface ContentWithScore extends RecommendedContent {
            score: number;
        }
        const contentWithScores: ContentWithScore[] = contentList.map((content): ContentWithScore => {
            const score = this.calculateRecommendationScore(content);
            const contentWithScore: ContentWithScore = {
                id: content.id,
                title: content.title,
                cover: content.cover,
                type: content.type,
                siteKey: content.siteKey,
                rating: content.rating,
                score: score
            };
            return contentWithScore;
        });
        // 按分数排序
        contentWithScores.sort((a, b) => (b.score || 0) - (a.score || 0));
        // 限制推荐数量
        return contentWithScores.slice(0, this.recommendationConfig.maxRecommendations);
    }
    /**
     * 获取个性化推荐内容 | Get personalized recommended content
     */
    public async getPersonalizedRecommendations(): Promise<ApiResponse<RecommendedContent[]>> {
        try {
            console.info(TAG + ': Getting personalized recommendations...');
            // 获取基础推荐内容
            const basicRecommendations = await this.getRecommendedContent();
            if (!basicRecommendations.isSuccess() || !basicRecommendations.data) {
                return ApiResponse.success([], '获取个性化推荐内容成功');
            }
            // 优化推荐内容
            const optimizedRecommendations = this.optimizeRecommendations(basicRecommendations.data);
            console.info(TAG + `: Generated ${optimizedRecommendations.length} personalized recommendations`);
            return ApiResponse.success(optimizedRecommendations, '获取个性化推荐内容成功');
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            console.error(error.message);
            return ApiResponse.error(500, '获取个性化推荐内容失败');
        }
    }
    /**
     * 关闭媒体服务 Close media service
     */
    public close(): void {
        if (!this.isInitialized) {
            return;
        }
        this.stopProgressSync();
        // 清理数据 Clean up data
        this.playbackRecords.clear();
        this.collections.clear();
        this.userBehaviors = [];
        this.userPreferences = [];
        this.isInitialized = false;
        console.info(TAG + ': Media service closed successfully');
    }
}
// 导出类和单例实例 Export class and singleton instance
export default MediaService;
export const mediaService = MediaService.getInstance();
