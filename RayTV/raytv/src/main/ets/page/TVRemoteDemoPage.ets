/**
 * TV遥控器交互演示页面
 * 展示TV友好的交互组件和遥控器支持
 */
import { Component, State } from '@ohos/arkui'
import { TVFriendlyPage } from './TVFriendlyPage'
import { TVGrid, GridItem } from '../component/tv/TVGrid'
import { TVNavigationMenu, MenuItem } from '../component/tv/TVNavigationMenu'
import { RemoteControlManager } from '../component/tv/RemoteControlManager'

@Entry
@Component
struct TVRemoteDemoPage extends TVFriendlyPage {
  @State gridItems: GridItem[] = []
  @State menuItems: MenuItem[] = []
  @State selectedContent: string = '请选择内容'
  
  private remoteManager: RemoteControlManager = RemoteControlManager.getInstance()
  
  aboutToAppear() {
    super.aboutToAppear()
    
    // 初始化网格数据
    this.gridItems = Array.from({ length: 12 }, (_, i) => ({
      id: `item_${i + 1}`,
      data: { title: `内容 ${i + 1}`, description: `这是内容项 ${i + 1}` }
    }))
    
    // 初始化菜单数据
    this.menuItems = [
      { id: 'home', label: '首页', icon: '🏠' },
      { id: 'movies', label: '电影', icon: '🎬' },
      { id: 'tv', label: '电视剧', icon: '📺' },
      { id: 'sports', label: '体育', icon: '⚽' },
      { id: 'music', label: '音乐', icon: '🎵' },
      { id: 'settings', label: '设置', icon: '⚙️' }
    ]
    
    // 设置焦点到第一个网格项
    if (this.gridItems.length > 0) {
      this.remoteManager.setFocus(this.gridItems[0].id)
    }
  }
  
  protected getPageTitle(): string {
    return 'TV遥控器演示'
  }
  
  protected renderSideMenu() {
    TVNavigationMenu({
      items: this.menuItems,
      onItemSelected: (item: MenuItem) => {
        this.selectedContent = `选择了菜单项: ${item.label}`
      },
      width: '100%'
    })
  }
  
  protected renderMainContent() {
    Column() {
      // 状态显示
      Text(`当前选择: ${this.selectedContent}`)
        .fontSize('18px')
        .fontWeight('500')
        .color('#333333')
        .margin({ bottom: '20px' })
      
      // 网格内容
      Text('内容网格 (使用方向键导航)')
        .fontSize('20px')
        .fontWeight('bold')
        .color('#007AFF')
        .margin({ bottom: '16px' })
      
      TVGrid({
        items: this.gridItems,
        columns: 4,
        itemHeight: '100px',
        gap: '12px',
        onItemFocus: (item: GridItem) => {
          this.selectedContent = `聚焦到: ${item.data.title}`
        },
        onItemClick: (item: GridItem) => {
          this.selectedContent = `点击了: ${item.data.title} - ${item.data.description}`
        }
      })
      .width('100%')
      .margin({ bottom: '30px' })
      
      // 操作说明
      Column() {
        Text('操作说明:')
          .fontSize('18px')
          .fontWeight('bold')
          .color('#333333')
          .margin({ bottom: '12px' })
        
        Column() {
          Text('• 方向键: 在网格项之间导航')
            .fontSize('16px')
            .color('#666666')
            .margin({ bottom: '8px' })
          Text('• 确认键: 选择当前聚焦的项目')
            .fontSize('16px')
            .color('#666666')
            .margin({ bottom: '8px' })
          Text('• 返回键: 返回上一级')
            .fontSize('16px')
            .color('#666666')
            .margin({ bottom: '8px' })
          Text('• 菜单按钮: 切换左侧导航菜单')
            .fontSize('16px')
            .color('#666666')
        }
        .width('100%')
        .padding('16px')
        .backgroundColor('#F5F5F5')
        .borderRadius('8px')
      }
      .width('100%')
    }
    .width('100%')
  }
  
  private handleBackAction = (): void => {
    this.selectedContent = '返回键被按下'
    // 这里可以添加实际的返回逻辑
  }
}