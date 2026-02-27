/**
 * 简化版TV页面
 */
import { Component, State } from '@ohos/arkui'
import { SimpleTVGrid } from '../component/tv/SimpleTVGrid'

@Entry
@Component
struct SimpleTVPage {
  @State items: any[] = []
  @State selectedContent: string = '请选择内容'
  
  aboutToAppear() {
    // 初始化数据
    this.items = Array.from({ length: 12 }, (_, i) => ({
      id: i + 1,
      title: `内容 ${i + 1}`,
      description: `这是内容项 ${i + 1}`
    }))
  }
  
  build() {
    Column() {
      // 标题
      Text('TV遥控器演示')
        .fontSize('24px')
        .fontWeight('bold')
        .color('#333333')
        .margin({ bottom: '20px' })
      
      // 状态显示
      Text(`当前选择: ${this.selectedContent}`)
        .fontSize('18px')
        .fontWeight('500')
        .color('#007AFF')
        .margin({ bottom: '20px' })
      
      // 网格内容
      Text('内容网格')
        .fontSize('20px')
        .fontWeight('bold')
        .color('#666666')
        .margin({ bottom: '16px' })
      
      SimpleTVGrid({
        items: this.items,
        columns: 4,
        onItemClick: (item: any) => {
          this.selectedContent = `选择了: ${item.title}`
        }
      })
      
      // 说明
      Column() {
        Text('TV遥控器操作说明:')
          .fontSize('16px')
          .fontWeight('bold')
          .color('#333333')
          .margin({ bottom: '12px' })
        
        Text('• 使用遥控器方向键在网格间导航')
          .fontSize('14px')
          .color('#666666')
          .margin({ bottom: '8px' })
        Text('• 按确认键选择项目')
          .fontSize('14px')
          .color('#666666')
          .margin({ bottom: '8px' })
        Text('• 按返回键退出')
          .fontSize('14px')
          .color('#666666')
      }
      .width('100%')
      .padding('16px')
      .backgroundColor('#F8F8F8')
      .borderRadius('8px')
      .margin({ top: '30px' })
    }
    .width('100%')
    .height('100%')
    .padding('20px')
    .backgroundColor('#FFFFFF')
  }
}