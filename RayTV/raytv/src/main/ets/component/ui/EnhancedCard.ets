/**
 * EnhancedCard.ets
 * 增强型卡片组件 - 专为TV应用优化的ArkTS卡片实现
 */

import { Component, Prop, State, Builder, AboutToAppear } from '@ohos/arkui'
import { FocusStyle } from '../../common/style/FocusStyle'

// ==================== 类型定义 ====================

export type CardVariant = 'elevated' | 'outlined' | 'filled' | 'glass'
export type CardSize = 'small' | 'medium' | 'large' | 'extraLarge'
export type CardElevation = 0 | 1 | 2 | 3 | 4 | 5

export interface EnhancedCardProps {
  // 基础属性
  title?: string
  subtitle?: string
  description?: string
  
  // 样式控制
  variant?: CardVariant
  size?: CardSize
  elevation?: CardElevation
  hoverable?: boolean
  clickable?: boolean
  selected?: boolean
  
  // 状态控制
  disabled?: boolean
  loading?: boolean
  
  // 交互属性
  focusable?: boolean
  autoFocus?: boolean
  
  // 尺寸定制
  width?: string | number
  height?: string | number
  maxWidth?: string | number
  maxHeight?: string | number
  
  // 样式定制
  customStyle?: Record<string, any>
  headerStyle?: Record<string, any>
  contentStyle?: Record<string, any>
  footerStyle?: Record<string, any>
  
  // 媒体内容
  coverImage?: string
  coverHeight?: string | number
  coverFit?: ImageFit
  
  // 事件回调
  onClick?: () => void
  onLongPress?: () => void
  onFocus?: () => void
  onBlur?: () => void
}

// ==================== 主题配置 ====================

