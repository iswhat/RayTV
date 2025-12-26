/**
 * 事件总线工具类
 * 提供统一的事件发布订阅机制，支持命名空间、防抖、批量操作等功能
 */

import Logger from './Logger';

/**
 * 事件处理器类型
 */
export type EventHandler<T = Record<string, string | number | boolean | null>> = (data?: T) => void;

/**
 * 事件订阅接口
 */
export interface Subscription {
  /**
   * 事件处理器
   */
  handler: EventHandler;
  
  /**
   * 优先级（数值越小优先级越高）
   */
  priority: number;
  
  /**
   * 是否一次性订阅
   */
  once: boolean;
  
  /**
   * 命名空间
   */
  namespace?: string;
}

/**
 * 批量订阅事件接口
 */
export interface BatchEvent {
  eventName: string;
  handler: EventHandler;
  priority?: number;
  once?: boolean;
  namespace?: string;
}

/**
 * 批量发布事件接口
 */
export interface BatchEmitEvent<T = Record<string, string | number | boolean | null>> {
  eventName: string;
  data?: T;
}

/**
 * 事件总线工具类
 */
export class EventBusUtil {
  private static instance: EventBusUtil | undefined;
  private eventMap: Record<string, Subscription[]> = {};
  private isPublishing = false;
  private debounceTimers: Record<string, number> = {};

  /**
   * 获取单例实例
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
   * @param priority 优先级（默认0）
   * @param once 是否一次性订阅（默认false）
   * @param namespace 命名空间
   */
  public on<T = Record<string, string | number | boolean | null>>(
    eventName: string,
    handler: EventHandler<T>,
    priority: number = 0,
    once: boolean = false,
    namespace?: string
  ): void {
    if (!this.eventMap[eventName]) {
      this.eventMap[eventName] = [];
    }

    const subscription: Subscription = {
      handler: handler as EventHandler,
      priority,
      once,
      namespace
    };

    this.eventMap[eventName].push(subscription);
    // 按优先级排序
    this.eventMap[eventName].sort((a, b) => a.priority - b.priority);

    Logger.debug('EventBus', `Subscribed to event: ${eventName}, priority: ${priority}, once: ${once}`);
  }

  /**
   * 一次性订阅事件
   * @param eventName 事件名称
   * @param handler 事件处理器
   * @param priority 优先级
   * @param namespace 命名空间
   */
  public once<T = Record<string, string | number | boolean | null>>(
    eventName: string,
    handler: EventHandler<T>,
    priority: number = 0,
    namespace?: string
  ): void {
    this.on(eventName, handler, priority, true, namespace);
  }

