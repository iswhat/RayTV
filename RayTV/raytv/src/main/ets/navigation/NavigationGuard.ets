/**
 * 导航守卫 | Navigation Guard
 * 负责路由的权限控制和导航拦截
 */
import Logger from '../common/util/Logger';
import EventBus from '../common/event/EventBus';
import { RouteDefinition, NavigationOptions } from './RouteManager';
import { AppState } from '../common/state/AppState';

// 导航守卫类型 | Navigation guard type
export type NavigationGuard = (
  to: RouteDefinition,
  from: RouteDefinition | null,
  options: NavigationOptions
) => boolean | Promise<boolean>;

// 导航守卫配置 | Navigation guard config
export interface NavigationGuardConfig {
  /**
   * 守卫名称 | Guard name
   */
  name: string;
  /**
   * 守卫函数 | Guard function
   */
  guard: NavigationGuard;
  /**
   * 优先级 | Priority (higher number means higher priority)
   */
  priority: number;
  /**
   * 适用的路由名称 | Applicable route names
   */
  routes?: string[];
}

// 导航守卫类型枚举 | Navigation guard type enum
export enum NavigationGuardType {
  /**
   * 全局守卫 | Global guard
   */
  GLOBAL = 'global',
  /**
   * 路由守卫 | Route guard
   */
  ROUTE = 'route',
  /**
   * 组件守卫 | Component guard
   */
  COMPONENT = 'component'
}

// 导航守卫回调 | Navigation guard callback
export type NavigationGuardCallback = (allowed: boolean, reason?: string) => void;

/**
 * 导航守卫管理器类 | Navigation guard manager class
 */
