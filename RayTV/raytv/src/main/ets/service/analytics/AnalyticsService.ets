// 数据分析服务
// 提供用户行为统计、页面访问追踪、播放统计等功能

import StorageUtil, { StorageType } from '../../common/util/StorageUtil';
import { HttpService } from '../HttpService';



/**
 * 分析配置接口
 */
export interface AnalyticsConfig {
  enabled: boolean;
}

/**
 * 视频播放参数接口
 */
export interface VideoPlayParams {
  episode_name?: string;
  position?: number;
  duration?: number;
  quality?: string;
}

/**
 * 搜索事件参数接口
 */
export interface SearchEventParams {
  keyword: string;
  site_key?: string;
  result_count?: number;
}

/**
 * 事件属性类型
 */
export interface EventProperties {
  [key: string]: string | number | boolean | null;
}

/**
 * 使用统计摘要
 */
export interface UsageSummary {
  userId: string;
  sessionId: string;
  sessionStartTime: number;
  totalPlays: number;
  totalPages: number;
  totalSearches: number;
  sessionDuration: number;
}

/**
 * 分析事件接口
 */
export interface AnalyticsEvent {
  eventName: string;
  timestamp: number;
  userId: string;
  sessionId: string;
  properties: EventProperties;
}

export class AnalyticsService {
  private static instance: AnalyticsService;
  private httpService: HttpService;
  private eventQueue: AnalyticsEvent[] = [];
  private isEnabled: boolean = true;
  private userId: string = '';
  private sessionId: string = '';
  private sessionStartTime: number = 0;