  /**
   * 取消事件订阅
   * @param eventName 事件名称
   * @param handler 事件处理器（可选，不传则取消该事件的所有订阅）
   */
  public off<T = Record<string, string | number | boolean | null>>(
    eventName: string, 
    handler?: EventHandler<T>
  ): void {
    if (!this.eventMap[eventName]) {
      return;
    }

    if (handler) {
      // 取消特定处理器的订阅
      const index = this.findIndex(this.eventMap[eventName], sub => sub.handler === handler);
      if (index !== -1) {
        this.eventMap[eventName].splice(index, 1);
        Logger.debug('EventBus', `Unsubscribed handler from event: ${eventName}`);
      }
    } else {
      // 取消该事件的所有订阅
      this.eventMap[eventName] = [];
      Logger.debug('EventBus', `Unsubscribed all handlers from event: ${eventName}`);
    }

    // 如果事件没有订阅者了，删除事件条目
    if (this.eventMap[eventName] && this.eventMap[eventName].length === 0) {
      // 创建新对象，排除当前事件
      const newEventMap: Record<string, Subscription[]> = {};
      const keys = Object.keys(this.eventMap);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key !== eventName) {
          newEventMap[key] = this.eventMap[key];
        }
      }
      this.eventMap = newEventMap;
    }
  }

  /**
   * 发布事件
   * @param eventName 事件名称
   * @param data 事件数据
   */
  public emit<T>(
    eventName: string, 
    data?: T
  ): void {
    if (!this.eventMap[eventName]) {
      return;
    }

    // 防止在事件处理过程中修改订阅列表
    this.isPublishing = true;

    try {
      // 复制订阅列表，避免在遍历过程中修改
      const subscriptions = this.eventMap[eventName].slice();
      const onceSubscriptions: number[] = [];

      // 执行所有订阅者
      for (let i = 0; i < subscriptions.length; i++) {
        const subscription = subscriptions[i];
        
        try {
          subscription.handler(data as Record<string, string | number | boolean | null>);
          
          // 标记一次性订阅
          if (subscription.once) {
            onceSubscriptions.push(i);
          }
        } catch (error) {
          Logger.error('EventBus', `Error in event handler for ${eventName}:`, error instanceof Error ? error : new Error(String(error)));
        }
      }

      // 移除一次性订阅
      if (onceSubscriptions.length > 0) {
        // 从后往前删除，避免索引变化
        for (let i = onceSubscriptions.length - 1; i >= 0; i--) {
          const index = onceSubscriptions[i];
          if (this.eventMap[eventName]) {
            this.eventMap[eventName].splice(index, 1);
          }
        }
        
        // 如果事件没有订阅者了，删除事件条目
        if (this.eventMap[eventName] && this.eventMap[eventName].length === 0) {
          // 创建新对象，排除当前事件
          const newEventMap: Record<string, Subscription[]> = {};
          const keys = Object.keys(this.eventMap);
          for (let i = 0; i < keys.length; i++) {
            const key = keys[i];
            if (key !== eventName) {
              newEventMap[key] = this.eventMap[key];
            }
          }
          this.eventMap = newEventMap;
        }
      }

      Logger.debug('EventBus', `Emitted event: ${eventName}, subscribers: ${subscriptions.length}`);
    } finally {
      this.isPublishing = false;
    }
  }

  /**
   * 批量订阅事件
   * @param events 事件配置数组
   */
  public onBatch(events: BatchEvent[]): void {
    for (let i = 0; i < events.length; i++) {
      const event = events[i];
      this.on(
        event.eventName,
        event.handler,
        event.priority || 0,
        event.once || false,
        event.namespace
      );
    }
  }

  /**
   * 批量发布事件
   * @param events 事件数组
   */
  public emitBatch<T>(events: BatchEmitEvent<T>[]): void {
    for (let i = 0; i < events.length; i++) {
      const event = events[i];
      this.emit<T>(event.eventName, event.data);
    }
  }

  /**
   * 防抖事件发布
   * @param eventName 事件名称
   * @param data 事件数据
   * @param wait 等待时间（毫秒）
   */
  public emitDebounced<T>(
    eventName: string, 
    data?: T, 
    wait: number = 300
  ): void {
    const debounceKey = `__debounce_${eventName}`;
    
    // 清除之前的定时器
    this.clearDebounceTimer(debounceKey);
    
    // 创建新的定时器
    const timerId = setTimeout(() => {
      // 清除定时器引用
      const newDebounceTimers: Record<string, number> = {};
      const keys = Object.keys(this.debounceTimers);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key !== debounceKey) {
          newDebounceTimers[key] = this.debounceTimers[key];
        }
      }
      this.debounceTimers = newDebounceTimers;
      
      // 发布事件
      this.emit<T>(eventName, data);
      Logger.debug('EventBus', `Debounced event emitted: ${eventName}`);
    }, wait);
    
    // 存储定时器ID
    this.debounceTimers[debounceKey] = timerId;
    Logger.debug('EventBus', `Debounced event scheduled: ${eventName}, wait: ${wait}ms`);
  }

  /**
   * 清除指定事件的防抖定时器
   * @param debounceKey 防抖键
   */
  private clearDebounceTimer(debounceKey: string): void {
    if (this.debounceTimers[debounceKey]) {
      const timerId = this.debounceTimers[debounceKey];
      clearTimeout(timerId);
      
      // 创建新对象，排除当前防抖键
      const newDebounceTimers: Record<string, number> = {};
      const keys = Object.keys(this.debounceTimers);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key !== debounceKey) {
          newDebounceTimers[key] = this.debounceTimers[key];
        }
      }
      this.debounceTimers = newDebounceTimers;
      
      Logger.debug('EventBus', `Debounced timer cleared for key: ${debounceKey}`);
    }
  }

  /**
   * 清除所有防抖定时器
   */
  public clearAllDebounceTimers(): void {
    try {
      Logger.debug('EventBus', 'Clearing all debounce timers');
      const debounceKeys = Object.keys(this.debounceTimers);
      for (let i = 0; i < debounceKeys.length; i++) {
        const debounceKey = debounceKeys[i];
        const timerId = this.debounceTimers[debounceKey];
        clearTimeout(timerId);
      }
      this.debounceTimers = {};
    } catch (error) {
      Logger.error('EventBus', 'Failed to clear debounce timers', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 查找数组中元素的索引（兼容ES5的findIndex实现）
   * @param array 数组
   * @param predicate 断言函数
   * @returns 索引，未找到返回-1
   */
  private findIndex<T>(array: T[], predicate: (item: T) => boolean): number {
    for (let i = 0; i < array.length; i++) {
      if (predicate(array[i])) {
        return i;
      }
    }
    return -1;
  }

  /**
   * 检查是否有特定事件的订阅者
   * @param eventName 事件名称
   * @returns 是否有订阅者
   */
  public hasSubscribers(eventName: string): boolean {
    return !!this.eventMap[eventName] && this.eventMap[eventName].length > 0;
  }

  /**
   * 获取所有事件名称
   * @returns 事件名称数组
   */
  public getEventNames(): string[] {
    return Object.keys(this.eventMap);
  }

  /**
   * 清空所有事件订阅
   */
  public clear(): void {
    // 创建操作函数
    const clearAll = (): void => {
      this.eventMap = {};
      // 同时清除所有防抖定时器
      this.clearAllDebounceTimers();
      Logger.debug('EventBus', 'All event subscriptions cleared');
    };

    // 如果当前正在发布事件，延迟执行
    if (this.isPublishing) {
      setTimeout(clearAll, 0);
    } else {
      clearAll();
    }
  }

  /**
   * 销毁事件总线实例
   */
  public destroy(): void {
    this.clear();
    EventBusUtil.instance = undefined;
    Logger.debug('EventBus', 'EventBus instance destroyed');
  }
}

/**
 * 事件命名空间类
 */
export class EventNamespace {
  private namespace: string;
  private eventBus: EventBusUtil;

  constructor(namespace: string) {
    this.namespace = namespace;
    this.eventBus = EventBusUtil.getInstance();
  }

  /**
   * 订阅命名空间事件
   */
  public on<T = Record<string, string | number | boolean | null>>(
    eventName: string, 
    handler: EventHandler<T>, 
    priority: number = 0, 
    once: boolean = false
  ): void {
    const fullEventName = `${this.namespace}:${eventName}`;
    this.eventBus.on<T>(fullEventName, handler, priority, once, this.namespace);
  }

  /**
   * 一次性订阅命名空间事件
   */
  public once<T = Record<string, string | number | boolean | null>>(
    eventName: string, 
    handler: EventHandler<T>, 
    priority: number = 0
  ): void {
    this.on<T>(eventName, handler, priority, true);
  }

  /**
   * 取消命名空间事件订阅
   */
  public off<T = Record<string, string | number | boolean | null>>(
    eventName: string, 
    handler?: EventHandler<T>
  ): void {
    const fullEventName = `${this.namespace}:${eventName}`;
    this.eventBus.off<T>(fullEventName, handler);
  }

  /**
   * 发布命名空间事件
   */
  public emit<T = Record<string, string | number | boolean | null>>(
    eventName: string, 
    data?: T
  ): void {
    const fullEventName = `${this.namespace}:${eventName}`;
    this.eventBus.emit<T>(fullEventName, data);
  }

  /**
   * 清空命名空间下的所有事件订阅
   */
  public clear(): void {
    const allEvents = this.eventBus.getEventNames();
    const namespaceEvents: string[] = [];
    
    // 收集命名空间下的所有事件
    for (let i = 0; i < allEvents.length; i++) {
      const event = allEvents[i];
      if (event.startsWith(`${this.namespace}:`)) {
        namespaceEvents.push(event);
      }
    }
    
    // 取消所有命名空间下的事件订阅
    for (let i = 0; i < namespaceEvents.length; i++) {
      const event = namespaceEvents[i];
      this.eventBus.off(event);
    }
  }
}

/**
 * 全局事件类型枚举
 */
export enum GlobalEventType {
  // 应用事件
  APP_START = 'app:start',
  APP_READY = 'app:ready',
  APP_PAUSE = 'app:pause',
  APP_RESUME = 'app:resume',
  APP_STOP = 'app:stop',
  
  // 网络事件
  NETWORK_CONNECTED = 'network:connected',
  NETWORK_DISCONNECTED = 'network:disconnected',
  NETWORK_CHANGED = 'network:changed',
  
  // 用户事件
  USER_LOGIN = 'user:login',
  USER_LOGOUT = 'user:logout',
  USER_PROFILE_UPDATED = 'user:profile_updated',
  
  // 播放事件
  PLAYBACK_START = 'playback:start',
  PLAYBACK_PAUSE = 'playback:pause',
  PLAYBACK_STOP = 'playback:stop',
  PLAYBACK_COMPLETE = 'playback:complete',
  PLAYBACK_ERROR = 'playback:error',
  
  // 数据同步事件
  DATA_SYNC_START = 'data_sync:start',
  DATA_SYNC_COMPLETE = 'data_sync:complete',
  DATA_SYNC_ERROR = 'data_sync:error'
}

// 导出默认实例
export default EventBusUtil.getInstance();
