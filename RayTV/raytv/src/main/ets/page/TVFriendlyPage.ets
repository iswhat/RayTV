/**
 * TV友好的页面模板
 * 提供标准的TV页面布局和遥控器交互支持
 */
import { Component, State, Builder } from '@ohos/arkui'
import { RemoteControlManager } from '../component/tv/RemoteControlManager'
import { RemoteEventHandler } from '../component/tv/RemoteEventHandler'

@Component
export struct TVFriendlyPage {
  @State pageTitle: string = 'TV页面'
  @State showMenu: boolean = false
  
  private remoteManager: RemoteControlManager = RemoteControlManager.getInstance()
  private eventHandler: RemoteEventHandler = RemoteEventHandler.getInstance()
  
  aboutToAppear() {
    // 设置页面标题
    this.pageTitle = this.getPageTitle()
    
    // 监听返回键事件
    this.remoteManager.addEventListener('backAction', this.handleBackAction)
    
    // 初始化遥控器事件处理
    this.setupRemoteControlEvents()
  }
  
  aboutToDisappear() {
    this.remoteManager.removeEventListener('backAction', this.handleBackAction)
  }
  
  /**
   * 子类应该重写此方法提供页面标题
   */
  protected getPageTitle(): string {
    return 'TV页面'
  }
  
  /**
   * 子类应该重写此方法提供主要内容
   */
  @Builder
  protected renderMainContent() {
    Text('请在子类中实现主要内容')
      .fontSize('16px')
      .color('#666666')
  }
  
  /**
   * 子类可以重写此方法提供左侧菜单
   */
  @Builder
  protected renderSideMenu() {
    // 默认空实现
  }
  
  /**
   * 子类可以重写此方法提供顶部导航
   */
  @Builder
  protected renderTopNavigation() {
    Text(this.pageTitle)
      .fontSize('24px')
      .fontWeight('bold')
      .color('#333333')
  }
  
  /**
   * 设置遥控器事件处理
   */
  private setupRemoteControlEvents(): void {
    // 这里可以添加特定页面的遥控器事件处理逻辑
    console.log('TV页面遥控器事件已设置')
  }
  
  /**
   * 处理返回键操作
   */
  private handleBackAction = (): void => {
    // 默认返回逻辑，子类可以重写
    console.log('返回键被按下')
  }
  
  /**
   * 切换菜单显示状态
   */
  protected toggleMenu(): void {
    this.showMenu = !this.showMenu
  }
  
  build() {
    Row() {
      // 左侧菜单区域
      if (this.showMenu) {
        Column() {
          this.renderSideMenu()
        }
        .width('250px')
        .height('100%')
        .backgroundColor('#F8F8F8')
        .border({ 
          width: '1px', 
          color: '#E0E0E0',
          side: 'end'
        })
      }
      
      // 主内容区域
      Column() {
        // 顶部导航
        Row() {
          this.renderTopNavigation()
          
          // 菜单切换按钮
          Button('菜单')
            .fontSize('14px')
            .backgroundColor('#007AFF')
            .fontColor('#FFFFFF')
            .borderRadius('6px')
            .padding({ left: '12px', right: '12px', top: '6px', bottom: '6px' })
            .margin({ left: '16px' })
            .onClick(() => this.toggleMenu())
        }
        .width('100%')
        .height('60px')
        .padding('16px')
        .backgroundColor('#FFFFFF')
        .border({ 
          width: '1px', 
          color: '#E0E0E0',
          side: 'bottom'
        })
        
        // 主要内容
        Scroll() {
          Column() {
            this.renderMainContent()
          }
          .width('100%')
          .padding('20px')
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width(this.showMenu ? 'calc(100% - 250px)' : '100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}