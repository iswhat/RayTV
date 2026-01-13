// 数据分析服务 | Data analytics service
// 提供用户行为统计、页面访问追踪、搜索统计等功能 | Provides user behavior statistics, page access tracking, search statistics, etc.

import StorageUtil, { StorageType } from '../../common/util/StorageUtil';
import { HttpService } from '../HttpService';



/**
 * 分析配置接口 | Analytics configuration interface
 */
export interface AnalyticsConfig {
  enabled: boolean;
}

/**
 * 视频播放参数接口 | Video play parameters interface
 */
export interface VideoPlayParams {
  episode_name?: string;
  position?: number;
  duration?: number;
  quality?: string;
}

/**
 * 搜索事件参数接口 | Search event parameters interface
 */
export interface SearchEventParams {
  keyword: string;
  site_key?: string;
  result_count?: number;
}

/**
 * 事件属性类型 | Event properties type
 */
export class EventProperties {
  page_name?: string;     // 页面名称 | Page name
  video_id?: string;      // 视频ID | Video ID
  site_key?: string;      // 站点Key | Site key
  episode_name?: string;  // 剧集名称 | Episode name
  position?: number;      // 播放位置 | Play position
  duration?: number;      // 播放时长 | Duration
  quality?: number;       // 视频质量 | Video quality
  keyword?: string;       // 搜索关键词 | Search keyword
  result_count?: number;  // 结果数量 | Result count
  item_id?: string;       // 项目ID | Item ID
  item_type?: 'vod' | 'live'; // 项目类型 | Item type
  error_type?: string;    // 错误类型 | Error type
  error_message?: string; // 错误信息 | Error message

  constructor(init?: Partial<EventProperties>) {
    if (init) {
      if (init.page_name !== undefined) {
        this.page_name = init.page_name;
      }
      if (init.video_id !== undefined) {
        this.video_id = init.video_id;
      }
      if (init.site_key !== undefined) {
        this.site_key = init.site_key;
      }
      if (init.episode_name !== undefined) {
        this.episode_name = init.episode_name;
      }
      if (init.position !== undefined) {
        this.position = init.position;
      }
      if (init.duration !== undefined) {
        this.duration = init.duration;
      }
      if (init.quality !== undefined) {
        this.quality = init.quality;
      }
      if (init.keyword !== undefined) {
        this.keyword = init.keyword;
      }
      if (init.result_count !== undefined) {
        this.result_count = init.result_count;
      }
      if (init.item_id !== undefined) {
        this.item_id = init.item_id;
      }
      if (init.item_type !== undefined) {
        this.item_type = init.item_type;
      }
      if (init.error_type !== undefined) {
        this.error_type = init.error_type;
      }
      if (init.error_message !== undefined) {
        this.error_message = init.error_message;
      }
    }
  }
}

/**
 * 使用统计摘要 | Usage summary
 */
export interface UsageSummary {
  userId: string;            // 用户ID | User ID
  sessionId: string;          // 会话ID | Session ID
  sessionStartTime: number;   // 会话开始时间 | Session start time
  totalPlays: number;         // 总播放次数 | Total plays
  totalPages: number;         // 总页面访问 | Total pages
  totalSearches: number;      // 总搜索次数 | Total searches
  sessionDuration: number;    // 会话时长 | Session duration
}

/**
 * 分析事件接口 | Analytics event interface
 */
export interface AnalyticsEvent {
  eventName: string;          // 事件名称 | Event name
  timestamp: number;          // 时间戳 | Timestamp
  userId: string;             // 用户ID | User ID
  sessionId: string;           // 会话ID | Session ID
  properties: EventProperties; // 事件属性 | Event properties
}

export class AnalyticsService {
  private static instance: AnalyticsService;
  private httpService: HttpService;
  private eventQueue: AnalyticsEvent[] = [];  // 事件队列 | Event queue
  private isEnabled: boolean = true;           // 是否启用 | Whether enabled
  private userId: string = '';                 // 用户ID | User ID
  private sessionId: string = '';              // 会话ID | Session ID
  private sessionStartTime: number = 0;        // 会话开始时间 | Session start time

