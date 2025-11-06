// EventBusUtil - 事件总线工具类
// 提供全局事件发布订阅机制，用于组件间通信

import Logger from '../common/util/Logger';

/**
 * 事件处理器函数类型
 */
export type EventHandler<T = unknown> = (data?: T) => void;

/**
 * 事件订阅信息接口
 */
interface Subscription {
  handler: EventHandler;
  once: boolean;
  priority: number;
}

/**
 * 事件总线工具类
 */
export class EventBusUtil {
  private static instance: EventBusUtil;
  private logger = Logger.getInstance();
  private eventMap: Map<string, Subscription[]> = new Map();
  private isPublishing = false;
  private pendingOperations: (() => void)[] = [];
  private debounceTimers: Map<string, number> = new Map();

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('EventBusUtil initialized');
  }

  /**
   * 获取EventBusUtil单例实例
   */
  public static getInstance(): EventBusUtil {
    if (!EventBusUtil.instance) {
      EventBusUtil.instance = new EventBusUtil();
    }
    return EventBusUtil.instance;
  }

  /**
   * 订阅事件
   * @param eventName 事件名称
   * @param handler 事件处理器
   * @param options 订阅选项
   */
  public on<T = unknown>(eventName: string, handler: EventHandler<T>, options: { once?: boolean; priority?: number } = {}): () => void {
    try {
      this.logger.debug(`Subscribing to event: ${eventName}, once: ${options.once || false}`);
      
      const subscription: Subscription = {
        handler: handler as EventHandler,
        once: options.once || false,
        priority: options.priority || 0
      };

      const operation = () => {
        if (!this.eventMap.has(eventName)) {
          this.eventMap.set(eventName, []);
        }
        
        const subscriptions = this.eventMap.get(eventName)!;
        subscriptions.push(subscription);
        
        // 按优先级排序（优先级高的先执行）
        subscriptions.sort((a, b) => b.priority - a.priority);
      };

      if (this.isPublishing) {
        this.pendingOperations.push(operation);
      } else {
        operation();
      }

      // 返回取消订阅的函数
      return () => this.off(eventName, handler);
    } catch (error) {
      this.logger.error(`Failed to subscribe to event: ${eventName}`, error as Error);
      return () => {};
    }
  }

  /**
   * 订阅事件（仅执行一次）
   * @param eventName 事件名称
   * @param handler 事件处理器
   * @param options 订阅选项
   */
  public once<T = unknown>(eventName: string, handler: EventHandler<T>, options: { priority?: number } = {}): () => void {
    return this.on(eventName, handler, { ...options, once: true });
  }

  /**
   * 取消订阅事件
   * @param eventName 事件名称
   * @param handler 事件处理器（可选，如果不提供则取消该事件的所有订阅）
   */
  public off(eventName: string, handler?: EventHandler): void {
    try {
      this.logger.debug(`Unsubscribing from event: ${eventName}`);
      
      const operation = () => {
        if (!this.eventMap.has(eventName)) {
          return;
        }

        const subscriptions = this.eventMap.get(eventName)!;

        if (handler) {
          // 取消特定处理器的订阅
          const index = subscriptions.findIndex(sub => sub.handler === handler);
          if (index !== -1) {
            subscriptions.splice(index, 1);
          }
        } else {
          // 取消所有订阅
          subscriptions.length = 0;
        }

        // 如果没有订阅者了，删除事件
        if (subscriptions.length === 0) {
          this.eventMap.delete(eventName);
        }
      };

      if (this.isPublishing) {
        this.pendingOperations.push(operation);
      } else {
        operation();
      }
    } catch (error) {
      this.logger.error(`Failed to unsubscribe from event: ${eventName}`, error as Error);
    }
  }

  /**
   * 发布事件
   * @param eventName 事件名称
   * @param data 事件数据
   */
  public emit<T = unknown>(eventName: string, data?: T): void {
    try {
      this.logger.debug(`Emitting event: ${eventName}`);
      
      this.isPublishing = true;
      const onceHandlersToRemove: EventHandler[] = [];

      try {
        if (this.eventMap.has(eventName)) {
          const subscriptions = [...this.eventMap.get(eventName)!]; // 创建副本，避免执行过程中的修改影响循环
          
          for (const subscription of subscriptions) {
            try {
              subscription.handler(data);
              
              // 标记一次性处理器
              if (subscription.once) {
                onceHandlersToRemove.push(subscription.handler);
              }
            } catch (handlerError) {
              this.logger.error(`Error in event handler for: ${eventName}`, handlerError as Error);
            }
          }
        }
      } finally {
        // 处理一次性处理器的移除
        for (const handler of onceHandlersToRemove) {
          this.off(eventName, handler);
        }
        
        this.isPublishing = false;
        
        // 执行待处理的操作
        this.processPendingOperations();
      }
    } catch (error) {
      this.logger.error(`Failed to emit event: ${eventName}`, error as Error);
      this.isPublishing = false;
      this.processPendingOperations();
    }
  }

  /**
   * 获取事件的订阅数量
   * @param eventName 事件名称
   */
  public getSubscriptionCount(eventName: string): number {
    if (!this.eventMap.has(eventName)) {
      return 0;
    }
    return this.eventMap.get(eventName)!.length;
  }

  /**
   * 检查是否有特定事件的订阅者
   * @param eventName 事件名称
   */
  public hasSubscribers(eventName: string): boolean {
    return this.getSubscriptionCount(eventName) > 0;
  }

  /**
   * 获取所有已注册的事件名称
   */
  public getEventNames(): string[] {
    return Array.from(this.eventMap.keys());
  }

  /**
   * 清空所有事件订阅
   */
  public clear(): void {
    try {
      this.logger.debug('Clearing all event subscriptions');
      
      const operation = () => {
        this.eventMap.clear();
        // 同时清除所有防抖定时器
        this.clearAllDebounceTimers();
      };

      if (this.isPublishing) {
        this.pendingOperations.push(operation);
      } else {
        operation();
      }
    } catch (error) {
      this.logger.error('Failed to clear event subscriptions', error as Error);
    }
  }

  /**
   * 清空特定事件的所有订阅
   * @param eventName 事件名称
   */
  public clearEvent(eventName: string): void {
    this.off(eventName);
  }

  /**
   * 创建事件命名空间
   * @param namespace 命名空间名称
   */
  public createNamespace(namespace: string): EventNamespace {
    return new EventNamespace(namespace, this);
  }

  /**
   * 执行待处理的操作
   */
  private processPendingOperations(): void {
    while (this.pendingOperations.length > 0) {
      const operation = this.pendingOperations.shift();
      if (operation) {
        try {
          operation();
        } catch (error) {
          this.logger.error('Error processing pending operation', error as Error);
        }
      }
    }
  }

  /**
   * 批量订阅多个事件
   * @param subscriptions 订阅配置数组
   */
  public subscribeMultiple(subscriptions: Array<{
    eventName: string;
    handler: EventHandler;
    options?: { once?: boolean; priority?: number };
  }>): () => void {
    const unsubscribeFunctions = subscriptions.map(sub => 
      this.on(sub.eventName, sub.handler, sub.options || {})
    );

    // 返回批量取消订阅的函数
    return () => {
      unsubscribeFunctions.forEach(unsubscribe => unsubscribe());
    };
  }

  /**
   * 批量发布多个事件
   * @param events 事件配置数组
   */
  public emitMultiple(events: Array<{
    eventName: string;
    data?: unknown;
  }>): void {
    events.forEach(event => {
      this.emit(event.eventName, event.data);
    });
  }

  /**
   * 创建延迟事件发布
   * @param eventName 事件名称
   * @param data 事件数据
   * @param delay 延迟时间（毫秒）
   */
  public emitDelayed<T = unknown>(eventName: string, data?: T, delay: number = 0): () => void {
    const timeoutId = setTimeout(() => {
      this.emit(eventName, data);
    }, delay);

    // 返回取消延迟事件的函数
    return () => {
      clearTimeout(timeoutId);
      this.logger.debug(`Delayed event canceled: ${eventName}`);
    };
  }

  /**
   * 防抖事件发布
   * @param eventName 事件名称
   * @param data 事件数据
   * @param wait 等待时间（毫秒）
   */
  public emitDebounced<T = unknown>(eventName: string, data?: T, wait: number = 300): void {
    const debounceKey = `__debounce_${eventName}`;
    
    // 清除之前的定时器
    this.clearDebounceTimer(debounceKey);
    
    // 创建新的定时器
    const timerId = setTimeout(() => {
      // 清除定时器引用
      this.debounceTimers.delete(debounceKey);
      // 发布事件
      this.emit(eventName, data);
      this.logger.debug(`Debounced event emitted: ${eventName}`);
    }, wait);
    
    // 存储定时器ID
    this.debounceTimers.set(debounceKey, timerId);
    this.logger.debug(`Debounced event scheduled: ${eventName}, wait: ${wait}ms`);
  }
  
  /**
   * 清除指定事件的防抖定时器
   * @param debounceKey 防抖键
   */
  private clearDebounceTimer(debounceKey: string): void {
    if (this.debounceTimers.has(debounceKey)) {
      const timerId = this.debounceTimers.get(debounceKey)!;
      clearTimeout(timerId);
      this.debounceTimers.delete(debounceKey);
      this.logger.debug(`Debounced timer cleared for key: ${debounceKey}`);
    }
  }
  
  /**
   * 清除所有防抖定时器
   */
  public clearAllDebounceTimers(): void {
    try {
      this.logger.debug('Clearing all debounce timers');
      this.debounceTimers.forEach(timerId => {
        clearTimeout(timerId);
      });
      this.debounceTimers.clear();
    } catch (error) {
      this.logger.error('Failed to clear debounce timers', error as Error);
    }
  }
}

