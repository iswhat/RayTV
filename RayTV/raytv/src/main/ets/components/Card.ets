/**
 * Card组件 | Card Component
 * 灵活的内容容器组件
 */
import { BaseComponent, BaseComponentProps } from './BaseComponent';

// ==================== Card组件属性 | Card Component Props ====================

export interface CardProps extends BaseComponentProps {
  // 内容区域
  header?: string;
  title?: string;
  subtitle?: string;
  content?: string;
  footer?: string;
  
  // 样式控制
  variant?: 'elevated' | 'outlined' | 'filled';
  size?: 'small' | 'medium' | 'large';
  cover?: boolean;
  hoverable?: boolean;
  
  // 媒体内容
  mediaSrc?: string;
  mediaAlt?: string;
  mediaHeight?: string;
}

// ==================== Card组件实现 | Card Component Implementation ====================

export class Card extends BaseComponent<CardProps> {
  private static readonly DEFAULT_PROPS: Partial<CardProps> = {
    variant: 'elevated',
    size: 'medium',
    cover: false,
    hoverable: false
  };
  
  constructor(props: CardProps) {
    super({ ...Card.DEFAULT_PROPS, ...props });
  }
  
  public render() {
    return Column() {
      this.renderCardContent()
    }
    .width('100%')
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(this.getBorderRadius())
    .border(this.getBorderStyle())
    .padding(this.getPadding())
    .shadow(this.getShadowStyle())
    .onHover((isHover: boolean) => {
      if (this.props.hoverable) {
        this.setState({ hovered: isHover });
      }
    })
    .onClick((event: ClickEvent) => {
      this.handleClick(event);
    });
  }
  
  private renderCardContent() {
    Column() {
      // 媒体区域
      if (this.props.mediaSrc) {
        this.renderMedia();
      }
      
      // 头部区域
      if (this.props.header) {
        this.renderHeader();
      }
      
      // 标题区域
      if (this.props.title || this.props.subtitle) {
        this.renderTitleSection();
      }
      
      // 内容区域
      if (this.props.content) {
        this.renderContent();
      }
      
      // 底部区域
      if (this.props.footer) {
        this.renderFooter();
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }
  
  private renderMedia() {
    Image(this.props.mediaSrc)
      .alt(this.props.mediaAlt || '')
      .width('100%')
      .height(this.props.mediaHeight || '200vp')
      .borderRadius(this.props.cover ? 0 : this.getBorderRadius())
      .objectFit(ImageFit.Cover)
      .margin({ bottom: 12 });
  }
  
  private renderHeader() {
    Text(this.props.header)
      .fontSize(12)
      .fontColor('#666666')
      .textCase(TextCase.UpperCase)
      .letterSpacing(1)
      .margin({ bottom: 8 });
  }
  
  private renderTitleSection() {
    Column() {
      if (this.props.title) {
        Text(this.props.title)
          .fontSize(this.getTitleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      
      if (this.props.subtitle) {
        Text(this.props.subtitle)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .margin({ bottom: 12 });
  }
  
  private renderContent() {
    Text(this.props.content)
      .fontSize(14)
      .fontColor('#555555')
      .lineHeight(20)
      .maxLines(4)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .margin({ bottom: 16 });
  }
  
  private renderFooter() {
    Text(this.props.footer)
      .fontSize(12)
      .fontColor('#888888')
      .marginTop(8)
      .padding({ top: 8 })
      .border({ width: { top: 1 }, color: '#EEEEEE' });
  }
  
  // ==================== 样式计算方法 | Style Calculation Methods ====================
  
  private getBackgroundColor(): string {
    const variant = this.props.variant || 'elevated';
    const colors: Record<string, string> = {
      elevated: '#FFFFFF',
      outlined: 'transparent',
      filled: '#F8F9FA'
    };
    return colors[variant];
  }
  
  private getBorderRadius(): number {
    const size = this.props.size || 'medium';
    const radius: Record<string, number> = {
      small: 8,
      medium: 12,
      large: 16
    };
    return radius[size];
  }
  
  private getBorderStyle(): BorderOptions {
    const variant = this.props.variant || 'elevated';
    if (variant === 'outlined') {
      return { width: 1, color: '#DDDDDD' };
    }
    return { width: 0, color: 'transparent' };
  }
  
  private getPadding(): string {
    const size = this.props.size || 'medium';
    const padding: Record<string, string> = {
      small: '12vp',
      medium: '16vp',
      large: '24vp'
    };
    return padding[size];
  }
  
  private getShadowStyle(): ShadowOptions | null {
    const variant = this.props.variant || 'elevated';
    if (variant === 'elevated') {
      return {
        radius: 8,
        color: '#00000020',
        offsetX: 0,
        offsetY: 2
      };
    }
    return null;
  }
  
  private getTitleFontSize(): number {
    const size = this.props.size || 'medium';
    const fontSize: Record<string, number> = {
      small: 16,
      medium: 18,
      large: 20
    };
    return fontSize[size];
  }
}

// ==================== 便捷工厂方法 | Convenience Factory Methods ====================

export const createCard = (props: CardProps): Card => {
  return new Card(props);
};

export const ElevatedCard = (props: Omit<CardProps, 'variant'>): Card => {
  return new Card({ ...props, variant: 'elevated' });
};

export const OutlinedCard = (props: Omit<CardProps, 'variant'>): Card => {
  return new Card({ ...props, variant: 'outlined' });
};

export const FilledCard = (props: Omit<CardProps, 'variant'>): Card => {
  return new Card({ ...props, variant: 'filled' });
};

// ==================== 导出类型 | Export Types ====================

export type { CardProps };