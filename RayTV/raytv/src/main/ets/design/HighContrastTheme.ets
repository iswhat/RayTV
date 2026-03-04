/**
 * HighContrastTheme - 高对比度主题
 * 
 * 为视力障碍用户提供高对比度的主题配置
 */

import { ThemeColors, ThemeShadows, ThemeSpaces, ThemeFonts, ThemeBorderRadius, ThemeEffects } from './DesignSystem';

/**
 * 高对比度主题颜色
 */
export const highContrastColors: ThemeColors = {
  // 背景颜色
  background: {
    primary: '#000000', // 纯黑背景
    secondary: '#1A1A1A',
    tertiary: '#2A2A2A',
    surface: '#333333'
  },
  
  // 文本颜色
  text: {
    primary: '#FFFFFF', // 纯白文本
    secondary: '#E0E0E0',
    tertiary: '#B0B0B0',
    disabled: '#808080'
  },
  
  // 主要颜色
  primary: {
    50: '#E6F7FF',
    100: '#B3E5FC',
    200: '#80D4FA',
    300: '#4DC3F7',
    400: '#26B4F5',
    500: '#1890FF', // 主要蓝色
    600: '#177DDC',
    700: '#1565B3',
    800: '#134E8A',
    900: '#0D2F55'
  },
  
  // 次要颜色
  secondary: {
    50: '#FFF7E6',
    100: '#FFE5B3',
    200: '#FFD280',
    300: '#FFBF4D',
    400: '#FFAB26',
    500: '#FA8C16', // 次要橙色
    600: '#E07B14',
    700: '#B36211',
    800: '#8A4A0E',
    900: '#552E09'
  },
  
  // 功能颜色
  error: '#FF4D4F', // 红色错误
  success: '#52C41A', // 绿色成功
  warning: '#FAAD14', // 黄色警告
  info: '#1890FF', // 蓝色信息
  
  // 边框颜色
  border: '#666666',
  divider: '#444444',
  
  // 其他
  overlay: 'rgba(0, 0, 0, 0.8)',
  backdrop: 'rgba(0, 0, 0, 0.6)',
  focus: '#1890FF',
  disabled: '#808080'
};

/**
 * 高对比度主题阴影
 */
export const highContrastShadows: ThemeShadows = {
  sm: '0 1px 2px rgba(255, 255, 255, 0.1)',
  md: '0 4px 6px rgba(255, 255, 255, 0.15)',
  lg: '0 10px 15px rgba(255, 255, 255, 0.2)',
  xl: '0 20px 25px rgba(255, 255, 255, 0.25)',
  xxl: '0 25px 50px rgba(255, 255, 255, 0.3)'
};

/**
 * 高对比度主题间距
 */
export const highContrastSpaces: ThemeSpaces = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48
};

/**
 * 高对比度主题字体
 */
export const highContrastFonts: ThemeFonts = {
  family: {
    primary: 'HarmonyOS Sans',
    secondary: 'HarmonyOS Sans',
    mono: 'Courier New'
  },
  size: {
    xs: '10px',
    sm: '12px',
    md: '14px',
    lg: '16px',
    xl: '18px',
    xxl: '24px',
    xxxl: '32px'
  },
  weight: {
    regular: 400,
    medium: 500,
    semibold: 600,
    bold: 700
  },
  lineHeight: {
    tight: 1.2,
    normal: 1.5,
    loose: 1.8
  }
};

/**
 * 高对比度主题边框半径
 */
export const highContrastBorderRadius: ThemeBorderRadius = {
  sm: '2px',
  md: '4px',
  lg: '8px',
  xl: '12px',
  round: '50%'
};

/**
 * 高对比度主题效果
 */
export const highContrastEffects: ThemeEffects = {
  transition: {
    fast: '0.15s ease',
    normal: '0.3s ease',
    slow: '0.5s ease'
  },
  opacity: {
    disabled: 0.5,
    hover: 0.8,
    active: 0.6
  }
};

/**
 * 高对比度主题
 */
export const highContrastTheme = {
  colors: highContrastColors,
  shadows: highContrastShadows,
  spaces: highContrastSpaces,
  fonts: highContrastFonts,
  borderRadius: highContrastBorderRadius,
  effects: highContrastEffects,
  name: 'high-contrast',
  isHighContrast: true
};

export default highContrastTheme;