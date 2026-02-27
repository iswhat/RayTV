/**
 * TV友好的可聚焦容器组件
 * 提供遥控器友好的焦点管理和视觉反馈
 */
import { Component, State, Prop, Builder } from '@ohos/arkui'
import { RemoteControlManager } from './RemoteControlManager'

@Component
export struct FocusableContainer {
  @Prop id: string
  @Prop onFocusChange: (focused: boolean) => void = () => {}
  @Prop onClick: () => void = () => {}
  
  @State isFocused: boolean = false
  @State isPressed: boolean = false
  
  private remoteManager: RemoteControlManager = RemoteControlManager.getInstance()
  
  aboutToAppear() {
    // 注册到遥控器管理器
    // 这里需要获取实际的元素位置信息
    const rect = { x: 0, y: 0, width: 100, height: 100 } // 占位符
    this.remoteManager.registerFocusableItem({
      id: this.id,
      element: this,
      rect: rect,
      focusable: true,
      visible: true
    })
    
    // 监听焦点变化
    this.remoteManager.addEventListener('focusChange', (focusedId: string) => {
      const newFocused = focusedId === this.id
      if (this.isFocused !== newFocused) {
        this.isFocused = newFocused
        this.onFocusChange(newFocused)
      }
    })
    
    // 监听点击事件
    this.remoteManager.addEventListener('itemClick', (clickedId: string) => {
      if (clickedId === this.id) {
        this.handleClick()
      }
    })
  }
  
  aboutToDisappear() {
    // 注销焦点项
    this.remoteManager.unregisterFocusableItem(this.id)
    
    // 移除事件监听器
    this.remoteManager.removeEventListener('focusChange', this.handleFocusChange)
    this.remoteManager.removeEventListener('itemClick', this.handleItemClick)
  }
  
  private handleFocusChange = (focusedId: string) => {
    const newFocused = focusedId === this.id
    if (this.isFocused !== newFocused) {
      this.isFocused = newFocused
      this.onFocusChange(newFocused)
    }
  }
  
  private handleItemClick = (clickedId: string) => {
    if (clickedId === this.id) {
      this.handleClick()
    }
  }
  
  private handleClick(): void {
    this.onClick()
  }
  
  private handleTouchDown(): void {
    this.isPressed = true
  }
  
  private handleTouchUp(): void {
    this.isPressed = false
  }
  
  private handleTouchCancel(): void {
    this.isPressed = false
  }
  
  build() {
    Stack()
    .width('100%')
    .border({
      width: this.isFocused ? '3px' : '1px',
      color: this.isFocused ? '#007AFF' : '#CCCCCC',
      radius: '8px'
    })
    .backgroundColor(this.isPressed ? '#E5E5EA' : '#FFFFFF')
    .scale({ x: this.isFocused ? 1.05 : 1, y: this.isFocused ? 1.05 : 1 })
    .animation({
      duration: 200,
      curve: 'ease-in-out'
    })
    {
      // 子内容将在这里渲染
      this.renderContent()
    }
    .onTouchDown(() => this.handleTouchDown())
    .onTouchUp(() => this.handleTouchUp())
    .onTouchCancel(() => this.handleTouchCancel())
  }
  
  @Builder
  private renderContent() {
    // 子类需要实现这个方法来渲染具体内容
    Text('Focusable Content')
      .fontSize('16px')
      .color('#333333')
  }
}