import { useState, useEffect, onWindowFocus, onWindowBlur } from '@ohos/base';
import { Router, RouteConfig } from '@ohos/router';
import { getContext } from '@ohos.ability.featureAbility';
import { LoadingProgress, Button, Text } from '@ohos/components';
import { mediaService } from './service/media/MediaService';
import { historyService } from './service/media/HistoryService';
import { favoriteService } from './service/media/FavoriteService';
import { configService } from './service/config/ConfigService';
import { subscriptionManager } from './service/config/SubscriptionManager';
import { lineManager } from './service/config/LineManager';
import Logger from './common/util/Logger';

/**
 * RayTV应用主入口
 * 负责应用初始化、路由配置、全局状态管理等
 */
@Entry
@Component
struct App {
  private readonly TAG: string = 'App';
  
  // 全局状态
  @State isInitialized: boolean = false;
  @State initializationError: string = '';
  @State appName: string = 'RayTV';
  @State appVersion: string = '1.0.0';
  
  // 路由配置
  private routeConfigs: RouteConfig[] = [
    {
      path: 'pages/HomePage',
      name: 'HomePage',
      meta: {
        title: '首页',
        showTabBar: true,
        icon: '🏠'
      }
    },
    {
      path: 'pages/CategoryPage',
      name: 'CategoryPage',
      meta: {
        title: '分类',
        showTabBar: true,
        icon: '📋'
      }
    },
    {
      path: 'pages/FavoritesPage',
      name: 'FavoritesPage',
      meta: {
        title: '收藏',
        showTabBar: true,
        icon: '⭐'
      }
    },
    {
      path: 'pages/HistoryPage',
      name: 'HistoryPage',
      meta: {
        title: '历史',
        showTabBar: true,
        icon: '⏰'
      }
    },
    {
      path: 'pages/SettingsPage',
      name: 'SettingsPage',
      meta: {
        title: '设置',
        showTabBar: true,
        icon: '⚙️'
      }
    },
    {      
      path: 'pages/subscription/SubscriptionManagerPage',
      name: 'SubscriptionManagerPage',
      meta: {
        title: '配置源管理',
        showTabBar: false
      }
    },
    {      
      path: 'pages/LineManagerPage',
      name: 'LineManagerPage',
      meta: {
        title: '线路管理',
        showTabBar: false
      }
    },
    {
      path: 'pages/SearchPage',
      name: 'SearchPage',
      meta: {
        title: '搜索',
        showTabBar: false
      }
    },
    {
      path: 'pages/MediaDetailPage',
      name: 'MediaDetailPage',
      meta: {
        title: '媒体详情',
        showTabBar: false
      }
    },
    {
      path: 'pages/PlaybackPage',
      name: 'PlaybackPage',
      meta: {
        title: '播放',
        showTabBar: false,
        immersive: true
      }
    }
  ];
  
  // 应用初始化
  useEffect(() => {
    this.initializeApp();
  }, []);
  
