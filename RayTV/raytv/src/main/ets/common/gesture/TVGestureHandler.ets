export interface GestureEvent {
  type: 'swipe' | 'tap' | 'longPress' | 'keyPress';
  direction?: 'up' | 'down' | 'left' | 'right';
  distance?: number;
  duration?: number;
  key?: string;
}

export interface GestureListener {
  (event: GestureEvent): void;
}

export class TVGestureHandler {
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private touchStartTime: number = 0;
  private isTouching: boolean = false;
  private listeners: GestureListener[] = [];
  private longPressTimer: number | null = null;
  private config: {
    swipeThreshold: number;
    longPressThreshold: number;
    enableTouch: boolean;
    enableKeyboard: boolean;
  };

  constructor(config?: Partial<TVGestureHandler['config']>) {
    this.config = {
      swipeThreshold: 50,
      longPressThreshold: 500,
      enableTouch: true,
      enableKeyboard: true,
      ...config
    };
    this.initializeEventListeners();
  }

  private initializeEventListeners(): void {
    // HarmonyOS中事件监听需要使用系统提供的API
    // 这里暂时保留结构，实际实现需要根据HarmonyOS的事件系统进行调整
  }

  private handleTouchStart(event: TouchEvent): void {
    if (event.touches && event.touches.length === 1) {
      const touch = event.touches[0];
      this.touchStartX = touch.clientX || 0;
      this.touchStartY = touch.clientY || 0;
      this.touchStartTime = Date.now();
      this.isTouching = true;

      // Set up long press timer
      this.longPressTimer = setTimeout(() => {
        this.emitGestureEvent({ type: 'longPress', duration: Date.now() - this.touchStartTime });
      }, this.config.longPressThreshold);
    }
  }

  private handleTouchMove(event: TouchEvent): void {
    if (!this.isTouching) return;

    const touch = event.touches[0];
    const currentX = touch.clientX || 0;
    const currentY = touch.clientY || 0;
    const distanceX = currentX - this.touchStartX;
    const distanceY = currentY - this.touchStartY;

    // If we've moved beyond the swipe threshold, cancel long press
    if (Math.abs(distanceX) > this.config.swipeThreshold || Math.abs(distanceY) > this.config.swipeThreshold) {
      if (this.longPressTimer) {
        clearTimeout(this.longPressTimer);
        this.longPressTimer = null;
      }
    }
  }

  private handleTouchEnd(event: TouchEvent): void {
    if (!this.isTouching) return;

    // Cancel long press timer
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }

    const touch = event.changedTouches[0];
    const endX = touch.clientX || 0;
    const endY = touch.clientY || 0;
    const distanceX = endX - this.touchStartX;
    const distanceY = endY - this.touchStartY;
    const duration = Date.now() - this.touchStartTime;

    // Determine if it's a swipe or tap
    if (Math.abs(distanceX) > this.config.swipeThreshold || Math.abs(distanceY) > this.config.swipeThreshold) {
      // Swipe
      let direction: 'up' | 'down' | 'left' | 'right';
      if (Math.abs(distanceX) > Math.abs(distanceY)) {
        direction = distanceX > 0 ? 'right' : 'left';
      } else {
        direction = distanceY > 0 ? 'down' : 'up';
      }
      this.emitGestureEvent({ type: 'swipe', direction, distance: Math.sqrt(distanceX * distanceX + distanceY * distanceY), duration });
    } else if (duration < this.config.longPressThreshold) {
      // Tap
      this.emitGestureEvent({ type: 'tap', duration });
    }

    this.isTouching = false;
  }

  private handleKeyDown(event: KeyEvent): void {
    this.emitGestureEvent({ type: 'keyPress', key: event.key });
  }

  private emitGestureEvent(event: GestureEvent): void {
    this.listeners.forEach(listener => {
      try {
        listener(event);
      } catch (error) {
        console.error('Error in gesture listener:', error);
      }
    });
  }

  addListener(listener: GestureListener): void {
    this.listeners.push(listener);
  }

  removeListener(listener: GestureListener): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  enable(): void {
    this.initializeEventListeners();
  }

  disable(): void {
    // HarmonyOS中移除事件监听需要使用系统提供的API
    // 这里暂时保留结构，实际实现需要根据HarmonyOS的事件系统进行调整

    // Clear any pending timers
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }

    this.isTouching = false;
  }

  setConfig(config: Partial<TVGestureHandler['config']>): void {
    this.config = { ...this.config, ...config };
  }

  getConfig(): TVGestureHandler['config'] {
    return { ...this.config };
  }
}

// Export a singleton instance
export const tvGestureHandler = new TVGestureHandler();
export default TVGestureHandler;