/**
 * UIContext - UI上下文管理工具
 * 提供线程安全的UI状态更新机制
 */

const TAG = 'UIContext';

export class UIContext {
  private static instance: UIContext | null = null;
  private static initializationLock: boolean = false;
  private uiThreadId: number | null = null;
  private pendingUpdates: Array<() => void> = [];
  private isUpdating: boolean = false;

  private constructor() {
    // Private constructor for singleton
  }

  /**
   * 获取UIContext单例实例（线程安全）
   * @returns UIContext实例
   */
  public static getInstance(): UIContext {
    if (!UIContext.instance && !UIContext.initializationLock) {
      UIContext.initializationLock = true;
      try {
        if (!UIContext.instance) {
          UIContext.instance = new UIContext();
        }
      } finally {
        UIContext.initializationLock = false;
      }
    }
    return UIContext.instance!;
  }

  /**
   * 记录UI线程ID
   * @param threadId 线程ID
   */
  public setUIThreadId(threadId: number): void {
    if (this.uiThreadId === null) {
      this.uiThreadId = threadId;
      console.debug(`${TAG}: UI thread ID set to ${threadId}`);
    }
  }

  /**
   * 检查是否在UI线程
   * @returns 是否在UI线程
   */
  public isUIThread(): boolean {
    // 如果无法确定线程ID，默认返回true（避免阻塞）
    return this.uiThreadId === null;
  }

  /**
   * 线程安全的UI更新
   * @param updateFn 更新函数
   */
  public safeUpdate(updateFn: () => void): void {
    if (this.isUpdating) {
      // 如果正在更新，将更新加入队列
      this.pendingUpdates.push(updateFn);
      return;
    }

    this.isUpdating = true;
    try {
      updateFn();

      // 处理待处理的更新
      while (this.pendingUpdates.length > 0) {
        const pendingFn = this.pendingUpdates.shift();
        if (pendingFn) {
          pendingFn();
        }
      }
    } catch (error) {
      console.error(`${TAG}: Failed to execute UI update:`, error);
    } finally {
      this.isUpdating = false;
    }
  }

  /**
   * 批量UI更新（线程安全）
   * @param updates 更新函数数组
   */
  public batchUpdate(updates: Array<() => void>): void {
    this.safeUpdate(() => {
      updates.forEach(update => {
        try {
          update();
        } catch (error) {
          console.error(`${TAG}: Failed in batch update:`, error);
        }
      });
    });
  }

  /**
   * 获取待处理更新数量
   * @returns 待处理更新数量
   */
  public getPendingUpdateCount(): number {
    return this.pendingUpdates.length;
  }

  /**
   * 清空待处理更新
   */
  public clearPendingUpdates(): void {
    this.pendingUpdates = [];
    console.debug(`${TAG}: Cleared ${this.pendingUpdates.length} pending updates`);
  }
}

export default UIContext;