export class NavigationGuardManager {
  private static instance: NavigationGuardManager | null = null;
  private guards: NavigationGuardConfig[] = [];
  private logger: Logger;
  private eventBus: EventBus;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): NavigationGuardManager {
    if (!NavigationGuardManager.instance) {
      NavigationGuardManager.instance = new NavigationGuardManager();
    }
    return NavigationGuardManager.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.logger = new Logger('NavigationGuardManager');
    this.eventBus = EventBus.getInstance();
    this.initializeDefaultGuards();
  }

  /**
   * 初始化默认守卫 | Initialize default guards
   */
  private initializeDefaultGuards(): void {
    // 注册认证守卫 | Register auth guard
    this.addGuard({
      name: 'auth',
      guard: this.authGuard,
      priority: 100
    });

    // 注册网络状态守卫 | Register network guard
    this.addGuard({
      name: 'network',
      guard: this.networkGuard,
      priority: 90
    });

    // 注册权限守卫 | Register permission guard
    this.addGuard({
      name: 'permission',
      guard: this.permissionGuard,
      priority: 80
    });

    // 注册速率限制守卫 | Register rate limit guard
    this.addGuard({
      name: 'rateLimit',
      guard: this.rateLimitGuard,
      priority: 70
    });

    // 注册缓存守卫 | Register cache guard
    this.addGuard({
      name: 'cache',
      guard: this.cacheGuard,
      priority: 60
    });

    // 注册设备能力守卫 | Register device capability guard
    this.addGuard({
      name: 'deviceCapability',
      guard: this.deviceCapabilityGuard,
      priority: 50
    });

    this.logger.info('Default guards initialized');
  }

  /**
   * 认证守卫 | Auth guard
   */
  private authGuard: NavigationGuard = (to, from, options) => {
    // 检查路由是否需要认证 | Check if route requires authentication
    if (to.meta?.requiresAuth) {
      const isAuthenticated = AppState.isAuthenticated;
      if (!isAuthenticated) {
        this.logger.warn(`Access denied to ${to.name}: authentication required`);
        // 可以在这里添加重定向逻辑 | Can add redirection logic here
        return false;
      }
    }
    return true;
  };

  /**
   * 网络状态守卫 | Network guard
   */
  private networkGuard: NavigationGuard = (to, from, options) => {
    // 检查网络状态 | Check network status
    const isConnected = AppState.isNetworkConnected;
    if (!isConnected) {
      this.logger.warn(`Access denied to ${to.name}: no network connection`);
      // 可以在这里添加提示逻辑 | Can add notification logic here
      return false;
    }
    return true;
  };

  /**
   * 权限守卫 | Permission guard
   */
  private permissionGuard: NavigationGuard = (to, from, options) => {
    // 检查用户权限 | Check user permissions
    const user = AppState.currentUser;
    if (user && user.preferences) {
      // 这里可以根据用户角色和权限进行更复杂的权限检查 | Can add more complex permission checks here
    }
    return true;
  };

  /**
   * 速率限制守卫 | Rate limit guard
   */
  private rateLimitGuard: NavigationGuard = (to, from, options) => {
    // 简单的速率限制实现 | Simple rate limit implementation
    const now = Date.now();
    const routeKey = `rate_limit_${to.name}`;
    
    // 检查是否有速率限制记录 | Check if rate limit record exists
    if (AppState.rateLimits && AppState.rateLimits[routeKey]) {
      const lastAccess = AppState.rateLimits[routeKey];
      const minInterval = 1000; // 1秒最小间隔 | 1 second minimum interval
      
      if (now - lastAccess < minInterval) {
        this.logger.warn(`Rate limit exceeded for ${to.name}`);
        return false;
      }
    }
    
    // 更新最后访问时间 | Update last access time
    if (!AppState.rateLimits) {
      AppState.rateLimits = {};
    }
    AppState.rateLimits[routeKey] = now;
    
    return true;
  };

  /**
   * 缓存守卫 | Cache guard
   */
  private cacheGuard: NavigationGuard = (to, from, options) => {
    // 检查是否有缓存内容 | Check if cached content exists
    if (to.meta?.cacheable) {
      const cacheKey = `route_cache_${to.name}`;
      // 这里可以添加缓存检查逻辑 | Can add cache check logic here
      this.logger.info(`Cache check for ${to.name}`);
    }
    return true;
  };

  /**
   * 设备能力守卫 | Device capability guard
   */
  private deviceCapabilityGuard: NavigationGuard = (to, from, options) => {
    // 检查设备能力 | Check device capabilities
    if (to.meta?.requiredCapabilities) {
      const requiredCapabilities = to.meta.requiredCapabilities;
      // 这里可以添加设备能力检查逻辑 | Can add device capability check logic here
      this.logger.info(`Device capability check for ${to.name}`);
    }
    return true;
  };

  /**
   * 添加守卫 | Add guard
   * @param config 守卫配置 | Guard config
   */
  public addGuard(config: NavigationGuardConfig): void {
    // 检查是否已存在同名守卫 | Check if guard with same name already exists
    const existingIndex = this.guards.findIndex(g => g.name === config.name);
    if (existingIndex !== -1) {
      this.logger.warn(`Guard ${config.name} already exists, overriding...`);
      this.guards[existingIndex] = config;
    } else {
      this.guards.push(config);
    }

    // 按优先级排序 | Sort by priority
    this.guards.sort((a, b) => b.priority - a.priority);
    this.logger.info(`Added guard: ${config.name} (priority: ${config.priority})`);
  }

  /**
   * 添加多个守卫 | Add multiple guards
   * @param configs 守卫配置数组 | Guard config array
   */
  public addGuards(configs: NavigationGuardConfig[]): void {
    configs.forEach(config => {
      this.addGuard(config);
    });
    this.logger.info(`Added ${configs.length} guards`);
  }

  /**
   * 移除守卫 | Remove guard
   * @param name 守卫名称 | Guard name
   */
  public removeGuard(name: string): void {
    const initialLength = this.guards.length;
    this.guards = this.guards.filter(g => g.name !== name);
    if (this.guards.length !== initialLength) {
      this.logger.info(`Removed guard: ${name}`);
    } else {
      this.logger.warn(`Guard ${name} not found`);
    }
  }

  /**
   * 清除所有守卫 | Clear all guards
   */
  public clearGuards(): void {
    this.guards = [];
    this.logger.info('Cleared all guards');
  }

  /**
   * 检查导航是否允许 | Check if navigation is allowed
   * @param to 目标路由 | Target route
   * @param from 当前路由 | Current route
   * @param options 导航选项 | Navigation options
   * @returns 是否允许导航 | Whether navigation is allowed
   */
  public async canActivate(
    to: RouteDefinition,
    from: RouteDefinition | null,
    options: NavigationOptions = {}
  ): Promise<boolean> {
    // 过滤适用于当前路由的守卫 | Filter guards applicable to current route
    const applicableGuards = this.guards.filter(guard => {
      // 如果没有指定路由，则适用于所有路由 | If no routes specified, apply to all routes
      if (!guard.routes || guard.routes.length === 0) {
        return true;
      }
      // 检查路由是否在适用列表中 | Check if route is in applicable list
      return guard.routes.includes(to.name);
    });

    // 依次执行守卫 | Execute guards in order
    for (const guard of applicableGuards) {
      try {
        const result = await guard.guard(to, from, options);
        if (!result) {
          this.logger.info(`Navigation to ${to.name} blocked by guard: ${guard.name}`);
          return false;
        }
      } catch (error) {
        this.logger.error(`Error in guard ${guard.name}:`, error);
        // 守卫执行出错时，默认阻止导航 | Block navigation on guard error
        return false;
      }
    }

    this.logger.info(`Navigation to ${to.name} allowed`);
    return true;
  }

  /**
   * 获取所有守卫 | Get all guards
   * @returns 守卫配置数组 | Guard config array
   */
  public getGuards(): NavigationGuardConfig[] {
    return [...this.guards];
  }

  /**
   * 获取守卫 | Get guard
   * @param name 守卫名称 | Guard name
   * @returns 守卫配置 | Guard config
   */
  public getGuard(name: string): NavigationGuardConfig | undefined {
    return this.guards.find(g => g.name === name);
  }

  /**
   * 更新守卫 | Update guard
   * @param name 守卫名称 | Guard name
   * @param config 守卫配置 | Guard config
   */
  public updateGuard(name: string, config: Partial<NavigationGuardConfig>): void {
    const index = this.guards.findIndex(g => g.name === name);
    if (index !== -1) {
      this.guards[index] = {
        ...this.guards[index],
        ...config
      };
      // 重新排序 | Re-sort
      this.guards.sort((a, b) => b.priority - a.priority);
      this.logger.info(`Updated guard: ${name}`);
    } else {
      this.logger.warn(`Guard ${name} not found`);
    }
  }

  /**
   * 重置守卫 | Reset guards
   */
  public reset(): void {
    this.guards = [];
    this.initializeDefaultGuards();
    this.logger.info('Navigation guard manager reset');
  }

  /**
   * 销毁 | Destroy
   */
  public destroy(): void {
    this.guards = [];
    this.logger.info('Navigation guard manager destroyed');
  }
}

// 导出单例实例 | Export singleton instance
export const navigationGuardManager = NavigationGuardManager.getInstance();

export default navigationGuardManager;
