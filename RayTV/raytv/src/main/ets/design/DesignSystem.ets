/**
 * 设计系统 - Design System
 * 
 * 定义应用的设计规范，包括颜色、字体、间距、阴影等
 */

/**
 * 颜色调色板
 */
export interface ColorPalette {
  primary: string;        // 主色调
  primaryLight: string;   // 主色调浅色
  primaryDark: string;    // 主色调深色
  secondary: string;      // 次要色调
  secondaryLight: string; // 次要色调浅色
  secondaryDark: string;  // 次要色调深色
  background: string;     // 背景色
  surface: string;        // 表面色
  text: string;           // 文本色
  textSecondary: string;  // 次要文本色
  error: string;          // 错误色
  warning: string;        // 警告色
  success: string;        // 成功色
  info: string;           // 信息色
  divider: string;        // 分隔线颜色
  placeholder: string;    // 占位符颜色
  disabled: string;       // 禁用颜色
}

/**
 * 字体大小规格
 */
export interface FontSizeScale {
  xs: number;           // 极小号字体
  sm: number;           // 小号字体
  md: number;           // 中号字体
  lg: number;           // 大号字体
  xl: number;           // 特大号字体
  xxl: number;          // 超大号字体
}

/**
 * 字体粗细规格
 */
export interface FontWeightScale {
  regular: number;      // 常规字重
  medium: number;       // 中等字重
  semibold: number;     // 半粗体
  bold: number;         // 粗体
}

/**
 * 字体规格
 */
export interface FontSpec {
  fontFamily: string;     // 字体家族
  fontSize: FontSizeScale;
  fontWeight: FontWeightScale;
}

/**
 * 间距比例
 */
export interface SpacingScale {
  xs: number;             // 极小间距
  sm: number;             // 小间距
  md: number;             // 中间距
  lg: number;             // 大间距
  xl: number;             // 特大间距
  xxl: number;            // 超大间距
}

/**
 * 圆角比例
 */
export interface BorderRadiusScale {
  xs: number;             // 极小圆角
  sm: number;             // 小圆角
  md: number;             // 中圆角
  lg: number;             // 大圆角
  xl: number;             // 特大圆角
  full: number;           // 全圆角
}

/**
 * 阴影级别
 */
export interface ShadowLevels {
  level1: string;         // 一级阴影
  level2: string;         // 二级阴影
  level3: string;         // 三级阴影
  level4: string;         // 四级阴影
  level5: string;         // 五级阴影
}

/**
 * 阴影规格
 */
export interface ShadowSpec {
  color: string;          // 阴影颜色
  offsetX: number;        // 水平偏移
  offsetY: number;        // 垂直偏移
  radius: number;         // 模糊半径
  spread: number;         // 扩散半径
}

/**
 * 响应式断点
 */
export interface BreakpointConfig {
  xs: number;             // 极小屏幕
  sm: number;             // 小屏幕
  md: number;             // 中等屏幕
  lg: number;             // 大屏幕
  xl: number;             // 超大屏幕
}

/**
 * 响应式排版样式
 */
export interface ResponsiveTypographyStyle {
  fontSize: number;
  fontWeight: number;
}

/**
 * 响应式排版比例
 */
export interface ResponsiveTypographyScale {
  xs: ResponsiveTypographyStyle;
  sm: ResponsiveTypographyStyle;
  md: ResponsiveTypographyStyle;
  lg: ResponsiveTypographyStyle;
  xl: ResponsiveTypographyStyle;
}

/**
 * 响应式排版配置
 */
export interface ResponsiveTypographyConfig {
  title: ResponsiveTypographyScale;
  subtitle: ResponsiveTypographyScale;
  body: ResponsiveTypographyScale;
}

/**
 * 设计系统
 */
export class DesignSystem {
  // 颜色调色板
  public static readonly Colors: ColorPalette = {
    primary: '#1976D2',
    primaryLight: '#42A5F5',
    primaryDark: '#1565C0',
    secondary: '#FFC107',
    secondaryLight: '#FFD54F',
    secondaryDark: '#FFA000',
    background: '#F8F9FA',
    surface: '#FFFFFF',
    text: '#333333',
    textSecondary: '#666666',
    error: '#F44336',
    warning: '#FF9800',
    success: '#4CAF50',
    info: '#2196F3',
    divider: '#E0E0E0',
    placeholder: '#9E9E9E',
    disabled: '#BDBDBD'
  };

