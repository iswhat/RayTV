/**
 * Local Recommendation Algorithm - 本地推荐算法实现
 * 
 * 基于用户行为和内容特征生成推荐，不依赖外部API
 * 支持多种推荐策略：协同过滤、内容推荐、流行度推荐等
 */

import Logger from '../../common/util/Logger';
import ContentAccessService from './ContentAccessService';
import { VodSiteWithSource, LiveChannelWithSource } from './SourcePoolManager';
import { RecommendationItem, RecommendationType, UserPreferences } from '../data/repository/RecommendationRepository';

// ========================================
// 推荐算法相关接口
// ========================================

/**
 * 内容特征向量
 */
export interface ContentFeature {
  id: string;
  title: string;
  category?: string;
  tags: string[];
  duration?: number;
  popularity: number;      // 热门程度 (0-1)
  freshness: number;        // 新鲜度 (0-1)
  viewCount?: number;
  releaseDate?: number;
}

/**
 * 用户行为记录
 */
export interface UserBehavior {
  videoId: string;
  action: 'view' | 'play' | 'like' | 'share' | 'search' | 'complete';
  timestamp: number;
  duration?: number;        // 观看时长
  totalDuration?: number;   // 总时长
  progress?: number;        // 观看进度
}

/**
 * 用户画像
 */
export interface UserProfile {
  userId: string;
  preferredCategories: Map<string, number>;  // 分类偏好权重
  preferredTags: Map<string, number>;        // 标签偏好权重
  viewingPatterns: {
    avgSessionDuration: number;             // 平均会话时长
    preferredTimeSlots: number[];            // 偏好时间段
    completionRate: number;                 // 完成率
  };
  watchedHistory: string[];                  // 已观看视频ID列表
  likedContent: string[];                   // 喜欢的内容ID
}

/**
 * 推荐得分结果
 */
export interface RecommendationScore {
  contentId: string;
  score: number;
  reasons: string[];                        // 推荐理由
  algorithm: string;                        // 使用的算法
}

// ========================================
// 本地推荐算法类
// ========================================

export class LocalRecommendationAlgorithm {
  private static instance: LocalRecommendationAlgorithm;
  private logger: Logger;
  private contentService: ContentAccessService;
  
  // 用户行为缓存
  private userBehaviors: Map<string, UserBehavior[]> = new Map();
  
  // 用户画像缓存
  private userProfile: UserProfile | null = null;
  
  // 内容特征缓存
  private contentFeaturesCache: Map<string, ContentFeature> = new Map();
  private cacheExpiry: number = 0;
  
  // 推荐配置
  private readonly weights = {
    collaborative: 0.35,    // 协同过滤权重
    contentBased: 0.30,     // 基于内容推荐权重
    popularity: 0.20,       // 流行度推荐权重
    freshness: 0.10,        // 新鲜度推荐权重
    diversity: 0.05         // 多样性推荐权重
  };
  
  private constructor() {
    this.logger = Logger.getInstance('LocalRecommendationAlgorithm');
    this.contentService = ContentAccessService.getInstance();
    this.logger.info('LocalRecommendationAlgorithm initialized');
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): LocalRecommendationAlgorithm {
    if (!LocalRecommendationAlgorithm.instance) {
      LocalRecommendationAlgorithm.instance = new LocalRecommendationAlgorithm();
    }
    return LocalRecommendationAlgorithm.instance;
  }
  
  /**
   * 初始化算法
   */
  public async initialize(): Promise<void> {
    try {
      // 加载用户行为历史
      await this.loadUserBehaviors();
      
      // 构建用户画像
      await this.buildUserProfile();
      
      this.logger.info('LocalRecommendationAlgorithm initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize LocalRecommendationAlgorithm', error as Error);
    }
  }
  
  /**
   * 生成个性化推荐
   */
  public async generatePersonalizedRecommendations(
    limit: number = 20,
    excludeIds?: string[]
  ): Promise<RecommendationItem[]> {
    try {
      // 检查用户行为数据是否足够
      const behaviors = this.getRecentBehaviors(50);
      if (behaviors.length < 3) {
        // 行为数据不足，返回热门推荐
        return await this.generateTrendingRecommendations(limit, excludeIds);
      }
      
      // 获取所有内容
      const allContents = await this.getAllContentFeatures();
      
      // 计算推荐得分
      const scores = await this.calculateRecommendationScores(allContents, excludeIds);
      
      // 应用多样性过滤
      const diversifiedScores = this.applyDiversification(scores);
      
      // 排序并取前N个
      const topScores = diversifiedScores
        .sort((a, b) => b.score - a.score)
        .slice(0, limit);
      
      // 转换为推荐项
      return this.convertToRecommendationItems(topScores);
    } catch (error) {
      this.logger.error('Failed to generate personalized recommendations', error as Error);
      return [];
    }
  }
  