const CARD_THEMES = {
  elevated: {
    normal: { 
      bg: '#FFFFFF', 
      border: 'transparent',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    hover: { 
      bg: '#FAFAFA', 
      border: 'transparent',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    selected: { 
      bg: '#F0F8FF', 
      border: '#007AFF',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    disabled: { 
      bg: '#F2F2F7', 
      border: 'transparent',
      text: '#8E8E93',
      subtitle: '#C7C7CC'
    }
  },
  outlined: {
    normal: { 
      bg: '#FFFFFF', 
      border: '#D1D1D6',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    hover: { 
      bg: '#FAFAFA', 
      border: '#007AFF',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    selected: { 
      bg: '#F0F8FF', 
      border: '#007AFF',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    disabled: { 
      bg: '#F2F2F7', 
      border: '#E5E5EA',
      text: '#8E8E93',
      subtitle: '#C7C7CC'
    }
  },
  filled: {
    normal: { 
      bg: '#F2F2F7', 
      border: 'transparent',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    hover: { 
      bg: '#E5E5EA', 
      border: 'transparent',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    selected: { 
      bg: '#D1D1D6', 
      border: 'transparent',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    disabled: { 
      bg: '#F2F2F7', 
      border: 'transparent',
      text: '#8E8E93',
      subtitle: '#C7C7CC'
    }
  },
  glass: {
    normal: { 
      bg: 'rgba(255,255,255,0.8)', 
      border: 'rgba(255,255,255,0.3)',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    hover: { 
      bg: 'rgba(255,255,255,0.9)', 
      border: 'rgba(0,122,255,0.3)',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    selected: { 
      bg: 'rgba(0,122,255,0.1)', 
      border: 'rgba(0,122,255,0.5)',
      text: '#000000',
      subtitle: '#8E8E93'
    },
    disabled: { 
      bg: 'rgba(242,242,247,0.6)', 
      border: 'rgba(229,229,234,0.3)',
      text: '#8E8E93',
      subtitle: '#C7C7CC'
    }
  }
}

const SIZE_CONFIGS = {
  small: { 
    padding: '12vp', 
    titleSize: 16, 
    subtitleSize: 14, 
    descriptionSize: 12,
    spacing: 8,
    borderRadius: 8
  },
  medium: { 
    padding: '16vp', 
    titleSize: 18, 
    subtitleSize: 16, 
    descriptionSize: 14,
    spacing: 12,
    borderRadius: 12
  },
  large: { 
    padding: '20vp', 
    titleSize: 20, 
    subtitleSize: 18, 
    descriptionSize: 16,
    spacing: 16,
    borderRadius: 16
  },
  extraLarge: { 
    padding: '24vp', 
    titleSize: 24, 
    subtitleSize: 20, 
    descriptionSize: 18,
    spacing: 20,
    borderRadius: 20
  }
}

const ELEVATION_SHADOWS = [
  'none',
  '0 2vp 4vp rgba(0,0,0,0.1)',
  '0 4vp 8vp rgba(0,0,0,0.15)',
  '0 8vp 16vp rgba(0,0,0,0.2)',
  '0 12vp 24vp rgba(0,0,0,0.25)',
  '0 16vp 32vp rgba(0,0,0,0.3)'
]

// ==================== 增强型卡片组件 ====================

@Component
export struct EnhancedCard {
  // Props
  @Prop title: string = ''
  @Prop subtitle: string = ''
  @Prop description: string = ''
  @Prop variant: CardVariant = 'elevated'
  @Prop size: CardSize = 'medium'
  @Prop elevation: CardElevation = 1
  @Prop hoverable: boolean = false
  @Prop clickable: boolean = false
  @Prop selected: boolean = false
  @Prop disabled: boolean = false
  @Prop loading: boolean = false
  @Prop focusable: boolean = true
  @Prop autoFocus: boolean = false
  @Prop width: string | number = '100%'
  @Prop height: string | number = 'auto'
  @Prop maxWidth: string | number = 'none'
  @Prop maxHeight: string | number = 'none'
  @Prop customStyle: Record<string, any> = {}
  @Prop headerStyle: Record<string, any> = {}
  @Prop contentStyle: Record<string, any> = {}
  @Prop footerStyle: Record<string, any> = {}
  @Prop coverImage: string = ''
  @Prop coverHeight: string | number = 160
  @Prop coverFit: ImageFit = ImageFit.Cover
  @Prop onClick: () => void = () => {}
  @Prop onLongPress: () => void = () => {}
  @Prop onFocus: () => void = () => {}
  @Prop onBlur: () => void = () => {}
  
  // State
  @State isHovered: boolean = false
  @State isFocused: boolean = false
  @State isPressed: boolean = false
  
  // Private properties
  private focusStyle: FocusStyle = new FocusStyle()
  private animationDuration: number = 200
  
  @AboutToAppear
  aboutToAppear(): void {
    // 初始化焦点样式
    this.focusStyle.setBorder({
      width: 3,
      color: '#007AFF',
      radius: this.getSizeConfig().borderRadius + 2
    })
    this.focusStyle.setShadow({
      color: '#007AFF',
      radius: 12,
      offsetX: 0,
      offsetY: 4
    })
  }
  
  // ==================== 计算属性 ====================
  
  private getThemeConfig() {
    return CARD_THEMES[this.variant] || CARD_THEMES.elevated
  }
  
  private getSizeConfig() {
    return SIZE_CONFIGS[this.size] || SIZE_CONFIGS.medium
  }
  
  private getCurrentState() {
    if (this.disabled) return 'disabled'
    if (this.selected) return 'selected'
    if (this.isHovered && this.hoverable) return 'hover'
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
  
  private getSubtitleColor(): string {
    const state = this.getCurrentState()
    return this.getThemeConfig()[state].subtitle
  }
  
  private getBoxShadow(): string {
    if (this.variant === 'outlined' || this.variant === 'filled') {
      return 'none'
    }
    return ELEVATION_SHADOWS[this.elevation] || ELEVATION_SHADOWS[1]
  }
  
  private getOpacity(): number {
    return this.disabled ? 0.6 : 1.0
  }
  
  private getScale(): number {
    if (this.isPressed && this.clickable) return 0.98
    if (this.isHovered && this.hoverable) return 1.02
    return 1.0
  }
  
  private getCursor(): string {
    if (this.disabled) return 'default'
    if (this.clickable) return 'pointer'
    return 'default'
  }
  
  // ==================== 事件处理 ====================
  
  private handleClick(): void {
    if (this.disabled || !this.clickable) return
    this.onClick()
  }
  
  private handleLongPress(): void {
    if (this.disabled || !this.clickable) return
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
    this.isHovered = enter && this.hoverable
  }
  
  private handleTouchDown(): void {
    if (this.disabled || !this.clickable) return
    this.isPressed = true
  }
  
  private handleTouchUp(): void {
    if (this.disabled || !this.clickable) return
    this.isPressed = false
  }
  
  private handleTouchCancel(): void {
    this.isPressed = false
  }
  
  // ==================== 渲染方法 ====================
  
  @Builder
  private renderCover(): void {
    if (this.coverImage) {
      Image(this.coverImage)
        .width('100%')
        .height(this.coverHeight)
        .objectFit(this.coverFit)
        .borderRadius({
          topLeft: this.getSizeConfig().borderRadius,
          topRight: this.getSizeConfig().borderRadius,
          bottomLeft: 0,
          bottomRight: 0
        })
        .margin({ bottom: this.getSizeConfig().spacing })
    }
  }
  
  @Builder
  private renderHeader(): void {
    if (this.title || this.subtitle) {
      Column() {
        if (this.title) {
          Text(this.title)
            .fontSize(this.getSizeConfig().titleSize)
            .fontWeight(600)
            .fontColor(this.getTextColor())
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        
        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize(this.getSizeConfig().subtitleSize)
            .fontColor(this.getSubtitleColor())
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width('100%')
      .margin({ bottom: this.getSizeConfig().spacing })
      .attrs(this.headerStyle)
    }
  }
  
  @Builder
  private renderContent(): void {
    if (this.$$.children.length > 0) {
      Column() {
        // 子内容将在这里渲染
        this.renderChildren()
      }
      .width('100%')
      .attrs(this.contentStyle)
    } else if (this.description) {
      Text(this.description)
        .fontSize(this.getSizeConfig().descriptionSize)
        .fontColor(this.getSubtitleColor())
        .lineHeight(this.getSizeConfig().descriptionSize * 1.5)
        .attrs(this.contentStyle)
    }
  }
  
  @Builder
  private renderChildren(): void {
    // 这里将渲染传入的子组件
    // 在实际使用中，可以通过插槽或children属性传递
    if (this.loading) {
      Text('加载中...')
        .fontSize(this.getSizeConfig().descriptionSize)
        .fontColor(this.getSubtitleColor())
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ vertical: 20 })
    }
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
    Stack({
      alignContent: 'top-start',
      onClick: () => this.handleClick()
    })
    .width(this.width)
    .height(this.height)
    .maxWidth(this.maxWidth)
    .maxHeight(this.maxHeight)
    .padding(this.getSizeConfig().padding)
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(this.getSizeConfig().borderRadius)
    .border({ width: this.variant === 'outlined' ? 1 : 0, color: this.getBorderColor() })
    .boxShadow(this.getBoxShadow())
    .opacity(this.getOpacity())
    .scale({ x: this.getScale(), y: this.getScale() })
    .animation({
      duration: this.animationDuration,
      curve: 'ease-in-out'
    })
    .focusable(this.focusable && !this.disabled)
    .autoFocus(this.autoFocus)
    .cursor(this.getCursor())
    .onFocus(() => this.handleFocus())
    .onBlur(() => this.handleBlur())
    .onHover((isHover: boolean) => this.handleHover(isHover))
    .onTouchDown(() => this.handleTouchDown())
    .onTouchUp(() => this.handleTouchUp())
    .onTouchCancel(() => this.handleTouchCancel())
    .onLongPress(() => this.handleLongPress())
    {
      Column() {
        // 封面图片
        this.renderCover()
        
        // 标题区域
        this.renderHeader()
        
        // 内容区域
        this.renderContent()
      }
      .width('100%')
      
      // 焦点指示器
      this.renderFocusIndicator()
    }
    // 应用自定义样式
    .attrs(this.customStyle)
  }
}

// ==================== 便捷工厂方法 ====================

export const createCard = (props: EnhancedCardProps): EnhancedCard => {
  return new EnhancedCard(props)
}

export const ElevatedCard = (props: Omit<EnhancedCardProps, 'variant'>): EnhancedCard => {
  return new EnhancedCard({ ...props, variant: 'elevated' })
}

export const OutlinedCard = (props: Omit<EnhancedCardProps, 'variant'>): EnhancedCard => {
  return new EnhancedCard({ ...props, variant: 'outlined' })
}

export const FilledCard = (props: Omit<EnhancedCardProps, 'variant'>): EnhancedCard => {
  return new EnhancedCard({ ...props, variant: 'filled' })
}

export const GlassCard = (props: Omit<EnhancedCardProps, 'variant'>): EnhancedCard => {
  return new EnhancedCard({ ...props, variant: 'glass' })
}

// ==================== 导出类型 ====================

export type { CardVariant, CardSize, CardElevation, EnhancedCardProps }