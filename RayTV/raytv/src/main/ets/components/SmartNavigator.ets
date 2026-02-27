import { FocusManager } from '../managers/FocusManager';
import { NavigationHistory } from '../managers/NavigationHistory';

/**
 * 智能导航组件
 * 提供键盘/遥控器友好的导航体验
 */
@Entry
@Component
struct SmartNavigator {
  @State private currentIndex: number = 0;
  @State private isNavigating: boolean = false;
  @State private navigationPath: string[] = [];
  
  private focusManager: FocusManager = FocusManager.getInstance();
  private navHistory: NavigationHistory = NavigationHistory.getInstance();
  private navigationTimer: number | null = null;

  // 组件属性
  @Prop routes: RouteConfig[] = [];
  @Prop initialRoute: string = '';
  @Prop enableHistory: boolean = true;
  @Prop transitionDuration: number = 300;
  @Prop onNavigate?: (from: string, to: string) => void;
  @Prop onBack?: () => void;

  aboutToAppear(): void {
    this.initializeNavigation();
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  private initializeNavigation(): void {
    // 设置初始路由
    const initialIndex = this.routes.findIndex(route => route.path === this.initialRoute);
    if (initialIndex !== -1) {
      this.currentIndex = initialIndex;
      this.navigationPath.push(this.initialRoute);
    }
    
    // 初始化焦点管理
    this.focusManager.initialize();
  }

  /**
   * 导航到指定路由
   */
  navigateTo(path: string, params?: any): void {
    const targetIndex = this.routes.findIndex(route => route.path === path);
    if (targetIndex === -1 || targetIndex === this.currentIndex) {
      return;
    }

    const fromRoute = this.routes[this.currentIndex]?.path || '';
    const toRoute = this.routes[targetIndex].path;

    // 记录历史
    if (this.enableHistory) {
      this.navHistory.push({
        path: fromRoute,
        timestamp: Date.now(),
        params: params
      });
      this.navigationPath.push(toRoute);
    }

    // 执行导航
    this.performNavigation(targetIndex, fromRoute, toRoute);
  }

  /**
   * 返回上一页
   */
  goBack(): boolean {
    if (!this.enableHistory || this.navigationPath.length <= 1) {
      this.onBack?.();
      return false;
    }

    this.navigationPath.pop(); // 移除当前路径
    const previousPath = this.navigationPath[this.navigationPath.length - 1];
    const previousIndex = this.routes.findIndex(route => route.path === previousPath);

    if (previousIndex !== -1) {
      const currentPath = this.routes[this.currentIndex].path;
      this.performNavigation(previousIndex, currentPath, previousPath);
      return true;
    }

    return false;
  }

  /**
   * 执行导航动画
   */
  private performNavigation(targetIndex: number, fromRoute: string, toRoute: string): void {
    if (this.isNavigating) return;

    this.isNavigating = true;
    
    // 触发导航事件
    this.onNavigate?.(fromRoute, toRoute);

    // 模拟导航动画
    setTimeout(() => {
      this.currentIndex = targetIndex;
      this.isNavigating = false;
      
      // 更新焦点
      this.focusManager.requestFocus(toRoute);
    }, this.transitionDuration);
  }

  /**
   * 处理键盘/遥控器输入
   */
  private handleNavigationInput(direction: NavigationDirection): void {
    if (this.isNavigating) return;

    switch (direction) {
      case NavigationDirection.LEFT:
        this.navigatePrevious();
        break;
      case NavigationDirection.RIGHT:
        this.navigateNext();
        break;
      case NavigationDirection.ENTER:
        this.activateCurrentRoute();
        break;
      case NavigationDirection.BACK:
        this.goBack();
        break;
    }
  }

  private navigatePrevious(): void {
    if (this.currentIndex > 0) {
      const newPath = this.routes[this.currentIndex - 1].path;
      this.navigateTo(newPath);
    }
  }

  private navigateNext(): void {
    if (this.currentIndex < this.routes.length - 1) {
      const newPath = this.routes[this.currentIndex + 1].path;
      this.navigateTo(newPath);
    }
  }

  private activateCurrentRoute(): void {
    const currentRoute = this.routes[this.currentIndex];
    if (currentRoute.action) {
      currentRoute.action();
    }
  }

  private cleanup(): void {
    if (this.navigationTimer) {
      clearTimeout(this.navigationTimer);
      this.navigationTimer = null;
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        ForEach(this.routes, (route: RouteConfig, index: number) => {
          Button(route.label)
            .key(`nav-${route.path}`)
            .type(ButtonType.Normal)
            .borderRadius(8)
            .backgroundColor(index === this.currentIndex ? '#007AFF' : '#f0f0f0')
            .fontColor(index === this.currentIndex ? '#ffffff' : '#333333')
            .onClick(() => {
              this.navigateTo(route.path);
            })
            .margin({ right: 12 })
            .focusable(true)
            .onFocus(() => {
              this.focusManager.setFocusedElement(`nav-${route.path}`);
            })
        })
      }
      .padding(16)
      .backgroundColor('#ffffff')
      .shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 })

      // 内容区域
      Stack() {
        ForEach(this.routes, (route: RouteConfig, index: number) => {
          Column() {
            if (index === this.currentIndex) {
              route.component()
            }
          }
          .key(`content-${route.path}`)
          .opacity(index === this.currentIndex ? 1 : 0)
          .animation({
            duration: this.transitionDuration,
            curve: Curve.EaseInOut
          })
        })
      }
      .layoutWeight(1)

      // 焦点指示器
      if (this.focusManager.hasFocusedElement()) {
        Row() {
          Text(`.Focused: ${this.focusManager.getFocusedElement()}`)
            .fontSize(12)
            .fontColor('#666666')
        }
        .padding({ top: 8, left: 16, right: 16, bottom: 8 })
        .backgroundColor('#f8f8f8')
      }
    }
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down) {
        switch (event.keyCode) {
          case KeyCode.KEYCODE_DPAD_LEFT:
            this.handleNavigationInput(NavigationDirection.LEFT);
            return true;
          case KeyCode.KEYCODE_DPAD_RIGHT:
            this.handleNavigationInput(NavigationDirection.RIGHT);
            return true;
          case KeyCode.KEYCODE_DPAD_CENTER:
          case KeyCode.KEYCODE_ENTER:
            this.handleNavigationInput(NavigationDirection.ENTER);
            return true;
          case KeyCode.KEYCODE_BACK:
            this.handleNavigationInput(NavigationDirection.BACK);
            return true;
        }
      }
      return false;
    })
  }
}

/**
 * 路由配置接口
 */
interface RouteConfig {
  /** 路由路径 */
  path: string;
  
  /** 显示标签 */
  label: string;
  
  /** 组件 */
  component: () => CustomComponent;
  
  /** 自定义动作 */
  action?: () => void;
  
  /** 是否可访问 */
  enabled?: boolean;
}

/**
 * 导航方向枚举
 */
enum NavigationDirection {
  LEFT = 'left',
  RIGHT = 'right',
  UP = 'up',
  DOWN = 'down',
  ENTER = 'enter',
  BACK = 'back'
}