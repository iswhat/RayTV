/**
 * AppState - 应用状态管理
 * 
 * 管理应用的全局状态，包括用户状态、设置、播放状态等
 */

import Logger from '../util/Logger';
import StorageUtil from '../util/StorageUtil';

const STORAGE_KEY = 'app_state';
const TAG = 'AppState';

// 状态类型定义
export interface UserState {
  isLoggedIn: boolean;
  userId: string;
  userName: string;
  preferences: Record<string, Object>;
}

export interface SettingsState {
  theme: string;
  language: string;
  autoPlay: boolean;
  quality: string;
  notifications: boolean;
  parentalControl: boolean;
}

export interface PlaybackState {
  currentMedia: {
    id: string;
    title: string;
    url: string;
    type: 'vod' | 'live';
  } | null;
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  playbackRate: number;
  volume: number;
}

export interface NavigationState {
  currentRoute: string;
  previousRoute: string;
  params: Record<string, Object>;
}

export interface NetworkState {
  isConnected: boolean;
  connectionType: 'wifi' | 'mobile' | 'none';
  signalStrength: number;
}

export interface LoadingState {
  isLoading: boolean;
  loadingMessage: string;
  loadingId: string;
}

export interface ErrorState {
  hasError: boolean;
  errorMessage: string;
  errorCode: string;
  errorDetails: Record<string, Object>;
}

export interface ContentState {
  recentlyWatched: Array<{
    id: string;
    title: string;
    type: 'vod' | 'live';
    lastWatched: number;
    progress: number;
  }>;
  favorites: Array<{
    id: string;
    title: string;
    type: 'vod' | 'live';
    addedAt: number;
  }>;
  watchHistory: Array<{
    id: string;
    title: string;
    type: 'vod' | 'live';
    watchedAt: number;
    duration: number;
    progress: number;
  }>;
}

export interface AppStateType {
  user: UserState;
  settings: SettingsState;
  playback: PlaybackState;
  navigation: NavigationState;
  network: NetworkState;
  loading: LoadingState;
  error: ErrorState;
  content: ContentState;
}

// 事件类型
export enum AppStateEvent {
  USER_STATE_CHANGED = 'user_state_changed',
  SETTINGS_CHANGED = 'settings_changed',
  PLAYBACK_STATE_CHANGED = 'playback_state_changed',
  NAVIGATION_STATE_CHANGED = 'navigation_state_changed',
  NETWORK_STATE_CHANGED = 'network_state_changed',
  LOADING_STATE_CHANGED = 'loading_state_changed',
  ERROR_STATE_CHANGED = 'error_state_changed',
  CONTENT_STATE_CHANGED = 'content_state_changed',
  STATE_RESET = 'state_reset'
}

// 默认状态
const defaultState: AppStateType = {
  user: {
    isLoggedIn: false,
    userId: '',
    userName: '',
    preferences: {}
  },
  settings: {
    theme: 'light',
    language: 'zh-CN',
    autoPlay: true,
    quality: '720p',
    notifications: true,
    parentalControl: false
  },
  playback: {
    currentMedia: null,
    isPlaying: false,
    currentTime: 0,
    duration: 0,
    playbackRate: 1.0,
    volume: 1.0
  },
  navigation: {
    currentRoute: 'home',
    previousRoute: '',
    params: {}
  },
  network: {
    isConnected: true,
    connectionType: 'wifi',
    signalStrength: 100
  },
  loading: {
    isLoading: false,
    loadingMessage: '',
    loadingId: ''
  },
  error: {
    hasError: false,
    errorMessage: '',
    errorCode: '',
    errorDetails: {}
  },
  content: {
    recentlyWatched: [],
    favorites: [],
    watchHistory: []
  }
};

/**
 * 应用状态管理类
 */
