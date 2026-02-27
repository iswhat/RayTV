/**
 * EnhancedButton.ets
 * 增强型按钮组件 - 专为TV应用优化的ArkTS按钮实现
 */

import { Component, Prop, State, Builder, AboutToAppear } from '@ohos/arkui'
import { FocusStyle } from '../../common/style/FocusStyle'

// ==================== 类型定义 ====================

export type ButtonType = 'primary' | 'secondary' | 'danger' | 'ghost' | 'success' | 'warning'
export type ButtonSize = 'mini' | 'small' | 'medium' | 'large' | 'extraLarge'
export type ButtonShape = 'rect' | 'round' | 'circle' | 'capsule'

export interface EnhancedButtonProps {
  // 基础属性
  text: string
  type?: ButtonType
  size?: ButtonSize
  shape?: ButtonShape
  
  // 状态控制
  disabled?: boolean
  loading?: boolean
  selected?: boolean
  
  // 交互属性
  focusable?: boolean
  autoFocus?: boolean
  
  // 音效配置
  enableSound?: boolean
  soundEffect?: string
  
  // 样式定制
  width?: string | number
  height?: string | number
  customStyle?: Record<string, any>
  
  // 事件回调
  onPress?: () => void
  onLongPress?: () => void
  onFocus?: () => void
  onBlur?: () => void
}

// ==================== 主题配置 ====================

const BUTTON_THEMES = {
  primary: {
    normal: { bg: '#007AFF', text: '#FFFFFF' },
    pressed: { bg: '#0062CC', text: '#FFFFFF' },
    disabled: { bg: '#B0B0B0', text: '#FFFFFF' }
  },
  secondary: {
    normal: { bg: '#F2F2F7', text: '#000000' },
    pressed: { bg: '#D1D1D6', text: '#000000' },
    disabled: { bg: '#E5E5EA', text: '#8E8E93' }
  },
  danger: {
    normal: { bg: '#FF3B30', text: '#FFFFFF' },
    pressed: { bg: '#D70015', text: '#FFFFFF' },
    disabled: { bg: '#FF9B95', text: '#FFFFFF' }
  },
  ghost: {
    normal: { bg: 'transparent', text: '#007AFF', border: '#007AFF' },
    pressed: { bg: 'rgba(0,122,255,0.1)', text: '#0062CC', border: '#0062CC' },
    disabled: { bg: 'transparent', text: '#B0B0B0', border: '#B0B0B0' }
  },
  success: {
    normal: { bg: '#34C759', text: '#FFFFFF' },
    pressed: { bg: '#248A3D', text: '#FFFFFF' },
    disabled: { bg: '#8ECA9D', text: '#FFFFFF' }
  },
  warning: {
    normal: { bg: '#FF9500', text: '#FFFFFF' },
    pressed: { bg: '#CC7700', text: '#FFFFFF' },
    disabled: { bg: '#FFCFA6', text: '#FFFFFF' }
  }
}

const SIZE_CONFIGS = {
  mini: { padding: '4vp 12vp', fontSize: 12, height: 32 },
  small: { padding: '8vp 16vp', fontSize: 14, height: 40 },
  medium: { padding: '12vp 24vp', fontSize: 16, height: 48 },
  large: { padding: '16vp 32vp', fontSize: 18, height: 56 },
  extraLarge: { padding: '20vp 40vp', fontSize: 20, height: 64 }
}

const SHAPE_CONFIGS = {
  rect: { borderRadius: 8 },
  round: { borderRadius: 20 },
  circle: { borderRadius: '50%' },
  capsule: { borderRadius: 999 }
}

// ==================== 增强型按钮组件 ====================

@Component
export struct EnhancedButton {
  // Props
  @Prop text: string = 'Button'
  @Prop type: ButtonType = 'primary'
  @Prop size: ButtonSize = 'medium'
  @Prop shape: ButtonShape = 'rect'
  @Prop disabled: boolean = false
  @Prop loading: boolean = false
  @Prop selected: boolean = false
  @Prop focusable: boolean = true
  @Prop autoFocus: boolean = false
  @Prop enableSound: boolean = true
  @Prop soundEffect: string = 'default'
  @Prop width: string | number = 'auto'
  @Prop height: string | number = 'auto'
  @Prop customStyle: Record<string, any> = {}
  @Prop onPress: () => void = () => {}
  @Prop onLongPress: () => void = () => {}
  @Prop onFocus: () => void = () => {}
  @Prop onBlur: () => void = () => {}
  
  // State
  @State isPressed: boolean = false
  @State isFocused: boolean = false
  @State isHovered: boolean = false
  
  // Private properties
  private focusStyle: FocusStyle = new FocusStyle()
  private animationDuration: number = 200
  
  @AboutToAppear
  aboutToAppear(): void {
    // 初始化焦点样式
    this.focusStyle.setBorder({
      width: 3,
      color: '#007AFF',
      radius: this.getCurrentBorderRadius()
    })
    this.focusStyle.setShadow({
      color: '#007AFF',
      radius: 10,
      offsetX: 0,
      offsetY: 0
    })
  }
  
  // ==================== 计算属性 ====================
  
  private getThemeConfig() {
    return BUTTON_THEMES[this.type] || BUTTON_THEMES.primary
  }
  
  private getSizeConfig() {
    return SIZE_CONFIGS[this.size] || SIZE_CONFIGS.medium
  }
  
  private getShapeConfig() {
    return SHAPE_CONFIGS[this.shape] || SHAPE_CONFIGS.rect
  }
  
  private getCurrentBorderRadius(): number | string {
    const shapeConfig = this.getShapeConfig()
    return shapeConfig.borderRadius
  }
  
