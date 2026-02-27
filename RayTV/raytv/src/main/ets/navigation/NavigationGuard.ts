import { routeManager, Route } from './RouteManager';

interface NavigationGuard {
  canActivate: (route: Route, params: Record<string, string>) => Promise<boolean> | boolean;
}

interface NavigationGuardConfig {
  [path: string]: NavigationGuard;
}

class NavigationGuardManager {
  private guards: NavigationGuardConfig = {};

  registerGuard(path: string, guard: NavigationGuard): void {
    this.guards[path] = guard;
  }

  registerGuards(guards: NavigationGuardConfig): void {
    this.guards = { ...this.guards, ...guards };
  }

  async canActivate(path: string, params: Record<string, string>): Promise<boolean> {
    const route = routeManager.getRouteByPath(path);
    if (!route) return false;

    const guard = this.guards[route.path];
    if (guard) {
      return await guard.canActivate(route, params);
    }

    return true;
  }

  getGuard(path: string): NavigationGuard | undefined {
    return this.guards[path];
  }

  getAllGuards(): NavigationGuardConfig {
    return { ...this.guards };
  }

  clearGuards(): void {
    this.guards = {};
  }
}

const navigationGuard = new NavigationGuardManager();

// 注册默认守卫
navigationGuard.registerGuards({
  '/settings': {
    canActivate: (route, params) => {
      // 这里可以添加权限检查逻辑
      return true;
    }
  },
  '/playback/:id': {
    canActivate: (route, params) => {
      // 检查是否有播放权限
      return !!params.id;
    }
  }
});

export { navigationGuard, NavigationGuardManager, NavigationGuard };