/**
 * 事件命名空间类
 */
export class EventNamespace {
  private eventBus: EventBusUtil;
  private namespace: string;

  /**
   * 构造函数
   * @param namespace 命名空间名称
   * @param eventBus 事件总线实例
   */
  constructor(namespace: string, eventBus: EventBusUtil) {
    this.namespace = namespace;
    this.eventBus = eventBus;
  }

  /**
   * 构建带命名空间的事件名称
   * @param eventName 事件名称
   */
  private getNamespacedEventName(eventName: string): string {
    return `${this.namespace}:${eventName}`;
  }

  /**
   * 订阅事件
   * @param eventName 事件名称
   * @param handler 事件处理器
   * @param options 订阅选项
   */
  public on<T = unknown>(eventName: string, handler: EventHandler<T>, options?: { once?: boolean; priority?: number }): () => void {
    return this.eventBus.on(this.getNamespacedEventName(eventName), handler, options);
  }

  /**
   * 订阅事件（仅执行一次）
   * @param eventName 事件名称
   * @param handler 事件处理器
   * @param options 订阅选项
   */
  public once<T = unknown>(eventName: string, handler: EventHandler<T>, options?: { priority?: number }): () => void {
    return this.eventBus.once(this.getNamespacedEventName(eventName), handler, options);
  }

