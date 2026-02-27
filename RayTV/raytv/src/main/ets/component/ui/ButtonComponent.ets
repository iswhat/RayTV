/**
 * 按钮组件
 * 支持多种样式和交互状态的通用按钮组件
 */
import { BaseComponent } from '../core/BaseComponent'
import { Stack, Text, TapGesture, LongPressGesture } from '@ohos/arkui'

export interface ButtonProps {
  id?: string
  className?: string
  style?: Record<string, any>
  disabled?: boolean
  visible?: boolean
  text: string
  type?: 'primary' | 'secondary' | 'danger' | 'ghost'
  size?: 'small' | 'medium' | 'large'
  shape?: 'rect' | 'round' | 'circle'
  loading?: boolean
  icon?: string
  iconPosition?: 'left' | 'right'
}

interface ButtonState {
  pressed: boolean
  hovered: boolean
  focused: boolean
}

export class ButtonComponent extends BaseComponent<ButtonProps> {
  private state: ButtonState = {
    pressed: false,
    hovered: false,
    focused: false
  }
  
  protected onCreate(): void {
    // 设置默认属性
    this.props.type = this.props.type || 'primary'
    this.props.size = this.props.size || 'medium'
    this.props.shape = this.props.shape || 'rect'
    this.props.iconPosition = this.props.iconPosition || 'left'
  }
  
  private getButtonStyle(): Record<string, any> {
    const baseStyle = {
      padding: this.getSizePadding(),
      backgroundColor: this.getBackgroundColor(),
      borderRadius: this.getBorderRadius(),
      opacity: this.props.disabled ? 0.6 : 1,
      transition: 'all 0.2s ease'
    }
    
    return { ...baseStyle, ...this.props.style }
  }
  
  private getTextStyle(): Record<string, any> {
    return {
      fontSize: this.getTextFontSize(),
      color: this.getTextColor(),
      fontWeight: '500'
    }
  }
  
  private getSizePadding(): string {
    switch (this.props.size) {
      case 'small': return '8px 16px'
      case 'large': return '16px 32px'
      default: return '12px 24px'
    }
  }
  
  private getTextFontSize(): string {
    switch (this.props.size) {
      case 'small': return '14px'
      case 'large': return '18px'
      default: return '16px'
    }
  }
  
  private getBackgroundColor(): string {
    if (this.props.disabled) {
      return this.getDisabledBackgroundColor()
    }
    
    if (this.state.pressed) {
      return this.getActiveBackgroundColor()
    }
    
    return this.getNormalBackgroundColor()
  }
  
  private getNormalBackgroundColor(): string {
    switch (this.props.type) {
      case 'primary': return '#007AFF'
      case 'secondary': return '#F2F2F7'
      case 'danger': return '#FF3B30'
      case 'ghost': return 'transparent'
      default: return '#007AFF'
    }
  }
  
  private getActiveBackgroundColor(): string {
    switch (this.props.type) {
      case 'primary': return '#0062CC'
      case 'secondary': return '#D1D1D6'
      case 'danger': return '#D70015'
      case 'ghost': return 'rgba(0, 0, 0, 0.1)'
      default: return '#0062CC'
    }
  }
  
  private getDisabledBackgroundColor(): string {
    switch (this.props.type) {
      case 'primary': return '#B0B0B0'
      case 'secondary': return '#E5E5EA'
      case 'danger': return '#FF9B95'
      case 'ghost': return 'transparent'
      default: return '#B0B0B0'
    }
  }
  
  private getTextColor(): string {
    if (this.props.type === 'ghost') {
      return this.props.disabled ? '#B0B0B0' : '#007AFF'
    }
    
    switch (this.props.type) {
      case 'secondary': return '#000000'
      default: return '#FFFFFF'
    }
  }
  
  private getBorderRadius(): string {
    switch (this.props.shape) {
      case 'round': return '20px'
      case 'circle': return '50%'
      default: return '8px'
    }
  }
  
  private handlePress(): void {
    if (this.props.disabled || this.props.loading) return
    
    this.emit('press', { text: this.props.text })
  }
  
  private handleLongPress(): void {
    if (this.props.disabled || this.props.loading) return
    
    this.emit('longPress', { text: this.props.text })
  }
  
  private handleHover(enter: boolean): void {
    if (this.props.disabled) return
    
    this.state.hovered = enter
    this.emit('hover', { hovering: enter })
  }
  
  private handleFocus(focused: boolean): void {
    if (this.props.disabled) return
    
    this.state.focused = focused
    this.emit('focus', { focused })
  }
  
  build() {
    Stack({
      alignContent: 'center',
      onClick: () => this.handlePress()
    })
    .width('100%')
    .height('100%')
    .padding(this.getButtonStyle().padding)
    .backgroundColor(this.getButtonStyle().backgroundColor)
    .borderRadius(this.getButtonStyle().borderRadius)
    .opacity(this.getButtonStyle().opacity)
    {
      if (this.props.loading) {
        // 显示加载状态
        Text('Loading...')
          .fontSize(this.getTextStyle().fontSize)
          .color(this.getTextStyle().color)
          .fontWeight(this.getTextStyle().fontWeight)
      } else {
        // 显示按钮文本
        Text(this.props.text)
          .fontSize(this.getTextStyle().fontSize)
          .color(this.getTextStyle().color)
          .fontWeight(this.getTextStyle().fontWeight)
      }
    }
  }
}