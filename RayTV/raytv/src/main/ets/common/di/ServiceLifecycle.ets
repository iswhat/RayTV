interface LifecycleHook {
  init?: () => Promise<void> | void;
  destroy?: () => Promise<void> | void;
}

class ServiceLifecycle {
  private services: Map<string, LifecycleHook> = new Map();

  registerService(key: string, hook: LifecycleHook): void {
    this.services.set(key, hook);
  }

  async initializeAll(): Promise<void> {
    for (const [key, hook] of this.services.entries()) {
      if (hook.init) {
        try {
          await hook.init();
        } catch (error) {
          console.error(`Failed to initialize service ${key}:`, error);
        }
      }
    }
  }

  async destroyAll(): Promise<void> {
    for (const [key, hook] of this.services.entries()) {
      if (hook.destroy) {
        try {
          await hook.destroy();
        } catch (error) {
          console.error(`Failed to destroy service ${key}:`, error);
        }
      }
    }
  }

  getServiceCount(): number {
    return this.services.size;
  }
}

export { ServiceLifecycle };