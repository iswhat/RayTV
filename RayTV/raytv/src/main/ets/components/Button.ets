/**
 * 按钮组件 | Button Component
 * 功能丰富、主题兼容的按钮组件
 * Feature-rich, theme-compatible button component
 */
import { BaseComponent, BaseComponentProps } from './BaseComponent';
import { Logger } from '../common/utils/Logger';

// ==================== 按钮特有属性 | Button Specific Props ====================

/**
 * 按钮类型 | Button Types
 */
export type ButtonType = 'primary' | 'secondary' | 'accent' | 'ghost' | 'link' | 'text';

/**
 * 按钮大小 | Button Sizes
 */
export type ButtonSize = 'small' | 'medium' | 'large' | 'extraLarge';

/**
 * 按钮属性扩展 | Extended Button Props
 */
export interface ButtonProps extends BaseComponentProps {
  // 按钮特有属性
  type?: ButtonType;
  size?: ButtonSize;
  icon?: string;
  iconPosition?: 'left' | 'right';
  fullWidth?: boolean;
  loadingText?: string;
  
  // 内容
  children: string | Resource;
}

// ==================== 按钮组件类 | Button Component Class ====================

/**
 * 按钮组件 | Button Component
 */
export class Button extends BaseComponent<ButtonProps> {
  private static readonly DEFAULT_PROPS: Partial<ButtonProps> = {
    type: 'primary',
    size: 'medium',
    iconPosition: 'left',
    fullWidth: false
  };
  
  constructor(props: ButtonProps) {
    super({ ...Button.DEFAULT_PROPS, ...props });
  }
  
  /**
   * 渲染按钮 | Render button
   */
  public render() {
    return Column() {
      this.renderButtonContent()
    }
    .width(this.props.fullWidth ? '100%' : 'auto')
    .onClick((event: ClickEvent) => {
      this.handleClick(event);
    })
    .onHover((isHover: boolean) => {
      this.setState({ hovered: isHover });
    })
    .focusable(true)
    .onFocus((event: FocusEvent) => {
      this.handleFocus(event);
    })
    .onBlur((event: FocusEvent) => {
      this.handleBlur(event);
    })
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(this.getBorderRadius())
    .padding(this.getPadding())
    .opacity(this.props.disabled ? 0.6 : 1.0);
  }
  
  /**
   * 渲染按钮内容 | Render button content
   */
  private renderButtonContent() {
    if (this.props.loading) {
      return this.renderLoadingState();
    }
    
    return Row({ space: 8 }) {
      if (this.props.icon && this.props.iconPosition === 'left') {
        this.renderIcon();
      }
      
      Text(this.props.children as string)
        .fontSize(this.getFontSize())
        .fontWeight(this.getFontWeight())
        .fontColor(this.getTextColor())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
      
      if (this.props.icon && this.props.iconPosition === 'right') {
        this.renderIcon();
      }
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center);
  }
  
  /**
   * 渲染加载状态 | Render loading state
   */
  private renderLoadingState() {
    return Row({ space: 8 }) {
      LoadingProgress()
        .color('#ffffff')
        .width(20)
        .height(20);
      
      if (this.props.loadingText) {
        Text(this.props.loadingText)
          .fontSize(14)
          .fontColor('#ffffff');
      }
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center);
  }
  
  /**
   * 渲染图标 | Render icon
   */
  private renderIcon() {
    if (this.props.icon) {
      // 这里可以根据图标名称渲染对应的图标
      Text(this.props.icon)
        .fontSize(16)
        .fontColor(this.getTextColor());
    }
  }
  
  /**
   * 获取背景颜色 | Get background color
   */
  private getBackgroundColor(): string | Resource {
    if (this.props.disabled) {
      return '#cccccc';
    }
    
    const colorMap: Record<ButtonType, string> = {
      primary: '#007AFF',
      secondary: '#34C759',
      accent: '#FF9500',
      ghost: 'transparent',
      link: 'transparent',
      text: 'transparent'
    };
    
    return colorMap[this.props.type || 'primary'];
  }
  
  /**
   * 获取文字颜色 | Get text color
   */
  private getTextColor(): string | Resource {
    const type = this.props.type || 'primary';
    
    if (type === 'ghost' || type === 'link' || type === 'text') {
      return this.getBackgroundColor();
    }
    
    return '#ffffff';
  }
  
  /**
   * 获取边框圆角 | Get border radius
   */
  private getBorderRadius(): number | string {
    const sizeMap: Record<ButtonSize, number> = {
      small: 4,
      medium: 6,
      large: 8,
      extraLarge: 12
    };
    
    return sizeMap[this.props.size || 'medium'];
  }
  
  /**
   * 获取内边距 | Get padding
   */
  private getPadding(): number | string {
    const paddingMap: Record<ButtonSize, string> = {
      small: '8vp 16vp',
      medium: '12vp 24vp',
      large: '16vp 32vp',
      extraLarge: '20vp 40vp'
    };
    
    return paddingMap[this.props.size || 'medium'];
  }
  
  /**
   * 获取字体大小 | Get font size
   */
  private getFontSize(): number {
    const sizeMap: Record<ButtonSize, number> = {
      small: 12,
      medium: 14,
      large: 16,
      extraLarge: 18
    };
    
    return sizeMap[this.props.size || 'medium'];
  }
  
  /**
   * 获取字体粗细 | Get font weight
   */
  private getFontWeight(): number {
    return this.props.type === 'primary' ? 500 : 400;
  }
}

// ==================== 便捷工厂方法 | Convenient Factory Methods ====================

export const createButton = (props: ButtonProps): Button => {
  return new Button(props);
};

export const PrimaryButton = (props: Omit<ButtonProps, 'type'>): Button => {
  return new Button({ ...props, type: 'primary' });
};

export const SecondaryButton = (props: Omit<ButtonProps, 'type'>): Button => {
  return new Button({ ...props, type: 'secondary' });
};

// ==================== 导出类型 | Export Types ====================

export type { ButtonProps, ButtonType, ButtonSize };