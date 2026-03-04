/**
 * Modern Design System - 现代设计系统
 * 
 * 提供统一的设计规范、颜色、间距、排版和组件样式
 * 支持响应式设计和主题切换
 */

// ========================================
// 主题模式
// ========================================

export type ThemeMode = 'light' | 'dark';

// ========================================
// 颜色系统
// ========================================

export interface ColorPalette {
  // 主色调
  primary: string;
  primaryLight: string;
  primaryDark: string;
  
  // 辅助色
  secondary: string;
  secondaryLight: string;
  secondaryDark: string;
  
  // 功能色
  success: string;
  warning: string;
  error: string;
  info: string;
  
  // 中性色
  background: string;
  surface: string;
  surfaceVariant: string;
  
  // 文本色
  text: string;
  textSecondary: string;
  textDisabled: string;
  
  // 边框色
  divider: string;
  outline: string;
  
  // 特殊色
  onPrimary: string;
  onSecondary: string;
  onSurface: string;
  onError: string;
}

// 浅色主题颜色
const LightThemeColors: ColorPalette = {
  primary: '#3B82F6',
  primaryLight: '#60A5FA',
  primaryDark: '#2563EB',
  
  secondary: '#8B5CF6',
  secondaryLight: '#A78BFA',
  secondaryDark: '#7C3AED',
  
  success: '#10B981',
  warning: '#F59E0B',
  error: '#EF4444',
  info: '#3B82F6',
  
  background: '#F9FAFB',
  surface: '#FFFFFF',
  surfaceVariant: '#F3F4F6',
  
  text: '#1F2937',
  textSecondary: '#6B7280',
  textDisabled: '#9CA3AF',
  
  divider: '#E5E7EB',
  outline: '#D1D5DB',
  
  onPrimary: '#FFFFFF',
  onSecondary: '#FFFFFF',
  onSurface: '#1F2937',
  onError: '#FFFFFF'
};

// 深色主题颜色
const DarkThemeColors: ColorPalette = {
  primary: '#3B82F6',
  primaryLight: '#60A5FA',
  primaryDark: '#2563EB',
  
  secondary: '#8B5CF6',
  secondaryLight: '#A78BFA',
  secondaryDark: '#7C3AED',
  
  success: '#10B981',
  warning: '#F59E0B',
  error: '#EF4444',
  info: '#3B82F6',
  
  background: '#111827',
  surface: '#1F2937',
  surfaceVariant: '#374151',
  
  text: '#F9FAFB',
  textSecondary: '#D1D5DB',
  textDisabled: '#6B7280',
  
  divider: '#374151',
  outline: '#4B5563',
  
  onPrimary: '#111827',
  onSecondary: '#111827',
  onSurface: '#F9FAFB',
  onError: '#111827'
};

// ========================================
// 间距系统
// ========================================

export interface SpacingScale {
  xs: number;   // 4px
  sm: number;   // 8px
  md: number;   // 16px
  lg: number;   // 24px
  xl: number;   // 32px
  '2xl': number; // 48px
  '3xl': number; // 64px
  '4xl': number; // 80px
}

export const Spacing: SpacingScale = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  '2xl': 48,
  '3xl': 64,
  '4xl': 80
};

// ========================================
// 边框半径系统
// ========================================

export interface BorderRadiusScale {
  sm: number;   // 4px
  md: number;   // 8px
  lg: number;   // 12px
  xl: number;   // 16px
  '2xl': number; // 24px
  full: number; // 9999px
}

export const BorderRadius: BorderRadiusScale = {
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  '2xl': 24,
  full: 9999
};

// ========================================
// 排版系统
// ========================================

export interface FontSpec {
  size: number;
  lineHeight: number;
  fontWeight: number;
}

export interface TypographyScale {
  h1: FontSpec; // 大标题
  h2: FontSpec; // 标题
  h3: FontSpec; // 小标题
  h4: FontSpec; // 副标题
  body: FontSpec; // 正文
  caption: FontSpec; // 说明文字
  button: FontSpec; // 按钮文字
}

export const Typography: TypographyScale = {
  h1: { size: 36, lineHeight: 44, fontWeight: 700 },
  h2: { size: 30, lineHeight: 36, fontWeight: 600 },
  h3: { size: 24, lineHeight: 32, fontWeight: 600 },
  h4: { size: 20, lineHeight: 28, fontWeight: 500 },
  body: { size: 16, lineHeight: 24, fontWeight: 400 },
  caption: { size: 14, lineHeight: 20, fontWeight: 400 },
  button: { size: 16, lineHeight: 24, fontWeight: 500 }
};

// ========================================
// 响应式断点
// ========================================

export interface BreakpointConfig {
  xs: number; // 手机竖屏
  sm: number; // 手机横屏
  md: number; // 平板
  lg: number; // 笔记本
  xl: number; // 桌面
  '2xl': number; // 大屏幕
}