  /**
   * 取消订阅事件
   * @param eventName 事件名称
   * @param handler 事件处理器（可选）
   */
  public off(eventName: string, handler?: EventHandler): void {
    this.eventBus.off(this.getNamespacedEventName(eventName), handler);
  }

  /**
   * 发布事件
   * @param eventName 事件名称
   * @param data 事件数据
   */
  public emit<T = unknown>(eventName: string, data?: T): void {
    this.eventBus.emit(this.getNamespacedEventName(eventName), data);
  }

  /**
   * 清空命名空间下的所有事件订阅
   */
  public clear(): void {
    const allEvents = this.eventBus.getEventNames();
    const namespaceEvents = allEvents.filter(event => event.startsWith(`${this.namespace}:`));
    
    namespaceEvents.forEach(event => {
      this.eventBus.clearEvent(event);
    });
  }
}

// 预定义的全局事件类型
export enum GlobalEventType {
  // 应用生命周期事件
  APP_START = 'app:start',
  APP_RESUME = 'app:resume',
  APP_PAUSE = 'app:pause',
  APP_STOP = 'app:stop',
  APP_ERROR = 'app:error',
  APP_UPDATE = 'app:update',
  
  // 用户相关事件
  USER_LOGIN = 'user:login',
  USER_LOGOUT = 'user:logout',
  USER_UPDATE = 'user:update',
  USER_PERMISSION_CHANGE = 'user:permission:change',
  
  // 网络相关事件
  NETWORK_STATUS_CHANGE = 'network:status:change',
  NETWORK_SLOW = 'network:slow',
  NETWORK_ERROR = 'network:error',
  
  // 数据相关事件
  DATA_UPDATE = 'data:update',
  DATA_LOADING_START = 'data:loading:start',
  DATA_LOADING_END = 'data:loading:end',
  DATA_REFRESH = 'data:refresh',
  
  // 播放相关事件
  PLAYER_PLAY = 'player:play',
  PLAYER_PAUSE = 'player:pause',
  PLAYER_STOP = 'player:stop',
  PLAYER_PROGRESS = 'player:progress',
  PLAYER_ERROR = 'player:error',
  PLAYER_FULLSCREEN = 'player:fullscreen',
  
  // 下载相关事件
  DOWNLOAD_START = 'download:start',
  DOWNLOAD_PROGRESS = 'download:progress',
  DOWNLOAD_COMPLETE = 'download:complete',
  DOWNLOAD_ERROR = 'download:error',
  DOWNLOAD_CANCEL = 'download:cancel',
  
  // 收藏相关事件
  FAVORITE_ADD = 'favorite:add',
  FAVORITE_REMOVE = 'favorite:remove',
  FAVORITE_UPDATE = 'favorite:update',
  
  // 历史记录相关事件
  HISTORY_ADD = 'history:add',
  HISTORY_UPDATE = 'history:update',
  HISTORY_CLEAR = 'history:clear',
  
  // 搜索相关事件
  SEARCH_START = 'search:start',
  SEARCH_COMPLETE = 'search:complete',
  SEARCH_ERROR = 'search:error',
  
  // 配置相关事件
  CONFIG_CHANGE = 'config:change',
  
  // UI相关事件
  UI_THEME_CHANGE = 'ui:theme:change',
  UI_LANGUAGE_CHANGE = 'ui:language:change',
  UI_SIZE_CHANGE = 'ui:size:change',
  
  // 通知相关事件
  NOTIFICATION_SHOW = 'notification:show',
  NOTIFICATION_CLOSE = 'notification:close',
  
  // 日志相关事件
  LOG_ERROR = 'log:error',
  LOG_WARN = 'log:warn',
  
  // 安全相关事件
  SECURITY_TOKEN_EXPIRE = 'security:token:expire',
  SECURITY_PERMISSION_DENY = 'security:permission:deny'
}

// 导出默认实例
export default EventBusUtil.getInstance();