  /**
   * 初始化应用
   */
  private async initializeApp(): Promise<void> {
    Logger.info(this.TAG, `Initializing ${this.appName} v${this.appVersion}...`);
    
    try {
      // 1. 初始化配置服务
      await this.initConfigService();
      
      // 2. 初始化数据库服务
      await this.initDatabaseServices();
      
      // 3. 初始化媒体服务
      await this.initMediaService();
      
      // 4. 初始化订阅管理器
      await this.initSubscriptionManager();
      
      // 5. 初始化线路管理器
      await this.initLineManager();
      
      // 6. 设置全局路由配置
      this.setupRouter();
      
      // 6. 执行启动任务
      await this.executeStartupTasks();
      
      this.isInitialized = true;
      Logger.info(this.TAG, 'Application initialized successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize application: ${error}`);
      this.initializationError = '应用初始化失败，请重启应用';
    }
  }
  
  /**
   * 初始化配置服务
   */
  private async initConfigService(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Initializing configuration service...');
      
      // 获取应用上下文并传递给配置服务
      const context = getContext(this);
      await configService.initialize(context);
      
      // 加载应用配置
      try {
        const appVersion = await configService.getConfig('appVersion', this.appVersion);
        if (appVersion) {
          this.appVersion = appVersion.toString();
        }
      } catch (e) {
        Logger.warn(this.TAG, 'Failed to get app version from config, using default');
      }
      
      Logger.info(this.TAG, 'Configuration service initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize configuration service: ${error}`);
      throw error;
    }
  }
  
  /**
   * 初始化订阅管理器
   */
  private async initSubscriptionManager(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Initializing subscription manager...');
      
      // 获取应用上下文并传递给订阅管理器
      const context = getContext(this);
      await subscriptionManager.initialize(context);
      
      Logger.info(this.TAG, 'Subscription manager initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize subscription manager: ${error}`);
      // 订阅管理器初始化失败不应阻止应用启动
      throw error;
    }
  }
  
  /**
   * 初始化线路管理器
   */
  private async initLineManager(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Initializing line manager...');
      
      // 获取应用上下文并传递给线路管理器
      const context = getContext(this);
      await lineManager.initialize(context);
      
      Logger.info(this.TAG, 'Line manager initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize line manager: ${error}`);
      // 线路管理器初始化失败不应阻止应用启动
    }
  }
  
  /**
   * 初始化数据库服务
   */
  private async initDatabaseServices(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Initializing database services...');
      
      // 初始化历史记录服务
      await historyService.initialize();
      
      // 初始化收藏服务
      await favoriteService.initialize();
      
      Logger.info(this.TAG, 'Database services initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize database services: ${error}`);
      throw error;
    }
  }
  
  /**
   * 初始化媒体服务
   */
  private async initMediaService(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Initializing media service...');
      await mediaService.initialize();
      Logger.info(this.TAG, 'Media service initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize media service: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置路由配置
   */
  private setupRouter(): void {
    try {
      Logger.info(this.TAG, 'Setting up router configuration...');
      
      // 注册路由
      this.routeConfigs.forEach(config => {
        Router.registerRoute(config);
      });
      
      // 检查是否有可用线路，如果没有则跳转到线路管理页面
      const hasAvailableLines = lineManager.hasAvailableLines();
      const defaultPath = hasAvailableLines ? 'pages/HomePage' : 'pages/LineManagerPage';
      
      // 设置默认路由
      Router.replace({
        url: defaultPath
      });
      
      Logger.info(this.TAG, `Default route set to: ${defaultPath}`);
      
      Logger.info(this.TAG, 'Router configured successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to setup router: ${error}`);
      throw error;
    }
  }
  
  /**
   * 执行启动任务
   */
  private async executeStartupTasks(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Executing startup tasks...');
      
      // 并行执行启动任务
      await Promise.all([
        this.cleanupOldData(),
        this.preloadCommonData(),
        this.checkAppUpdate()
      ]);
      
      Logger.info(this.TAG, 'Startup tasks completed');
    } catch (error) {
      Logger.warn(this.TAG, `Some startup tasks failed: ${error}`);
      // 启动任务失败不影响应用启动
    }
  }
  
  /**
   * 清理旧数据
   */
  private async cleanupOldData(): Promise<void> {
    try {
      // 清理过期的历史记录
      await historyService.cleanupExpiredHistories();
      
      Logger.info(this.TAG, 'Old data cleaned up');
    } catch (error) {
      Logger.error(this.TAG, `Failed to cleanup old data: ${error}`);
      throw error;
    }
  }
  
  /**
   * 预加载常用数据
   */
  private async preloadCommonData(): Promise<void> {
    try {
      // 预加载一些常用的数据，如分类列表、热门搜索词等
      await Promise.all([
        mediaService.getCategories(),
        mediaService.getHotSearchKeywords(10)
      ]);
      
      Logger.info(this.TAG, 'Common data preloaded');
    } catch (error) {
      Logger.warn(this.TAG, `Failed to preload common data: ${error}`);
    }
  }
  
  /**
   * 检查应用更新
   */
  private async checkAppUpdate(): Promise<void> {
    try {
      // 检查是否启用了自动更新
      const enableUpdateCheck = await configService.getConfig('enableUpdateCheck', true);
      
      if (enableUpdateCheck) {
        Logger.info(this.TAG, 'Checking for app updates...');
        // 这里应该调用更新检查服务
        // 暂时跳过实际的更新检查
      }
    } catch (error) {
      Logger.warn(this.TAG, `Failed to check for updates: ${error}`);
    }
  }
  
  /**
   * 应用获得焦点
   */
  onWindowFocus() {
    Logger.info(this.TAG, 'App window focused');
    
    // 处理应用回到前台的逻辑
    this.handleAppResume();
  }
  
  /**
   * 应用失去焦点
   */
  onWindowBlur() {
    Logger.info(this.TAG, 'App window blurred');
    
    // 处理应用进入后台的逻辑
    this.handleAppPause();
  }
  
  /**
   * 处理应用恢复
   */
  private async handleAppResume(): Promise<void> {
    try {
      // 刷新缓存的数据
      await mediaService.refreshCache();
      
      Logger.info(this.TAG, 'App resumed successfully');
    } catch (error) {
      Logger.warn(this.TAG, `Failed to handle app resume: ${error}`);
    }
  }
  
  /**
   * 处理应用暂停
   */
  private async handleAppPause(): Promise<void> {
    try {
      // 保存应用状态
      await this.saveAppState();
      
      // 清理临时资源
      await mediaService.cleanupTempResources();
      
      Logger.info(this.TAG, 'App paused successfully');
    } catch (error) {
      Logger.warn(this.TAG, `Failed to handle app pause: ${error}`);
    }
  }
  
  /**
   * 保存应用状态
   */
  private async saveAppState(): Promise<void> {
    try {
      // 保存当前应用状态信息
      const appState = {
        lastActiveTime: new Date().toISOString(),
        version: this.appVersion
      };
      
      await configService.setConfig('appState', appState);
      
      Logger.info(this.TAG, 'App state saved');
    } catch (error) {
      Logger.error(this.TAG, `Failed to save app state: ${error}`);
    }
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    <Stack className="loading-container">
      <LoadingProgress className="loading-spinner" color="#FF4500" />
      <Text className="loading-text">正在启动 {this.appName}...</Text>
    </Stack>
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    <Stack className="error-container">
      <Text className="error-icon">⚠️</Text>
      <Text className="error-title">启动失败</Text>
      <Text className="error-message">{this.initializationError}</Text>
      <Button className="retry-button" onClick={() => this.initializeApp()}>
        重试
      </Button>
    </Stack>
  }
  
  /**
   * 渲染应用容器
   */
  @Builder
  private renderAppContainer(): void {
    <Stack className="app-container">
      {/* 路由视图容器 */}
      <Router.RouterView className="router-view" />
    </Stack>
  }
  
  /**
   * 组件渲染
   */
  build() {
    <Stack className="app">
      {!this.isInitialized && !this.initializationError ? (
        this.renderLoading()
      ) : this.initializationError ? (
        this.renderError()
      ) : (
        this.renderAppContainer()
      )}
    </Stack>
  }
}

export default App;