/**
 * 卡片组件
 * 通用的内容容器组件，支持阴影、边框和各种样式
 */
import { BaseComponent } from '../core/BaseComponent'
import { Stack, Column, Row } from '@ohos/arkui'

export interface CardProps {
  id?: string
  className?: string
  style?: Record<string, any>
  disabled?: boolean
  visible?: boolean
  title?: string
  subtitle?: string
  header?: any
  footer?: any
  elevation?: number // 阴影等级 0-5
  variant?: 'filled' | 'outlined' | 'elevated'
  padding?: string
  margin?: string
  borderRadius?: string
  borderColor?: string
  backgroundColor?: string
}

interface CardState {
  hovered: boolean
  pressed: boolean
}

export class CardComponent extends BaseComponent<CardProps> {
  private state: CardState = {
    hovered: false,
    pressed: false
  }
  
  protected onCreate(): void {
    // 设置默认属性
    this.props.elevation = this.props.elevation ?? 1
    this.props.variant = this.props.variant || 'elevated'
    this.props.padding = this.props.padding || '16px'
    this.props.margin = this.props.margin || '8px'
    this.props.borderRadius = this.props.borderRadius || '12px'
  }
  
  private getCardStyle(): Record<string, any> {
    const baseStyle = {
      padding: this.props.padding,
      margin: this.props.margin,
      borderRadius: this.props.borderRadius,
      backgroundColor: this.getBackgroundColor(),
      border: this.getBorderStyle(),
      boxShadow: this.getBoxShadow(),
      transition: 'all 0.3s ease'
    }
    
    return { ...baseStyle, ...this.props.style }
  }
  
  private getBackgroundColor(): string {
    if (this.props.backgroundColor) {
      return this.props.backgroundColor
    }
    
    switch (this.props.variant) {
      case 'filled': return '#FFFFFF'
      case 'outlined': return '#FFFFFF'
      case 'elevated': return '#FFFFFF'
      default: return '#FFFFFF'
    }
  }
  
  private getBorderStyle(): string {
    if (this.props.variant === 'outlined') {
      const color = this.props.borderColor || '#E0E0E0'
      return `1px solid ${color}`
    }
    return 'none'
  }
  
  private getBoxShadow(): string {
    if (this.props.variant !== 'elevated') {
      return 'none'
    }
    
    const elevations = [
      'none',
      '0 2px 4px rgba(0,0,0,0.1)',
      '0 4px 8px rgba(0,0,0,0.15)',
      '0 8px 16px rgba(0,0,0,0.2)',
      '0 12px 24px rgba(0,0,0,0.25)',
      '0 16px 32px rgba(0,0,0,0.3)'
    ]
    
    return elevations[Math.min(Math.max(this.props.elevation || 1, 0), 5)]
  }
  
  private getTitleStyle(): Record<string, any> {
    return {
      fontSize: '18px',
      fontWeight: '600',
      color: '#333333',
      marginBottom: '4px'
    }
  }
  
  private getSubtitleStyle(): Record<string, any> {
    return {
      fontSize: '14px',
      color: '#666666',
      marginBottom: '12px'
    }
  }
  
  private handleHover(enter: boolean): void {
    this.state.hovered = enter
    this.emit('hover', { hovering: enter })
  }
  
  private handlePress(): void {
    if (this.props.disabled) return
    this.emit('press', {})
  }
  
  @Builder
  private renderHeader() {
    if (this.props.title) {
      Column() {
        Text(this.props.title)
          .fontSize(this.getTitleStyle().fontSize)
          .fontWeight(this.getTitleStyle().fontWeight)
          .color(this.getTitleStyle().color)
        
        if (this.props.subtitle) {
          Text(this.props.subtitle)
            .fontSize(this.getSubtitleStyle().fontSize)
            .color(this.getSubtitleStyle().color)
        }
      }
      .width('100%')
      .margin({ bottom: '12px' })
    }
  }
  
  @Builder
  private renderFooter() {
    // Footer content would go here
  }
  
  build() {
    Stack({
      onClick: () => this.handlePress()
    })
    .width('100%')
    .padding(this.getCardStyle().padding)
    .margin(this.getCardStyle().margin)
    .backgroundColor(this.getCardStyle().backgroundColor)
    .borderRadius(this.getCardStyle().borderRadius)
    .border(this.getCardStyle().border)
    .boxShadow(this.getCardStyle().boxShadow)
    {
      Column() {
        // 渲染头部
        this.renderHeader()
        
        // 渲染子内容
        Column() {
          Text('Card Content Area')
            .fontSize('14px')
            .color('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        
        // 渲染底部
        this.renderFooter()
      }
      .width('100%')
      .height('100%')
    }
  }
}