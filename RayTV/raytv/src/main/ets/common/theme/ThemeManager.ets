/**
 * ThemeManager.ets
 * 主题管理系统 - 实现暗黑模式、自定义主题和动态主题切换
 */

import { Component, State, Prop, Builder, AboutToAppear } from '@ohos/arkui'
import Logger from '../util/Logger'
import { StorageUtil, StorageType } from '../util/StorageUtil'

// ==================== 类型定义 ====================\n\nexport type ThemeMode = 'light' | 'dark' | 'auto' | 'highContrast'
export type ColorScheme = 'red' | 'blue' | 'green' | 'purple' | 'orange' | 'pink'

export interface ThemeColors {
  // 主要色彩
  primary: string
  primaryLight: string
  primaryDark: string
  onPrimary: string
  
  // 次要色彩
  secondary: string
  secondaryLight: string
  secondaryDark: string
  onSecondary: string
  
  // 背景色彩
  background: string
  surface: string
  surfaceVariant: string
  onBackground: string
  onSurface: string
  onSurfaceVariant: string
  
  // 状态色彩
  success: string
  warning: string
  error: string
  info: string
  onSuccess: string
  onWarning: string
  onError: string
  onInfo: string
  
  // 中性色彩
  outline: string
  outlineVariant: string
  scrim: string
  shadow: string
}

export interface ThemeTypography {
  fontFamily: string
  headlineLarge: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  headlineMedium: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  headlineSmall: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  titleLarge: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  titleMedium: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  titleSmall: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  bodyLarge: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  bodyMedium: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  bodySmall: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  labelLarge: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  labelMedium: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
  labelSmall: { fontSize: number; fontWeight: number; lineHeight: number; rem?: number }
}

export interface ThemeSpacing {
  xs: number
  sm: number
  md: number
  lg: number
  xl: number
  xxl: number
}

export interface ThemeConfig {
  mode: ThemeMode
  colorScheme: ColorScheme
  colors: ThemeColors
  typography: ThemeTypography
  spacing: ThemeSpacing
  borderRadius: number
  elevation: number
}

export interface ThemeChangeListener {
  (theme: ThemeConfig): void
}

// ==================== 主题配置 ====================

const LIGHT_THEME_COLORS: ThemeColors = {
  primary: '#007AFF',
  primaryLight: '#4DA6FF',
  primaryDark: '#0056B3',
  onPrimary: '#FFFFFF',
  
  secondary: '#8E8E93',
  secondaryLight: '#AEAEB2',
  secondaryDark: '#636366',
  onSecondary: '#FFFFFF',
  
  background: '#FFFFFF',
  surface: '#F2F2F7',
  surfaceVariant: '#E5E5EA',
  onBackground: '#000000',
  onSurface: '#3C3C43',
  onSurfaceVariant: '#8E8E93',
  
  success: '#34C759',
  warning: '#FF9500',
  error: '#FF3B30',
  info: '#5AC8FA',
  onSuccess: '#FFFFFF',
  onWarning: '#FFFFFF',
  onError: '#FFFFFF',
  onInfo: '#FFFFFF',
  
  outline: '#D1D1D6',
  outlineVariant: '#C7C7CC',
  scrim: '#000000',
  shadow: '#000000'
}

const DARK_THEME_COLORS: ThemeColors = {
  primary: '#0A84FF',
  primaryLight: '#409CFF',
  primaryDark: '#0066CC',
  onPrimary: '#FFFFFF',
  
  secondary: '#8E8E93',
  secondaryLight: '#AEAEB2',
  secondaryDark: '#636366',
  onSecondary: '#FFFFFF',
  
  background: '#000000',
  surface: '#1C1C1E',
  surfaceVariant: '#2C2C2E',
  onBackground: '#FFFFFF',
  onSurface: '#F2F2F7',
  onSurfaceVariant: '#AEAEB2',
  
  success: '#30D158',
  warning: '#FF9F0A',
  error: '#FF453A',
  info: '#64D2FF',
  onSuccess: '#000000',
  onWarning: '#000000',
  onError: '#FFFFFF',
  onInfo: '#000000',
  
  outline: '#48484A',
  outlineVariant: '#424245',
  scrim: '#000000',
  shadow: '#000000'
}

