/**
 * 组件化重构基础框架 - ArkTS 版
 *
 * 目标：建立统一的 Design System 组件库，提升组件复用性和一致性。
 * 注意：ArkTS 无 DOM API，本框架提供数据驱动的组件状态管理抽象，
 * 实际 UI 渲染由 ArkUI 声明式组件实现。
 */

// ─── 基础组件抽象 ───────────────────────────────────────────────────────────

/**
 * 组件基类
 * 管理 props / state 的数据层逻辑，UI 渲染由各 @Component 子类通过 ArkUI 负责。
 */
export abstract class BaseComponent {
  protected props: Record<string, Object> = {};
  protected state: Record<string, Object> = {};

  constructor(props: Record<string, Object> = {}) {
    this.props = Object.assign({}, props);
    this.state = this.getInitialState();
  }

  protected abstract getInitialState(): Record<string, Object>;

  /** 通知宿主 UI 框架执行渲染/更新（由子类或宿主重写绑定 ArkUI 刷新机制） */
  protected abstract onRender(): void;

  protected abstract componentDidMount(): void;

  protected abstract componentDidUpdate(prevProps: Record<string, Object>, prevState: Record<string, Object>): void;

  /**
   * 更新 props 并触发重渲染
   */
  public updateProps(newProps: Record<string, Object>): void {
    const prevProps: Record<string, Object> = Object.assign({}, this.props);
    const prevState: Record<string, Object> = Object.assign({}, this.state);

    this.props = Object.assign({}, this.props, newProps);
    this.state = this.getStateFromProps(this.props, this.state);

    this.onRender();
    this.componentDidUpdate(prevProps, prevState);
  }

  protected getStateFromProps(
    props: Record<string, Object>,
    state: Record<string, Object>
  ): Record<string, Object> {
    return state;
  }

  /**
   * 发出组件事件（通过事件总线转发）
   */
  protected emit(event: string, data?: Object): void {
    ComponentEventBus.getInstance().dispatch(event, data);
  }
}

// ─── 组件事件总线 ──────────────────────────────────────────────────────────

type EventCallback = (data?: Object) => void;

/**
 * 轻量事件总线，替代 DOM CustomEvent
 */
export class ComponentEventBus {
  private static instance: ComponentEventBus | null = null;
  private listeners: Map<string, EventCallback[]> = new Map<string, EventCallback[]>();

  private constructor() {}

  public static getInstance(): ComponentEventBus {
    if (!ComponentEventBus.instance) {
      ComponentEventBus.instance = new ComponentEventBus();
    }
    return ComponentEventBus.instance;
  }

  public on(event: string, callback: EventCallback): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    const cbs = this.listeners.get(event);
    if (cbs) {
      cbs.push(callback);
    }
  }

  public off(event: string, callback: EventCallback): void {
    const cbs = this.listeners.get(event);
    if (!cbs) {
      return;
    }
    const idx = cbs.indexOf(callback);
    if (idx > -1) {
      cbs.splice(idx, 1);
    }
  }

  public dispatch(event: string, data?: Object): void {
    const cbs = this.listeners.get(event);
    if (cbs) {
      for (const cb of cbs) {
        cb(data);
      }
    }
  }
}

// ─── 组件样式注册表 ────────────────────────────────────────────────────────

/**
 * 组件样式系统（存储设计 Token / 样式字符串，供 ArkUI 组件按需读取）
 */
export class ComponentStyles {
  private static styles: Map<string, string> = new Map<string, string>();

  public static register(componentName: string, css: string): void {
    ComponentStyles.styles.set(componentName, css);
  }

  public static get(componentName: string): string {
    return ComponentStyles.styles.get(componentName) ?? '';
  }

  public static getAll(): string {
    const parts: string[] = [];
    ComponentStyles.styles.forEach((v: string) => parts.push(v));
    return parts.join('\n');
  }
}

// ─── 响应式状态管理 ────────────────────────────────────────────────────────

type WatcherCallback = (newValue: Object, oldValue: Object) => void;

/**
 * 轻量响应式状态观察者
 */
export class ReactiveState {
  private watchers: Map<string, WatcherCallback[]> = new Map<string, WatcherCallback[]>();

  public watch(property: string, callback: WatcherCallback): void {
    if (!this.watchers.has(property)) {
      this.watchers.set(property, []);
    }
    const cbs = this.watchers.get(property);
    if (cbs) {
      cbs.push(callback);
    }
  }

  public notify(property: string, newValue: Object, oldValue: Object): void {
    const callbacks = this.watchers.get(property);
    if (callbacks) {
      for (const cb of callbacks) {
        cb(newValue, oldValue);
      }
    }
  }
}

// ─── 焦点管理器 ───────────────────────────────────────────────────────────

/**
 * 组件焦点管理器（TV 导航用，ID 驱动，不依赖 DOM）
 */
export class ComponentFocusManager {
  private static instance: ComponentFocusManager | null = null;
  private focusableIds: string[] = [];
  private currentIndex: number = 0;
  private focusChangeListeners: ((id: string) => void)[] = [];

  private constructor() {}

  public static getInstance(): ComponentFocusManager {
    if (!ComponentFocusManager.instance) {
      ComponentFocusManager.instance = new ComponentFocusManager();
    }
    return ComponentFocusManager.instance;
  }

  public registerFocusable(id: string): void {
    if (!this.focusableIds.includes(id)) {
      this.focusableIds.push(id);
    }
  }

  public unregisterFocusable(id: string): void {
    const idx = this.focusableIds.indexOf(id);
    if (idx > -1) {
      this.focusableIds.splice(idx, 1);
      if (this.currentIndex >= this.focusableIds.length) {
        this.currentIndex = Math.max(0, this.focusableIds.length - 1);
      }
    }
  }

  public focusNext(): void {
    if (this.focusableIds.length === 0) {
      return;
    }
    this.currentIndex = (this.currentIndex + 1) % this.focusableIds.length;
    this.notifyFocusChange();
  }

  public focusPrevious(): void {
    if (this.focusableIds.length === 0) {
      return;
    }
    this.currentIndex = (this.currentIndex - 1 + this.focusableIds.length) % this.focusableIds.length;
    this.notifyFocusChange();
  }

  public getCurrentFocusedId(): string | null {
    return this.focusableIds[this.currentIndex] ?? null;
  }

  public onFocusChange(listener: (id: string) => void): void {
    this.focusChangeListeners.push(listener);
  }

  private notifyFocusChange(): void {
    const id = this.getCurrentFocusedId();
    if (id !== null) {
      for (const listener of this.focusChangeListeners) {
        listener(id);
      }
    }
  }
}

// ─── 组件注册表 ───────────────────────────────────────────────────────────

/**
 * 全局组件注册表（存储组件构造函数或工厂，供 DI 容器按名称创建）
 */
export class ComponentRegistry {
  private static components: Map<string, Object> = new Map<string, Object>();

  public static register(name: string, componentClass: Object): void {
    ComponentRegistry.components.set(name, componentClass);
  }

  public static get(name: string): Object | undefined {
    return ComponentRegistry.components.get(name);
  }

  public static has(name: string): boolean {
    return ComponentRegistry.components.has(name);
  }

  public static getAll(): Map<string, Object> {
    return new Map<string, Object>(ComponentRegistry.components);
  }
}
