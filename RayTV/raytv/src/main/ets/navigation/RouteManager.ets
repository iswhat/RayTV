/**
 * 路由管理器 | Route Manager
 * 负责路由的注册、匹配和管理
 */
import Logger from '../common/util/Logger';
import EventBus from '../common/event/EventBus';
import { AppState, RouteInfo } from '../common/state/AppState';

// 路由定义接口 | Route definition interface
export interface RouteDefinition {
  /**
   * 路由名称 | Route name
   */
  name: string;
  /**
   * 路由路径 | Route path
   */
  path: string;
  /**
   * 组件名称 | Component name
   */
  component: string;
  /**
   * 路由参数 | Route params
   */
  params?: Record<string, any>;
  /**
   * 路由元数据 | Route meta data
   */
  meta?: {
    title?: string;
    requiresAuth?: boolean;
    transition?: string;
    [key: string]: any;
  };
}

// 路由匹配结果 | Route match result
export interface RouteMatchResult {
  route: RouteDefinition;
  params: Record<string, string>;
  path: string;
}

// 导航选项 | Navigation options
export interface NavigationOptions {
  replace?: boolean;
  transition?: string;
  title?: string;
  [key: string]: any;
}

// 路由事件 | Route events
export enum RouteEvent {
  ROUTE_REGISTERED = 'route_registered',
  ROUTE_UNREGISTERED = 'route_unregistered',
  ROUTE_CHANGED = 'route_changed',
  ROUTE_NOT_FOUND = 'route_not_found'
}

/**
 * 路由管理器类 | Route manager class
 */
