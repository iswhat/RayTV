/**
 * 智能推荐引擎 | Intelligent Recommendation Engine
 * 基于用户行为和内容特征提供个性化推荐 | Provides personalized recommendations based on user behavior and content features
 */
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import CacheService from '../cache/CacheService';
import { UnifiedMediaContent, UserPreferences } from '../../types/MediaContent';
import ApiResponse from '../../data/dto/ApiResponse';

// 推荐算法类型枚举 | Recommendation algorithm type enum
export enum RecommendationAlgorithm {
  POPULARITY = 'popularity',
  SIMILARITY = 'similarity',
  PERSONALIZED = 'personalized',
  TRENDING = 'trending',
  COLLABORATIVE = 'collaborative'
}

// 用户行为记录 | User behavior record
export interface UserBehavior {
  userId: string;
  contentId: string;
  action: 'view' | 'favorite' | 'share' | 'search' | 'skip';
  timestamp: number;
  duration?: number; // 观看时长(秒) | Viewing duration (seconds)
  rating?: number; // 评分(1-10) | Rating (1-10)
}

// 推荐结果 | Recommendation result
export interface RecommendationResult {
  content: UnifiedMediaContent;
  score: number;
  algorithm: RecommendationAlgorithm;
  reason: string;
  timestamp: number;
}

// 用户画像 | User profile
export interface UserProfile {
  userId: string;
  preferences: UserPreferences;
  behaviorHistory: UserBehavior[];
  favoriteGenres: Map<string, number>; // genre -> weight
  favoriteActors: Map<string, number>; // actor -> weight
  viewingPatterns: ViewingPatterns;
  lastUpdated: number;
}

// 观看模式 | Viewing patterns
export interface ViewingPatterns {
  preferredTimeSlots: number[]; // 24小时制小时数组 | 24-hour format hour array
  averageSessionDuration: number; // 平均会话时长(分钟) | Average session duration (minutes)
  preferredQuality: string; // 偏好画质 | Preferred quality
  devicePreferences: string[]; // 设备偏好 | Device preferences
  completionRate: number; // 完成率 | Completion rate
}

/**
 * 智能推荐引擎类 | Intelligent recommendation engine class
 */