  private getBackgroundColor(): string {
    if (this.disabled) {
      return this.getThemeConfig().disabled.bg
    }
    
    if (this.isPressed || this.selected) {
      return this.getThemeConfig().pressed.bg
    }
    
    return this.getThemeConfig().normal.bg
  }
  
  private getTextColor(): string {
    if (this.disabled) {
      return this.getThemeConfig().disabled.text
    }
    
    if (this.isPressed || this.selected) {
      return this.getThemeConfig().pressed.text
    }
    
    return this.getThemeConfig().normal.text
  }
  
  private getBorderColor(): string {
    if (this.type === 'ghost') {
      if (this.disabled) {
        return this.getThemeConfig().disabled.border
      }
      if (this.isPressed || this.selected) {
        return this.getThemeConfig().pressed.border
      }
      return this.getThemeConfig().normal.border
    }
    return 'transparent'
  }
  
  private getOpacity(): number {
    return this.disabled ? 0.6 : 1.0
  }
  
  private getScale(): number {
    return this.isPressed ? 0.95 : 1.0
  }
  
  private getWidth(): string | number {
    if (this.width !== 'auto') return this.width
    if (this.shape === 'circle') return this.getSizeConfig().height
    return 'auto'
  }
  
  private getHeight(): string | number {
    if (this.height !== 'auto') return this.height
    if (this.shape === 'circle') return this.getSizeConfig().height
    return this.getSizeConfig().height
  }
  
  // ==================== 事件处理 ====================
  
  private playSoundEffect(): void {
    if (this.enableSound) {
      // 这里可以实现实际的音效播放逻辑
      // 例如，使用HarmonyOS的音频API播放音效
      console.log(`Playing sound effect: ${this.soundEffect}`)
    }
  }
  
  private handleClick(): void {
    if (this.disabled || this.loading) return
    this.playSoundEffect()
    this.onPress()
  }
  
  private handleLongPress(): void {
    if (this.disabled || this.loading) return
    this.onLongPress()
  }
  
  private handleFocus(): void {
    if (this.disabled) return
    this.isFocused = true
    this.onFocus()
  }
  
  private handleBlur(): void {
    if (this.disabled) return
    this.isFocused = false
    this.onBlur()
  }
  
  private handleHover(enter: boolean): void {
    if (this.disabled) return
    this.isHovered = enter
  }
  
  private handleTouchDown(): void {
    if (this.disabled || this.loading) return
    this.isPressed = true
  }
  
  private handleTouchUp(): void {
    if (this.disabled || this.loading) return
    this.isPressed = false
  }
  
  private handleTouchCancel(): void {
    this.isPressed = false
  }
  
  // ==================== 渲染方法 ====================
  
  @Builder
  private renderButtonText(): void {
    if (this.loading) {
      Text('加载中...')
        .fontSize(this.getSizeConfig().fontSize)
        .fontColor(this.getTextColor())
        .fontWeight(500)
    } else {
      Text(this.text)
        .fontSize(this.getSizeConfig().fontSize)
        .fontColor(this.getTextColor())
        .fontWeight(500)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
  }
  
  @Builder
  private renderFocusIndicator(): void {
    if (this.isFocused) {
      // 焦点指示器
      Stack()
        .width('100%')
        .height('100%')
        .border({
          width: this.focusStyle.border.width,
          color: this.focusStyle.border.color,
          radius: this.focusStyle.border.radius
        })
        .shadow({
          radius: this.focusStyle.shadow.radius,
          color: this.focusStyle.shadow.color,
          offsetX: this.focusStyle.shadow.offsetX,
          offsetY: this.focusStyle.shadow.offsetY
        })
    }
  }
  
  build() {
    Stack({
      alignContent: 'center',
      onClick: () => this.handleClick()
    })
    .width(this.getWidth())
    .height(this.getHeight())
    .padding(this.getSizeConfig().padding)
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(this.getCurrentBorderRadius())
    .border({ width: this.type === 'ghost' ? 2 : 0, color: this.getBorderColor() })
    .opacity(this.getOpacity())
    .scale({ x: this.getScale(), y: this.getScale() })
    .animation({
      duration: this.animationDuration,
      curve: 'ease-in-out'
    })
    .focusable(this.focusable)
    .autoFocus(this.autoFocus)
    .onFocus(() => this.handleFocus())
    .onBlur(() => this.handleBlur())
    .onHover((isHover: boolean) => this.handleHover(isHover))
    .onTouchDown(() => this.handleTouchDown())
    .onTouchUp(() => this.handleTouchUp())
    .onTouchCancel(() => this.handleTouchCancel())
    .onLongPress(() => this.handleLongPress())
    {
      // 按钮文本
      this.renderButtonText()
      
      // 焦点指示器
      this.renderFocusIndicator()
    }
    // 应用自定义样式
    .attrs(this.customStyle)
  }
}

// ==================== 便捷工厂方法 ====================

export const createButton = (props: EnhancedButtonProps): EnhancedButton => {
  return new EnhancedButton(props)
}

export const PrimaryButton = (props: Omit<EnhancedButtonProps, 'type'>): EnhancedButton => {
  return new EnhancedButton({ ...props, type: 'primary' })
}

export const SecondaryButton = (props: Omit<EnhancedButtonProps, 'type'>): EnhancedButton => {
  return new EnhancedButton({ ...props, type: 'secondary' })
}

export const DangerButton = (props: Omit<EnhancedButtonProps, 'type'>): EnhancedButton => {
  return new EnhancedButton({ ...props, type: 'danger' })
}

export const GhostButton = (props: Omit<EnhancedButtonProps, 'type'>): EnhancedButton => {
  return new EnhancedButton({ ...props, type: 'ghost' })
}

// ==================== 导出类型 ====================

export type { ButtonType, ButtonSize, ButtonShape, EnhancedButtonProps }