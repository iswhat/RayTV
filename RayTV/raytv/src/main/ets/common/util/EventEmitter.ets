// EventEmitter.ets - 简单的事件发射器实现 // Simple event emitter implementation
// 为AVPlayerService提供事件发射功能 // Provides event emission functionality for AVPlayerService

export class EventEmitter {
  private eventListeners: Map<string, Array<(...args: any[]) => void>> = new Map();

  /**
   * 注册事件监听器 // Register event listener
   * @param event 事件名称 // Event name
   * @param listener 事件处理函数 // Event handler function
   */
  public on(event: string, listener: (...args: any[]) => void): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    const listeners = this.eventListeners.get(event) as Array<(...args: any[]) => void>;
    listeners.push(listener);
  }

  /**
   * 移除事件监听器 // Remove event listener
   * @param event 事件名称 // Event name
   * @param listener 事件处理函数 // Event handler function
   */
  public off(event: string, listener: (...args: any[]) => void): void {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
      // 如果事件没有监听器了，删除该事件 // If event has no listeners, delete the event
      if (listeners.length === 0) {
        this.eventListeners.delete(event);
      }
    }
  }

  /**
   * 触发事件 // Emit event
   * @param event 事件名称 // Event name
   * @param args 事件参数 // Event arguments
   */
  public emit(event: string, ...args: any[]): void {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      // 复制监听器数组，避免在事件处理过程中修改 // Copy listener array to avoid modification during event processing
      const listenersCopy = listeners.slice();
      for (const listener of listenersCopy) {
        try {
          listener(...args);
        } catch (error) {
          console.error(`Error in event listener for ${event}:`, error);
        }
      }
    }
  }

  /**
   * 注册一次性事件监听器 // Register one-time event listener
   * @param event 事件名称 // Event name
   * @param listener 事件处理函数 // Event handler function
   */
  public once(event: string, listener: (...args: any[]) => void): void {
    const onceListener = (...args: any[]) => {
      this.off(event, onceListener);
      listener(...args);
    };
    this.on(event, onceListener);
  }

  /**
   * 移除指定事件的所有监听器 // Remove all listeners for specified event
   * @param event 事件名称 // Event name
   */
  public removeAllListeners(event?: string): void {
    if (event) {
      this.eventListeners.delete(event);
    } else {
      this.eventListeners.clear();
    }
  }

  /**
   * 获取指定事件的监听器数量 // Get listener count for specified event
   * @param event 事件名称 // Event name
   * @returns 监听器数量 // Listener count
   */
  public listenerCount(event: string): number {
    const listeners = this.eventListeners.get(event);
    return listeners ? listeners.length : 0;
  }

  /**
   * 获取所有事件名称 // Get all event names
   * @returns 事件名称数组 // Event name array
   */
  public eventNames(): string[] {
    return Array.from(this.eventListeners.keys());
  }
}
