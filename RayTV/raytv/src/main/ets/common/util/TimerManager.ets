/**
 * TimerManager - 定时器管理器
 * 统一管理所有定时器，防止定时器泄漏
 */

export class TimerManager {
  private static instance: TimerManager | null = null;
  private static initializationLock: boolean = false;
  private timers: Map<number, NodeJS.Timeout> = new Map();
  private timerIdCounter: number = 0;

  private constructor() {
    // Private constructor for singleton
  }

  /**
   * 获取TimerManager单例实例（线程安全）
   * @returns TimerManager实例
   */
  public static getInstance(): TimerManager {
    if (!TimerManager.instance && !TimerManager.initializationLock) {
      TimerManager.initializationLock = true;
      try {
        if (!TimerManager.instance) {
          TimerManager.instance = new TimerManager();
        }
      } finally {
        TimerManager.initializationLock = false;
      }
    }
    return TimerManager.instance!;
  }

  /**
   * 创建定时器
   * @param callback 回调函数
   * @param delay 延迟时间（毫秒）
   * @param context 上下文标识（用于日志）
   * @returns 定时器ID
   */
  public setInterval(
    callback: () => void,
    delay: number,
    context: string = 'unknown'
  ): number {
    const timerId = this.timerIdCounter++;
    const timer = setInterval(() => {
      try {
        callback();
      } catch (error) {
        console.error(`TimerManager: Timer callback failed [context: ${context}]:`, error);
      }
    }, delay);

    this.timers.set(timerId, timer);
    console.debug(`TimerManager: Created interval timer [id: ${timerId}, delay: ${delay}ms, context: ${context}]`);
    return timerId;
  }

  /**
   * 创建一次性定时器
   * @param callback 回调函数
   * @param delay 延迟时间（毫秒）
   * @param context 上下文标识（用于日志）
   * @returns 定时器ID
   */
  public setTimeout(
    callback: () => void,
    delay: number,
    context: string = 'unknown'
  ): number {
    const timerId = this.timerIdCounter++;
    const timer = setTimeout(() => {
      try {
        callback();
      } catch (error) {
        console.error(`TimerManager: Timer callback failed [context: ${context}]:`, error);
      }
      // 执行后自动清理
      this.timers.delete(timerId);
    }, delay);

    this.timers.set(timerId, timer);
    console.debug(`TimerManager: Created timeout timer [id: ${timerId}, delay: ${delay}ms, context: ${context}]`);
    return timerId;
  }

  /**
   * 清除定时器
   * @param timerId 定时器ID
   */
  public clearInterval(timerId: number): void {
    const timer = this.timers.get(timerId);
    if (timer) {
      clearInterval(timer);
      this.timers.delete(timerId);
      console.debug(`TimerManager: Cleared interval timer [id: ${timerId}]`);
    }
  }

  /**
   * 清除一次性定时器
   * @param timerId 定时器ID
   */
  public clearTimeout(timerId: number): void {
    const timer = this.timers.get(timerId);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(timerId);
      console.debug(`TimerManager: Cleared timeout timer [id: ${timerId}]`);
    }
  }

  /**
   * 清除所有定时器
   */
  public clearAll(): void {
    this.timers.forEach((timer) => {
      clearInterval(timer);
      clearTimeout(timer);
    });
    const count = this.timers.size;
    this.timers.clear();
    console.debug(`TimerManager: Cleared all timers [count: ${count}]`);
  }

  /**
   * 获取当前定时器数量
   * @returns 定时器数量
   */
  public getTimerCount(): number {
    return this.timers.size;
  }
}

export default TimerManager;
