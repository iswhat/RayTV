// 面包屑导航组件 | Breadcrumb navigation component
// 显示当前页面的导航路径，支持点击导航到历史页面

import { AppNavigator, BreadcrumbItem } from '../navigation/AppNavigator';
import { Row, Column, Text, Button, FlexAlign } from '@ohos/arkui';

// 面包屑导航组件参数 | Breadcrumb navigation component parameters
interface BreadcrumbNavigationParams {
  showHome?: boolean; // 是否显示首页面包屑 | Whether to show home breadcrumb
  maxItems?: number; // 最大显示的面包屑项数 | Maximum number of breadcrumb items to show
  separator?: string; // 面包屑分隔符 | Breadcrumb separator
}

@Component
export struct BreadcrumbNavigation {
  private readonly TAG: string = 'BreadcrumbNavigation';
  private appNavigator: AppNavigator = AppNavigator.getInstance();
  
  // 参数 | Parameters
  @Prop showHome: boolean = true;
  @Prop maxItems: number = 5;
  @Prop separator: string = '>';
  
  // 状态 | State
  @State breadcrumbs: BreadcrumbItem[] = [];
  
  constructor(params?: BreadcrumbNavigationParams) {
    if (params) {
      this.showHome = params.showHome !== undefined ? params.showHome : true;
      this.maxItems = params.maxItems !== undefined ? params.maxItems : 5;
      this.separator = params.separator !== undefined ? params.separator : '>';
    }
    this.updateBreadcrumbs();
  }
  
  // 更新面包屑数据 | Update breadcrumb data
  private updateBreadcrumbs(): void {
    this.breadcrumbs = this.appNavigator.getBreadcrumbs();
  }
  
  // 处理面包屑点击 | Handle breadcrumb click
  private async handleBreadcrumbClick(index: number): Promise<void> {
    await this.appNavigator.navigateToBreadcrumb(index);
  }
  
  // 渲染面包屑项 | Render breadcrumb item
  @Builder
  private renderBreadcrumbItem(item: BreadcrumbItem, index: number, isLast: boolean) {
    Column() {
      Text(item.title)
        .fontSize(14)
        .fontColor(isLast ? '#333333' : '#007AFF')
        .fontWeight(isLast ? 600 : 400)
        .margin({ horizontal: 8 })
    }
    .onClick(() => {
      if (!isLast) {
        this.handleBreadcrumbClick(index);
      }
    })
  }
  
  // 渲染分隔符 | Render separator
  @Builder
  private renderSeparator() {
    Text(this.separator)
      .fontSize(14)
      .fontColor('#666666')
      .margin({ horizontal: 4 })
  }
  
  build() {
    Row() {
      // 更新面包屑数据
      this.updateBreadcrumbs();
      
      // 限制显示的面包屑项数
      let displayBreadcrumbs = this.breadcrumbs;
      if (displayBreadcrumbs.length > this.maxItems) {
        // 只显示首页和最后几个面包屑项
        const startItems = this.showHome ? [displayBreadcrumbs[0]] : [];
        const endItems = displayBreadcrumbs.slice(-(this.maxItems - startItems.length));
        displayBreadcrumbs = [...startItems, ...endItems];
      }
      
      // 渲染面包屑项
      ForEach(displayBreadcrumbs, (item: BreadcrumbItem, index: number) => {
        const isLast = index === displayBreadcrumbs.length - 1;
        this.renderBreadcrumbItem(item, index, isLast);
        if (!isLast) {
          this.renderSeparator();
        }
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#F5F5F5')
  }
}

export default BreadcrumbNavigation;