  private constructor() {
    this.httpService = HttpService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService();
    }
    return AnalyticsService.instance;
  }

  /**
   * 初始化分析服务
   */
  public async initialize(): Promise<void> {
    // 加载配置
    const defaultConfig: AnalyticsConfig = { enabled: true };
    const configObj = await StorageUtil.getObject<AnalyticsConfig>('analyticsConfig', StorageType.PREFERENCES);
    const config = configObj ? configObj : defaultConfig;
    this.isEnabled = config?.enabled ?? defaultConfig.enabled;

    // 生成或获取用户ID
    const defaultUserId = this.generateId();
    const storedUserId = await StorageUtil.getString('userId', StorageType.PREFERENCES, defaultUserId);
    this.userId = storedUserId || defaultUserId;
    await StorageUtil.setString('userId', this.userId, StorageType.PREFERENCES);

    // 创建新会话
    this.createNewSession();

    // 开始自动上报
    this.startAutoReport();
  }

  /**
   * 创建新会话
   */
  private createNewSession(): void {
    this.sessionId = this.generateId();
    this.sessionStartTime = Date.now();
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  /**
   * 开始自动上报
   */
  private startAutoReport(): void {
    // 30秒上报一次事件队列
    setInterval(() => {
      this.reportEvents();
    }, 30000);

    // 应用进入后台时上报
    // 在鸿蒙系统中监听应用生命周期事件
    // 这里需要注册到应用的生命周期监听中
  }

  /**
   * 记录页面访问
   * @param pageName 页面名称
   * @param params 额外参数
   */
  public trackPageView(pageName: string, params?: EventProperties): void {
    if (!this.isEnabled) return;

    // 创建事件对象，手动合并参数
    const eventProperties: EventProperties = {
      page_name: pageName
    };
    
    // 手动合并params，不使用for..in循环
    if (params) {
      // 使用Object.keys和forEach替代for..in循环
      const keys = Object.keys(params);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        eventProperties[key] = params[key];
      }
    }

    const event: AnalyticsEvent = {
      eventName: 'page_view',
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      properties: eventProperties
    };

    this.addToQueue(event);
  }

  /**
   * 记录视频播放
   * @param videoId 视频ID
   * @param siteKey 站点Key
   * @param params 播放参数
   */
  public trackVideoPlay(videoId: string, siteKey: string, params?: VideoPlayParams): void {
    if (!this.isEnabled) return;

    // 创建事件对象，手动合并参数
    const eventProperties: EventProperties = {
      video_id: videoId,
      site_key: siteKey
    };
    
    // 手动合并params，不使用扩展运算符
    if (params) {
      if (params.episode_name !== undefined) {
        eventProperties.episode_name = params.episode_name;
      }
      if (params.position !== undefined) {
        eventProperties.position = params.position;
      }
      if (params.duration !== undefined) {
        eventProperties.duration = params.duration;
      }
      if (params.quality !== undefined) {
        eventProperties.quality = params.quality;
      }
    }

    const event: AnalyticsEvent = {
      eventName: 'video_play',
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      properties: eventProperties
    };

    this.addToQueue(event);
  }

  /**
   * 记录视频播放完成
   * @param videoId 视频ID
   * @param duration 播放时长
   * @param params 额外参数
   */
  public trackVideoComplete(videoId: string, duration: number, params?: EventProperties): void {
    if (!this.isEnabled) return;

    // 创建事件对象，手动合并参数
    const eventProperties: EventProperties = {
      video_id: videoId,
      duration: duration
    };
    
    // 手动合并params，不使用for..in循环
    if (params) {
      // 使用Object.keys和forEach替代for..in循环
      const keys = Object.keys(params);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        eventProperties[key] = params[key];
      }
    }

    const event: AnalyticsEvent = {
      eventName: 'video_complete',
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      properties: eventProperties
    };

    this.addToQueue(event);
  }

  /**
   * 记录搜索事件
   * @param keyword 搜索关键词
   * @param siteKey 站点Key
   * @param resultCount 结果数量
   */
  public trackSearch(keyword: string, siteKey?: string, resultCount?: number): void {
    if (!this.isEnabled) return;

    const properties: EventProperties = {
      keyword: keyword,
      site_key: siteKey || null,
      result_count: resultCount || null
    };
    const event: AnalyticsEvent = {
      eventName: 'search',
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      properties: properties
    };

    this.addToQueue(event);
  }

  /**
   * 记录收藏事件
   * @param itemId 收藏项ID
   * @param itemType 收藏项类型
   */
  public trackFavorite(itemId: string, itemType: 'vod' | 'live'): void {
    if (!this.isEnabled) return;

    const properties: EventProperties = {
      item_id: itemId,
      item_type: itemType
    };
    const event: AnalyticsEvent = {
      eventName: 'favorite',
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      properties: properties
    };

    this.addToQueue(event);
  }

  /**
   * 记录错误事件
   * @param errorType 错误类型
   * @param message 错误消息
   * @param context 错误上下文
   */
  public trackError(errorType: string, message: string, context?: EventProperties): void {
    if (!this.isEnabled) return;

    // 创建事件对象，手动合并参数
    const eventProperties: EventProperties = {
      error_type: errorType,
      error_message: message
    };
    
    // 手动合并context，不使用for..in循环
    if (context) {
      // 使用Object.keys和forEach替代for..in循环
      const keys = Object.keys(context);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        eventProperties[`context_${key}`] = context[key];
      }
    }

    const event: AnalyticsEvent = {
      eventName: 'error',
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      properties: eventProperties
    };

    this.addToQueue(event);
  }

  /**
   * 添加事件到队列
   * @param event 分析事件
   */
  private addToQueue(event: AnalyticsEvent): void {
    this.eventQueue.push(event);

    // 如果队列超过100个事件，立即上报
    if (this.eventQueue.length >= 100) {
      this.reportEvents();
    }
  }

  /**
   * 上报事件
   */
  private async reportEvents(): Promise<void> {
    if (this.eventQueue.length === 0) return;

    // 使用传统方式复制数组，不使用扩展运算符
    const eventsToReport: AnalyticsEvent[] = [];
    for (let i = 0; i < this.eventQueue.length; i++) {
      eventsToReport.push(this.eventQueue[i]);
    }
    this.eventQueue = [];

    try {
      // 这里应该发送到分析服务器
      // 由于是本地实现，可以保存到本地存储或日志文件
      // 模拟上报
      // await this.httpService.post('https://analytics-api.example.com/events', {
      //   events: eventsToReport
      // });

      // 保存到本地日志
      await this.saveEventsToLog(eventsToReport);
    } catch (error) {
      // 上报失败，将事件重新加入队列
      // 上报失败，将事件重新加入队列
      // 使用传统方式合并数组，不使用扩展运算符
      for (let i = 0; i < eventsToReport.length; i++) {
        this.eventQueue.unshift(eventsToReport[i]);
      }
    }
  }

  /**
   * 保存事件到本地日志
   * @param events 事件列表
   */
  private async saveEventsToLog(events: AnalyticsEvent[]): Promise<void> {
    try {
      const logKey = `analytics_log_${new Date().toISOString().split('T')[0]}`;
      const existingLogs = await StorageUtil.getString(logKey, StorageType.PREFERENCES, '');
      let newLogs = '';
      for (let i = 0; i < events.length; i++) {
        newLogs += JSON.stringify(events[i]);
        if (i < events.length - 1) {
          newLogs += '\n';
        }
      }
      await StorageUtil.setString(logKey, existingLogs + newLogs + '\n', StorageType.PREFERENCES);
    } catch (error) {
      // 保存日志失败
    }
  }

  /**
   * 启用/禁用分析
   * @param enabled 是否启用
   */
  public async setEnabled(enabled: boolean): Promise<void> {
    this.isEnabled = enabled;
    const config: AnalyticsConfig = {
      enabled: enabled
    };
    await StorageUtil.setObject('analyticsConfig', config, StorageType.PREFERENCES);
  }

  /**
   * 获取分析状态
   */
  public getEnabled(): boolean {
    return this.isEnabled;
  }

  /**
   * 清除所有数据
   */
  public async clearData(): Promise<void> {
    this.eventQueue = [];
    this.createNewSession();
    await StorageUtil.remove('userId', StorageType.PREFERENCES);
    this.userId = this.generateId();
    await StorageUtil.setString('userId', this.userId, StorageType.PREFERENCES);
  }

  /**
   * 获取使用统计摘要
   */
  public async getUsageSummary(): Promise<UsageSummary> {
    const today = new Date().toISOString().split('T')[0];
    const logKey = `analytics_log_${today}`;
    const logs = await StorageUtil.getString(logKey, StorageType.PREFERENCES, '');
    
    let totalPlays = 0;
    let totalPages = 0;
    let totalSearches = 0;

    if (logs) {
      const logLines = logs.split('\n');
      for (const line of logLines) {
        if (!line) continue;
        try {
          const event = JSON.parse(line) as AnalyticsEvent;
          switch (event.eventName) {
            case 'video_play':
              totalPlays++;
              break;
            case 'page_view':
              totalPages++;
              break;
            case 'search':
              totalSearches++;
              break;
          }
        } catch (e) {
          // 忽略解析错误
        }
      }
    }

    return {
      userId: this.userId,
      sessionId: this.sessionId,
      sessionStartTime: this.sessionStartTime,
      totalPlays,
      totalPages,
      totalSearches,
      sessionDuration: Date.now() - this.sessionStartTime
    };
  }
}
