/**
 * 主题提供者 | Theme Provider
 * 管理应用程序的主题状态和主题切换功能
 * Manages application theme state and theme switching functionality
 */
import { DesignSystem, ColorPalette, ShadowLevels } from '../design/DesignSystem';
import Logger from '../common/util/Logger';

// ==================== 主题类型定义 | Theme Type Definitions ====================

/**
 * 主题模式 | Theme Mode
 */
export type ThemeMode = 'light' | 'dark' | 'auto';

/**
 * 主题配置 | Theme Configuration
 */
export interface ThemeConfig {
  mode: ThemeMode;
  colors: ColorPalette;
  shadows: ShadowLevels;
  name: string;
  description: string;
}

/**
 * 主题变更回调 | Theme Change Callback
 */
export type ThemeChangeListener = (newTheme: ThemeConfig, oldTheme: ThemeConfig) => void;

/**
 * 主题存储接口 | Theme Storage Interface
 */
export interface ThemeStorage {
  saveTheme(mode: ThemeMode): void;
  loadTheme(): ThemeMode | null;
  clearTheme(): void;
}

// ==================== 内置主题 | Built-in Themes ====================

/**
 * 暗色主题配置 | Dark Theme Configuration
 */
export const DarkTheme: ThemeConfig = {
  mode: 'dark',
  colors: {
    primary: {
      50: '#E3F2FD',
      100: '#BBDEFB',
      200: '#90CAF9',
      300: '#64B5F6',
      400: '#42A5F5',
      500: '#2196F3',
      600: '#1E88E5',
      700: '#1976D2',
      800: '#1565C0',
      900: '#0D47A1'
    },
    secondary: {
      50: '#F3E5F5',
      100: '#E1BEE7',
      200: '#CE93D8',
      300: '#BA68C8',
      400: '#AB47BC',
      500: '#9C27B0',
      600: '#8E24AA',
      700: '#7B1FA2',
      800: '#6A1B9A',
      900: '#4A148C'
    },
    accent: {
      50: '#FFF3E0',
      100: '#FFE0B2',
      200: '#FFCC80',
      300: '#FFB74D',
      400: '#FFA726',
      500: '#FF9800',
      600: '#FB8C00',
      700: '#F57C00',
      800: '#EF6C00',
      900: '#E65100'
    },
    neutral: {
      50: '#FAFAFA',
      100: '#F5F5F5',
      200: '#EEEEEE',
      300: '#E0E0E0',
      400: '#BDBDBD',
      500: '#9E9E9E',
      600: '#757575',
      700: '#616161',
      800: '#424242',
      900: '#212121'
    },
    status: {
      success: '#4CAF50',
      warning: '#FF9800',
      error: '#F44336',
      info: '#2196F3'
    },
    semantic: {
      background: {
        primary: '#121212',
        secondary: '#1E1E1E',
        tertiary: '#2C2C2C',
        inverse: '#FFFFFF'
      },
      text: {
        primary: '#FFFFFF',
        secondary: '#E0E0E0',
        tertiary: '#9E9E9E',
        inverse: '#212121',
        disabled: '#616161'
      },
      border: {
        primary: '#424242',
        secondary: '#616161',
        subtle: '#2C2C2C'
      },
      interactive: {
        hover: 'rgba(33, 150, 243, 0.1)',
        active: 'rgba(33, 150, 243, 0.2)',
        focus: 'rgba(33, 150, 243, 0.3)'
      }
    }
  },
  shadows: {
    sm: { x: 0, y: 1, blur: 2, color: 'rgba(0, 0, 0, 0.2)' },
    md: { x: 0, y: 4, blur: 8, color: 'rgba(0, 0, 0, 0.3)' },
    lg: { x: 0, y: 8, blur: 16, color: 'rgba(0, 0, 0, 0.4)' },
    xl: { x: 0, y: 16, blur: 32, color: 'rgba(0, 0, 0, 0.5)' }
  },
  name: 'Dark Theme',
  description: '默认暗色主题，适合夜间使用'
};

/**
 * 亮色主题配置 | Light Theme Configuration
 */
