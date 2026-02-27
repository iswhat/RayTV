/**
 * 简单按钮组件
 * 使用标准ArkTS语法的按钮组件
 */
import { Component, State, Prop } from '@ohos/arkui'

@Component
export struct SimpleButton {
  @Prop text: string = 'Button'
  @Prop type: 'primary' | 'secondary' | 'danger' = 'primary'
  @Prop size: 'small' | 'medium' | 'large' = 'medium'
  @Prop disabled: boolean = false
  @Prop loading: boolean = false
  
  @State isPressed: boolean = false
  
  private getBackgroundColor(): string {
    if (this.disabled) {
      return '#B0B0B0'
    }
    
    if (this.isPressed) {
      switch (this.type) {
        case 'primary': return '#0062CC'
        case 'secondary': return '#D1D1D6'
        case 'danger': return '#D70015'
        default: return '#0062CC'
      }
    }
    
    switch (this.type) {
      case 'primary': return '#007AFF'
      case 'secondary': return '#F2F2F7'
      case 'danger': return '#FF3B30'
      default: return '#007AFF'
    }
  }
  
  private getTextColor(): string {
    if (this.type === 'secondary') {
      return '#000000'
    }
    return '#FFFFFF'
  }
  
  private getPadding(): string {
    switch (this.size) {
      case 'small': return '8px 16px'
      case 'large': return '16px 32px'
      default: return '12px 24px'
    }
  }
  
  private handleClick(): void {
    if (this.disabled || this.loading) return
    // 这里可以添加点击事件处理
    console.log('Button clicked:', this.text)
  }
  
  build() {
    Stack({
      alignContent: 'center',
      onClick: () => this.handleClick()
    })
    .width('100%')
    .height('100%')
    .padding(this.getPadding())
    .backgroundColor(this.getBackgroundColor())
    .borderRadius('8px')
    .opacity(this.disabled ? 0.6 : 1)
    {
      if (this.loading) {
        Text('Loading...')
          .fontSize('16px')
          .color(this.getTextColor())
          .fontWeight('500')
      } else {
        Text(this.text)
          .fontSize('16px')
          .color(this.getTextColor())
          .fontWeight('500')
      }
    }
    .onTouchDown(() => {
      this.isPressed = true
    })
    .onTouchUp(() => {
      this.isPressed = false
    })
    .onTouchCancel(() => {
      this.isPressed = false
    })
  }
}