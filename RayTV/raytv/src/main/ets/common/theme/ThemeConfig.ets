// 主题配置文件 | Theme configuration file
// 集中管理应用的样式配置，包括颜色、尺寸、字体等 | Centralized management of application style configuration, including colors, sizes, fonts, etc.

import { Curve } from '@kit.ArkUI';


/**
 * 颜色配置 | Color configuration
 */
export const Colors = {
  // 主色调 | Primary colors
  primary: '#007AFF',
  primaryLight: 'rgba(255, 255, 255, 0.1)',
  
  // 背景色 | Background colors
  background: {
    primary: '#121212',
    secondary: '#1E1E1E',
    card: '#2C2C2C'
  },
  
  // 文本颜色 | Text colors
  text: {
    primary: '#FFFFFF',
    secondary: '#E0E0E0',
    disabled: '#8E8E93',
    error: '#FF5252',
    warning: '#FF9800'
  },
  
  // 功能色 | Functional colors
  success: '#4CAF50',
  warning: '#FF9800',
  error: '#FF5252',
  info: '#2196F3'
};

/**
 * 尺寸配置 | Size configuration
 */
export const Sizes = {
  // 间距 | Spacing
  spacing: {
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
    xxl: 30,
    xxxl: 40
  },
  
  // 字体大小 | Font sizes
  font: {
    xs: 12,
    sm: 14,
    md: 16,
    lg: 18,
    xl: 20,
    xxl: 24
  },
  
  // 边框半径 | Border radius
  borderRadius: {
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
    xxl: 20
  },
  
  // 高度 | Heights
  height: {
    header: 80,
    menu: 60,
    button: 48
  },
  
  // 媒体项尺寸 | Media item sizes
  media: {
    // 横向模式 | Landscape mode
    landscape: {
      width: 260,
      height: 440,
      imageHeight: 320,
      skeleton: {
        width: 234,
        height: 320,
        titleWidth: 216
      }
    },
    // 纵向模式 | Portrait mode
    portrait: {
      width: 200,
      height: 370,
      imageHeight: 240,
      skeleton: {
        width: 176,
        height: 240,
        titleWidth: 168
      }
    },
    // 列表高度 | List height
    list: {
      landscape: 500,
      portrait: 400
    }
  }
};

/**
 * 日期格式配置 | Date format configuration
 */
export const DateFormat = {
  // 完整日期时间格式 | Full date time format
  full: '{year}年{month}月{day}日 {hours}:{minutes}',
  // 日期格式 | Date format
  date: '{year}年{month}月{day}日',
  // 时间格式 | Time format
  time: '{hours}:{minutes}'
};

/**
 * 阴影配置 | Shadow configuration
 */
export const Shadows = {
  card: {
    radius: 12,
    color: 'rgba(0, 0, 0, 0.4)',
    offsetY: 6
  }
};

/**
 * 动画配置 | Animation configuration
 */
export const Animations = {
  duration: {
    short: 200,
    medium: 500,
    long: 1000
  },
  curve: {
    easeIn: Curve.EaseIn,
    easeOut: Curve.EaseOut,
    easeInOut: Curve.EaseInOut
  }
};

/**
 * 主题管理器 | Theme manager
 */
export class ThemeManager {
  private static instance: ThemeManager;
  private currentTheme: 'light' | 'dark' = 'dark';
  
  private constructor() {}
  
  public static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }
  
  /**
   * 获取当前主题的颜色配置 | Get color configuration for current theme
   */
  public getColors() {
    return Colors;
  }
  
  /**
   * 获取当前主题的尺寸配置 | Get size configuration for current theme
   */
  public getSizes() {
    return Sizes;
  }
  
  /**
   * 获取当前主题的日期格式配置 | Get date format configuration for current theme
   */
  public getDateFormat() {
    return DateFormat;
  }
  
  /**
   * 获取当前主题的阴影配置 | Get shadow configuration for current theme
   */
  public getShadows() {
    return Shadows;
  }
  
  /**
   * 获取当前主题的动画配置 | Get animation configuration for current theme
   */
  public getAnimations() {
    return Animations;
  }
  
  /**
   * 切换主题 | Switch theme
   */
  public switchTheme(theme: 'light' | 'dark') {
    this.currentTheme = theme;
    // 这里可以添加主题切换的逻辑
  }
  
  /**
   * 获取当前主题 | Get current theme
   */
  public getCurrentTheme() {
    return this.currentTheme;
  }
}

// 导出主题实例 | Export theme instance
export const theme = ThemeManager.getInstance();