  // 字体规格
  public static readonly Fonts: FontSpec = {
    fontFamily: 'sans-serif',
    fontSize: {
      xs: 10,
      sm: 12,
      md: 14,
      lg: 16,
      xl: 18,
      xxl: 24
    },
    fontWeight: {
      regular: 400,
      medium: 500,
      semibold: 600,
      bold: 700
    }
  };

  // 间距比例
  public static readonly Spacing: SpacingScale = {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48
  };

  // 圆角比例
  public static readonly BorderRadius: BorderRadiusScale = {
    xs: 2,
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
    full: 9999
  };

  // 阴影级别
  public static readonly Shadows: ShadowLevels = {
    level1: '4px 4px 8px rgba(0, 0, 0, 0.1)',
    level2: '8px 8px 16px rgba(0, 0, 0, 0.1)',
    level3: '12px 12px 24px rgba(0, 0, 0, 0.1)',
    level4: '16px 16px 32px rgba(0, 0, 0, 0.1)',
    level5: '20px 20px 40px rgba(0, 0, 0, 0.1)'
  };

  // 响应式断点
  public static readonly Breakpoints: BreakpointConfig = {
    xs: 0,
    sm: 600,
    md: 768,
    lg: 992,
    xl: 1200
  };

  // 响应式排版
  public static readonly ResponsiveTypography: ResponsiveTypographyConfig = {
    title: {
      xs: { fontSize: 20, fontWeight: 700 },
      sm: { fontSize: 24, fontWeight: 700 },
      md: { fontSize: 28, fontWeight: 700 },
      lg: { fontSize: 32, fontWeight: 700 },
      xl: { fontSize: 36, fontWeight: 700 }
    },
    subtitle: {
      xs: { fontSize: 16, fontWeight: 600 },
      sm: { fontSize: 18, fontWeight: 600 },
      md: { fontSize: 20, fontWeight: 600 },
      lg: { fontSize: 22, fontWeight: 600 },
      xl: { fontSize: 24, fontWeight: 600 }
    },
    body: {
      xs: { fontSize: 14, fontWeight: 400 },
      sm: { fontSize: 14, fontWeight: 400 },
      md: { fontSize: 16, fontWeight: 400 },
      lg: { fontSize: 16, fontWeight: 400 },
      xl: { fontSize: 18, fontWeight: 400 }
    }
  };

  // 深色主题
  public static readonly DarkThemeColors: ColorPalette = {
    primary: '#64B5F6',
    primaryLight: '#90CAF9',
    primaryDark: '#42A5F5',
    secondary: '#FFD54F',
    secondaryLight: '#FFE082',
    secondaryDark: '#FFCA28',
    background: '#121212',
    surface: '#1E1E1E',
    text: '#FFFFFF',
    textSecondary: '#B0B0B0',
    error: '#EF5350',
    warning: '#FFA726',
    success: '#66BB6A',
    info: '#42A5F5',
    divider: '#333333',
    placeholder: '#757575',
    disabled: '#616161'
  };

  // 深色主题阴影
  public static readonly DarkShadows: ShadowLevels = {
    level1: '4px 4px 8px rgba(0, 0, 0, 0.3)',
    level2: '8px 8px 16px rgba(0, 0, 0, 0.3)',
    level3: '12px 12px 24px rgba(0, 0, 0, 0.3)',
    level4: '16px 16px 32px rgba(0, 0, 0, 0.3)',
    level5: '20px 20px 40px rgba(0, 0, 0, 0.3)'
  };

  /**
   * 根据屏幕宽度获取当前断点
   */
  public static getCurrentBreakpoint(screenWidth: number): keyof BreakpointConfig {
    if (screenWidth >= DesignSystem.Breakpoints.xl) return 'xl';
    if (screenWidth >= DesignSystem.Breakpoints.lg) return 'lg';
    if (screenWidth >= DesignSystem.Breakpoints.md) return 'md';
    if (screenWidth >= DesignSystem.Breakpoints.sm) return 'sm';
    return 'xs';
  }

  /**
   * 获取响应式样式
   */
  public static getResponsiveStyle<T>(
    screenWidth: number,
    styles: Record<keyof BreakpointConfig, T>
  ): T {
    const breakpoint = DesignSystem.getCurrentBreakpoint(screenWidth);
    return styles[breakpoint];
  }
}

// 导出默认实例
export default DesignSystem;