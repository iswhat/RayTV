import { BaseService } from '../core/BaseService';
import { Logger } from '../../common/utils/Logger';
import { CacheService } from '../cache/CacheService';

/**
 * 广告模式识别接口
 */
interface AdPattern {
  id: string;
  name: string;
  type: 'url' | 'content' | 'behavior' | 'metadata';
  pattern: string | RegExp;
  confidence: number;
  priority: number;
  enabled: boolean;
}

/**
 * 广告拦截规则
 */
interface AdBlockRule {
  id: string;
  name: string;
  description: string;
  patterns: string[];
  action: 'block' | 'redirect' | 'mute' | 'skip';
  scope: 'global' | 'source' | 'category';
  priority: number;
  enabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * 广告检测结果
 */
interface AdDetectionResult {
  isAd: boolean;
  confidence: number;
  matchedPatterns: string[];
  suggestedAction: 'block' | 'allow' | 'review';
  metadata: Record<string, any>;
}

/**
 * 用户广告偏好设置
 */
interface AdPreference {
  userId: string;
  blockLevel: 'strict' | 'moderate' | 'lenient' | 'off';
  categories: string[];
  whitelist: string[];
  blacklist: string[];
  autoSkipAds: boolean;
  muteAudioAds: boolean;
  showAdNotifications: boolean;
  lastUpdated: Date;
}

/**
 * 增强广告拦截服务
 * 提供智能广告识别、拦截和用户偏好管理功能
 */
export class EnhancedAdBlockService extends BaseService {
  private static instance: EnhancedAdBlockService | null = null;
  private cacheService: CacheService;
  private logger: Logger;
  
  // 广告模式数据库
  private adPatterns: Map<string, AdPattern> = new Map();
  private adBlockRules: Map<string, AdBlockRule> = new Map();
  private userPreferences: Map<string, AdPreference> = new Map();
  
  // 运行时统计
  private detectionStats = {
    totalRequests: 0,
    adsBlocked: 0,
    falsePositives: 0,
    falseNegatives: 0,
    patternsMatched: new Map<string, number>()
  };

  private constructor() {
    super('EnhancedAdBlockService');
    this.cacheService = CacheService.getInstance();
    this.logger = Logger.getInstance();
    this.initializeAdPatterns();
    this.loadDefaultRules();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): EnhancedAdBlockService {
    if (!EnhancedAdBlockService.instance) {
      EnhancedAdBlockService.instance = new EnhancedAdBlockService();
    }
    return EnhancedAdBlockService.instance;
  }

  /**
   * 初始化广告识别模式
   */
  private initializeAdPatterns(): void {
    const patterns: AdPattern[] = [
      // URL模式
      {
        id: 'url_ads',
        name: '广告URL标识',
        type: 'url',
        pattern: '(\\/ad(s)?\\/|\\/ads\\.|\\/advert|\\/banner)',
        confidence: 0.9,
        priority: 10,
        enabled: true
      },
      {
        id: 'url_tracking',
        name: '跟踪URL标识',
        type: 'url',
        pattern: '(track|analytics|metrics|beacon)',
        confidence: 0.8,
        priority: 8,
        enabled: true
      },
      
      // 内容模式
      {
        id: 'content_duration',
        name: '异常时长内容',
        type: 'content',
        pattern: '^([0-5]|[5-9][0-9])s$', // 0-99秒的内容
        confidence: 0.7,
        priority: 6,
        enabled: true
      },
      {
        id: 'content_title',
        name: '广告标题关键词',
        type: 'content',
        pattern: '(广告|推广|赞助|限时|优惠|点击|购买)',
        confidence: 0.85,
        priority: 7,
        enabled: true
      },
      
      // 行为模式
      {
        id: 'behavior_autoplay',
        name: '自动播放广告',
        type: 'behavior',
        pattern: 'autoplay=true&ad=true',
        confidence: 0.95,
        priority: 9,
        enabled: true
      },
      
      // 元数据模式
      {
        id: 'metadata_category',
        name: '广告分类标识',
        type: 'metadata',
        pattern: 'category=(advertisement|promotion|commercial)',
        confidence: 0.9,
        priority: 8,
        enabled: true
      }
    ];

    patterns.forEach(pattern => {
      this.adPatterns.set(pattern.id, pattern);
    });

    this.logger.info(`初始化了 ${patterns.length} 个广告识别模式`);
  }