const HIGH_CONTRAST_LIGHT_THEME_COLORS: ThemeColors = {
  primary: '#0000FF',
  primaryLight: '#3333FF',
  primaryDark: '#0000CC',
  onPrimary: '#FFFFFF',
  
  secondary: '#006400',
  secondaryLight: '#338733',
  secondaryDark: '#004B00',
  onSecondary: '#FFFFFF',
  
  background: '#FFFFFF',
  surface: '#FFFFFF',
  surfaceVariant: '#E5E5E5',
  onBackground: '#000000',
  onSurface: '#000000',
  onSurfaceVariant: '#000000',
  
  success: '#008000',
  warning: '#FF8C00',
  error: '#FF0000',
  info: '#0000FF',
  onSuccess: '#FFFFFF',
  onWarning: '#000000',
  onError: '#FFFFFF',
  onInfo: '#FFFFFF',
  
  outline: '#000000',
  outlineVariant: '#333333',
  scrim: '#000000',
  shadow: '#000000'
}

const HIGH_CONTRAST_DARK_THEME_COLORS: ThemeColors = {
  primary: '#00FFFF',
  primaryLight: '#33FFFF',
  primaryDark: '#00CCCC',
  onPrimary: '#000000',
  
  secondary: '#FFFF00',
  secondaryLight: '#FFFF33',
  secondaryDark: '#CCCC00',
  onSecondary: '#000000',
  
  background: '#000000',
  surface: '#000000',
  surfaceVariant: '#1A1A1A',
  onBackground: '#FFFFFF',
  onSurface: '#FFFFFF',
  onSurfaceVariant: '#FFFFFF',
  
  success: '#00FF00',
  warning: '#FF8C00',
  error: '#FF0000',
  info: '#00FFFF',
  onSuccess: '#000000',
  onWarning: '#000000',
  onError: '#000000',
  onInfo: '#000000',
  
  outline: '#FFFFFF',
  outlineVariant: '#CCCCCC',
  scrim: '#000000',
  shadow: '#000000'
}

// 基准字体大小（px）| Base font size (px)
const BASE_FONT_SIZE = 16;

// 响应式字体大小配置 | Responsive font size configuration
const THEME_TYPOGRAPHY: ThemeTypography = {
  fontFamily: 'HarmonyOS Sans SC',
  headlineLarge: { fontSize: 32, fontWeight: 700, lineHeight: 40, rem: 2.0 }, // 32px = 2.0rem
  headlineMedium: { fontSize: 28, fontWeight: 700, lineHeight: 36, rem: 1.75 }, // 28px = 1.75rem
  headlineSmall: { fontSize: 24, fontWeight: 700, lineHeight: 32, rem: 1.5 }, // 24px = 1.5rem
  titleLarge: { fontSize: 22, fontWeight: 600, lineHeight: 28, rem: 1.375 }, // 22px = 1.375rem
  titleMedium: { fontSize: 16, fontWeight: 600, lineHeight: 24, rem: 1.0 }, // 16px = 1.0rem
  titleSmall: { fontSize: 14, fontWeight: 600, lineHeight: 20, rem: 0.875 }, // 14px = 0.875rem
  bodyLarge: { fontSize: 16, fontWeight: 400, lineHeight: 24, rem: 1.0 }, // 16px = 1.0rem
  bodyMedium: { fontSize: 14, fontWeight: 400, lineHeight: 20, rem: 0.875 }, // 14px = 0.875rem
  bodySmall: { fontSize: 12, fontWeight: 400, lineHeight: 16, rem: 0.75 }, // 12px = 0.75rem
  labelLarge: { fontSize: 14, fontWeight: 500, lineHeight: 20, rem: 0.875 }, // 14px = 0.875rem
  labelMedium: { fontSize: 12, fontWeight: 500, lineHeight: 16, rem: 0.75 }, // 12px = 0.75rem
  labelSmall: { fontSize: 11, fontWeight: 500, lineHeight: 12, rem: 0.6875 } // 11px = 0.6875rem
}

