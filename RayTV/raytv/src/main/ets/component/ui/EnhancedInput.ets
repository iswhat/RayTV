/**
 * EnhancedInput.ets
 * 增强型输入框组件 - 专为TV应用优化的ArkTS输入框实现
 */

import { Component, Prop, State, Builder, AboutToAppear } from '@ohos/arkui'
import { FocusStyle } from '../../common/style/FocusStyle'

// ==================== 类型定义 ====================

export type InputType = 'text' | 'password' | 'number' | 'email' | 'tel' | 'url'
export type InputSize = 'small' | 'medium' | 'large'
export type InputVariant = 'outlined' | 'filled' | 'standard'

export interface EnhancedInputProps {
  // 基础属性
  value?: string
  placeholder?: string
  type?: InputType
  size?: InputSize
  variant?: InputVariant
  
  // 状态控制
  disabled?: boolean
  readOnly?: boolean
  required?: boolean
  
  // 交互属性
  focusable?: boolean
  autoFocus?: boolean
  clearable?: boolean
  
  // 样式定制
  width?: string | number
  height?: string | number
  maxLength?: number
  customStyle?: Record<string, any>
  
  // 前后缀
  prefix?: string
  suffix?: string
  prefixIcon?: string
  suffixIcon?: string
  
  // 事件回调
  onChange?: (value: string) => void
  onInput?: (value: string) => void
  onFocus?: () => void
  onBlur?: () => void
  onClear?: () => void
  onSubmit?: (value: string) => void
}

// ==================== 主题配置 ====================

const INPUT_THEMES = {
  outlined: {
    normal: { 
      bg: '#FFFFFF', 
      border: '#D1D1D6', 
      text: '#000000',
      placeholder: '#8E8E93'
    },
    focused: { 
      bg: '#FFFFFF', 
      border: '#007AFF', 
      text: '#000000',
      placeholder: '#8E8E93'
    },
    disabled: { 
      bg: '#F2F2F7', 
      border: '#E5E5EA', 
      text: '#8E8E93',
      placeholder: '#C7C7CC'
    }
  },
  filled: {
    normal: { 
      bg: '#F2F2F7', 
      border: 'transparent', 
      text: '#000000',
      placeholder: '#8E8E93'
    },
    focused: { 
      bg: '#E5E5EA', 
      border: 'transparent', 
      text: '#000000',
      placeholder: '#8E8E93'
    },
    disabled: { 
      bg: '#F2F2F7', 
      border: 'transparent', 
      text: '#8E8E93',
      placeholder: '#C7C7CC'
    }
  },
  standard: {
    normal: { 
      bg: 'transparent', 
      border: 'transparent', 
      text: '#000000',
      placeholder: '#8E8E93',
      underline: '#D1D1D6'
    },
    focused: { 
      bg: 'transparent', 
      border: 'transparent', 
      text: '#000000',
      placeholder: '#8E8E93',
      underline: '#007AFF'
    },
    disabled: { 
      bg: 'transparent', 
      border: 'transparent', 
      text: '#8E8E93',
      placeholder: '#C7C7CC',
      underline: '#E5E5EA'
    }
  }
}

const SIZE_CONFIGS = {
  small: { 
    height: 40, 
    fontSize: 14, 
    padding: '8vp 12vp',
    iconSize: 16
  },
  medium: { 
    height: 48, 
    fontSize: 16, 
    padding: '12vp 16vp',
    iconSize: 20
  },
  large: { 
    height: 56, 
    fontSize: 18, 
    padding: '16vp 20vp',
    iconSize: 24
  }
}

// ==================== 增强型输入框组件 ====================

@Component
export struct EnhancedInput {
  // Props
  @Prop value: string = ''
  @Prop placeholder: string = '请输入内容'
  @Prop type: InputType = 'text'
  @Prop size: InputSize = 'medium'
  @Prop variant: InputVariant = 'outlined'
  @Prop disabled: boolean = false
  @Prop readOnly: boolean = false
  @Prop required: boolean = false
  @Prop focusable: boolean = true
  @Prop autoFocus: boolean = false
  @Prop clearable: boolean = false
  @Prop width: string | number = '100%'
  @Prop height: string | number = 'auto'
  @Prop maxLength: number = 1000
  @Prop customStyle: Record<string, any> = {}
  @Prop prefix: string = ''
  @Prop suffix: string = ''
  @Prop prefixIcon: string = ''
  @Prop suffixIcon: string = ''
  @Prop onChange: (value: string) => void = () => {}
  @Prop onInput: (value: string) => void = () => {}
  @Prop onFocus: () => void = () => {}
  @Prop onBlur: () => void = () => {}
  @Prop onClear: () => void = () => {}
  @Prop onSubmit: (value: string) => void = () => {}
  
