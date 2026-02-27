interface GestureEvent {
  type: 'swipe' | 'tap' | 'longPress' | 'keyPress';
  direction?: 'up' | 'down' | 'left' | 'right';
  distance?: number;
  duration?: number;
  key?: string;
}

interface GestureListener {
  (event: GestureEvent): void;
}

class TVGestureHandler {
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
    if (this.config.enableTouch) {
      document.addEventListener('touchstart', this.handleTouchStart.bind(this));
      document.addEventListener('touchmove', this.handleTouchMove.bind(this));
      document.addEventListener('touchend', this.handleTouchEnd.bind(this));
    }

    if (this.config.enableKeyboard) {
      document.addEventListener('keydown', this.handleKeyDown.bind(this));
    }
  }

  private handleTouchStart(event: TouchEvent): void {
    if (event.touches.length === 1) {
      const touch = event.touches[0];
      this.touchStartX = touch.clientX;
      this.touchStartY = touch.clientY;
      this.touchStartTime = Date.now();
      this.isTouching = true;

      // Set up long press timer
      this.longPressTimer = window.setTimeout(() => {
        this.emitGestureEvent({ type: 'longPress', duration: Date.now() - this.touchStartTime });
      }, this.config.longPressThreshold);
    }
  }

  private handleTouchMove(event: TouchEvent): void {
    if (!this.isTouching) return;

    const touch = event.touches[0];
    const currentX = touch.clientX;
    const currentY = touch.clientY;
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
    const endX = touch.clientX;
    const endY = touch.clientY;
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

  private handleKeyDown(event: KeyboardEvent): void {
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
    if (this.config.enableTouch) {
      document.removeEventListener('touchstart', this.handleTouchStart.bind(this));
      document.removeEventListener('touchmove', this.handleTouchMove.bind(this));
      document.removeEventListener('touchend', this.handleTouchEnd.bind(this));
    }

    if (this.config.enableKeyboard) {
      document.removeEventListener('keydown', this.handleKeyDown.bind(this));
    }

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