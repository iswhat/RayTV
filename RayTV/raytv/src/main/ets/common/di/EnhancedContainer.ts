import { ServiceLifecycle } from './ServiceLifecycle';

interface Registration<T> {
  factory: () => T;
  isSingleton: boolean;
  instance?: T;
}

class EnhancedDIContainer {
  private registrations: Map<string, Registration<any>> = new Map();
  private lifecycle: ServiceLifecycle = new ServiceLifecycle();

  register<T>(key: string, factory: () => T, isSingleton: boolean = true): void {
    this.registrations.set(key, {
      factory,
      isSingleton
    });
  }

  registerMultiple(registrations: Array<{
    key: string;
    factory: () => any;
    isSingleton?: boolean;
  }>): void {
    registrations.forEach(({ key, factory, isSingleton = true }) => {
      this.register(key, factory, isSingleton);
    });
  }

  resolve<T>(key: string): T {
    const registration = this.registrations.get(key);
    if (!registration) {
      throw new Error(`Service not registered: ${key}`);
    }

    if (registration.isSingleton && registration.instance) {
      return registration.instance;
    }

    const instance = registration.factory();
    if (registration.isSingleton) {
      registration.instance = instance;
    }

    return instance;
  }

  resolveAll(keys: string[]): any[] {
    return keys.map(key => this.resolve(key));
  }

  getLifecycle(): ServiceLifecycle {
    return this.lifecycle;
  }

  clear(): void {
    this.registrations.clear();
  }
}

export const container = new EnhancedDIContainer();
export { EnhancedDIContainer };