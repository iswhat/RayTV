// TimeoutManager - 超时管理工具类 Timeout Manager Utility Class
import Logger from './Logger';


const TAG = 'TimeoutManager';

/**
 * 超时管理器 Timeout Manager
 * 提供统一的超时控制和管理功能 Provides unified timeout control and management functionality
 */
export default class TimeoutManager {
  private static instance: TimeoutManager;
  private timeouts: Map<string, number> = new Map();
  private defaultTimeout: number = 30000; // 默认30秒超时 Default 30 seconds timeout

  /**
   * 私有构造函数 Private Constructor
   */
  private constructor() {
    Logger.info(TAG, 'TimeoutManager initialized');
  }

  /**
   * 获取单例实例 Get Singleton Instance
   */
  public static getInstance(): TimeoutManager {
    if (!TimeoutManager.instance) {
      TimeoutManager.instance = new TimeoutManager();
    }
    return TimeoutManager.instance;
  }

  /**
   * 设置默认超时时间 Set Default Timeout
   * @param milliseconds 默认超时时间(毫秒) Default timeout time (milliseconds)
   */
  public setDefaultTimeout(milliseconds: number): void {
    if (milliseconds > 0) {
      this.defaultTimeout = milliseconds;
      Logger.info(TAG, `Default timeout set to: ${milliseconds}ms`);
    }
  }

  /**
   * 创建超时任务 Create Timeout Task
   * @param id 超时任务ID Timeout task ID
   * @param callback 超时回调函数 Timeout callback function
   * @param timeout 超时时间(毫秒)，如果未指定则使用默认值 Timeout time (milliseconds), uses default if not specified
   */
  public setTimeout(id: string, callback: () => void, timeout?: number): void {
    // 清除已存在的相同ID的超时任务 Clear existing timeout task with the same ID
    this.clearTimeout(id);

    // 设置新的超时任务 Set new timeout task
    const actualTimeout = timeout || this.defaultTimeout;
    const timerId = setTimeout(() => {
      try {
        this.timeouts.delete(id);
        callback();
      } catch (error) {
        Logger.error(TAG, `Error in timeout callback for ${id}: ${error}`);
      }
    }, actualTimeout);

    this.timeouts.set(id, timerId);
    Logger.debug(TAG, `Timeout set for ${id}: ${actualTimeout}ms`);
  }

  /**
   * 清除指定ID的超时任务 Clear Timeout Task
   * @param id 超时任务ID Timeout task ID
   * @returns 是否成功清除 Whether cleared successfully
   */
  public clearTimeout(id: string): boolean {
    const timerId = this.timeouts.get(id);
    if (timerId) {
      clearTimeout(timerId);
      this.timeouts.delete(id);
      Logger.debug(TAG, `Timeout cleared for ${id}`);
      return true;
    }
    return false;
  }

  /**
   * 清除所有超时任务 Clear All Timeouts
   */
  public clearAllTimeouts(): void {
    for (const [id, timerId] of this.timeouts) {
      clearTimeout(timerId);
    }
    const count = this.timeouts.size;
    this.timeouts.clear();
    Logger.info(TAG, `Cleared all ${count} timeouts`);
  }

  /**
   * 创建带超时的Promise Create Timeout Promise
   * @param promise 原始Promise Original Promise
   * @param timeout 超时时间(毫秒) Timeout time (milliseconds)
   * @param timeoutMessage 超时错误消息 Timeout error message
   * @returns 包装后的Promise Wrapped Promise
   */
  public withTimeout<T>(
    promise: Promise<T>,
    timeout?: number,
    timeoutMessage?: string
  ): Promise<T> {
    const actualTimeout = timeout || this.defaultTimeout;
    const id = `promise_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    return new Promise<T>((resolve, reject) => {
      // 设置超时 Set timeout
      this.setTimeout(
        id,
        () => {
          reject(new Error(timeoutMessage || `Operation timed out after ${actualTimeout}ms`));
        },
        actualTimeout
      );

      // 处理原始Promise Process original Promise
      promise
        .then((result) => {
          this.clearTimeout(id);
          resolve(result);
        })
        .catch((error) => {
          this.clearTimeout(id);
          reject(error);
        });
    });
  }

  /**
   * 获取当前活跃的超时任务数量 Get Active Timeout Count
   */
  public getActiveTimeoutCount(): number {
    return this.timeouts.size;
  }

  /**
   * 检查指定ID的超时任务是否存在 Check Timeout Exists
   * @param id 超时任务ID Timeout task ID
   * @returns 是否存在 Whether it exists
   */
  public hasTimeout(id: string): boolean {
    return this.timeouts.has(id);
  }

  /**
   * 创建一个可取消的延迟函数 Create Cancellable Delay
   * @param delay 延迟时间(毫秒) Delay time (milliseconds)
   * @returns 包含promise和cancel方法的对象 Object with promise and cancel method
   */
  public delay(delay: number): {
    promise: Promise<void>;
    cancel: () => void;
  } {
    const id = `delay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    let cancelled = false;

    const promise = new Promise<void>((resolve) => {
      this.setTimeout(id, () => {
        if (!cancelled) {
          resolve();
        }
      }, delay);
    });

    const cancel = () => {
      cancelled = true;
      this.clearTimeout(id);
    };

    return { promise, cancel };
  }

  /**
   * 创建重试机制，带超时控制 Create Retry Mechanism with Timeout Control
   * @param fn 要重试的函数 Function to retry
   * @param options 重试选项 Retry options
   * @returns 执行结果 Execution result
   */
  public async withRetry<T>(
    fn: () => Promise<T>,
    options: {
      maxRetries?: number;
      retryDelay?: number;
      timeout?: number;
      onRetry?: (attempt: number, error: Error) => void;
    } = {}
  ): Promise<T> {
    try {
      const maxRetries = options.maxRetries ?? 3;
      const retryDelay = options.retryDelay ?? 1000;
      const timeout = options.timeout;
      const onRetry = options.onRetry;
      let lastError: Error | null = null;

      for (let attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          // 使用带超时的Promise执行函数 Execute function with timeout promise
          return await this.withTimeout(fn(), timeout);
        } catch (error) {
          lastError = error instanceof Error ? error : new Error(String(error));

          // 如果是最后一次尝试，则抛出错误 If it's the last attempt, throw error
          if (attempt >= maxRetries) {
            Logger.error(TAG, `All ${maxRetries + 1} attempts failed: ${lastError.message}`);
            throw lastError;
          }

          // 调用重试回调 Call retry callback
          if (onRetry) {
            try {
              onRetry(attempt + 1, lastError);
            } catch (callbackError) {
              Logger.error(TAG, `Error in retry callback: ${callbackError instanceof Error ? callbackError.message : String(callbackError)}`);
            }
          }

          Logger.warn(TAG, `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}`);

          // 等待重试延迟 Wait for retry delay
          await new Promise((resolve) => setTimeout(resolve, retryDelay));
        }
      }

      // 这一行理论上不会执行到，但为了类型安全 This line theoretically won't be executed, but for type safety
      const finalError = lastError || new Error('Retry failed without error');
      Logger.error(TAG, 'Unexpected end of retry loop: ' + finalError.message);
      throw finalError;
    } catch (error) {
      // 确保抛出的是Error类型 Ensure thrown value is Error type
      const finalError = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Error in withRetry method: ${finalError.message}`);
      throw finalError;
    }
  }
}