export const Breakpoints: BreakpointConfig = {
  xs: 0,
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  '2xl': 1536
};

// ========================================
// 阴影系统
// ========================================

export interface ShadowSpec {
  shadowColor: string;
  shadowOffsetX: number;
  shadowOffsetY: number;
  shadowRadius: number;
  shadowOpacity: number;
}

export interface ShadowLevels {
  sm: ShadowSpec;  // 小阴影
  md: ShadowSpec;  // 中等阴影
  lg: ShadowSpec;  // 大阴影
  xl: ShadowSpec;  // 超大阴影
}

// 浅色主题阴影
const LightShadows: ShadowLevels = {
  sm: { shadowColor: '#000000', shadowOffsetX: 0, shadowOffsetY: 1, shadowRadius: 2, shadowOpacity: 0.05 },
  md: { shadowColor: '#000000', shadowOffsetX: 0, shadowOffsetY: 2, shadowRadius: 4, shadowOpacity: 0.1 },
  lg: { shadowColor: '#000000', shadowOffsetX: 0, shadowOffsetY: 4, shadowRadius: 8, shadowOpacity: 0.15 },
  xl: { shadowColor: '#000000', shadowOffsetX: 0, shadowOffsetY: 8, shadowRadius: 16, shadowOpacity: 0.2 }
};

// 深色主题阴影
const DarkShadows: ShadowLevels = {
  sm: { shadowColor: '#000000', shadowOffsetX: 0, shadowOffsetY: 1, shadowRadius: 2, shadowOpacity: 0.15 },
  md: { shadowColor: '#000000', shadowOffsetX: 0, shadowOffsetY: 2, shadowRadius: 4, shadowOpacity: 0.2 },
  lg: { shadowColor: '#000000', shadowOffsetX: 0, shadowOffsetY: 4, shadowRadius: 8, shadowOpacity: 0.25 },
  xl: { shadowColor: '#000000', shadowOffsetX: 0, shadowOffsetY: 8, shadowRadius: 16, shadowOpacity: 0.3 }
};

// ========================================
// 动画系统
// ========================================

export interface AnimationConfig {
  duration: number;
  delay: number;
  timingFunction: string;
  iterations: number;
}

export const Animations: Record<string, AnimationConfig> = {
  fast: { duration: 200, delay: 0, timingFunction: 'ease-out', iterations: 1 },
  normal: { duration: 300, delay: 0, timingFunction: 'ease-out', iterations: 1 },
  slow: { duration: 500, delay: 0, timingFunction: 'ease-out', iterations: 1 },
  bounce: { duration: 300, delay: 0, timingFunction: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)', iterations: 1 },
  fadeIn: { duration: 300, delay: 0, timingFunction: 'ease-out', iterations: 1 },
  slideIn: { duration: 300, delay: 0, timingFunction: 'ease-out', iterations: 1 }
};

// ========================================
// 主题接口
// ========================================

export interface Theme {
  mode: ThemeMode;
  colors: ColorPalette;
  shadows: ShadowLevels;
}

// ========================================
// 设计系统类
// ========================================

class ModernDesignSystem {
  // 静态属性
  public static readonly Spacing = Spacing;
  public static readonly BorderRadius = BorderRadius;
  public static readonly Typography = Typography;
  public static readonly Breakpoints = Breakpoints;
  public static readonly Animations = Animations;
  public static readonly LightTheme: Theme = {
    mode: 'light',
    colors: LightThemeColors,
    shadows: LightShadows
  };
  public static readonly DarkTheme: Theme = {
    mode: 'dark',
    colors: DarkThemeColors,
    shadows: DarkShadows
  };
  
  // 获取当前主题
  public static getCurrentTheme(): Theme {
    // 这里可以根据系统设置或用户偏好返回相应主题
    return ModernDesignSystem.LightTheme;
  }
  
  // 切换主题
  public static switchTheme(mode: ThemeMode): Theme {
    return mode === 'light' ? ModernDesignSystem.LightTheme : ModernDesignSystem.DarkTheme;
  }
  
  // 获取响应式布局配置
  public static getResponsiveConfig(screenWidth: number): {
    containerWidth: string;
    gridColumns: number;
    itemWidth: string;
  } {
    if (screenWidth >= Breakpoints.xl) {
      return { containerWidth: '1200px', gridColumns: 5, itemWidth: '220px' };
    } else if (screenWidth >= Breakpoints.lg) {
      return { containerWidth: '960px', gridColumns: 4, itemWidth: '220px' };
    } else if (screenWidth >= Breakpoints.md) {
      return { containerWidth: '720px', gridColumns: 3, itemWidth: '220px' };
    } else if (screenWidth >= Breakpoints.sm) {
      return { containerWidth: '100%', gridColumns: 2, itemWidth: '160px' };
    } else {
      return { containerWidth: '100%', gridColumns: 1, itemWidth: '100%' };
    }
  }
}

export default ModernDesignSystem;