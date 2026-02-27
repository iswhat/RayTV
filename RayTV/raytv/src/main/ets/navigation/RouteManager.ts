interface Route {
  path: string;
  component: string;
  title?: string;
  params?: Record<string, string>;
}

interface RouteMatch {
  route: Route;
  params: Record<string, string>;
}

class RouteManager {
  private routes: Route[] = [];

  registerRoute(route: Route): void {
    this.routes.push(route);
  }

  registerRoutes(routes: Route[]): void {
    this.routes.push(...routes);
  }

  match(path: string): RouteMatch | null {
    for (const route of this.routes) {
      const match = this.matchRoute(route, path);
      if (match) {
        return match;
      }
    }
    return null;
  }

  private matchRoute(route: Route, path: string): RouteMatch | null {
    const routePath = route.path.replace(/\/:([^/]+)/g, '(\\w+)');
    const regex = new RegExp(`^${routePath}$`);
    const match = path.match(regex);

    if (!match) return null;

    const params: Record<string, string> = {};
    const paramNames = route.path.match(/\/:([^/]+)/g) || [];
    
    paramNames.forEach((param, index) => {
      const paramName = param.substring(1);
      params[paramName] = match[index + 1];
    });

    return {
      route,
      params
    };
  }

  getRouteByPath(path: string): Route | null {
    const match = this.match(path);
    return match ? match.route : null;
  }

  getRouteByComponent(component: string): Route | null {
    return this.routes.find(route => route.component === component) || null;
  }

  generatePath(routePath: string, params?: Record<string, string>): string {
    let path = routePath;
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        path = path.replace(`:${key}`, value);
      });
    }
    return path;
  }

  getAllRoutes(): Route[] {
    return [...this.routes];
  }

  clearRoutes(): void {
    this.routes = [];
  }
}

const routeManager = new RouteManager();

// 注册默认路由
routeManager.registerRoutes([
  { path: '/', component: 'HomePage', title: '首页' },
  { path: '/playback/:id', component: 'PlaybackPage', title: '播放页面' },
  { path: '/settings', component: 'SettingsPage', title: '设置' },
  { path: '/category/:category', component: 'CategoryPage', title: '分类页面' }
]);

export { routeManager, RouteManager, Route, RouteMatch };