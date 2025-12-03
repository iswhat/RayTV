// TimeoutManager - 超时管理工具�?import Logger from './Logger';

const TAG = 'TimeoutManager';

/**
 * 超时管理�? * 提供统一的超时控制和管理功能
 */
export default class TimeoutManager {
  private static instance: TimeoutManager;
  private timeouts: Map<string, number> = new Map();
  private defaultTimeout: number = 30000; // 默认30秒超�?
  /**
   * 私有构造函�?   */
  private constructor() {
    Logger.info(TAG, 'TimeoutManager initialized');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): TimeoutManager {
    if (!TimeoutManager.instance) {
      TimeoutManager.instance = new TimeoutManager();
    }
    return TimeoutManager.instance;
  }

  /**
   * 设置默认超时时间
   * @param milliseconds 默认超时时间（毫秒）
   */
  public setDefaultTimeout(milliseconds: number): void {
    if (milliseconds > 0) {
      this.defaultTimeout = milliseconds;
      Logger.info(TAG, `Default timeout set to: ${milliseconds}ms`);
    }
  }

  /**
   * 创建超时任务
   * @param id 超时任务ID
   * @param callback 超时回调函数
   * @param timeout 超时时间（毫秒），如果不指定则使用默认�?   */
  public setTimeout(id: string, callback: () => void, timeout?: number): void {
    // 清除已存在的相同ID的超时任�?    this.clearTimeout(id);

    // 设置新的超时任务
    const actualTimeout = timeout || this.defaultTimeout;
    const timerId = setTimeout(() => {
      try {
        this.timeouts.delete(id);
        callback();
      } catch (error) {
        Logger.error(TAG, `Error in timeout callback for ${id}: ${error}`);
      }
    }, actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout instanceof Error ? actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout : new Error(String(actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout instanceof Error ? actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout instanceof Error ? actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout : new Error(String(actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout : new Error(String(actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout instanceof Error ? actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout : new Error(String(actualTimeout instanceof Error ? actualTimeout : new Error(String(actualTimeout)))))));

    this.timeouts.set(id, timerId);
    Logger.debug(TAG, `Timeout set for ${id}: ${actualTimeout}ms`);
  }

  /**
   * 清除指定ID的超时任�?   * @param id 超时任务ID
   * @returns 是否成功清除
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
   * 清除所有超时任�?   */
  public clearAllTimeouts(): void {
    for (const [id, timerId] of this.timeouts) {
      clearTimeout(timerId);
    }
    const count = this.timeouts.size;
    this.timeouts.clear();
    Logger.info(TAG, `Cleared all ${count} timeouts`);
  }

  /**
   * 创建带超时的Promise
   * @param promise 原始Promise
   * @param timeout 超时时间（毫秒）
   * @param timeoutMessage 超时错误消息
   * @returns 包装后的Promise
   */
  public withTimeout<T>(
    promise: Promise<T>,
    timeout?: number,
    timeoutMessage?: string
  ): Promise<T> {
    const actualTimeout = timeout || this.defaultTimeout;
    const id = `promise_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    return new Promise<T>((resolve, reject) => {
      // 设置超时
      this.setTimeout(
        id,
        () => {
          reject(new Error(timeoutMessage || `Operation timed out after ${actualTimeout}ms`));
        },
        actualTimeout
      );

      // 处理原始Promise
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
   * 获取当前活跃的超时任务数�?   */
  public getActiveTimeoutCount(): number {
    return this.timeouts.size;
  }

  /**
   * 检查指定ID的超时任务是否存�?   * @param id 超时任务ID
   * @returns 是否存在
   */
  public hasTimeout(id: string): boolean {
    return this.timeouts.has(id);
  }

  /**
   * 创建一个可取消的延迟函�?   * @param delay 延迟时间（毫秒）
   * @returns 包含promise和cancel方法的对�?   */
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
   * 创建重试机制，带超时控制
   * @param fn 要重试的函数
   * @param options 重试选项
   * @returns 执行结果
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
          // 使用带超时的Promise执行函数
          return await this.withTimeout(fn(), timeout);
        } catch (error) {
          lastError = error instanceof Error ? error : new Error(String(error));

          // 如果是最后一次尝试，则抛出错�?          if (attempt >= maxRetries) {
            Logger.error(TAG, `All ${maxRetries + 1} attempts failed: ${lastError.message}`);
            throw lastError;
          }

          // 调用重试回调
          if (onRetry) {
            try {
              onRetry(attempt + 1, lastError instanceof Error ? lastError : new Error(String(lastError instanceof Error ? lastError instanceof Error ? lastError : new Error(String(lastError : new Error(String(lastError instanceof Error ? lastError : new Error(String(lastError instanceof Error ? lastError instanceof Error ? lastError : new Error(String(lastError instanceof Error ? lastError instanceof Error ? lastError : new Error(String(lastError : new Error(String(lastError instanceof Error ? lastError : new Error(String(lastError : new Error(String(lastError instanceof Error ? lastError : new Error(String(lastError instanceof Error ? lastError instanceof Error ? lastError : new Error(String(lastError : new Error(String(lastError instanceof Error ? lastError : new Error(String(lastError)))))));
            } catch (callbackError) {
              Logger.error(TAG, `Error in retry callback: ${callbackError instanceof Error ? callbackError.message : String(callbackError)}`);
            }
          }

          Logger.warn(TAG, `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` instanceof Error ? `Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}` : new Error(String(`Attempt ${attempt + 1} failed, retrying in ${retryDelay}ms: ${lastError.message}`)))))));

          // 等待重试延迟
          await new Promise((resolve) => setTimeout(resolve, retryDelay));
        }
      }

      // 这一行理论上不会执行到，但为了类型安�?      const finalError = lastError || new Error('Retry failed without error');
      Logger.error(TAG, 'Unexpected end of retry loop: ' + finalError.message);
      throw finalError;
    } catch (error) {
      // 确保抛出的总是Error类型
      const finalError = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}` instanceof Error ? `Error in withRetry method: ${finalError.message}` : new Error(String(`Error in withRetry method: ${finalError.message}`)))))));
      throw finalError;
    }
  }
}