export class RouteManager {
  private static instance: RouteManager | null = null;
  private routes: Map<string, RouteDefinition> = new Map();
  private currentRoute: RouteDefinition | null = null;
  private navigationHistory: RouteInfo[] = [];
  private navigationStack: RouteInfo[] = [];
  private logger: Logger;
  private eventBus: EventBus;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): RouteManager {
    if (!RouteManager.instance) {
      RouteManager.instance = new RouteManager();
    }
    return RouteManager.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.logger = new Logger('RouteManager');
    this.eventBus = EventBus.getInstance();
    this.initializeDefaultRoutes();
  }

  /**
   * 初始化默认路由 | Initialize default routes
   */
  private initializeDefaultRoutes(): void {
    // 注册默认路由 | Register default routes
    this.registerRoute({
      name: 'home',
      path: '/',
      component: 'HomePage',
      meta: {
        title: '首页'
      }
    });

    this.registerRoute({
      name: 'live',
      path: '/live',
      component: 'LivePage',
      meta: {
        title: '直播'
      }
    });

    this.registerRoute({
      name: 'vod',
      path: '/vod',
      component: 'CategoryPage',
      meta: {
        title: '点播'
      }
    });

    this.registerRoute({
      name: 'search',
      path: '/search',
      component: 'SearchPage',
      meta: {
        title: '搜索'
      }
    });

    this.registerRoute({
      name: 'settings',
      path: '/settings',
      component: 'SettingsPage',
      meta: {
        title: '设置'
      }
    });

    this.registerRoute({
      name: 'detail',
      path: '/detail/:id',
      component: 'MediaDetailPage',
      meta: {
        title: '详情'
      }
    });

    this.registerRoute({
      name: 'playback',
      path: '/playback/:id',
      component: 'PlaybackPage',
      meta: {
        title: '播放'
      }
    });

    this.logger.info('Default routes initialized');
  }

  /**
   * 注册路由 | Register route
   * @param route 路由定义 | Route definition
   */
  public registerRoute(route: RouteDefinition): void {
    if (this.routes.has(route.name)) {
      this.logger.warn(`Route ${route.name} already registered, overriding...`);
    }

    this.routes.set(route.name, route);
    this.eventBus.publish(RouteEvent.ROUTE_REGISTERED, route);
    this.logger.info(`Registered route: ${route.name} (${route.path})`);
  }

  /**
   * 注册多个路由 | Register multiple routes
   * @param routes 路由定义数组 | Route definition array
   */
  public registerRoutes(routes: RouteDefinition[]): void {
    routes.forEach(route => {
      this.registerRoute(route);
    });
    this.logger.info(`Registered ${routes.length} routes`);
  }

  /**
   * 注销路由 | Unregister route
   * @param name 路由名称 | Route name
   */
  public unregisterRoute(name: string): void {
    if (this.routes.has(name)) {
      const route = this.routes.get(name);
      this.routes.delete(name);
      this.eventBus.publish(RouteEvent.ROUTE_UNREGISTERED, route);
      this.logger.info(`Unregistered route: ${name}`);
    } else {
      this.logger.warn(`Route ${name} not found`);
    }
  }

  /**
   * 获取路由 | Get route
   * @param name 路由名称 | Route name
   * @returns 路由定义 | Route definition
   */
  public getRoute(name: string): RouteDefinition | undefined {
    return this.routes.get(name);
  }

  /**
   * 获取所有路由 | Get all routes
   * @returns 路由定义数组 | Route definition array
   */
  public getAllRoutes(): RouteDefinition[] {
    return Array.from(this.routes.values());
  }

  /**
   * 匹配路径 | Match path
   * @param path 路径 | Path
   * @returns 匹配结果 | Match result
   */
  public matchPath(path: string): RouteMatchResult | null {
    // 移除路径末尾的斜杠 | Remove trailing slash
    const normalizedPath = path.replace(/\/$/, '');

    for (const route of this.routes.values()) {
      const match = this.matchRoute(route, normalizedPath);
      if (match) {
        return match;
      }
    }

    return null;
  }

  /**
   * 匹配单个路由 | Match single route
   * @param route 路由定义 | Route definition
   * @param path 路径 | Path
   * @returns 匹配结果 | Match result
   */
  private matchRoute(route: RouteDefinition, path: string): RouteMatchResult | null {
    const routePath = route.path.replace(/\/$/, '');
    const routeParts = routePath.split('/');
    const pathParts = path.split('/');

    if (routeParts.length !== pathParts.length) {
      return null;
    }

    const params: Record<string, string> = {};

    for (let i = 0; i < routeParts.length; i++) {
      const routePart = routeParts[i];
      const pathPart = pathParts[i];

      if (routePart.startsWith(':')) {
        // 捕获参数 | Capture parameter
        const paramName = routePart.substring(1);
        params[paramName] = pathPart;
      } else if (routePart !== pathPart) {
        // 路径不匹配 | Path doesn't match
        return null;
      }
    }

    return {
      route,
      params,
      path
    };
  }

  /**
   * 导航到路由 | Navigate to route
   * @param name 路由名称 | Route name
   * @param params 路由参数 | Route params
   * @param options 导航选项 | Navigation options
   */
  public async navigateTo(name: string, params?: Record<string, any>, options: NavigationOptions = {}): Promise<boolean> {
    const route = this.routes.get(name);
    if (!route) {
      this.logger.error(`Route ${name} not found`);
      this.eventBus.publish(RouteEvent.ROUTE_NOT_FOUND, name);
      return false;
    }

    try {
      // 构建路由信息 | Build route info
      const routeInfo: RouteInfo = {
        name: route.name,
        path: this.buildPath(route.path, params),
        params,
        timestamp: Date.now()
      };

      // 更新当前路由 | Update current route
      this.currentRoute = route;

      // 更新导航历史 | Update navigation history
      if (!options.replace) {
        this.navigationHistory.push(routeInfo);
        this.navigationStack.push(routeInfo);

        // 限制历史记录长度 | Limit history length
        if (this.navigationHistory.length > 50) {
          this.navigationHistory.shift();
        }
      } else {
        // 替换当前路由 | Replace current route
        if (this.navigationStack.length > 0) {
          this.navigationStack.pop();
          this.navigationStack.push(routeInfo);
        }
      }

      // 更新AppState | Update AppState
      AppState.setCurrentRoute(routeInfo);

      // 发布路由变更事件 | Publish route change event
      this.eventBus.publish(RouteEvent.ROUTE_CHANGED, {
        route: routeInfo,
        options
      });

      this.logger.info(`Navigated to route: ${name} with params: ${JSON.stringify(params)}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to navigate to route ${name}:`, error);
      return false;
    }
  }

  /**
   * 构建路径 | Build path
   * @param pathTemplate 路径模板 | Path template
   * @param params 参数 | Params
   * @returns 构建后的路径 | Built path
   */
  private buildPath(pathTemplate: string, params?: Record<string, any>): string {
    if (!params) {
      return pathTemplate;
    }

    let path = pathTemplate;
    for (const [key, value] of Object.entries(params)) {
      path = path.replace(`:${key}`, encodeURIComponent(String(value)));
    }
    return path;
  }

  /**
   * 导航回退 | Navigate back
   * @returns 回退是否成功 | Whether back navigation was successful
   */
  public async navigateBack(): Promise<boolean> {
    if (this.navigationStack.length > 1) {
      this.navigationStack.pop();
      const previousRouteInfo = this.navigationStack[this.navigationStack.length - 1];
      
      if (previousRouteInfo) {
        const route = this.routes.get(previousRouteInfo.name);
        if (route) {
          this.currentRoute = route;
          AppState.setCurrentRoute(previousRouteInfo);
          
          this.eventBus.publish(RouteEvent.ROUTE_CHANGED, {
            route: previousRouteInfo,
            options: {}
          });

          this.logger.info(`Navigated back to route: ${previousRouteInfo.name}`);
          return true;
        }
      }
    }

    this.logger.warn('Cannot navigate back: no previous route');
    return false;
  }

  /**
   * 获取当前路由 | Get current route
   * @returns 当前路由 | Current route
   */
  public getCurrentRoute(): RouteDefinition | null {
    return this.currentRoute;
  }

  /**
   * 获取导航历史 | Get navigation history
   * @returns 导航历史 | Navigation history
   */
  public getNavigationHistory(): RouteInfo[] {
    return [...this.navigationHistory];
  }

  /**
   * 清除导航历史 | Clear navigation history
   */
  public clearNavigationHistory(): void {
    this.navigationHistory = [];
    this.navigationStack = [];
    if (this.currentRoute) {
      const currentRouteInfo: RouteInfo = {
        name: this.currentRoute.name,
        path: this.currentRoute.path,
        timestamp: Date.now()
      };
      this.navigationHistory.push(currentRouteInfo);
      this.navigationStack.push(currentRouteInfo);
    }
    this.logger.info('Navigation history cleared');
  }

  /**
   * 重置路由管理器 | Reset route manager
   */
  public reset(): void {
    this.routes.clear();
    this.currentRoute = null;
    this.navigationHistory = [];
    this.navigationStack = [];
    this.initializeDefaultRoutes();
    this.logger.info('Route manager reset');
  }

  /**
   * 销毁 | Destroy
   */
  public destroy(): void {
    this.routes.clear();
    this.currentRoute = null;
    this.navigationHistory = [];
    this.navigationStack = [];
    this.logger.info('Route manager destroyed');
  }
}

// 导出单例实例 | Export singleton instance
export const routeManager = RouteManager.getInstance();

export default routeManager;