export class AppState {
  private static instance: AppState | null = null;
  private state: AppStateType;
  private previousState: AppStateType;
  private listeners: Map<AppStateEvent, Array<(state: AppStateType) => void>>;
  private logger: Logger;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): AppState {
    if (!AppState.instance) {
      AppState.instance = new AppState();
    }
    return AppState.instance;
  }
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.state = { ...defaultState };
    this.previousState = { ...defaultState };
    this.listeners = new Map();
    this.logger = new Logger(TAG);
    this.loadState();
  }
  
  /**
   * 获取当前状态
   */
  public getState(): AppStateType {
    return { ...this.state };
  }
  
  /**
   * 更新用户状态
   */
  public updateUserState(updates: Partial<UserState>): void {
    this.previousState = { ...this.state };
    this.state.user = {
      ...this.state.user,
      ...updates
    };
    this.saveState();
    this.notifyListeners(AppStateEvent.USER_STATE_CHANGED);
  }
  
  /**
   * 更新设置
   */
  public updateSettings(updates: Partial<SettingsState>): void {
    this.previousState = { ...this.state };
    this.state.settings = {
      ...this.state.settings,
      ...updates
    };
    this.saveState();
    this.notifyListeners(AppStateEvent.SETTINGS_CHANGED);
  }
  
  /**
   * 更新播放状态
   */
  public updatePlaybackState(updates: Partial<PlaybackState>): void {
    this.previousState = { ...this.state };
    this.state.playback = {
      ...this.state.playback,
      ...updates
    };
    this.saveState();
    this.notifyListeners(AppStateEvent.PLAYBACK_STATE_CHANGED);
  }
  
  /**
   * 更新导航状态
   */
  public updateNavigationState(updates: Partial<NavigationState>): void {
    this.previousState = { ...this.state };
    this.state.navigation = {
      ...this.state.navigation,
      ...updates
    };
    this.saveState();
    this.notifyListeners(AppStateEvent.NAVIGATION_STATE_CHANGED);
  }
  
  /**
   * 更新网络状态
   */
  public updateNetworkState(updates: Partial<NetworkState>): void {
    this.previousState = { ...this.state };
    this.state.network = {
      ...this.state.network,
      ...updates
    };
    this.saveState();
    this.notifyListeners(AppStateEvent.NETWORK_STATE_CHANGED);
  }
  
  /**
   * 更新加载状态
   */
  public updateLoadingState(updates: Partial<LoadingState>): void {
    this.previousState = { ...this.state };
    this.state.loading = {
      ...this.state.loading,
      ...updates
    };
    this.saveState();
    this.notifyListeners(AppStateEvent.LOADING_STATE_CHANGED);
  }
  
  /**
   * 更新错误状态
   */
  public updateErrorState(updates: Partial<ErrorState>): void {
    this.previousState = { ...this.state };
    this.state.error = {
      ...this.state.error,
      ...updates
    };
    this.saveState();
    this.notifyListeners(AppStateEvent.ERROR_STATE_CHANGED);
  }
  
  /**
   * 重置状态
   */
  public resetState(): void {
    this.previousState = { ...this.state };
    this.state = { ...defaultState };
    this.saveState();
    this.notifyListeners(AppStateEvent.STATE_RESET);
  }
  
  /**
   * 回滚状态
   */
  public rollbackState(): void {
    this.state = { ...this.previousState };
    this.saveState();
    this.notifyListeners(AppStateEvent.STATE_RESET);
  }
  
  /**
   * 添加状态监听器
   */
  public addStateListener(event: AppStateEvent, listener: (state: AppStateType) => void): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)?.push(listener);
  }
  
  /**
   * 移除状态监听器
   */
  public removeStateListener(event: AppStateEvent, listener: (state: AppStateType) => void): void {
    if (this.listeners.has(event)) {
      const listeners = this.listeners.get(event);
      if (listeners) {
        this.listeners.set(event, listeners.filter(l => l !== listener));
      }
    }
  }
  
  /**
   * 保存状态到存储
   */
  private saveState(): void {
    try {
      StorageUtil.setItem(STORAGE_KEY, JSON.stringify(this.state));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error('Failed to save state', err);
    }
  }
  
  /**
   * 从存储加载状态
   */
  private loadState(): void {
    try {
      const savedState = StorageUtil.getItem(STORAGE_KEY);
      if (savedState) {
        this.state = JSON.parse(savedState) as AppStateType;
        this.previousState = { ...this.state };
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error('Failed to load state, using default', err);
      this.state = { ...defaultState };
      this.previousState = { ...defaultState };
    }
  }
  
  /**
   * 通知监听器
   */
  private notifyListeners(event: AppStateEvent): void {
    const eventListeners = this.listeners.get(event);
    if (eventListeners) {
      eventListeners.forEach(listener => {
        try {
          listener(this.getState());
        } catch (error) {
          const err = error instanceof Error ? error : new Error(String(error));
          this.logger.error('Error in state listener', err);
        }
      });
    }
  }
}

// 导出单例实例
export default AppState.getInstance();