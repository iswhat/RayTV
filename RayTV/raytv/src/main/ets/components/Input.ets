/**
 * 输入框组件 | Input Component
 * 功能完整的输入框组件
 * Feature-complete input component
 */
import { BaseComponent, BaseComponentProps } from './BaseComponent';
import { Logger } from '../common/utils/Logger';

// ==================== 输入框特有属性 | Input Specific Props ====================

/**
 * 输入框类型 | Input Types
 */
export type InputType = 'text' | 'password' | 'email' | 'number' | 'tel';

/**
 * 输入框大小 | Input Sizes
 */
export type InputSize = 'small' | 'medium' | 'large';

/**
 * 输入框属性扩展 | Extended Input Props
 */
export interface InputProps extends BaseComponentProps {
  // 输入框特有属性
  type?: InputType;
  size?: InputSize;
  placeholder?: string;
  value?: string;
  defaultValue?: string;
  name?: string;
  readonly?: boolean;
  maxlength?: number;
  
  // 前缀后缀
  prefix?: string;
  suffix?: string;
  
  // 图标
  icon?: string;
  iconPosition?: 'left' | 'right';
  
  // 事件
  onInput?: (value: string, event: ?) => void;
  onChange?: (value: string, event: ?) => void;
  onBlur?: (value: string, event: ?) => void;
  onFocus?: (value: string, event: ?) => void;
}

// ==================== 输入框组件类 | Input Component Class ====================

/**
 * 输入框组件 | Input Component
 */
export class Input extends BaseComponent<InputProps> {
  private static readonly DEFAULT_PROPS: Partial<InputProps> = {
    type: 'text',
    size: 'medium',
    iconPosition: 'left'
  };
  
  private currentValue: string = '';
  
  constructor(props: InputProps) {
    super({ ...Input.DEFAULT_PROPS, ...props });
    this.currentValue = props.value || props.defaultValue || '';
  }
  
  /**
   * 渲染输入框 | Render input
   */
  public render() {
    return Column() {
      this.renderInputContainer()
    }
    .width('100%');
  }
  
  /**
   * 渲染输入框容器 | Render input container
   */
  private renderInputContainer() {
    return Row() {
      // 前缀
      if (this.props.prefix) {
        this.renderPrefix();
      }
      
      // 图标
      if (this.props.icon && this.props.iconPosition === 'left') {
        this.renderIcon();
      }
      
      // 输入框
      this.renderTextInput();
      
      // 图标
      if (this.props.icon && this.props.iconPosition === 'right') {
        this.renderIcon();
      }
      
      // 后缀
      if (this.props.suffix) {
        this.renderSuffix();
      }
    }
    .width('100%')
    .height(this.getHeight())
    .backgroundColor('#ffffff')
    .borderRadius(6)
    .border({ width: 1, color: this.getBorderColor() })
    .onFocus(() => {
      this.setState({ focused: true });
    })
    .onBlur(() => {
      this.setState({ focused: false });
    });
  }
  
  /**
   * 渲染文本输入框 | Render text input
   */
  private renderTextInput() {
    return TextInput({ placeholder: this.props.placeholder || '', text: this.currentValue })
      .placeholderColor('#999999')
      .caretColor('#007AFF')
      .onChange((value: string) => {
        this.currentValue = value;
        this.props.onInput?.(value, null);
      })
      .onSubmit((value: string) => {
        this.props.onChange?.(value, null);
      })
      .textInputStyle({
        fontSize: this.getFontSize(),
        fontColor: '#333333'
      })
      .layoutWeight(1);
  }
  
  /**
   * 渲染前缀 | Render prefix
   */
  private renderPrefix() {
    if (this.props.prefix) {
      return Text(this.props.prefix)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ left: 12, right: 8 });
    }
  }
  
  /**
   * 渲染后缀 | Render suffix
   */
  private renderSuffix() {
    if (this.props.suffix) {
      return Text(this.props.suffix)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ left: 8, right: 12 });
    }
  }
  
  /**
   * 渲染图标 | Render icon
   */
  private renderIcon() {
    if (this.props.icon) {
      return Text(this.props.icon)
        .fontSize(16)
        .fontColor('#999999')
        .margin({ left: 12, right: 12 });
    }
  }
  
  /**
   * 获取高度 | Get height
   */
  private getHeight(): string {
    const heightMap: Record<InputSize, string> = {
      small: '32vp',
      medium: '40vp',
      large: '48vp'
    };
    
    return heightMap[this.props.size || 'medium'];
  }
  
  /**
   * 获取字体大小 | Get font size
   */
  private getFontSize(): number {
    const sizeMap: Record<InputSize, number> = {
      small: 12,
      medium: 14,
      large: 16
    };
    
    return sizeMap[this.props.size || 'medium'];
  }
  
  /**
   * 获取边框颜色 | Get border color
   */
  private getBorderColor(): string {
    if (this.props.disabled) {
      return '#dddddd';
    }
    
    if (this.state.focused) {
      return '#007AFF';
    }
    
    return '#e0e0e0';
  }
  
  /**
   * 获取当前值 | Get current value
   */
  public getValue(): string {
    return this.currentValue;
  }
  
  /**
   * 设置值 | Set value
   */
  public setValue(value: string): void {
    this.currentValue = value;
    this.updateProps({ value });
  }
  
  /**
   * 清空值 | Clear value
   */
  public clear(): void {
    this.setValue('');
  }
}

// ==================== 便捷工厂方法 | Convenient Factory Methods ====================

export const createInput = (props: InputProps): Input => {
  return new Input(props);
};

export const TextInput = (props: Omit<InputProps, 'type'>): Input => {
  return new Input({ ...props, type: 'text' });
};

export const PasswordInput = (props: Omit<InputProps, 'type'>): Input => {
  return new Input({ ...props, type: 'password' });
};

export const EmailInput = (props: Omit<InputProps, 'type'>): Input => {
  return new Input({ ...props, type: 'email' });
};

// ==================== 导出类型 | Export Types ====================

export type { InputProps, InputType, InputSize };