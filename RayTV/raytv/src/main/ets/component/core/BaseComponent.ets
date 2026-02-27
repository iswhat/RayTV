/**
 * 基础组件类 - 所有UI组件的基类
 * 提供统一的组件生命周期、状态管理和事件处理机制
 */
import { Component, State, Prop, Emit, Watch } from '@ohos/arkui'

export interface ComponentProps {
  // 组件通用属性
  id?: string
  className?: string
  style?: Record<string, any>
  disabled?: boolean
  visible?: boolean
}

export interface ComponentState {
  // 组件内部状态
  initialized: boolean
  mounted: boolean
  destroyed: boolean
}

export abstract class BaseComponent<T extends ComponentProps = ComponentProps> extends Component {
  // 组件属性
  @Prop protected props: T
  
  // 组件状态
  @State protected state: ComponentState = {
    initialized: false,
    mounted: false,
    destroyed: false
  }
  
  // 组件唯一标识
  protected componentId: string
  
  // 组件名称（用于日志和调试）
  protected componentName: string
  
  // 子组件引用
  protected children: BaseComponent[] = []
  
  constructor(props: T) {
    super()
    this.props = props
    this.componentId = props.id || this.generateId()
    this.componentName = this.constructor.name
    this.initialize()
  }
  
  /**
   * 组件初始化
   * 在构造函数中调用，用于设置初始状态
   */
  protected initialize(): void {
    if (this.state.initialized) return
    
    this.onCreate()
    this.state.initialized = true
  }
  
  /**
   * 组件创建时的钩子函数
   * 子类可以重写此方法来进行初始化操作
   */
  protected onCreate(): void {
    // 子类实现
  }
  
  /**
   * 组件挂载前的钩子函数
   */
  protected onBeforeMount(): void {
    // 子类实现
  }
  
  /**
   * 组件挂载后的钩子函数
   */
  protected onMounted(): void {
    this.state.mounted = true
    // 子类实现
  }
  
  /**
   * 组件更新前的钩子函数
   */
  protected onBeforeUpdate(): void {
    // 子类实现
  }
  
  /**
   * 组件更新后的钩子函数
   */
  protected onUpdated(): void {
    // 子类实现
  }
  
  /**
   * 组件销毁前的钩子函数
   */
  protected onBeforeDestroy(): void {
    // 子类实现
  }
  
  /**
   * 组件销毁后的钩子函数
   */
  protected onDestroyed(): void {
    this.state.destroyed = true
    this.state.mounted = false
    // 子类实现
  }
  
  /**
   * 属性变更监听器
   */
  @Watch('props')
  protected onPropsChanged(newProps: T, oldProps: T): void {
    this.onBeforeUpdate()
    // 子类可以重写处理属性变更
    this.onUpdated()
  }
  
  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return `${this.componentName}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }
  
  /**
   * 发射事件
   */
  protected emit(eventName: string, data?: any): void {
    // 事件发射逻辑
    console.log(`[${this.componentName}] Emitting event: ${eventName}`, data)
  }
  
  /**
   * 添加子组件
   */
  protected addChild(child: BaseComponent): void {
    this.children.push(child)
  }
  
  /**
   * 移除子组件
   */
  protected removeChild(child: BaseComponent): void {
    const index = this.children.indexOf(child)
    if (index > -1) {
      this.children.splice(index, 1)
    }
  }
  
  /**
   * 获取子组件
   */
  protected getChildren(): BaseComponent[] {
    return [...this.children]
  }
  
  /**
   * 设置组件可见性
   */
  protected setVisible(visible: boolean): void {
    this.props.visible = visible
  }
  
  /**
   * 设置组件禁用状态
   */
  protected setDisabled(disabled: boolean): void {
    this.props.disabled = disabled
  }
  
  /**
   * 获取组件样式
   */
  protected getStyle(): Record<string, any> {
    return this.props.style || {}
  }
  
  /**
   * 合并样式
   */
  protected mergeStyle(additionalStyle: Record<string, any>): Record<string, any> {
    return { ...this.getStyle(), ...additionalStyle }
  }
  
  /**
   * 组件渲染方法 - 需要子类实现
   */
  abstract render(): any
  
  /**
   * 组件构建方法
   */
  build(): any {
    if (!this.state.initialized) {
      this.initialize()
    }
    
    if (!this.state.mounted) {
      this.onBeforeMount()
      this.onMounted()
    }
    
    return this.render()
  }
}