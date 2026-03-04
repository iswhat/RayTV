/**
 * 主题提供者 - Theme Provider
 * 
 * 管理应用的主题状态和切换逻辑
 */

import DesignSystem, { ColorPalette, ShadowLevels } from './DesignSystem';
import StorageUtil from '../common/util/StorageUtil';

/**
 * 主题模式
 */
export enum ThemeMode {
  LIGHT = 'light',  // 浅色主题
  DARK = 'dark',    // 深色主题
  AUTO = 'auto'     // 自动模式（根据系统设置）
}

/**
 * 主题配置
 */
export interface ThemeConfig {
  mode: ThemeMode;           // 主题模式
  useSystemAccentColor: boolean; // 是否使用系统强调色
  customAccentColor?: string;    // 自定义强调色
}

/**
 * 主题变更监听器
 */
export type ThemeChangeListener = (theme: Theme) => void;

/**
 * 主题
 */
export interface Theme {
  mode: ThemeMode;           // 主题模式
  colors: ColorPalette;      // 颜色调色板
  shadows: ShadowLevels;     // 阴影级别
  isDark: boolean;           // 是否为深色主题
}

/**
 * 主题存储接口
 */
export interface ThemeStorage {
  saveTheme(config: ThemeConfig): Promise<void>;
  loadTheme(): Promise<ThemeConfig | null>;
  clearTheme(): Promise<void>;
}

/**
 * 本地存储主题存储
 */
export class LocalStorageThemeStorage implements ThemeStorage {
  private readonly STORAGE_KEY = 'raytv_theme_config';

  async saveTheme(config: ThemeConfig): Promise<void> {
    try {
      const configStr = JSON.stringify(config);
      await StorageUtil.setItem(this.STORAGE_KEY, configStr);
    } catch (error) {
      console.error('Failed to save theme config:', error);
    }
  }

  async loadTheme(): Promise<ThemeConfig | null> {
    try {
      const configStr = await StorageUtil.getItem(this.STORAGE_KEY);
      if (configStr) {
        return JSON.parse(configStr) as ThemeConfig;
      }
      return null;
    } catch (error) {
      console.error('Failed to load theme config:', error);
      return null;
    }
  }

  async clearTheme(): Promise<void> {
    try {
      await StorageUtil.deleteItem(this.STORAGE_KEY);
    } catch (error) {
      console.error('Failed to clear theme config:', error);
    }
  }
}

/**
 * 主题提供者
 */
export class ThemeProvider {
  private static instance: ThemeProvider | null = null;
  private listeners: ThemeChangeListener[] = [];
  private config: ThemeConfig;
  private storage: ThemeStorage;
  private currentTheme: Theme;

  /**
   * 获取单例实例
   */
  public static getInstance(): ThemeProvider {
    if (!ThemeProvider.instance) {
      ThemeProvider.instance = new ThemeProvider();
    }
    return ThemeProvider.instance;
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.storage = new LocalStorageThemeStorage();
    this.config = {
      mode: ThemeMode.LIGHT,
      useSystemAccentColor: false
    };
    this.currentTheme = this.generateTheme(this.config);
    this.loadSavedTheme();
  }

  /**
   * 加载保存的主题配置
   */
  private async loadSavedTheme(): Promise<void> {
    try {
      const savedConfig = await this.storage.loadTheme();
      if (savedConfig) {
        this.config = savedConfig;
        this.updateTheme();
      }
    } catch (error) {
      console.error('Failed to load saved theme:', error);
    }
  }

  /**
   * 生成主题
   */
  private generateTheme(config: ThemeConfig): Theme {
    const isDark = config.mode === ThemeMode.DARK || 
      (config.mode === ThemeMode.AUTO && this.isSystemDarkMode());

    const colors = isDark ? DesignSystem.DarkThemeColors : DesignSystem.Colors;
    const shadows = isDark ? DesignSystem.DarkShadows : DesignSystem.Shadows;

    // 如果使用自定义强调色
    if (!config.useSystemAccentColor && config.customAccentColor) {
      colors.primary = config.customAccentColor;
      // 生成对应的浅色和深色变体
      colors.primaryLight = this.lightenColor(config.customAccentColor, 0.2);
      colors.primaryDark = this.darkenColor(config.customAccentColor, 0.2);
    }

    return {
      mode: config.mode,
      colors,
      shadows,
      isDark
    };
  }

  /**
   * 检查系统是否为深色模式
   */
  private isSystemDarkMode(): boolean {
    try {
      // 这里需要使用HarmonyOS的API来获取系统主题模式
      // 暂时返回false，实际实现需要根据HarmonyOS API调整
      return false;
    } catch (error) {
      console.error('Failed to get system theme mode:', error);
      return false;
    }
  }

  /**
   * 提亮颜色
   */
  private lightenColor(color: string, amount: number): string {
    // 简单的颜色提亮实现
    // 实际项目中可能需要更复杂的颜色处理
    return color;
  }

  /**
   * 变暗颜色
   */
  private darkenColor(color: string, amount: number): string {
    // 简单的颜色变暗实现
    // 实际项目中可能需要更复杂的颜色处理
    return color;
  }

  /**
   * 更新主题
   */
  private updateTheme(): void {
    this.currentTheme = this.generateTheme(this.config);
    this.notifyListeners();
  }

  /**
   * 通知监听器
   */
  private notifyListeners(): void {
    this.listeners.forEach(listener => {
      try {
        listener(this.currentTheme);
      } catch (error) {
        console.error('Error in theme change listener:', error);
      }
    });
  }

  /**
   * 获取当前主题
   */
  public getCurrentTheme(): Theme {
    return this.currentTheme;
  }

  /**
   * 获取当前主题配置
   */
  public getCurrentConfig(): ThemeConfig {
    return { ...this.config };
  }

  /**
   * 设置主题模式
   */
  public async setThemeMode(mode: ThemeMode): Promise<void> {
    this.config.mode = mode;
    await this.storage.saveTheme(this.config);
    this.updateTheme();
  }

  /**
   * 设置是否使用系统强调色
   */
  public async setUseSystemAccentColor(useSystem: boolean): Promise<void> {
    this.config.useSystemAccentColor = useSystem;
    await this.storage.saveTheme(this.config);
    this.updateTheme();
  }

  /**
   * 设置自定义强调色
   */
  public async setCustomAccentColor(color: string): Promise<void> {
    this.config.customAccentColor = color;
    this.config.useSystemAccentColor = false;
    await this.storage.saveTheme(this.config);
    this.updateTheme();
  }

  /**
   * 重置主题为默认值
   */
  public async resetTheme(): Promise<void> {
    this.config = {
      mode: ThemeMode.LIGHT,
      useSystemAccentColor: false
    };
    await this.storage.saveTheme(this.config);
    this.updateTheme();
  }

  /**
   * 添加主题变更监听器
   */
  public addThemeChangeListener(listener: ThemeChangeListener): void {
    this.listeners.push(listener);
  }

  /**
   * 移除主题变更监听器
   */
  public removeThemeChangeListener(listener: ThemeChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 浅色主题
   */
  public static readonly LightTheme: Theme = {
    mode: ThemeMode.LIGHT,
    colors: DesignSystem.Colors,
    shadows: DesignSystem.Shadows,
    isDark: false
  };

  /**
   * 深色主题
   */
  public static readonly DarkTheme: Theme = {
    mode: ThemeMode.DARK,
    colors: DesignSystem.DarkThemeColors,
    shadows: DesignSystem.DarkShadows,
    isDark: true
  };
}

// 导出默认实例
export default ThemeProvider.getInstance();