  // State
  @State currentValue: string = ''
  @State isFocused: boolean = false
  @State isHovered: boolean = false
  @State showPassword: boolean = false
  
  // Private properties
  private focusStyle: FocusStyle = new FocusStyle()
  private animationDuration: number = 200
  
  @AboutToAppear
  aboutToAppear(): void {
    this.currentValue = this.value
    
    // 初始化焦点样式
    this.focusStyle.setBorder({
      width: 2,
      color: '#007AFF',
      radius: 8
    })
    this.focusStyle.setShadow({
      color: 'rgba(0,122,255,0.2)',
      radius: 8,
      offsetX: 0,
      offsetY: 2
    })
  }
  
  // ==================== 计算属性 ====================
  
  private getThemeConfig() {
    return INPUT_THEMES[this.variant] || INPUT_THEMES.outlined
  }
  
  private getSizeConfig() {
    return SIZE_CONFIGS[this.size] || SIZE_CONFIGS.medium
  }
  
  private getCurrentState() {
    if (this.disabled) return 'disabled'
    if (this.isFocused) return 'focused'
    return 'normal'
  }
  
  private getBackgroundColor(): string {
    const state = this.getCurrentState()
    return this.getThemeConfig()[state].bg
  }
  
  private getBorderColor(): string {
    const state = this.getCurrentState()
    return this.getThemeConfig()[state].border
  }
  
  private getTextColor(): string {
    const state = this.getCurrentState()
    return this.getThemeConfig()[state].text
  }
  
  private getPlaceholderColor(): string {
    const state = this.getCurrentState()
    return this.getThemeConfig()[state].placeholder
  }
  
  private getUnderlineColor(): string {
    if (this.variant !== 'standard') return 'transparent'
    const state = this.getCurrentState()
    return this.getThemeConfig()[state].underline || 'transparent'
  }
  
  private getOpacity(): number {
    return this.disabled ? 0.6 : 1.0
  }
  
  private getInputType(): InputType {
    if (this.type === 'password' && this.showPassword) {
      return 'text'
    }
    return this.type
  }
  
  private shouldShowClear(): boolean {
    return this.clearable && !this.disabled && this.currentValue.length > 0
  }
  
  private shouldShowPasswordToggle(): boolean {
    return this.type === 'password' && !this.disabled
  }
  
  // ==================== 事件处理 ====================
  
  private handleInputChange(value: string): void {
    if (this.disabled || this.readOnly) return
    
    this.currentValue = value
    this.onInput(value)
  }
  
  private handleValueChange(value: string): void {
    if (this.disabled || this.readOnly) return
    
    this.currentValue = value
    this.onChange(value)
  }
  
