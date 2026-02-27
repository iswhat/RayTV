interface Subscription {
  unsubscribe: () => void;
}

class BaseViewModel {
  private eventHandlers: Map<string, Array<(data: any) => void>> = new Map();

  protected emit(event: string, data?: any): void {
    const handlers = this.eventHandlers.get(event);
    if (handlers) {
      handlers.forEach(handler => {
        try {
          handler(data);
        } catch (error) {
          console.error(`Error in event handler for ${event}:`, error);
        }
      });
    }
  }

  on(event: string, handler: (data: any) => void): Subscription {
    if (!this.eventHandlers.has(event)) {
      this.eventHandlers.set(event, []);
    }
    this.eventHandlers.get(event)?.push(handler);

    return {
      unsubscribe: () => {
        const handlers = this.eventHandlers.get(event);
        if (handlers) {
          const index = handlers.indexOf(handler);
          if (index > -1) {
            handlers.splice(index, 1);
          }
        }
      }
    };
  }

  off(event: string, handler?: (data: any) => void): void {
    if (handler) {
      const handlers = this.eventHandlers.get(event);
      if (handlers) {
        const index = handlers.indexOf(handler);
        if (index > -1) {
          handlers.splice(index, 1);
        }
      }
    } else {
      this.eventHandlers.delete(event);
    }
  }

  clearEvents(): void {
    this.eventHandlers.clear();
  }

  protected dispose(): void {
    this.clearEvents();
  }
}

export { BaseViewModel };