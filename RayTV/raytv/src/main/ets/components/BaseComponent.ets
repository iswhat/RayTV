/**
 * 组件基础类 | Component Base Class
 * 所有组件的基类，提供通用功能和生命周期管理
 * Base class for all components, providing common functionality and lifecycle management
 */
import { Logger } from '../common/utils/Logger';

// ==================== 组件基础接口 | Component Base Interfaces ====================

/**
 * 组件基础属性 | Base Component Props
 */
export interface BaseComponentProps {
  // 基础标识
  id?: string;
  key?: string;
  
  // 样式相关
  className?: string;
  style?: Record<string, any>;
  
  // 状态控制
  disabled?: boolean;
  loading?: boolean;
  hidden?: boolean;
  
  // 事件处理
  onClick?: (event: ClickEvent) => void;
  onMouseEnter?: (event: MouseEvent) => void;
  onMouseLeave?: (event: MouseEvent) => void;
  onFocus?: (event: FocusEvent) => void;
  onBlur?: (event: FocusEvent) => void;
  
  // 生命周期
  onMount?: () => void;
  onUnmount?: () => void;
}

/**
 * 组件状态 | Component State
 */
export interface ComponentState {
  mounted: boolean;
  focused: boolean;
  hovered: boolean;
  active: boolean;
}

// ==================== 组件基类 | Component Base Class ====================

/**
 * 抽象组件基类 | Abstract Component Base Class
 */
export abstract class BaseComponent<P extends BaseComponentProps = BaseComponentProps, S = any> {
  
  protected props: P;
  protected state: ComponentState;
  protected logger: Logger;
  private element: ComponentController | null = null;
  
  constructor(props: P) {
    this.props = { ...props };
    this.logger = new Logger(this.constructor.name);
    
    // 初始化状态
    this.state = {
      mounted: false,
      focused: false,
      hovered: false,
      active: false
    };
    
    this.logger.debug('Component initialized', { props, state: this.state });
  }
  
  /**
   * 渲染组件 | Render component
   */
  public abstract render(): any;
  
  /**
   * 更新组件属性 | Update component props
   */
  public updateProps(newProps: Partial<P>): void {
    const prevProps = { ...this.props };
    this.props = { ...this.props, ...newProps };
    
    this.logger.debug('Component props updated', { prevProps, newProps });
  }
  
  /**
   * 设置组件状态 | Set component state
   */
  protected setState(newState: Partial<ComponentState>): void {
    const prevState = { ...this.state };
    this.state = { ...this.state, ...newState };
    
    this.logger.debug('Component state updated', { prevState, newState });
  }
  
  /**
   * 获取当前状态 | Get current state
   */
  protected getState(): ComponentState {
    return { ...this.state };
  }
  
  /**
   * 检查组件是否挂载 | Check if component is mounted
   */
  public isMounted(): boolean {
    return this.state.mounted;
  }
  
  /**
   * 处理点击事件 | Handle click event
   */
  protected handleClick(event: ClickEvent): void {
    if (this.props.disabled || this.props.loading) {
      return;
    }
    
    this.props.onClick?.(event);
  }
  
  /**
   * 处理鼠标进入 | Handle mouse enter
   */
  protected handleMouseEnter(event: MouseEvent): void {
    this.setState({ hovered: true });
    this.props.onMouseEnter?.(event);
  }
  
  /**
   * 处理鼠标离开 | Handle mouse leave
   */
  protected handleMouseLeave(event: MouseEvent): void {
    this.setState({ hovered: false });
    this.props.onMouseLeave?.(event);
  }
  
  /**
   * 处理焦点获得 | Handle focus
   */
  protected handleFocus(event: FocusEvent): void {
    this.setState({ focused: true });
    this.props.onFocus?.(event);
  }
  
  /**
   * 处理焦点失去 | Handle blur
   */
  protected handleBlur(event: FocusEvent): void {
    this.setState({ focused: false });
    this.props.onBlur?.(event);
  }
}

// ==================== 便捷导出 | Convenient Exports ====================

export type { BaseComponentProps, ComponentState };
export { BaseComponent };