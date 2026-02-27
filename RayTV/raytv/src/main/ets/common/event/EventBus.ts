/**
 * 事件总线系统 | Event Bus System
 * 实现组件间的松耦合通信 | Implements loose coupling communication between components
 */
import Logger from '../util/Logger';

// 事件回调类型 | Event callback type
export type EventCallback<T = any> = (data: T) => void;

// 事件监听器 | Event listener
export interface EventListener<T = any> {
  id: string;
  callback: EventCallback<T>;
  once: boolean;
}

// 事件数据 | Event data
export interface EventData<T = any> {
  name: string;
  data: T;
  timestamp: number;
  source?: string;
}

/**
 * 事件总线类 | Event bus class
 */
export class EventBus {
  private static instance: EventBus | null = null;
  private listeners: Map<string, EventListener[]> = new Map();
  private logger: Logger;
  private eventIdCounter: number = 0;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): EventBus {
    if (!EventBus.instance) {
      EventBus.instance = new EventBus();
    }
    return EventBus.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.logger = new Logger('EventBus');
  }

  /**
   * 订阅事件 | Subscribe to event
   * @param eventName 事件名称 | Event name
   * @param callback 回调函数 | Callback function
   * @param once 是否只触发一次 | Whether trigger only once
   * @returns 监听器ID | Listener ID
   */
  public subscribe<T = any>(
    eventName: string,
    callback: EventCallback<T>,
    once: boolean = false
  ): string {
    const listenerId = this.generateListenerId();
    const listener: EventListener<T> = {
      id: listenerId,
      callback,
      once
    };

    if (!this.listeners.has(eventName)) {
      this.listeners.set(eventName, []);
    }

    this.listeners.get(eventName)!.push(listener);
    this.logger.info(`Subscribed to event: ${eventName} (id: ${listenerId})`);
    
    return listenerId;
  }

  /**
   * 订阅一次性事件 | Subscribe to one-time event
   * @param eventName 事件名称 | Event name
   * @param callback 回调函数 | Callback function
   * @returns 监听器ID | Listener ID
   */
  public once<T = any>(eventName: string, callback: EventCallback<T>): string {
    return this.subscribe(eventName, callback, true);
  }

  /**
   * 取消订阅 | Unsubscribe
   * @param eventName 事件名称 | Event name
   * @param listenerId 监听器ID | Listener ID
   */
  public unsubscribe(eventName: string, listenerId: string): void {
    const listeners = this.listeners.get(eventName);
    if (listeners) {
      const index = listeners.findIndex(listener => listener.id === listenerId);
      if (index !== -1) {
        listeners.splice(index, 1);
        this.logger.info(`Unsubscribed from event: ${eventName} (id: ${listenerId})`);
        
        // 如果没有监听器了，删除事件 | If no listeners left, delete event
        if (listeners.length === 0) {
          this.listeners.delete(eventName);
        }
      }
    }
  }

  /**
   * 取消所有订阅 | Unsubscribe all
   * @param eventName 可选的事件名称，如果不提供则取消所有事件 | Optional event name, cancels all events if not provided
   */
  public unsubscribeAll(eventName?: string): void {
    if (eventName) {
      this.listeners.delete(eventName);
      this.logger.info(`Unsubscribed all listeners from event: ${eventName}`);
    } else {
      this.listeners.clear();
      this.logger.info('Unsubscribed all listeners from all events');
    }
  }

  /**
   * 发布事件 | Publish event
   * @param eventName 事件名称 | Event name
   * @param data 事件数据 | Event data
   * @param source 事件来源 | Event source
   */
  public publish<T = any>(eventName: string, data?: T, source?: string): void {
    const listeners = this.listeners.get(eventName);
    if (!listeners || listeners.length === 0) {
      this.logger.debug(`No listeners for event: ${eventName}`);
      return;
    }

    const eventData: EventData<T> = {
      name: eventName,
      data: data as T,
      timestamp: Date.now(),
      source
    };

    // 创建监听器副本以避免在遍历过程中修改数组 | Create listener copy to avoid modifying array during iteration
    const listenersCopy = [...listeners];
    const remainingListeners: EventListener[] = [];

    listenersCopy.forEach(listener => {
      try {
        listener.callback(eventData.data);
        
        // 如果不是一次性监听器，保留它 | Keep it if not one-time listener
        if (!listener.once) {
          remainingListeners.push(listener);
        } else {
          this.logger.debug(`One-time listener executed and removed: ${listener.id}`);
        }
      } catch (error) {
        this.logger.error(`Error in event listener ${listener.id} for event ${eventName}`, error);
      }
    });

    // 更新监听器列表 | Update listener list
    if (remainingListeners.length === 0) {
      this.listeners.delete(eventName);
    } else {
      this.listeners.set(eventName, remainingListeners);
    }

    this.logger.info(`Published event: ${eventName} to ${listenersCopy.length} listeners`);
  }

  /**
   * 检查是否有监听器 | Check if has listeners
   * @param eventName 事件名称 | Event name
   * @returns 是否有监听器 | Whether has listeners
   */
  public hasListeners(eventName: string): boolean {
    const listeners = this.listeners.get(eventName);
    return !!listeners && listeners.length > 0;
  }

  /**
   * 获取监听器数量 | Get listener count
   * @param eventName 事件名称 | Event name
   * @returns 监听器数量 | Listener count
   */
  public getListenerCount(eventName: string): number {
    const listeners = this.listeners.get(eventName);
    return listeners ? listeners.length : 0;
  }

  /**
   * 获取所有事件名称 | Get all event names
   * @returns 事件名称数组 | Event name array
   */
  public getAllEventNames(): string[] {
    return Array.from(this.listeners.keys());
  }

  /**
   * 清理过期的一次性监听器 | Clean up expired one-time listeners
   */
  public cleanup(): void {
    let cleanedCount = 0;
    
    this.listeners.forEach((listeners, eventName) => {
      const validListeners = listeners.filter(listener => !listener.once);
      if (validListeners.length !== listeners.length) {
        cleanedCount += listeners.length - validListeners.length;
        if (validListeners.length === 0) {
          this.listeners.delete(eventName);
        } else {
          this.listeners.set(eventName, validListeners);
        }
      }
    });

    if (cleanedCount > 0) {
      this.logger.info(`Cleaned up ${cleanedCount} expired one-time listeners`);
    }
  }

  /**
   * 销毁事件总线 | Destroy event bus
   */
  public destroy(): void {
    this.listeners.clear();
    this.logger.info('EventBus destroyed');
  }

  /**
   * 生成监听器ID | Generate listener ID
   * @returns 监听器ID | Listener ID
   */
  private generateListenerId(): string {
    return `listener_${++this.eventIdCounter}_${Date.now()}`;
  }
}