export class RecommendationEngine {
  private static instance: RecommendationEngine | null = null;
  private cacheService: CacheService;
  private logger: Logger;
  private userProfiles: Map<string, UserProfile> = new Map();
  private behaviorBuffer: UserBehavior[] = [];
  private bufferFlushInterval: number = 300000; // 5分钟刷新间隔 | 5-minute flush interval

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): RecommendationEngine {
    if (!RecommendationEngine.instance) {
      RecommendationEngine.instance = new RecommendationEngine();
    }
    return RecommendationEngine.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.cacheService = CacheService.getInstance();
    this.logger = new Logger('RecommendationEngine');
    this.startBehaviorBufferFlush();
  }

  /**
   * 初始化推荐引擎 | Initialize recommendation engine
   */
  public async initialize(): Promise<void> {
    try {
      await this.loadUserProfiles();
      this.logger.info('RecommendationEngine initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize RecommendationEngine', error);
      throw error;
    }
  }

  /**
   * 生成推荐内容 | Generate recommended content
   */
  public async generateRecommendations(
    userId: string,
    contents: UnifiedMediaContent[],
    algorithm: RecommendationAlgorithm = RecommendationAlgorithm.PERSONALIZED,
    limit: number = 20
  ): Promise<ApiResponse<RecommendationResult[]>> {
    try {
      this.logger.info(`Generating ${algorithm} recommendations for user ${userId}`);

      // 获取用户画像 | Get user profile
      const userProfile = await this.getUserProfile(userId);
      
      // 根据算法生成推荐 | Generate recommendations based on algorithm
      let recommendations: RecommendationResult[] = [];
      
      switch (algorithm) {
        case RecommendationAlgorithm.POPULARITY:
          recommendations = this.generatePopularityBasedRecommendations(contents, limit);
          break;
        case RecommendationAlgorithm.SIMILARITY:
          recommendations = this.generateSimilarityBasedRecommendations(contents, userProfile, limit);
          break;
        case RecommendationAlgorithm.PERSONALIZED:
          recommendations = await this.generatePersonalizedRecommendations(contents, userProfile, limit);
          break;
        case RecommendationAlgorithm.TRENDING:
          recommendations = this.generateTrendingRecommendations(contents, limit);
          break;
        case RecommendationAlgorithm.COLLABORATIVE:
          recommendations = await this.generateCollaborativeRecommendations(contents, userProfile, limit);
          break;
        default:
          recommendations = this.generatePopularityBasedRecommendations(contents, limit);
      }

      // 缓存推荐结果 | Cache recommendation results
      const cacheKey = `recommendations_${userId}_${algorithm}_${Date.now()}`;
      await this.cacheService.set(cacheKey, recommendations, 1800000); // 30分钟缓存 | 30-minute cache

      this.logger.info(`Generated ${recommendations.length} recommendations for user ${userId}`);
      return ApiResponse.success(recommendations);

    } catch (error) {
      this.logger.error(`Failed to generate recommendations for user ${userId}`, error);
      return ApiResponse.failure(`Recommendation generation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 记录用户行为 | Record user behavior
   */
  public async recordUserBehavior(behavior: UserBehavior): Promise<ApiResponse<boolean>> {
    try {
      // 添加到缓冲区 | Add to buffer
      this.behaviorBuffer.push(behavior);
      
      // 更新用户画像 | Update user profile
      await this.updateUserProfile(behavior);
      
      // 实时更新推荐 | Update recommendations in real-time
      await this.triggerRealTimeRecommendation(behavior.userId);
      
      return ApiResponse.success(true);

    } catch (error) {
      this.logger.error(`Failed to record user behavior`, error);
      return ApiResponse.failure(`Behavior recording failed: ${(error as Error).message}`);
    }
  }

  /**
   * 获取用户画像 | Get user profile
   */
  public async getUserProfile(userId: string): Promise<UserProfile> {
    // 检查内存缓存 | Check memory cache
    if (this.userProfiles.has(userId)) {
      return this.userProfiles.get(userId)!;
    }

    // 从存储加载 | Load from storage
    const storedProfile = await StorageUtil.getItem<UserProfile>(`user_profile_${userId}`);
    if (storedProfile) {
      this.userProfiles.set(userId, storedProfile);
      return storedProfile;
    }

    // 创建新用户画像 | Create new user profile
    const newProfile: UserProfile = {
      userId,
      preferences: {
        favoriteGenres: [],
        favoriteActors: [],
        favoriteDirectors: [],
        preferredQuality: 'auto',
        preferredLanguages: ['zh'],
        excludeGenres: [],
        excludeActors: []
      },
      behaviorHistory: [],
      favoriteGenres: new Map(),
      favoriteActors: new Map(),
      viewingPatterns: {
        preferredTimeSlots: [],
        averageSessionDuration: 0,
        preferredQuality: 'auto',
        devicePreferences: [],
        completionRate: 0
      },
      lastUpdated: Date.now()
    };

    this.userProfiles.set(userId, newProfile);
    return newProfile;
  }

  /**
   * 基于流行度的推荐 | Popularity-based recommendations
   */
  private generatePopularityBasedRecommendations(
    contents: UnifiedMediaContent[],
    limit: number
  ): RecommendationResult[] {
    return contents
      .map(content => ({
        content,
        score: content.popularityScore,
        algorithm: RecommendationAlgorithm.POPULARITY,
        reason: '基于内容流行度推荐',
        timestamp: Date.now()
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
  }

  /**
   * 基于相似度的推荐 | Similarity-based recommendations
   */
  private generateSimilarityBasedRecommendations(
    contents: UnifiedMediaContent[],
    userProfile: UserProfile,
    limit: number
  ): RecommendationResult[] {
    const favoriteGenreSet = new Set(userProfile.preferences.favoriteGenres);
    
    return contents
      .map(content => {
        let score = 0;
        let reasons: string[] = [];

        // 类型匹配得分 | Genre matching score
        const genreMatches = content.genres.filter(genre => favoriteGenreSet.has(genre));
        if (genreMatches.length > 0) {
          score += genreMatches.length * 0.3;
          reasons.push(`匹配喜好类型: ${genreMatches.join(', ')}`);
        }

        // 演员匹配得分 | Actor matching score
        const actorMatches = content.actors?.filter(actor => 
          userProfile.preferences.favoriteActors.includes(actor)
        ) || [];
        if (actorMatches.length > 0) {
          score += actorMatches.length * 0.2;
          reasons.push(`包含喜爱演员: ${actorMatches.join(', ')}`);
        }

        // 评分加权 | Rating weighted
        if (content.rating) {
          score += (content.rating / 10) * 0.2;
        }

        // 流行度加权 | Popularity weighted
        score += content.popularityScore * 0.3;

        return {
          content,
          score,
          algorithm: RecommendationAlgorithm.SIMILARITY,
          reason: reasons.length > 0 ? reasons.join('; ') : '基础相似度匹配',
          timestamp: Date.now()
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
  }

  /**
   * 个性化推荐 | Personalized recommendations
   */
  private async generatePersonalizedRecommendations(
    contents: UnifiedMediaContent[],
    userProfile: UserProfile,
    limit: number
  ): Promise<RecommendationResult[]> {
    // 结合多种算法的混合推荐 | Hybrid recommendation combining multiple algorithms
    const popularityRecs = this.generatePopularityBasedRecommendations(contents, limit * 2);
    const similarityRecs = this.generateSimilarityBasedRecommendations(contents, userProfile, limit * 2);
    
    // 合并并去重 | Merge and deduplicate
    const mergedResults = new Map<string, RecommendationResult>();
    
    [...popularityRecs, ...similarityRecs].forEach(rec => {
      const key = rec.content.id;
      if (!mergedResults.has(key) || mergedResults.get(key)!.score < rec.score) {
        mergedResults.set(key, rec);
      }
    });

    // 重新计算个性化得分 | Recalculate personalized scores
    const personalizedResults = Array.from(mergedResults.values()).map(rec => {
      let finalScore = rec.score;
      let reason = rec.reason;

      // 根据用户历史行为调整得分 | Adjust score based on user history
      const recentBehaviors = userProfile.behaviorHistory
        .filter(b => b.timestamp > Date.now() - 604800000) // 最近7天 | Last 7 days
        .slice(-10);

      if (recentBehaviors.length > 0) {
        const viewTypeCount = recentBehaviors.filter(b => b.action === 'view').length;
        const favoriteCount = recentBehaviors.filter(b => b.action === 'favorite').length;
        
        // 观看行为加权 | Viewing behavior weighting
        finalScore += (viewTypeCount / 10) * 0.1;
        
        // 收藏行为加权 | Favorite behavior weighting
        finalScore += (favoriteCount / 5) * 0.2;
        
        if (favoriteCount > 0) {
          reason += '; 基于近期收藏行为';
        }
      }

      return {
        ...rec,
        score: Math.min(finalScore, 1), // 限制在0-1范围内 | Limit to 0-1 range
        algorithm: RecommendationAlgorithm.PERSONALIZED,
        reason
      };
    });

    return personalizedResults
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
  }

  /**
   * 趋势推荐 | Trending recommendations
   */
  private generateTrendingRecommendations(
    contents: UnifiedMediaContent[],
    limit: number
  ): RecommendationResult[] {
    const now = Date.now();
    const oneDayAgo = now - 86400000; // 24小时前 | 24 hours ago

    return contents
      .map(content => {
        // 计算趋势得分 | Calculate trend score
        const ageInDays = (now - content.lastUpdated) / 86400000;
        const freshnessFactor = Math.max(0, 1 - (ageInDays / 30)); // 30天内新鲜度因子 | Freshness factor within 30 days
        
        let trendScore = content.popularityScore * freshnessFactor;
        
        // 新内容加权 | New content weighting
        if (ageInDays < 7) {
          trendScore *= 1.5;
        }

        return {
          content,
          score: trendScore,
          algorithm: RecommendationAlgorithm.TRENDING,
          reason: ageInDays < 7 ? '新发布热门内容' : '近期热门内容',
          timestamp: Date.now()
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
  }

  /**
   * 协同过滤推荐 | Collaborative filtering recommendations
   */
  private async generateCollaborativeRecommendations(
    contents: UnifiedMediaContent[],
    userProfile: UserProfile,
    limit: number
  ): Promise<RecommendationResult[]> {
    // 简化的协同过滤实现 | Simplified collaborative filtering implementation
    // 实际项目中需要更复杂的用户相似度计算 | More complex user similarity calculation needed in actual projects
    
    const similarUsers = await this.findSimilarUsers(userProfile.userId);
    
    // 基于相似用户喜好的推荐 | Recommendations based on similar users' preferences
    const collaborativeScores = new Map<string, number>();
    
    similarUsers.forEach(similarUserId => {
      const similarProfile = this.userProfiles.get(similarUserId);
      if (similarProfile) {
        similarProfile.behaviorHistory
          .filter(b => b.action === 'favorite' || b.action === 'view')
          .forEach(behavior => {
            const currentScore = collaborativeScores.get(behavior.contentId) || 0;
            const increment = behavior.action === 'favorite' ? 0.3 : 0.1;
            collaborativeScores.set(behavior.contentId, currentScore + increment);
          });
      }
    });

    return contents
      .filter(content => collaborativeScores.has(content.id))
      .map(content => ({
        content,
        score: collaborativeScores.get(content.id) || 0,
        algorithm: RecommendationAlgorithm.COLLABORATIVE,
        reason: '基于相似用户喜好推荐',
        timestamp: Date.now()
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
  }

  /**
   * 更新用户画像 | Update user profile
   */
  private async updateUserProfile(behavior: UserBehavior): Promise<void> {
    const profile = await this.getUserProfile(behavior.userId);
    
    // 添加行为记录 | Add behavior record
    profile.behaviorHistory.push(behavior);
    
    // 限制历史记录数量 | Limit history record count
    if (profile.behaviorHistory.length > 1000) {
      profile.behaviorHistory = profile.behaviorHistory.slice(-500);
    }

    // 更新偏好统计 | Update preference statistics
    await this.updatePreferenceStatistics(profile, behavior);
    
    // 更新观看模式 | Update viewing patterns
    await this.updateViewingPatterns(profile);
    
    profile.lastUpdated = Date.now();
    
    // 保存到存储 | Save to storage
    await StorageUtil.setItem(`user_profile_${behavior.userId}`, profile);
  }

  /**
   * 更新偏好统计 | Update preference statistics
   */
  private async updatePreferenceStatistics(profile: UserProfile, behavior: UserBehavior): Promise<void> {
    if (behavior.action === 'favorite' || behavior.action === 'view') {
      // 这里需要获取内容详情来更新类型和演员偏好 | Need to get content details to update genre and actor preferences
      // 简化实现，实际项目中需要关联内容数据 | Simplified implementation, actual projects need to associate content data
    }
  }

  /**
   * 更新观看模式 | Update viewing patterns
   */
  private async updateViewingPatterns(profile: UserProfile): Promise<void> {
    const recentBehaviors = profile.behaviorHistory
      .filter(b => b.timestamp > Date.now() - 2592000000) // 最近30天 | Last 30 days
      .filter(b => b.action === 'view' && b.duration);

    if (recentBehaviors.length > 0) {
      // 更新时间段偏好 | Update time slot preferences
      const timeSlots = recentBehaviors.map(b => new Date(b.timestamp).getHours());
      profile.viewingPatterns.preferredTimeSlots = Array.from(new Set(timeSlots)).sort();

      // 更新平均会话时长 | Update average session duration
      const totalDuration = recentBehaviors.reduce((sum, b) => sum + (b.duration || 0), 0);
      profile.viewingPatterns.averageSessionDuration = totalDuration / recentBehaviors.length / 60; // 转换为分钟 | Convert to minutes

      // 更新完成率 | Update completion rate
      const completedViews = recentBehaviors.filter(b => 
        b.duration && b.duration > 1800 // 观看超过30分钟视为完成 | Viewing over 30 minutes considered complete
      ).length;
      profile.viewingPatterns.completionRate = completedViews / recentBehaviors.length;
    }
  }

  /**
   * 查找相似用户 | Find similar users
   */
  private async findSimilarUsers(userId: string): Promise<string[]> {
    // 简化的相似用户查找 | Simplified similar user finding
    // 实际项目中需要基于用户行为的复杂相似度计算 | Actual projects need complex similarity calculation based on user behavior
    return Array.from(this.userProfiles.keys()).filter(id => id !== userId).slice(0, 5);
  }

  /**
   * 触发实时推荐更新 | Trigger real-time recommendation update
   */
  private async triggerRealTimeRecommendation(userId: string): Promise<void> {
    // 这里可以实现实时推荐更新逻辑 | Real-time recommendation update logic can be implemented here
    // 例如：基于用户最近的行为更新推荐缓存 | For example: Update recommendation cache based on user's recent behavior
  }

  /**
   * 启动行为缓冲区刷新 | Start behavior buffer flush
   */
  private startBehaviorBufferFlush(): void {
    setInterval(async () => {
      if (this.behaviorBuffer.length > 0) {
        this.logger.info(`Flushing ${this.behaviorBuffer.length} buffered behaviors`);
        this.behaviorBuffer = []; // 简化处理，实际项目中需要持久化 | Simplified processing, actual projects need persistence
      }
    }, this.bufferFlushInterval);
  }

  /**
   * 加载用户画像 | Load user profiles
   */
  private async loadUserProfiles(): Promise<void> {
    // 这里可以实现从存储加载所有用户画像的逻辑 | Logic for loading all user profiles from storage can be implemented here
    this.logger.info('User profiles loading completed');
  }
}

// 导出单例实例 | Export singleton instance
export default RecommendationEngine.getInstance();