  /**
   * 生成热门推荐
   */
  public async generateTrendingRecommendations(
    limit: number = 20,
    excludeIds?: string[]
  ): Promise<RecommendationItem[]> {
    try {
      const allContents = await this.getAllContentFeatures();
      
      // 基于流行度和新鲜度排序
      const trendingScores: RecommendationScore[] = [];
      
      for (const content of allContents) {
        if (excludeIds && excludeIds.includes(content.id)) {
          continue;
        }
        
        const popularityScore = content.popularity * 0.7;
        const freshnessScore = content.freshness * 0.3;
        const totalScore = popularityScore + freshnessScore;
        
        trendingScores.push({
          contentId: content.id,
          score: totalScore,
          reasons: [`流行度: ${(content.popularity * 100).toFixed(0)}%`, `新鲜度: ${(content.freshness * 100).toFixed(0)}%`],
          algorithm: 'trending'
        });
      }
      
      // 排序并取前N个
      const topScores = trendingScores
        .sort((a, b) => b.score - a.score)
        .slice(0, limit);
      
      return this.convertToRecommendationItems(topScores);
    } catch (error) {
      this.logger.error('Failed to generate trending recommendations', error as Error);
      return [];
    }
  }
  
  /**
   * 生成相似内容推荐
   */
  public async generateSimilarRecommendations(
    videoId: string,
    limit: number = 10,
    excludeIds?: string[]
  ): Promise<RecommendationItem[]> {
    try {
      // 获取目标内容的特征
      const targetFeature = await this.getContentFeature(videoId);
      if (!targetFeature) {
        return [];
      }
      
      // 获取所有内容
      const allContents = await this.getAllContentFeatures();
      
      // 计算相似度
      const similarityScores: RecommendationScore[] = [];
      
      for (const content of allContents) {
        if (content.id === videoId) {
          continue;
        }
        
        if (excludeIds && excludeIds.includes(content.id)) {
          continue;
        }
        
        const similarity = this.calculateContentSimilarity(targetFeature, content);
        
        similarityScores.push({
          contentId: content.id,
          score: similarity,
          reasons: [`相似度: ${(similarity * 100).toFixed(0)}%`],
          algorithm: 'similarity'
        });
      }
      
      // 排序并取前N个
      const topScores = similarityScores
        .sort((a, b) => b.score - a.score)
        .slice(0, limit);
      
      return this.convertToRecommendationItems(topScores);
    } catch (error) {
      this.logger.error('Failed to generate similar recommendations', error as Error);
      return [];
    }
  }
  