// 便捷的事件类型定义 | Convenient event type definitions

/**
 * 应用事件枚举 | Application events enum
 */
export enum AppEvents {
  // 配置源相关事件 | Config source related events
  CONFIG_SOURCE_ADDED = 'config_source_added',
  CONFIG_SOURCE_REMOVED = 'config_source_removed',
  CONFIG_SOURCE_UPDATED = 'config_source_updated',
  CONFIG_SOURCE_HEALTH_CHECK = 'config_source_health_check',

  // 内容聚合相关事件 | Content aggregation related events
  CONTENT_AGGREGATION_START = 'content_aggregation_start',
  CONTENT_AGGREGATION_COMPLETE = 'content_aggregation_complete',
  CONTENT_AGGREGATION_ERROR = 'content_aggregation_error',

  // 播放相关事件 | Playback related events
  PLAYBACK_START = 'playback_start',
  PLAYBACK_PAUSE = 'playback_pause',
  PLAYBACK_STOP = 'playback_stop',
  PLAYBACK_ERROR = 'playback_error',
  PLAYBACK_PROGRESS = 'playback_progress',

  // 用户界面事件 | UI events
  NAVIGATION_CHANGE = 'navigation_change',
  FOCUS_CHANGE = 'focus_change',
  THEME_CHANGE = 'theme_change',

  // 系统事件 | System events
  APP_RESUME = 'app_resume',
  APP_SUSPEND = 'app_suspend',
  NETWORK_STATUS_CHANGE = 'network_status_change',
  STORAGE_LOW = 'storage_low'
}

// 导出单例实例 | Export singleton instance
export default EventBus.getInstance();