  /**
   * 加载默认拦截规则
   */
  private loadDefaultRules(): void {
    const rules: AdBlockRule[] = [
      {
        id: 'block_pre_roll',
        name: '前置广告拦截',
        description: '拦截视频播放前的广告',
        patterns: ['url_ads', 'behavior_autoplay'],
        action: 'block',
        scope: 'global',
        priority: 10,
        enabled: true,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 'block_mid_roll',
        name: '中插广告拦截',
        description: '拦截视频播放中的广告',
        patterns: ['url_ads', 'content_duration'],
        action: 'skip',
        scope: 'global',
        priority: 8,
        enabled: true,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 'mute_audio_ads',
        name: '音频广告静音',
        description: '自动静音音频广告',
        patterns: ['content_duration'],
        action: 'mute',
        scope: 'global',
        priority: 6,
        enabled: true,
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ];

    rules.forEach(rule => {
      this.adBlockRules.set(rule.id, rule);
    });

    this.logger.info(`加载了 ${rules.length} 条默认拦截规则`);
  }

  /**
   * 检测内容是否为广告
   */
  public async detectAd(content: any, context?: any): Promise<AdDetectionResult> {
    this.detectionStats.totalRequests++;
    
    const matchedPatterns: string[] = [];
    let maxConfidence = 0;
    const metadata: Record<string, any> = {};

    // URL检测
    if (content.url) {
      const urlMatches = this.checkUrlPatterns(content.url);
      matchedPatterns.push(...urlMatches.map(p => p.id));
      urlMatches.forEach(match => {
        maxConfidence = Math.max(maxConfidence, match.confidence);
        this.updatePatternStats(match.id);
      });
      metadata.urlMatches = urlMatches.length;
    }

    // 内容检测
    if (content.title || content.description) {
      const contentText = `${content.title || ''} ${content.description || ''}`;
      const contentMatches = this.checkContentPatterns(contentText);
      matchedPatterns.push(...contentMatches.map(p => p.id));
      contentMatches.forEach(match => {
        maxConfidence = Math.max(maxConfidence, match.confidence);
        this.updatePatternStats(match.id);
      });
      metadata.contentMatches = contentMatches.length;
    }

    // 元数据检测
    if (content.metadata) {
      const metaMatches = this.checkMetadataPatterns(content.metadata);
      matchedPatterns.push(...metaMatches.map(p => p.id));
      metaMatches.forEach(match => {
        maxConfidence = Math.max(maxConfidence, match.confidence);
        this.updatePatternStats(match.id);
      });
      metadata.metaMatches = metaMatches.length;
    }

    // 行为检测
    if (context?.behavior) {
      const behaviorMatches = this.checkBehaviorPatterns(context.behavior);
      matchedPatterns.push(...behaviorMatches.map(p => p.id));
      behaviorMatches.forEach(match => {
        maxConfidence = Math.max(maxConfidence, match.confidence);
        this.updatePatternStats(match.id);
      });
      metadata.behaviorMatches = behaviorMatches.length;
    }

    const isAd = matchedPatterns.length > 0 && maxConfidence >= 0.7;
    const suggestedAction = this.determineAction(isAd, maxConfidence, matchedPatterns);

    if (isAd) {
      this.detectionStats.adsBlocked++;
    }

    return {
      isAd,
      confidence: maxConfidence,
      matchedPatterns,
      suggestedAction,
      metadata
    };
  }

  /**
   * 检查URL模式
   */
  private checkUrlPatterns(url: string): AdPattern[] {
    const matches: AdPattern[] = [];
    
    for (const [_, pattern] of this.adPatterns) {
      if (pattern.type === 'url' && pattern.enabled) {
        const regex = new RegExp(pattern.pattern, 'i');
        if (regex.test(url)) {
          matches.push(pattern);
        }
      }
    }
    
    return matches.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 检查内容模式
   */
  private checkContentPatterns(text: string): AdPattern[] {
    const matches: AdPattern[] = [];
    
    for (const [_, pattern] of this.adPatterns) {
      if (pattern.type === 'content' && pattern.enabled) {
        const regex = new RegExp(pattern.pattern, 'i');
        if (regex.test(text)) {
          matches.push(pattern);
        }
      }
    }
    
    return matches.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 检查元数据模式
   */
  private checkMetadataPatterns(metadata: any): AdPattern[] {
    const matches: AdPattern[] = [];
    const metadataString = JSON.stringify(metadata);
    
    for (const [_, pattern] of this.adPatterns) {
      if (pattern.type === 'metadata' && pattern.enabled) {
        const regex = new RegExp(pattern.pattern, 'i');
        if (regex.test(metadataString)) {
          matches.push(pattern);
        }
      }
    }
    
    return matches.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 检查行为模式
   */
  private checkBehaviorPatterns(behavior: any): AdPattern[] {
    const matches: AdPattern[] = [];
    const behaviorString = JSON.stringify(behavior);
    
    for (const [_, pattern] of this.adPatterns) {
      if (pattern.type === 'behavior' && pattern.enabled) {
        const regex = new RegExp(pattern.pattern, 'i');
        if (regex.test(behaviorString)) {
          matches.push(pattern);
        }
      }
    }
    
    return matches.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 确定处理动作
   */
  private determineAction(isAd: boolean, confidence: number, patterns: string[]): 'block' | 'allow' | 'review' {
    if (!isAd) return 'allow';
    
    if (confidence >= 0.9) return 'block';
    if (confidence >= 0.8) return 'review';
    return 'allow';
  }

  /**
   * 应用拦截规则
   */
  public async applyBlockRules(
    content: any,
    detectionResult: AdDetectionResult,
    userId?: string
  ): Promise<'blocked' | 'allowed' | 'skipped' | 'muted'> {
    
    if (!detectionResult.isAd) {
      return 'allowed';
    }

    // 获取用户偏好
    const preference = userId ? this.getUserPreference(userId) : null;
    
    // 检查白名单
    if (preference && this.isWhitelisted(content, preference)) {
      return 'allowed';
    }

    // 应用规则
    const applicableRules = this.getApplicableRules(detectionResult.matchedPatterns);
    
    if (applicableRules.length === 0) {
      return 'allowed';
    }

    // 执行最高优先级规则
    const highestPriorityRule = applicableRules.reduce((prev, current) =>
      prev.priority > current.priority ? prev : current
    );

    switch (highestPriorityRule.action) {
      case 'block':
        return 'blocked';
      case 'skip':
        return 'skipped';
      case 'mute':
        return 'muted';
      case 'redirect':
        return 'allowed'; // 重定向通常允许但改变目标
      default:
        return 'allowed';
    }
  }

  /**
   * 获取适用规则
   */
  private getApplicableRules(patternIds: string[]): AdBlockRule[] {
    const rules: AdBlockRule[] = [];
    
    for (const [_, rule] of this.adBlockRules) {
      if (rule.enabled && rule.patterns.some(pattern => patternIds.includes(pattern))) {
        rules.push(rule);
      }
    }
    
    return rules.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 设置用户广告偏好
   */
  public setUserPreference(userId: string, preference: Partial<AdPreference>): void {
    const existing = this.userPreferences.get(userId) || {
      userId,
      blockLevel: 'moderate',
      categories: [],
      whitelist: [],
      blacklist: [],
      autoSkipAds: true,
      muteAudioAds: true,
      showAdNotifications: false,
      lastUpdated: new Date()
    };

    const updated: AdPreference = {
      ...existing,
      ...preference,
      lastUpdated: new Date()
    };

    this.userPreferences.set(userId, updated);
    this.cacheService.set(`ad_preference_${userId}`, updated, 24 * 60 * 60 * 1000); // 24小时缓存
    
    this.logger.info(`更新用户 ${userId} 的广告偏好设置`);
  }

  /**
   * 获取用户广告偏好
   */
  public getUserPreference(userId: string): AdPreference | null {
    // 先从缓存获取
    const cached = this.cacheService.get(`ad_preference_${userId}`);
    if (cached) {
      return cached as AdPreference;
    }

    // 从内存获取
    const preference = this.userPreferences.get(userId);
    if (preference) {
      this.cacheService.set(`ad_preference_${userId}`, preference, 24 * 60 * 60 * 1000);
    }

    return preference || null;
  }

  /**
   * 检查内容是否在白名单中
   */
  private isWhitelisted(content: any, preference: AdPreference): boolean {
    if (!content.url && !content.title) return false;
    
    const contentIdentifier = content.url || content.title;
    return preference.whitelist.some(item => 
      contentIdentifier.toLowerCase().includes(item.toLowerCase())
    );
  }

  /**
   * 更新模式匹配统计
   */
  private updatePatternStats(patternId: string): void {
    const current = this.detectionStats.patternsMatched.get(patternId) || 0;
    this.detectionStats.patternsMatched.set(patternId, current + 1);
  }

  /**
   * 获取统计信息
   */
  public getStatistics(): any {
    return {
      ...this.detectionStats,
      activePatterns: Array.from(this.adPatterns.values()).filter(p => p.enabled).length,
      activeRules: Array.from(this.adBlockRules.values()).filter(r => r.enabled).length,
      userPreferences: this.userPreferences.size
    };
  }

  /**
   * 添加自定义广告模式
   */
  public addCustomPattern(pattern: Omit<AdPattern, 'id'>): string {
    const id = `custom_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const newPattern: AdPattern = { ...pattern, id };
    
    this.adPatterns.set(id, newPattern);
    this.logger.info(`添加自定义广告模式: ${pattern.name}`);
    
    return id;
  }

  /**
   * 添加自定义拦截规则
   */
  public addCustomRule(rule: Omit<AdBlockRule, 'id' | 'createdAt' | 'updatedAt'>): string {
    const id = `custom_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const newRule: AdBlockRule = {
      ...rule,
      id,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    this.adBlockRules.set(id, newRule);
    this.logger.info(`添加自定义拦截规则: ${rule.name}`);
    
    return id;
  }

  /**
   * 导出配置
   */
  public exportConfiguration(): any {
    return {
      patterns: Array.from(this.adPatterns.values()),
      rules: Array.from(this.adBlockRules.values()),
      statistics: this.getStatistics()
    };
  }

  /**
   * 导入配置
   */
  public importConfiguration(config: any): void {
    if (config.patterns) {
      config.patterns.forEach((pattern: any) => {
        this.adPatterns.set(pattern.id, pattern);
      });
    }
    
    if (config.rules) {
      config.rules.forEach((rule: any) => {
        this.adBlockRules.set(rule.id, rule);
      });
    }
    
    this.logger.info('导入广告拦截配置完成');
  }

  protected async initialize(): Promise<void> {
    this.logger.info('EnhancedAdBlockService 初始化完成');
  }

  protected async cleanup(): Promise<void> {
    this.adPatterns.clear();
    this.adBlockRules.clear();
    this.userPreferences.clear();
    this.logger.info('EnhancedAdBlockService 清理完成');
  }
}