  private handleSubmit(value: string): void {
    if (this.disabled || this.readOnly) return
    
    this.onSubmit(value)
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
  
  private handleClear(): void {
    if (this.disabled || this.readOnly) return
    
    this.currentValue = ''
    this.onChange('')
    this.onClear()
  }
  
  private handlePasswordToggle(): void {
    if (this.disabled || this.readOnly) return
    this.showPassword = !this.showPassword
  }
  
  // ==================== 渲染方法 ====================
  
  @Builder
  private renderPrefix(): void {
    if (this.prefix || this.prefixIcon) {
      Row() {
        if (this.prefixIcon) {
          // 图标前缀
          Text(this.prefixIcon)
            .fontSize(this.getSizeConfig().iconSize)
            .fontColor(this.getTextColor())
            .margin({ right: 8 })
        }
        
        if (this.prefix) {
          // 文本前缀
          Text(this.prefix)
            .fontSize(this.getSizeConfig().fontSize - 2)
            .fontColor(this.getTextColor())
            .margin({ right: 8 })
        }
      }
      .alignItems(VerticalAlign.Center)
    }
  }
  
  @Builder
  private renderSuffix(): void {
    Row() {
      // 密码切换按钮
      if (this.shouldShowPasswordToggle()) {
        Button() {
          Text(this.showPassword ? '👁️' : '🔒')
            .fontSize(this.getSizeConfig().iconSize - 4)
            .fontColor(this.getTextColor())
        }
        .width(32)
        .height(32)
        .backgroundColor('transparent')
        .borderRadius(16)
        .margin({ right: 8 })
        .onClick(() => this.handlePasswordToggle())
      }
      
      // 清除按钮
      if (this.shouldShowClear()) {
        Button() {
          Text('✕')
            .fontSize(this.getSizeConfig().iconSize - 4)
            .fontColor(this.getPlaceholderColor())
        }
        .width(32)
        .height(32)
        .backgroundColor('transparent')
        .borderRadius(16)
        .margin({ right: 8 })
        .onClick(() => this.handleClear())
      }
      
      if (this.suffix || this.suffixIcon) {
        if (this.suffixIcon) {
          // 图标后缀
          Text(this.suffixIcon)
            .fontSize(this.getSizeConfig().iconSize)
            .fontColor(this.getTextColor())
            .margin({ left: 8 })
        }
        
        if (this.suffix) {
          // 文本后缀
          Text(this.suffix)
            .fontSize(this.getSizeConfig().fontSize - 2)
            .fontColor(this.getTextColor())
            .margin({ left: 8 })
        }
      }
    }
    .alignItems(VerticalAlign.Center)
  }
  
  @Builder
  private renderTextInput(): void {
    TextInput({ 
      placeholder: this.required ? `${this.placeholder} *` : this.placeholder,
      text: this.currentValue
    })
    .placeholderColor(this.getPlaceholderColor())
    .caretColor('#007AFF')
    .maxLength(this.maxLength)
    .readOnly(this.readOnly)
    .onChange((value: string) => this.handleInputChange(value))
    .onSubmit((value: string) => this.handleSubmit(value))
    .textInputStyle({
      fontSize: this.getSizeConfig().fontSize,
      fontColor: this.getTextColor()
    })
    .layoutWeight(1)
  }
  
  @Builder
  private renderFocusIndicator(): void {
    if (this.isFocused) {
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
    Row() {
      // 前缀
      this.renderPrefix()
      
      // 输入框主体
      this.renderTextInput()
      
      // 后缀
      this.renderSuffix()
    }
    .width(this.width)
    .height(this.height === 'auto' ? this.getSizeConfig().height : this.height)
    .padding(this.getSizeConfig().padding)
    .backgroundColor(this.getBackgroundColor())
    .border({
      width: this.variant === 'standard' ? 0 : 1,
      color: this.getBorderColor(),
      radius: 8
    })
    .border({ // 下划线（仅standard变体）
      width: this.variant === 'standard' ? 0 : 0,
      color: 'transparent',
      radius: 0,
      bottom: this.variant === 'standard' ? 2 : 0,
      bottomColor: this.getUnderlineColor()
    })
    .opacity(this.getOpacity())
    .focusable(this.focusable && !this.disabled)
    .autoFocus(this.autoFocus)
    .onFocus(() => this.handleFocus())
    .onBlur(() => this.handleBlur())
    .onHover((isHover: boolean) => this.handleHover(isHover))
    {
      // 焦点指示器
      this.renderFocusIndicator()
    }
    // 应用自定义样式
    .attrs(this.customStyle)
  }
}

// ==================== 便捷工厂方法 ====================

export const createInput = (props: EnhancedInputProps): EnhancedInput => {
  return new EnhancedInput(props)
}

export const OutlinedInput = (props: Omit<EnhancedInputProps, 'variant'>): EnhancedInput => {
  return new EnhancedInput({ ...props, variant: 'outlined' })
}

export const FilledInput = (props: Omit<EnhancedInputProps, 'variant'>): EnhancedInput => {
  return new EnhancedInput({ ...props, variant: 'filled' })
}

export const StandardInput = (props: Omit<EnhancedInputProps, 'variant'>): EnhancedInput => {
  return new EnhancedInput({ ...props, variant: 'standard' })
}

// ==================== 导出类型 ====================

export type { InputType, InputSize, InputVariant, EnhancedInputProps }