const THEME_SPACING: ThemeSpacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48
}

// ==================== 主题管理器 ====================

export class ThemeManager {
  private static instance: ThemeManager
  private logger: Logger
  private storage: StorageUtil
  private currentTheme: ThemeConfig
  private listeners: ThemeChangeListener[] = []
  private systemThemeListener: ((matches: boolean) => void) | null = null
  
  private constructor() {
    this.logger = new Logger('ThemeManager')
    this.storage = StorageUtil.getInstance()
    this.currentTheme = this.getDefaultTheme()
    this.loadSavedTheme()
    this.setupSystemThemeListener()
  }
  
  public static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager()
    }
    return ThemeManager.instance
  }
  
  /**
   * 获取默认主题配置
   */
  private getDefaultTheme(): ThemeConfig {
    return {
      mode: 'dark',
      colorScheme: 'blue',
      colors: DARK_THEME_COLORS,
      typography: THEME_TYPOGRAPHY,
      spacing: THEME_SPACING,
      borderRadius: 8,
      elevation: 2
    }
  }
  
  /**
   * 加载保存的主题
   */
  private async loadSavedTheme(): Promise<void> {
    try {
      const savedTheme = await this.storage.getObject<ThemeConfig>('theme_config', StorageType.DEFAULT)
      if (savedTheme) {
        this.currentTheme = savedTheme
        this.applyTheme()
        this.logger.info('Loaded saved theme configuration')
      }
    } catch (error) {
      this.logger.error('Failed to load saved theme:', error)
    }
  }
  
  /**
   * 设置系统主题监听器
   */
  private setupSystemThemeListener(): void {
    try {
      // 模拟系统主题检测
      const systemPrefersDark = this.detectSystemTheme()
      if (this.currentTheme.mode === 'auto') {
        this.applySystemTheme(systemPrefersDark)
      }
      
      // 模拟系统主题变化监听
      this.systemThemeListener = (prefersDark: boolean) => {
        if (this.currentTheme.mode === 'auto') {
          this.applySystemTheme(prefersDark)
        }
      }
      
      this.logger.info('System theme listener setup completed')
    } catch (error) {
      this.logger.error('Failed to setup system theme listener:', error)
    }
  }
  
  /**
   * 检测系统主题偏好
   */
  private detectSystemTheme(): boolean {
    try {
      // 尝试使用HarmonyOS系统API检测主题
      const display = require('@ohos.display');
      const displayInfo = display.getDefaultDisplaySync();
      // 这里需要根据HarmonyOS的实际API来获取系统主题偏好
      // 由于API可能有差异，这里使用合理的默认值
      return false; // 默认返回亮色主题
    } catch (error) {
      this.logger.warn('Failed to detect system theme, using default', error);
      return false; // 默认返回亮色主题
    }
  }
  
  /**
   * 应用系统主题
   */
  private applySystemTheme(prefersDark: boolean): void {
    const newColors = prefersDark ? DARK_THEME_COLORS : LIGHT_THEME_COLORS
    this.currentTheme.colors = newColors
    this.notifyListeners()
    this.logger.info(`Applied system theme: ${prefersDark ? 'dark' : 'light'}`)
  }
  
  /**
   * 切换主题模式
   */
  public async switchThemeMode(mode: ThemeMode): Promise<void> {
    this.currentTheme.mode = mode
    
    if (mode === 'auto') {
      const systemPrefersDark = this.detectSystemTheme()
      this.applySystemTheme(systemPrefersDark)
    } else if (mode === 'highContrast') {
      // 高对比度模式默认使用暗色主题
      this.currentTheme.colors = HIGH_CONTRAST_DARK_THEME_COLORS
    } else {
      const isDark = mode === 'dark'
      this.currentTheme.colors = isDark ? DARK_THEME_COLORS : LIGHT_THEME_COLORS
    }
    
    await this.saveTheme()
    this.notifyListeners()
    this.logger.info(`Theme mode switched to: ${mode}`)
  }
  
  /**
   * 切换颜色方案
   */
  public async switchColorScheme(colorScheme: ColorScheme): Promise<void> {
    this.currentTheme.colorScheme = colorScheme
    this.updatePrimaryColors(colorScheme)
    await this.saveTheme()
    this.notifyListeners()
    this.logger.info(`Color scheme switched to: ${colorScheme}`)
  }
  
  /**
   * 更新主色调
   */
  private updatePrimaryColors(colorScheme: ColorScheme): void {
    const colorMap: Record<ColorScheme, { light: string; main: string; dark: string }> = {
      red: { light: '#FF6B6B', main: '#FF4757', dark: '#FF2E40' },
      blue: { light: '#4DA6FF', main: '#007AFF', dark: '#0056B3' },
      green: { light: '#2ECC71', main: '#27AE60', dark: '#219653' },
      purple: { light: '#BB8FCE', main: '#9B59B6', dark: '#8E44AD' },
      orange: { light: '#FFA502', main: '#FF9500', dark: '#FF7000' },
      pink: { light: '#FF79A9', main: '#FF6B9D', dark: '#FF5C90' }
    }
    
    const colors = colorMap[colorScheme]
    this.currentTheme.colors.primaryLight = colors.light
    this.currentTheme.colors.primary = colors.main
    this.currentTheme.colors.primaryDark = colors.dark
  }
  
  /**
   * 获取当前主题
   */
  public getCurrentTheme(): ThemeConfig {
    return { ...this.currentTheme }
  }
  
  /**
   * 获取主题颜色
   */
  public getColors(): ThemeColors {
    return { ...this.currentTheme.colors }
  }
  
  /**
   * 获取主题排版
   */
  public getTypography(): ThemeTypography {
    return { ...this.currentTheme.typography }
  }
  
  /**
   * 获取主题间距
   */
  public getSpacing(): ThemeSpacing {
    return { ...this.currentTheme.spacing }
  }
  
  /**
   * 添加主题变化监听器
   */
  public addThemeListener(listener: ThemeChangeListener): void {
    this.listeners.push(listener)
  }
  
  /**
   * 移除主题变化监听器
   */
  public removeThemeListener(listener: ThemeChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }
  
  /**
   * 通知监听器
   */
  private notifyListeners(): void {
    const themeCopy = this.getCurrentTheme()
    this.listeners.forEach(listener => {
      try {
        listener(themeCopy)
      } catch (error) {
        this.logger.error('Error in theme listener:', error)
      }
    })
  }
  
  /**
   * 保存主题配置
   */
  private async saveTheme(): Promise<void> {
    try {
      await this.storage.setObject('theme_config', this.currentTheme, StorageType.DEFAULT)
      this.logger.info('Theme configuration saved')
    } catch (error) {
      this.logger.error('Failed to save theme:', error)
    }
  }
  
  /**
   * 应用主题到系统
   */
  private applyTheme(): void {
    // 这里可以应用主题到系统级别
    // 例如设置状态栏颜色、导航栏颜色等
    this.logger.info('Theme applied to system')
  }
  
  /**
   * 获取基准字体大小
   * @returns 基准字体大小（px）
   */
  public getBaseFontSize(): number {
    return BASE_FONT_SIZE;
  }
  
  /**
   * 根据rem值计算字体大小
   * @param rem rem值
   * @returns 计算后的字体大小（px）
   */
  public calculateFontSize(rem: number): number {
    return BASE_FONT_SIZE * rem;
  }
  
  /**
   * 根据设备尺寸获取响应式基准字体大小
   * @param deviceWidth 设备宽度（px）
   * @returns 响应式基准字体大小（px）
   */
  public getResponsiveBaseFontSize(deviceWidth: number): number {
    // 根据设备宽度调整基准字体大小
    // 小屏幕设备使用稍小的基准字体大小，大屏幕设备使用稍大的基准字体大小
    if (deviceWidth < 768) {
      return BASE_FONT_SIZE * 0.8; // 小屏幕：12.8px
    } else if (deviceWidth < 1024) {
      return BASE_FONT_SIZE; // 中屏幕：16px
    } else if (deviceWidth < 1440) {
      return BASE_FONT_SIZE * 1.1; // 大屏幕：17.6px
    } else {
      return BASE_FONT_SIZE * 1.2; // 超大屏幕：19.2px
    }
  }
  
  /**
   * 获取响应式字体配置
   * @param deviceWidth 设备宽度（px）
   * @returns 响应式字体配置
   */
  public getResponsiveTypography(deviceWidth: number): ThemeTypography {
    const responsiveBaseSize = this.getResponsiveBaseFontSize(deviceWidth);
    const scale = responsiveBaseSize / BASE_FONT_SIZE;
    
    // 创建响应式字体配置
    const responsiveTypography: ThemeTypography = {
      fontFamily: this.currentTheme.typography.fontFamily,
      headlineLarge: {
        fontSize: this.currentTheme.typography.headlineLarge.fontSize * scale,
        fontWeight: this.currentTheme.typography.headlineLarge.fontWeight,
        lineHeight: this.currentTheme.typography.headlineLarge.lineHeight * scale,
        rem: this.currentTheme.typography.headlineLarge.rem
      },
      headlineMedium: {
        fontSize: this.currentTheme.typography.headlineMedium.fontSize * scale,
        fontWeight: this.currentTheme.typography.headlineMedium.fontWeight,
        lineHeight: this.currentTheme.typography.headlineMedium.lineHeight * scale,
        rem: this.currentTheme.typography.headlineMedium.rem
      },
      headlineSmall: {
        fontSize: this.currentTheme.typography.headlineSmall.fontSize * scale,
        fontWeight: this.currentTheme.typography.headlineSmall.fontWeight,
        lineHeight: this.currentTheme.typography.headlineSmall.lineHeight * scale,
        rem: this.currentTheme.typography.headlineSmall.rem
      },
      titleLarge: {
        fontSize: this.currentTheme.typography.titleLarge.fontSize * scale,
        fontWeight: this.currentTheme.typography.titleLarge.fontWeight,
        lineHeight: this.currentTheme.typography.titleLarge.lineHeight * scale,
        rem: this.currentTheme.typography.titleLarge.rem
      },
      titleMedium: {
        fontSize: this.currentTheme.typography.titleMedium.fontSize * scale,
        fontWeight: this.currentTheme.typography.titleMedium.fontWeight,
        lineHeight: this.currentTheme.typography.titleMedium.lineHeight * scale,
        rem: this.currentTheme.typography.titleMedium.rem
      },
      titleSmall: {
        fontSize: this.currentTheme.typography.titleSmall.fontSize * scale,
        fontWeight: this.currentTheme.typography.titleSmall.fontWeight,
        lineHeight: this.currentTheme.typography.titleSmall.lineHeight * scale,
        rem: this.currentTheme.typography.titleSmall.rem
      },
      bodyLarge: {
        fontSize: this.currentTheme.typography.bodyLarge.fontSize * scale,
        fontWeight: this.currentTheme.typography.bodyLarge.fontWeight,
        lineHeight: this.currentTheme.typography.bodyLarge.lineHeight * scale,
        rem: this.currentTheme.typography.bodyLarge.rem
      },
      bodyMedium: {
        fontSize: this.currentTheme.typography.bodyMedium.fontSize * scale,
        fontWeight: this.currentTheme.typography.bodyMedium.fontWeight,
        lineHeight: this.currentTheme.typography.bodyMedium.lineHeight * scale,
        rem: this.currentTheme.typography.bodyMedium.rem
      },
      bodySmall: {
        fontSize: this.currentTheme.typography.bodySmall.fontSize * scale,
        fontWeight: this.currentTheme.typography.bodySmall.fontWeight,
        lineHeight: this.currentTheme.typography.bodySmall.lineHeight * scale,
        rem: this.currentTheme.typography.bodySmall.rem
      },
      labelLarge: {
        fontSize: this.currentTheme.typography.labelLarge.fontSize * scale,
        fontWeight: this.currentTheme.typography.labelLarge.fontWeight,
        lineHeight: this.currentTheme.typography.labelLarge.lineHeight * scale,
        rem: this.currentTheme.typography.labelLarge.rem
      },
      labelMedium: {
        fontSize: this.currentTheme.typography.labelMedium.fontSize * scale,
        fontWeight: this.currentTheme.typography.labelMedium.fontWeight,
        lineHeight: this.currentTheme.typography.labelMedium.lineHeight * scale,
        rem: this.currentTheme.typography.labelMedium.rem
      },
      labelSmall: {
        fontSize: this.currentTheme.typography.labelSmall.fontSize * scale,
        fontWeight: this.currentTheme.typography.labelSmall.fontWeight,
        lineHeight: this.currentTheme.typography.labelSmall.lineHeight * scale,
        rem: this.currentTheme.typography.labelSmall.rem
      }
    };
    
    return responsiveTypography;
  }
  
  /**
   * 获取响应式字体大小
   * @param variant 字体变体
   * @param deviceWidth 设备宽度（px）
   * @returns 响应式字体大小（px）
   */
  public getResponsiveFontSize(variant: keyof Omit<ThemeTypography, 'fontFamily'>, deviceWidth: number): number {
    const responsiveTypography = this.getResponsiveTypography(deviceWidth);
    return responsiveTypography[variant].fontSize;
  }
  
  /**
   * 销毁主题管理器
   */
  public destroy(): void {
    this.listeners = []
    this.systemThemeListener = null
    this.logger.info('ThemeManager destroyed')
  }
  
  /**
   * 检查色彩对比度是否符合WCAG标准
   * @param backgroundColor 背景色
   * @param textColor 文本色
   * @returns 对比度值和是否符合AA级和AAA级标准
   */
  public checkContrast(backgroundColor: string, textColor: string): {
    ratio: number;
    meetsAA: boolean;
    meetsAAA: boolean;
  } {
    const bgLuminance = this.getLuminance(backgroundColor);
    const textLuminance = this.getLuminance(textColor);
    const ratio = this.calculateContrastRatio(bgLuminance, textLuminance);
    
    return {
      ratio: Math.round(ratio * 100) / 100,
      meetsAA: ratio >= 4.5, // AA级标准：普通文本4.5:1，大文本3:1
      meetsAAA: ratio >= 7.0 // AAA级标准：普通文本7:1，大文本4.5:1
    };
  }
  
  /**
   * 获取颜色的相对亮度
   * @param color 颜色值（十六进制）
   * @returns 相对亮度值（0-1）
   */
  private getLuminance(color: string): number {
    // 移除#号
    const hex = color.replace('#', '');
    // 解析RGB值
    const r = parseInt(hex.length === 3 ? hex[0] + hex[0] : hex.substring(0, 2), 16) / 255;
    const g = parseInt(hex.length === 3 ? hex[1] + hex[1] : hex.substring(2, 4), 16) / 255;
    const b = parseInt(hex.length === 3 ? hex[2] + hex[2] : hex.substring(4, 6), 16) / 255;
    
    // 应用伽马校正
    const gammaCorrect = (value: number): number => {
      return value <= 0.03928 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
    };
    
    const rLinear = gammaCorrect(r);
    const gLinear = gammaCorrect(g);
    const bLinear = gammaCorrect(b);
    
    // 计算相对亮度
    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }
  
  /**
   * 计算对比度比率
   * @param luminance1 第一个颜色的相对亮度
   * @param luminance2 第二个颜色的相对亮度
   * @returns 对比度比率
   */
  private calculateContrastRatio(luminance1: number, luminance2: number): number {
    const lighter = Math.max(luminance1, luminance2);
    const darker = Math.min(luminance1, luminance2);
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /**
   * 验证当前主题的对比度是否符合WCAG标准
   * @returns 验证结果
   */
  public validateThemeContrast(): {
    isValid: boolean;
    issues: Array<{
      element: string;
      backgroundColor: string;
      textColor: string;
      contrastRatio: number;
      meetsAA: boolean;
      meetsAAA: boolean;
    }>;
  } {
    const colors = this.currentTheme.colors;
    const issues = [];
    
    // 检查主要文本对比度
    const backgroundCheck = this.checkContrast(colors.background, colors.onBackground);
    if (!backgroundCheck.meetsAA) {
      issues.push({
        element: 'Background text',
        backgroundColor: colors.background,
        textColor: colors.onBackground,
        contrastRatio: backgroundCheck.ratio,
        meetsAA: backgroundCheck.meetsAA,
        meetsAAA: backgroundCheck.meetsAAA
      });
    }
    
    // 检查表面文本对比度
    const surfaceCheck = this.checkContrast(colors.surface, colors.onSurface);
    if (!surfaceCheck.meetsAA) {
      issues.push({
        element: 'Surface text',
        backgroundColor: colors.surface,
        textColor: colors.onSurface,
        contrastRatio: surfaceCheck.ratio,
        meetsAA: surfaceCheck.meetsAA,
        meetsAAA: surfaceCheck.meetsAAA
      });
    }
    
    // 检查表面变体文本对比度
    const surfaceVariantCheck = this.checkContrast(colors.surfaceVariant, colors.onSurfaceVariant);
    if (!surfaceVariantCheck.meetsAA) {
      issues.push({
        element: 'Surface variant text',
        backgroundColor: colors.surfaceVariant,
        textColor: colors.onSurfaceVariant,
        contrastRatio: surfaceVariantCheck.ratio,
        meetsAA: surfaceVariantCheck.meetsAA,
        meetsAAA: surfaceVariantCheck.meetsAAA
      });
    }
    
    // 检查主要按钮对比度
    const primaryCheck = this.checkContrast(colors.primary, colors.onPrimary);
    if (!primaryCheck.meetsAA) {
      issues.push({
        element: 'Primary button text',
        backgroundColor: colors.primary,
        textColor: colors.onPrimary,
        contrastRatio: primaryCheck.ratio,
        meetsAA: primaryCheck.meetsAA,
        meetsAAA: primaryCheck.meetsAAA
      });
    }
    
    // 检查次要按钮对比度
    const secondaryCheck = this.checkContrast(colors.secondary, colors.onSecondary);
    if (!secondaryCheck.meetsAA) {
      issues.push({
        element: 'Secondary button text',
        backgroundColor: colors.secondary,
        textColor: colors.onSecondary,
        contrastRatio: secondaryCheck.ratio,
        meetsAA: secondaryCheck.meetsAA,
        meetsAAA: secondaryCheck.meetsAAA
      });
    }
    
    return {
      isValid: issues.length === 0,
      issues
    };
  }
}

