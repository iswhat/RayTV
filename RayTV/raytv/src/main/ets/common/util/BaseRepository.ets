/**
 * BaseRepository - 基础仓库类
 * 提供统一的资源清理和事件监听管理
 */

import EventBusUtil from './EventBusUtil';

export abstract class BaseRepository {
  protected eventRegistrations: Array<{ event: string, handler: Function }> = [];
  private destroyed: boolean = false;
  private destroyLock: boolean = false;

  /**
   * 注册事件监听器
   * @param event 事件名称
   * @param handler 事件处理器
   */
  protected registerEventListener(event: string, handler: Function): void {
    if (this.destroyed) {
      console.warn(`BaseRepository: Cannot register event listener on destroyed instance [event: ${event}]`);
      return;
    }
    try {
      EventBusUtil.getInstance().on(event, handler);
      this.eventRegistrations.push({ event, handler });
    } catch (error) {
      console.error(`BaseRepository: Failed to register event listener [event: ${event}]:`, error);
    }
  }

  /**
   * 销毁资源（线程安全）
   * 清理所有事件监听器
   */
  public destroy(): void {
    if (this.destroyLock) {
      console.warn(`BaseRepository: Destroy already in progress for ${this.constructor.name}`);
      return;
    }

    if (this.destroyed) {
      console.debug(`BaseRepository: ${this.constructor.name} already destroyed`);
      return;
    }

    this.destroyLock = true;
    try {
      // 移除所有事件监听器
      this.eventRegistrations.forEach(({ event, handler }) => {
        try {
          EventBusUtil.getInstance().off(event, handler);
        } catch (error) {
          console.error(`BaseRepository: Failed to remove event listener [event: ${event}]:`, error);
        }
      });
      this.eventRegistrations = [];
      this.destroyed = true;

      console.debug(`${this.constructor.name}: Resources destroyed`);
    } catch (error) {
      console.error(`BaseRepository: Failed to destroy ${this.constructor.name}:`, error);
    } finally {
      this.destroyLock = false;
    }
  }

  /**
   * 检查资源是否已销毁
   * @returns 是否已销毁
   */
  protected isDestroyed(): boolean {
    return this.destroyed;
  }
}

export default BaseRepository;
