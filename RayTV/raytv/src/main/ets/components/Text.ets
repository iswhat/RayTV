/**
 * Text组件 | Text Component
 * 增强型文本显示组件
 */
import { BaseComponent, BaseComponentProps } from './BaseComponent';

// ==================== Text组件属性 | Text Component Props ====================

export interface TextProps extends BaseComponentProps {
  // 文本内容
  content: string;
  
  // 文本样式
  type?: 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info';
  size?: 'tiny' | 'small' | 'medium' | 'large' | 'extraLarge' | 'huge';
  weight?: 'light' | 'normal' | 'medium' | 'bold' | 'extraBold';
  
  // 排版控制
  align?: TextAlign;
  decoration?: TextDecoration;
  lineHeight?: number;
  letterSpacing?: number;
  
  // 功能特性
  selectable?: boolean;
  ellipsis?: boolean;
  maxLines?: number;
  
  // 国际化支持
  translationKey?: string;
}

// ==================== Text组件实现 | Text Component Implementation ====================

export class TextComponent extends BaseComponent<TextProps> {
  private static readonly DEFAULT_PROPS: Partial<TextProps> = {
    type: 'primary',
    size: 'medium',
    weight: 'normal',
    align: TextAlign.Start,
    selectable: false,
    ellipsis: false,
    maxLines: 1
  };
  
  constructor(props: TextProps) {
    super({ ...Text.DEFAULT_PROPS, ...props });
  }
  
  public render() {
    return Text(this.getDisplayContent())
      .fontSize(this.getFontSize())
      .fontColor(this.getFontColor())
      .fontWeight(this.getFontWeight())
      .textAlign(this.props.align || TextAlign.Start)
      .textDecoration(this.props.decoration || { type: TextDecorationType.None })
      .lineHeight(this.getLineHeight())
      .letterSpacing(this.getLetterSpacing())
      .maxLines(this.props.maxLines || 1)
      .textOverflow(this.getTextOverflow())
      .copyOption(this.props.selectable ? CopyOptions.InApp : CopyOptions.None)
      .onClick((event: ClickEvent) => {
        this.handleClick(event);
      });
  }
  
  private getDisplayContent(): string {
    // 这里可以集成国际化翻译逻辑
    if (this.props.translationKey) {
      // return i18n.translate(this.props.translationKey);
      return `[${this.props.translationKey}] ${this.props.content}`;
    }
    return this.props.content;
  }
  
  private getFontSize(): number {
    const sizeMap: Record<string, number> = {
      tiny: 10,
      small: 12,
      medium: 14,
      large: 16,
      extraLarge: 18,
      huge: 24
    };
    return sizeMap[this.props.size || 'medium'];
  }
  
  private getFontColor(): string {
    const colorMap: Record<string, string> = {
      primary: '#333333',
      secondary: '#666666',
      success: '#34C759',
      warning: '#FF9500',
      error: '#FF3B30',
      info: '#007AFF'
    };
    return colorMap[this.props.type || 'primary'];
  }
  
  private getFontWeight(): number {
    const weightMap: Record<string, number> = {
      light: 300,
      normal: 400,
      medium: 500,
      bold: 700,
      extraBold: 800
    };
    return weightMap[this.props.weight || 'normal'];
  }
  
  private getLineHeight(): number {
    if (this.props.lineHeight) {
      return this.props.lineHeight;
    }
    
    // 基于字体大小的默认行高
    const baseSize = this.getFontSize();
    return baseSize * 1.5;
  }
  
  private getLetterSpacing(): number {
    return this.props.letterSpacing || 0;
  }
  
  private getTextOverflow(): TextOverflow {
    return this.props.ellipsis ? TextOverflow.Ellipsis : TextOverflow.Clip;
  }
}

// ==================== 预设文本组件 | Preset Text Components ====================

export class Heading1 extends TextComponent {
  constructor(props: Omit<TextProps, 'size' | 'weight'>) {
    super({ ...props, size: 'huge', weight: 'bold' });
  }
}

export class Heading2 extends TextComponent {
  constructor(props: Omit<TextProps, 'size' | 'weight'>) {
    super({ ...props, size: 'extraLarge', weight: 'bold' });
  }
}

export class Heading3 extends TextComponent {
  constructor(props: Omit<TextProps, 'size' | 'weight'>) {
    super({ ...props, size: 'large', weight: 'bold' });
  }
}

export class BodyText extends TextComponent {
  constructor(props: Omit<TextProps, 'size' | 'type'>) {
    super({ ...props, size: 'medium', type: 'primary' });
  }
}

export class CaptionText extends TextComponent {
  constructor(props: Omit<TextProps, 'size' | 'type'>) {
    super({ ...props, size: 'small', type: 'secondary' });
  }
}

export class LinkText extends TextComponent {
  constructor(props: Omit<TextProps, 'type' | 'decoration'>) {
    super({ 
      ...props, 
      type: 'info', 
      decoration: { type: TextDecorationType.Underline } 
    });
  }
}

// ==================== 便捷工厂方法 | Convenience Factory Methods ====================

export const createText = (props: TextProps): TextComponent => {
  return new TextComponent(props);
};

export const H1 = (content: string, props?: Omit<TextProps, 'content'>): Heading1 => {
  return new Heading1({ content, ...props });
};

export const H2 = (content: string, props?: Omit<TextProps, 'content'>): Heading2 => {
  return new Heading2({ content, ...props });
};

export const H3 = (content: string, props?: Omit<TextProps, 'content'>): Heading3 => {
  return new Heading3({ content, ...props });
};

export const Body = (content: string, props?: Omit<TextProps, 'content'>): BodyText => {
  return new BodyText({ content, ...props });
};

export const Caption = (content: string, props?: Omit<TextProps, 'content'>): CaptionText => {
  return new CaptionText({ content, ...props });
};

// ==================== 导出类型 | Export Types ====================

export type { TextProps };