export const LightTheme: ThemeConfig = {
  mode: 'light',
  colors: {
    primary: {
      50: '#E3F2FD',
      100: '#BBDEFB',
      200: '#90CAF9',
      300: '#64B5F6',
      400: '#42A5F5',
      500: '#2196F3',
      600: '#1E88E5',
      700: '#1976D2',
      800: '#1565C0',
      900: '#0D47A1'
    },
    secondary: {
      50: '#F3E5F5',
      100: '#E1BEE7',
      200: '#CE93D8',
      300: '#BA68C8',
      400: '#AB47BC',
      500: '#9C27B0',
      600: '#8E24AA',
      700: '#7B1FA2',
      800: '#6A1B9A',
      900: '#4A148C'
    },
    accent: {
      50: '#FFF3E0',
      100: '#FFE0B2',
      200: '#FFCC80',
      300: '#FFB74D',
      400: '#FFA726',
      500: '#FF9800',
      600: '#FB8C00',
      700: '#F57C00',
      800: '#EF6C00',
      900: '#E65100'
    },
    neutral: {
      50: '#FAFAFA',
      100: '#F5F5F5',
      200: '#EEEEEE',
      300: '#E0E0E0',
      400: '#BDBDBD',
      500: '#9E9E9E',
      600: '#757575',
      700: '#616161',
      800: '#424242',
      900: '#212121'
    },
    status: {
      success: '#4CAF50',
      warning: '#FF9800',
      error: '#F44336',
      info: '#2196F3'
    },
    semantic: {
      background: {
        primary: '#FFFFFF',
        secondary: '#F5F5F5',
        tertiary: '#EEEEEE',
        inverse: '#212121'
      },
      text: {
        primary: '#212121',
        secondary: '#616161',
        tertiary: '#9E9E9E',
        inverse: '#FFFFFF',
        disabled: '#BDBDBD'
      },
      border: {
        primary: '#E0E0E0',
        secondary: '#BDBDBD',
        subtle: '#F5F5F5'
      },
      interactive: {
        hover: 'rgba(33, 150, 243, 0.05)',
        active: 'rgba(33, 150, 243, 0.1)',
        focus: 'rgba(33, 150, 243, 0.2)'
      }
    }
  },
  shadows: {
    sm: { x: 0, y: 1, blur: 2, color: 'rgba(0, 0, 0, 0.1)' },
    md: { x: 0, y: 4, blur: 8, color: 'rgba(0, 0, 0, 0.15)' },
    lg: { x: 0, y: 8, blur: 16, color: 'rgba(0, 0, 0, 0.2)' },
    xl: { x: 0, y: 16, blur: 32, color: 'rgba(0, 0, 0, 0.25)' }
  },
  name: 'Light Theme',
  description: '默认亮色主题，适合日间使用'
};

// ==================== 本地存储实现 | Local Storage Implementation ====================

/**
 * 本地存储主题管理器 | Local Storage Theme Manager
 */
export class LocalStorageThemeStorage implements ThemeStorage {
  private static readonly STORAGE_KEY = 'raytv-theme-mode';
  
  saveTheme(mode: ThemeMode): void {
    try {
      localStorage.setItem(LocalStorageThemeStorage.STORAGE_KEY, mode);
    } catch (error) {
      console.warn('Failed to save theme to localStorage:', error);
    }
  }
  
  loadTheme(): ThemeMode | null {
    try {
      const mode = localStorage.getItem(LocalStorageThemeStorage.STORAGE_KEY) as ThemeMode | null;
      return mode && ['light', 'dark', 'auto'].includes(mode) ? mode : null;
    } catch (error) {
      console.warn('Failed to load theme from localStorage:', error);
      return null;
    }
  }
  
  clearTheme(): void {
    try {
      localStorage.removeItem(LocalStorageThemeStorage.STORAGE_KEY);
    } catch (error) {
      console.warn('Failed to clear theme from localStorage:', error);
    }
  }
}

// ==================== 主题提供者核心类 | Theme Provider Core Class ====================

/**
 * 主题提供者 | Theme Provider
 */
export class ThemeProvider {
  private static instance: ThemeProvider;
  private logger: Logger;
  private designSystem: DesignSystem;
  private currentTheme: ThemeConfig;
  private listeners: Set<ThemeChangeListener> = new Set();
  private storage: ThemeStorage;
  private systemThemeListener: (() => void) | null = null;
  
  private constructor() {
    this.logger = new Logger('ThemeProvider');
    this.designSystem = DesignSystem.getInstance();
    this.storage = new LocalStorageThemeStorage();
    this.currentTheme = DarkTheme; // 默认暗色主题
    
    this.initializeTheme();
    this.logger.info('ThemeProvider initialized');
  }
  
  public static getInstance(): ThemeProvider {
    if (!ThemeProvider.instance) {
      ThemeProvider.instance = new ThemeProvider();
    }
    return ThemeProvider.instance;
  }
  
  /**
   * 初始化主题 | Initialize theme
   */
  private initializeTheme(): void {
    // 从存储中加载保存的主题 | Load saved theme from storage
    const savedMode = this.storage.loadTheme();
    if (savedMode) {
      this.setThemeMode(savedMode);
    } else {
      // 检查系统偏好设置 | Check system preference
      this.detectSystemTheme();
    }
    
    // 监听系统主题变化 | Listen for system theme changes
    this.setupSystemThemeListener();
  }
  