  /**
   * 生成继续观看推荐
   */
  public async generateContinueWatchingRecommendations(
    limit: number = 10
  ): Promise<RecommendationItem[]> {
    try {
      const behaviors = this.getRecentBehaviors(100);
      
      // 过滤出有播放进度的内容
      const continueWatchingItems = behaviors
        .filter(b => 
          b.action === 'play' && 
          b.progress !== undefined && 
          b.totalDuration !== undefined &&
          b.progress < b.totalDuration * 0.9  // 进度小于90%
        )
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, limit);
      
      // 转换为推荐项
      const recommendationItems: RecommendationItem[] = [];
      
      for (const behavior of continueWatchingItems) {
        const feature = await this.getContentFeature(behavior.videoId);
        if (feature) {
          const progressPercent = behavior.totalDuration 
            ? ((behavior.progress || 0) / behavior.totalDuration * 100).toFixed(0)
            : '0';
          
          recommendationItems.push({
            id: behavior.videoId,
            type: 'video',
            data: {
              id: feature.id,
              title: feature.title,
              category: feature.category,
              tags: feature.tags,
              progress: behavior.progress,
              totalDuration: behavior.totalDuration
            },
            reason: `观看进度: ${progressPercent}%`,
            score: 0.8,
            tags: ['continue-watching'],
            category: feature.category,
            duration: feature.duration
          });
        }
      }
      
      return recommendationItems;
    } catch (error) {
      this.logger.error('Failed to generate continue watching recommendations', error as Error);
      return [];
    }
  }
  
  /**
   * 生成新发布推荐
   */
  public async generateNewReleasesRecommendations(
    limit: number = 20,
    excludeIds?: string[]
  ): Promise<RecommendationItem[]> {
    try {
      const allContents = await this.getAllContentFeatures();
      
      // 按发布时间排序
      const newScores: RecommendationScore[] = [];
      
      for (const content of allContents) {
        if (excludeIds && excludeIds.includes(content.id)) {
          continue;
        }
        
        const score = content.freshness;
        
        newScores.push({
          contentId: content.id,
          score: score,
          reasons: [`新鲜度: ${(content.freshness * 100).toFixed(0)}%`],
          algorithm: 'freshness'
        });
      }
      
      // 排序并取前N个
      const topScores = newScores
        .sort((a, b) => b.score - a.score)
        .slice(0, limit);
      
      return this.convertToRecommendationItems(topScores);
    } catch (error) {
      this.logger.error('Failed to generate new releases recommendations', error as Error);
      return [];
    }
  }
  
  /**
   * 记录用户行为
   */
  public recordUserBehavior(behavior: UserBehavior): void {
    const key = behavior.videoId;
    
    if (!this.userBehaviors.has(key)) {
      this.userBehaviors.set(key, []);
    }
    
    const behaviors = this.userBehaviors.get(key) || [];
    behaviors.push(behavior);
    
    // 只保留最近100条行为
    if (behaviors.length > 100) {
      behaviors.shift();
    }
    
    this.userBehaviors.set(key, behaviors);
    
    // 异步保存到存储
    this.saveUserBehaviors().catch(err => {
      this.logger.warn('Failed to save user behaviors', err);
    });
  }
  
  // ========================================
  // 私有方法
  // ========================================
  
  /**
   * 加载用户行为历史
   */
  private async loadUserBehaviors(): Promise<void> {
    // TODO: 从本地存储加载用户行为
    this.logger.debug('User behaviors loaded');
  }
  
  /**
   * 保存用户行为
   */
  private async saveUserBehaviors(): Promise<void> {
    // TODO: 保存用户行为到本地存储
    this.logger.debug('User behaviors saved');
  }
  
  /**
   * 构建用户画像
   */
  private async buildUserProfile(): Promise<void> {
    const behaviors = this.getRecentBehaviors(100);
    
    const preferredCategories = new Map<string, number>();
    const preferredTags = new Map<string, number>();
    const watchedHistory: string[] = [];
    const likedContent: string[] = [];
    
    let totalDuration = 0;
    let completedCount = 0;
    let totalCount = 0;
    
    for (const behavior of behaviors) {
      // 提取内容特征
      const feature = await this.getContentFeature(behavior.videoId);
      if (!feature) {
        continue;
      }
      
      // 更新分类偏好
      if (feature.category) {
        const currentScore = preferredCategories.get(feature.category) || 0;
        preferredCategories.set(feature.category, currentScore + 1);
      }
      
      // 更新标签偏好
      for (const tag of feature.tags) {
        const currentScore = preferredTags.get(tag) || 0;
        preferredTags.set(tag, currentScore + 1);
      }
      
      // 更新观看历史
      if (!watchedHistory.includes(behavior.videoId)) {
        watchedHistory.push(behavior.videoId);
      }
      
      // 更新喜欢的内容
      if (behavior.action === 'like' || behavior.action === 'complete') {
        likedContent.push(behavior.videoId);
      }
      
      // 计算统计信息
      if (behavior.duration) {
        totalDuration += behavior.duration;
      }
      
      if (behavior.action === 'complete') {
        completedCount++;
      }
      totalCount++;
    }
    
    // 归一化偏好权重
    this.normalizeWeights(preferredCategories);
    this.normalizeWeights(preferredTags);
    
    // 计算完成率
    const completionRate = totalCount > 0 ? completedCount / totalCount : 0;
    
    // 构建用户画像
    this.userProfile = {
      userId: 'current_user',
      preferredCategories,
      preferredTags,
      viewingPatterns: {
        avgSessionDuration: totalCount > 0 ? totalDuration / totalCount : 0,
        preferredTimeSlots: [],
        completionRate
      },
      watchedHistory,
      likedContent
    };
  }
  
  /**
   * 归一化权重
   */
  private normalizeWeights(weights: Map<string, number>): void {
    const total = Array.from(weights.values()).reduce((sum, val) => sum + val, 0);
    
    if (total > 0) {
      for (const [key, value] of weights.entries()) {
        weights.set(key, value / total);
      }
    }
  }
  
  /**
   * 获取最近的用户行为
   */
  private getRecentBehaviors(count: number): UserBehavior[] {
    const allBehaviors: UserBehavior[] = [];
    
    for (const behaviors of this.userBehaviors.values()) {
      allBehaviors.push(...behaviors);
    }
    
    // 按时间排序，取最近的N条
    return allBehaviors
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice(0, count);
  }
  
  /**
   * 获取所有内容特征
   */
  private async getAllContentFeatures(): Promise<ContentFeature[]> {
    // 检查缓存
    if (Date.now() < this.cacheExpiry && this.contentFeaturesCache.size > 0) {
      return Array.from(this.contentFeaturesCache.values());
    }
    
    try {
      // 从ContentAccessService获取内容
      const vodSites = this.contentService.getAllVodSites();
      const liveChannels = this.contentService.getAllLiveChannels();
      
      const features: ContentFeature[] = [];
      
      // 转换点播站点特征
      for (const site of vodSites) {
        const feature = this.extractVodSiteFeature(site);
        features.push(feature);
        this.contentFeaturesCache.set(feature.id, feature);
      }
      
      // 转换直播频道特征
      for (const channel of liveChannels) {
        const feature = this.extractLiveChannelFeature(channel);
        features.push(feature);
        this.contentFeaturesCache.set(feature.id, feature);
      }
      
      // 更新缓存过期时间（10分钟）
      this.cacheExpiry = Date.now() + 10 * 60 * 1000;
      
      this.logger.info(`Loaded ${features.length} content features`);
      
      return features;
    } catch (error) {
      this.logger.error('Failed to get all content features', error as Error);
      return [];
    }
  }
  
  /**
   * 提取点播站点特征
   */
  private extractVodSiteFeature(site: VodSiteWithSource): ContentFeature {
    return {
      id: site.id,
      title: site.name,
      category: site.type,
      tags: site.tags || [],
      popularity: this.calculatePopularity(site),
      freshness: this.calculateFreshness(site.lastUpdated),
      releaseDate: site.lastUpdated
    };
  }
  
  /**
   * 提取直播频道特征
   */
  private extractLiveChannelFeature(channel: LiveChannelWithSource): ContentFeature {
    return {
      id: channel.id,
      title: channel.name,
      category: channel.category,
      tags: channel.tags || [],
      popularity: this.calculatePopularity(channel),
      freshness: 1.0,  // 直播总是新鲜的
      releaseDate: Date.now()
    };
  }
  
  /**
   * 计算流行度
   */
  private calculatePopularity(item: VodSiteWithSource | LiveChannelWithSource): number {
    // 基于观看次数、喜欢次数等计算
    // 这里使用简化的计算方式
    const baseScore = 0.5;
    const randomFactor = Math.random() * 0.3;  // 模拟随机性
    return Math.min(1.0, baseScore + randomFactor);
  }
  
  /**
   * 计算新鲜度
   */
  private calculateFreshness(timestamp?: number): number {
    if (!timestamp) {
      return 0.5;
    }
    
    const now = Date.now();
    const daysSinceUpdate = (now - timestamp) / (24 * 60 * 60 * 1000);
    
    // 7天内为最新，30天后为陈旧
    if (daysSinceUpdate < 7) {
      return 1.0;
    } else if (daysSinceUpdate < 30) {
      return 1.0 - (daysSinceUpdate - 7) / 23 * 0.5;
    } else {
      return 0.5;
    }
  }
  
  /**
   * 获取内容特征
   */
  private async getContentFeature(contentId: string): Promise<ContentFeature | null> {
    const allFeatures = await this.getAllContentFeatures();
    return allFeatures.find(f => f.id === contentId) || null;
  }
  
  /**
   * 计算推荐得分
   */
  private async calculateRecommendationScores(
    contents: ContentFeature[],
    excludeIds?: string[]
  ): Promise<RecommendationScore[]> {
    const scores: RecommendationScore[] = [];
    const userProfile = this.userProfile;
    
    if (!userProfile) {
      return scores;
    }
    
    for (const content of contents) {
      if (excludeIds && excludeIds.includes(content.id)) {
        continue;
      }
      
      if (userProfile.watchedHistory.includes(content.id)) {
        continue;
      }
      
      const collaborativeScore = this.calculateCollaborativeScore(content, userProfile);
      const contentBasedScore = this.calculateContentBasedScore(content, userProfile);
      const popularityScore = content.popularity;
      const freshnessScore = content.freshness;
      
      const totalScore = 
        collaborativeScore * this.weights.collaborative +
        contentBasedScore * this.weights.contentBased +
        popularityScore * this.weights.popularity +
        freshnessScore * this.weights.freshness;
      
      const reasons: string[] = [];
      if (collaborativeScore > 0.3) reasons.push('基于您的观看历史');
      if (contentBasedScore > 0.3) reasons.push('符合您的喜好');
      if (popularityScore > 0.5) reasons.push('热门内容');
      if (freshnessScore > 0.5) reasons.push('新发布');
      
      scores.push({
        contentId: content.id,
        score: totalScore,
        reasons,
        algorithm: 'personalized'
      });
    }
    
    return scores;
  }
  
  /**
   * 计算协同过滤得分
   */
  private calculateCollaborativeScore(content: ContentFeature, userProfile: UserProfile): number {
    // 简化的协同过滤算法
    // 实际应用中可以使用矩阵分解等算法
    
    // 检查是否喜欢类似的内容
    let score = 0;
    
    for (const likedId of userProfile.likedContent) {
      const likedFeature = this.contentFeaturesCache.get(likedId);
      if (likedFeature) {
        const similarity = this.calculateContentSimilarity(likedFeature, content);
        score += similarity;
      }
    }
    
    // 归一化
    return Math.min(1.0, score / userProfile.likedContent.length);
  }
  
  /**
   * 计算基于内容的推荐得分
   */
  private calculateContentBasedScore(content: ContentFeature, userProfile: UserProfile): number {
    let categoryScore = 0;
    let tagScore = 0;
    
    // 分类匹配
    if (content.category) {
      categoryScore = userProfile.preferredCategories.get(content.category) || 0;
    }
    
    // 标签匹配
    for (const tag of content.tags) {
      tagScore += userProfile.preferredTags.get(tag) || 0;
    }
    
    if (content.tags.length > 0) {
      tagScore /= content.tags.length;
    }
    
    return (categoryScore + tagScore) / 2;
  }
  
  /**
   * 计算内容相似度
   */
  private calculateContentSimilarity(feature1: ContentFeature, feature2: ContentFeature): number {
    // 分类相似度
    const categorySimilarity = feature1.category === feature2.category ? 1.0 : 0.0;
    
    // 标签相似度（Jaccard相似度）
    const tags1 = new Set(feature1.tags);
    const tags2 = new Set(feature2.tags);
    
    const intersection = new Set([...tags1].filter(x => tags2.has(x)));
    const union = new Set([...tags1, ...tags2]);
    
    const tagSimilarity = union.size > 0 ? intersection.size / union.size : 0.0;
    
    // 综合相似度
    return categorySimilarity * 0.4 + tagSimilarity * 0.6;
  }
  
  /**
   * 应用多样性过滤
   */
  private applyDiversification(scores: RecommendationScore[]): RecommendationScore[] {
    // 使用MMR (Maximal Marginal Relevance)算法增加多样性
    const diversified: RecommendationScore[] = [];
    const remaining = [...scores];
    
    if (remaining.length === 0) {
      return diversified;
    }
    
    // 选择得分最高的作为第一个
    remaining.sort((a, b) => b.score - a.score);
    diversified.push(remaining.shift()!);
    
    while (remaining.length > 0 && diversified.length < scores.length) {
      let bestIndex = -1;
      let bestScore = -Infinity;
      
      for (let i = 0; i < remaining.length; i++) {
        const item = remaining[i];
        
        // 计算与已选项目的最小相似度
        let minSimilarity = Infinity;
        for (const selected of diversified) {
          const feature1 = this.contentFeaturesCache.get(item.contentId);
          const feature2 = this.contentFeaturesCache.get(selected.contentId);
          
          if (feature1 && feature2) {
            const similarity = this.calculateContentSimilarity(feature1, feature2);
            minSimilarity = Math.min(minSimilarity, similarity);
          }
        }
        
        // MMR得分 = 相关性 - λ * 相似度
        const mmrScore = item.score - 0.5 * minSimilarity;
        
        if (mmrScore > bestScore) {
          bestScore = mmrScore;
          bestIndex = i;
        }
      }
      
      if (bestIndex >= 0) {
        diversified.push(remaining.splice(bestIndex, 1)[0]);
      } else {
        break;
      }
    }
    
    return diversified;
  }
  
  /**
   * 转换为推荐项
   */
  private async convertToRecommendationItems(scores: RecommendationScore[]): Promise<RecommendationItem[]> {
    const items: RecommendationItem[] = [];
    
    for (const score of scores) {
      const feature = this.contentFeaturesCache.get(score.contentId);
      if (!feature) {
        continue;
      }
      
      items.push({
        id: feature.id,
        type: 'video',
        data: {
          id: feature.id,
          title: feature.title,
          category: feature.category,
          tags: feature.tags,
          duration: feature.duration,
          viewCount: feature.viewCount,
          releaseDate: feature.releaseDate
        },
        reason: score.reasons.join(', '),
        score: score.score,
        tags: feature.tags,
        category: feature.category,
        duration: feature.duration,
        releaseDate: feature.releaseDate
      });
    }
    
    return items;
  }
}

export default LocalRecommendationAlgorithm;