  private constructor() {
    this.httpService = HttpService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService();
    }
    return AnalyticsService.instance;
  }

  /**
   * 初始化分析服务 | Initialize analytics service
   */
  public async initialize(): Promise<void> {
    // 加载配置 | Load configuration
    const defaultConfig: AnalyticsConfig = { enabled: true };
    const configObj = await StorageUtil.getObject<AnalyticsConfig>('analyticsConfig', StorageType.PREFERENCES);
    const config = configObj ? configObj : defaultConfig;
    this.isEnabled = config?.enabled ?? defaultConfig.enabled;

    // 生成或获取用户ID | Generate or get user ID
    const defaultUserId = this.generateId();
    const storedUserId = await StorageUtil.getString('userId', StorageType.PREFERENCES, defaultUserId);
    this.userId = storedUserId || defaultUserId;
    await StorageUtil.setString('userId', this.userId, StorageType.PREFERENCES);

    // 创建新会话 | Create new session
    this.createNewSession();

    // 开始自动上报 | Start auto report
    this.startAutoReport();
  }

  /**
   * 创建新会话 | Create new session
   */
  private createNewSession(): void {
    this.sessionId = this.generateId();
    this.sessionStartTime = Date.now();
  }

  /**
   * 生成唯一ID | Generate unique ID
   */
  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  /**
   * 开始自动上报 | Start auto report
   */
  private startAutoReport(): void {
    // 30秒上报一次事件队列 | Report event queue every 30 seconds
    setInterval(() => {
      this.reportEvents();
    }, 30000);

    // 应用进入后台时上报 | Report when app enters background
    // 在鸿蒙系统中监听应用生命周期事件 | Listen to app lifecycle events in HarmonyOS
    // 这里需要注册到应用的生命周期监听中 | Need to register to app's lifecycle listener
  }

  /**
   * 记录页面访问 | Track page view
   * @param pageName 页面名称 | Page name
   * @param params 额外参数 | Additional parameters
   */
  public trackPageView(pageName: string, params?: Partial<EventProperties>): void {
    if (!this.isEnabled) return;

    // 创建事件对象，手动合并参数 | Create event object, manually merge parameters
    const eventProperties = new EventProperties();
    eventProperties.page_name = pageName;
    
    // 手动合并params | Manually merge params
    if (params) {
      if (params.page_name !== undefined) {
        eventProperties.page_name = params.page_name;
      }
      if (params.video_id !== undefined) {
        eventProperties.video_id = params.video_id;
      }
      if (params.site_key !== undefined) {
        eventProperties.site_key = params.site_key;
      }
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
      if (params.keyword !== undefined) {
        eventProperties.keyword = params.keyword;
      }
      if (params.result_count !== undefined) {
        eventProperties.result_count = params.result_count;
      }
      if (params.item_id !== undefined) {
        eventProperties.item_id = params.item_id;
      }
      if (params.item_type !== undefined) {
        eventProperties.item_type = params.item_type;
      }
      if (params.error_type !== undefined) {
        eventProperties.error_type = params.error_type;
      }
      if (params.error_message !== undefined) {
        eventProperties.error_message = params.error_message;
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
   * 记录视频播放 | Track video play
   * @param videoId 视频ID | Video ID
   * @param siteKey 站点Key | Site key
   * @param params 播放参数 | Play parameters
   */
  public trackVideoPlay(videoId: string, siteKey: string, params?: VideoPlayParams): void {
    if (!this.isEnabled) return;

    // 创建事件对象，手动合并参数 | Create event object, manually merge parameters
    const eventProperties = new EventProperties();
    eventProperties.video_id = videoId;
    eventProperties.site_key = siteKey;
    
    // 手动合并params | Manually merge params
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
        eventProperties.quality = parseInt(params.quality, 10) || 0;
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
   * 记录视频播放完成 | Track video complete
   * @param videoId 视频ID | Video ID
   * @param duration 播放时长 | Duration
   * @param params 额外参数 | Additional parameters
   */
  public trackVideoComplete(videoId: string, duration: number, params?: Partial<EventProperties>): void {
    if (!this.isEnabled) return;

    // 创建事件对象，手动合并参数 | Create event object, manually merge parameters
    const eventProperties = new EventProperties();
    eventProperties.video_id = videoId;
    eventProperties.duration = duration;
    
    // 手动合并params | Manually merge params
    if (params) {
      if (params.page_name !== undefined) {
        eventProperties.page_name = params.page_name;
      }
      if (params.video_id !== undefined) {
        eventProperties.video_id = params.video_id;
      }
      if (params.site_key !== undefined) {
        eventProperties.site_key = params.site_key;
      }
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
      if (params.keyword !== undefined) {
        eventProperties.keyword = params.keyword;
      }
      if (params.result_count !== undefined) {
        eventProperties.result_count = params.result_count;
      }
      if (params.item_id !== undefined) {
        eventProperties.item_id = params.item_id;
      }
      if (params.item_type !== undefined) {
        eventProperties.item_type = params.item_type;
      }
      if (params.error_type !== undefined) {
        eventProperties.error_type = params.error_type;
      }
      if (params.error_message !== undefined) {
        eventProperties.error_message = params.error_message;
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
   * 记录搜索事件 | Track search event
   * @param keyword 搜索关键词 | Search keyword
   * @param siteKey 站点Key | Site key
   * @param resultCount 结果数量 | Result count
   */
  public trackSearch(keyword: string, siteKey?: string, resultCount?: number): void {
    if (!this.isEnabled) return;

    const properties = new EventProperties();
    properties.keyword = keyword;
    if (siteKey !== undefined) {
      properties.site_key = siteKey;
    }
    if (resultCount !== undefined) {
      properties.result_count = resultCount;
    }
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
   * 记录收藏事件 | Track favorite event
   * @param itemId 收藏项ID | Favorite item ID
   * @param itemType 收藏项类型 | Favorite item type
   */
  public trackFavorite(itemId: string, itemType: 'vod' | 'live'): void {
    if (!this.isEnabled) return;

    const properties = new EventProperties();
    properties.item_id = itemId;
    properties.item_type = itemType;
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
   * 记录错误事件 | Track error event
   * @param errorType 错误类型 | Error type
   * @param message 错误信息 | Error message
   * @param context 错误上下文 | Error context
   */
  public trackError(errorType: string, message: string, context?: EventProperties): void {
    if (!this.isEnabled) return;

    // 创建事件对象，手动合并参数 | Create event object, manually merge parameters
    const eventProperties = new EventProperties();
    eventProperties.error_type = errorType;
    eventProperties.error_message = message;

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
   * 添加事件到队列 | Add event to queue
   * @param event 分析事件 | Analytics event
   */
  private addToQueue(event: AnalyticsEvent): void {
    this.eventQueue.push(event);

    // 如果队列超过100个事件，立即上报 | If queue exceeds 100 events, report immediately
    if (this.eventQueue.length >= 100) {
      this.reportEvents();
    }
  }

  /**
   * 上报事件 | Report events
   */
  private async reportEvents(): Promise<void> {
    if (this.eventQueue.length === 0) return;

    // 使用传统方式复制数组，不使用扩展运算符 | Use traditional way to copy array, not using spread operator
    const eventsToReport: AnalyticsEvent[] = [];
    for (let i = 0; i < this.eventQueue.length; i++) {
      eventsToReport.push(this.eventQueue[i]);
    }
    this.eventQueue = [];

    try {
      // 这里应该发送到分析服务器 | Should send to analytics server here
      // 由于是本地实现，可以保存到本地存储或日志文件 | Since it's local implementation, can save to local storage or log file
      // 模拟上报 | Simulate report
      // await this.httpService.post('https://analytics-api.example.com/events', {
      //   events: eventsToReport
      // });

      // 保存到本地日志 | Save to local log
      await this.saveEventsToLog(eventsToReport);
    } catch (error) {
      // 上报失败，将事件重新加入队列 | Report failed, add events back to queue
      // 使用传统方式合并数组，不使用扩展运算符 | Use traditional way to merge array, not using spread operator
      for (let i = 0; i < eventsToReport.length; i++) {
        this.eventQueue.unshift(eventsToReport[i]);
      }
    }
  }

  /**
   * 保存事件到本地日志 | Save events to local log
   * @param events 事件列表 | Event list
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
      // 保存日志失败 | Save log failed
    }
  }

  /**
   * 启用/禁用分析 | Enable/disable analytics
   * @param enabled 是否启用 | Whether enabled
   */
  public async setEnabled(enabled: boolean): Promise<void> {
    this.isEnabled = enabled;
    const config: AnalyticsConfig = {
      enabled: enabled
    };
    await StorageUtil.setObject('analyticsConfig', config, StorageType.PREFERENCES);
  }

  /**
   * 获取分析状态 | Get analytics status
   */
  public getEnabled(): boolean {
    return this.isEnabled;
  }

  /**
   * 清除所有数据 | Clear all data
   */
  public async clearData(): Promise<void> {
    this.eventQueue = [];
    this.createNewSession();
    await StorageUtil.remove('userId', StorageType.PREFERENCES);
    this.userId = this.generateId();
    await StorageUtil.setString('userId', this.userId, StorageType.PREFERENCES);
  }

  /**
   * 获取使用统计摘要 | Get usage summary
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
          // 忽略解析错误 | Ignore parse error
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