  /**
   * 设置主题模式 | Set theme mode
   */
  public setThemeMode(mode: ThemeMode): void {
    const oldTheme = this.currentTheme;
    let newTheme: ThemeConfig;
    
    switch (mode) {
      case 'light':
        newTheme = LightTheme;
        break;
      case 'dark':
        newTheme = DarkTheme;
        break;
      case 'auto':
        newTheme = this.getSystemPreferredTheme();
        break;
      default:
        this.logger.warn(`Unknown theme mode: ${mode}`);
        return;
    }
    
    // 更新设计系统 | Update design system
    this.designSystem.switchTheme(mode === 'light' ? 'light' : 'dark');
    
    // 更新当前主题 | Update current theme
    this.currentTheme = newTheme;
    
    // 保存到存储 | Save to storage
    if (mode !== 'auto') {
      this.storage.saveTheme(mode);
    }
    
    // 通知监听器 | Notify listeners
    this.notifyListeners(newTheme, oldTheme);
    
    this.logger.info(`Theme switched to ${mode}`);
  }
  
  /**
   * 获取当前主题 | Get current theme
   */
  public getCurrentTheme(): ThemeConfig {
    return this.currentTheme;
  }
  
  /**
   * 获取当前主题模式 | Get current theme mode
   */
  public getCurrentThemeMode(): ThemeMode {
    return this.currentTheme.mode;
  }
  
  /**
   * 切换主题 | Toggle theme
   */
  public toggleTheme(): void {
    const currentMode = this.getCurrentThemeMode();
    const newMode = currentMode === 'dark' ? 'light' : 'dark';
    this.setThemeMode(newMode);
  }
  
  /**
   * 添加主题变更监听器 | Add theme change listener
   */
  public addThemeChangeListener(listener: ThemeChangeListener): void {
    this.listeners.add(listener);
  }
  
  /**
   * 移除主题变更监听器 | Remove theme change listener
   */
  public removeThemeChangeListener(listener: ThemeChangeListener): void {
    this.listeners.delete(listener);
  }
  
  /**
   * 获取系统偏好主题 | Get system preferred theme
   */
  private getSystemPreferredTheme(): ThemeConfig {
    if (typeof window !== 'undefined' && window.matchMedia) {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      return prefersDark ? DarkTheme : LightTheme;
    }
    return DarkTheme; // 默认返回暗色主题
  }
  
  /**
   * 检测系统主题 | Detect system theme
   */
  private detectSystemTheme(): void {
    const systemTheme = this.getSystemPreferredTheme();
    this.currentTheme = systemTheme;
    this.designSystem.switchTheme(systemTheme.mode === 'light' ? 'light' : 'dark');
    this.logger.info('System theme detected and applied');
  }
  
  /**
   * 设置系统主题监听器 | Setup system theme listener
   */
  private setupSystemThemeListener(): void {
    if (typeof window !== 'undefined' && window.matchMedia) {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      this.systemThemeListener = () => {
        if (this.getCurrentThemeMode() === 'auto') {
          this.detectSystemTheme();
        }
      };
      
      // 添加监听器 | Add listener
      mediaQuery.addEventListener('change', this.systemThemeListener);
    }
  }
  
  /**
   * 通知监听器 | Notify listeners
   */
  private notifyListeners(newTheme: ThemeConfig, oldTheme: ThemeConfig): void {
    this.listeners.forEach(listener => {
      try {
        listener(newTheme, oldTheme);
      } catch (error) {
        this.logger.error('Error in theme change listener:', error);
      }
    });
  }
  
  /**
   * 清理资源 | Cleanup resources
   */
  public destroy(): void {
    // 移除系统主题监听器 | Remove system theme listener
    if (this.systemThemeListener && typeof window !== 'undefined') {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      mediaQuery.removeEventListener('change', this.systemThemeListener);
    }
    
    // 清空监听器 | Clear listeners
    this.listeners.clear();
    
    this.logger.info('ThemeProvider destroyed');
  }
  
  /**
   * 验证主题配置 | Validate theme configuration
   */
  public validateTheme(theme: ThemeConfig): boolean {
    try {
      // 验证必需的颜色属性 | Validate required color properties
      const requiredColors = ['primary', 'secondary', 'accent', 'neutral', 'status', 'semantic'];
      for (const color of requiredColors) {
        if (!theme.colors[color as keyof ColorPalette]) {
          this.logger.error(`Missing required color: ${color}`);
          return false;
        }
      }
      
      // 验证阴影配置 | Validate shadow configuration
      const requiredShadows = ['sm', 'md', 'lg', 'xl'];
      for (const shadow of requiredShadows) {
        if (!theme.shadows[shadow as keyof ShadowLevels]) {
          this.logger.error(`Missing required shadow: ${shadow}`);
          return false;
        }
      }
      
      return true;
    } catch (error) {
      this.logger.error('Theme validation failed:', error);
      return false;
    }
  }
}

// ==================== 便捷导出 | Convenient Exports ====================

// 导出单例实例 | Export singleton instance
export const themeProvider = ThemeProvider.getInstance();

// 导出类型和常量 | Export types and constants
export type { ThemeMode, ThemeConfig, ThemeChangeListener, ThemeStorage };
export { DarkTheme, LightTheme, LocalStorageThemeStorage };