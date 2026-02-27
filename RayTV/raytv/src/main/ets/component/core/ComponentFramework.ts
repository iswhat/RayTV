/**
 * 组件化重构基础框架
 * 
 * 目标：建立统一的Design System组件库，提升组件复用性和一致性
 */

// 组件基类定义
export abstract class BaseComponent {
  protected element: HTMLElement | null = null;
  protected props: Record<string, any> = {};
  protected state: Record<string, any> = {};
  
  constructor(props: Record<string, any> = {}) {
    this.props = { ...props };
    this.state = this.getInitialState();
  }
  
  protected abstract getInitialState(): Record<string, any>;
  protected abstract render(): string;
  protected abstract componentDidMount(): void;
  protected abstract componentDidUpdate(prevProps: any, prevState: any): void;
  
  public mount(container: HTMLElement): void {
    container.innerHTML = this.render();
    this.element = container.firstElementChild as HTMLElement;
    this.componentDidMount();
  }
  
  public updateProps(newProps: Record<string, any>): void {
    const prevProps = { ...this.props };
    const prevState = { ...this.state };
    
    this.props = { ...this.props, ...newProps };
    this.state = this.getStateFromProps(this.props, this.state);
    
    if (this.element) {
      this.element.outerHTML = this.render();
      this.element = this.element.parentElement?.firstElementChild as HTMLElement;
      this.componentDidUpdate(prevProps, prevState);
    }
  }
  
  protected getStateFromProps(props: any, state: any): Record<string, any> {
    return state;
  }
  
  protected emit(event: string, data?: any): void {
    if (this.element) {
      const customEvent = new CustomEvent(event, { detail: data });
      this.element.dispatchEvent(customEvent);
    }
  }
}

// 组件样式系统
export class ComponentStyles {
  private static styles: Map<string, string> = new Map();
  
  public static register(componentName: string, css: string): void {
    this.styles.set(componentName, css);
  }
  
  public static get(componentName: string): string {
    return this.styles.get(componentName) || '';
  }
  
  public static getAll(): string {
    return Array.from(this.styles.values()).join('\n');
  }
}

// 响应式状态管理
export class ReactiveState {
  private watchers: Map<string, Function[]> = new Map();
  
  public watch(property: string, callback: Function): void {
    if (!this.watchers.has(property)) {
      this.watchers.set(property, []);
    }
    this.watchers.get(property)?.push(callback);
  }
  
  public notify(property: string, newValue: any, oldValue: any): void {
    const callbacks = this.watchers.get(property);
    if (callbacks) {
      callbacks.forEach(callback => callback(newValue, oldValue));
    }
  }
}

// 焦点管理器
export class FocusManager {
  private static instance: FocusManager | null = null;
  private focusableElements: HTMLElement[] = [];
  private currentIndex: number = 0;
  
  private constructor() {}
  
  public static getInstance(): FocusManager {
    if (!FocusManager.instance) {
      FocusManager.instance = new FocusManager();
    }
    return FocusManager.instance;
  }
  
  public registerFocusable(element: HTMLElement): void {
    if (!this.focusableElements.includes(element)) {
      this.focusableElements.push(element);
      element.tabIndex = 0;
      element.addEventListener('focus', () => {
        this.currentIndex = this.focusableElements.indexOf(element);
      });
    }
  }
  
  public unregisterFocusable(element: HTMLElement): void {
    const index = this.focusableElements.indexOf(element);
    if (index > -1) {
      this.focusableElements.splice(index, 1);
      if (this.currentIndex >= this.focusableElements.length) {
        this.currentIndex = Math.max(0, this.focusableElements.length - 1);
      }
    }
  }
  
  public focusNext(): void {
    if (this.focusableElements.length === 0) return;
    
    this.currentIndex = (this.currentIndex + 1) % this.focusableElements.length;
    this.focusableElements[this.currentIndex].focus();
  }
  
  public focusPrevious(): void {
    if (this.focusableElements.length === 0) return;
    
    this.currentIndex = (this.currentIndex - 1 + this.focusableElements.length) % this.focusableElements.length;
    this.focusableElements[this.currentIndex].focus();
  }
  
  public getCurrentFocused(): HTMLElement | null {
    return this.focusableElements[this.currentIndex] || null;
  }
}

// 组件注册表
export class ComponentRegistry {
  private static components: Map<string, any> = new Map();
  
  public static register(name: string, componentClass: any): void {
    this.components.set(name, componentClass);
  }
  
  public static get(name: string): any {
    return this.components.get(name);
  }
  
  public static has(name: string): boolean {
    return this.components.has(name);
  }
  
  public static getAll(): Map<string, any> {
    return new Map(this.components);
  }
}