// ==================== 主题提供者组件 ====================

@Component
export struct ThemeProvider {
  @Prop children: any[]
  @State currentTheme: ThemeConfig = ThemeManager.getInstance().getCurrentTheme()
  private themeManager: ThemeManager = ThemeManager.getInstance()
  
  @AboutToAppear
  aboutToAppear(): void {
    this.themeManager.addThemeListener(this.handleThemeChange)
  }
  
  private handleThemeChange = (theme: ThemeConfig): void => {
    this.currentTheme = theme
  }
  
  build() {
    Column() {
      // 渲染子组件
      if (this.children && this.children.length > 0) {
        ForEach(this.children, (child: any) => {
          child
        })
      }
    }
    .backgroundColor(this.currentTheme.colors.background)
    .fontFamily(this.currentTheme.typography.fontFamily)
  }
}

// ==================== 主题消费者Hook ====================

export function useTheme(): ThemeConfig {
  const themeManager = ThemeManager.getInstance()
  return themeManager.getCurrentTheme()
}

export function useColors(): ThemeColors {
  const themeManager = ThemeManager.getInstance()
  return themeManager.getColors()
}

export function useTypography(): ThemeTypography {
  const themeManager = ThemeManager.getInstance()
  return themeManager.getTypography()
}

export function useSpacing(): ThemeSpacing {
  const themeManager = ThemeManager.getInstance()
  return themeManager.getSpacing()
}

// ==================== 便捷工厂方法 ====================

export const createThemeProvider = (children: any[]): ThemeProvider => {
  return new ThemeProvider({ children })
}

// ==================== 导出类型 ====================

export type { 
  ThemeMode, 
  ColorScheme, 
  ThemeColors, 
  ThemeTypography, 
  ThemeSpacing, 
  ThemeConfig, 
  ThemeChangeListener 
}

// ==================== 导出实例 ====================

export const themeManager = ThemeManager.getInstance()