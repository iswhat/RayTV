/**
 * 基础TV页面
 */
import { Component, State } from '@ohos/arkui'
import { BasicTVGrid } from '../component/tv/BasicTVGrid'

@Entry
@Component
struct BasicTVPage {
  @State items: any[] = []
  @State selectedContent: string = '请选择内容'
  
  aboutToAppear() {
    this.items = Array.from({ length: 9 }, (_, i) => ({
      id: i + 1,
      title: `内容 ${i + 1}`
    }))
  }
  
  build() {
    Column() {
      Text('TV遥控器演示')
        .margin({ bottom: '20px' })
      
      Text(`当前选择: ${this.selectedContent}`)
        .margin({ bottom: '20px' })
      
      BasicTVGrid({
        items: this.items,
        onItemClick: (item: any) => {
          this.selectedContent = `选择了: ${item.title}`
        }
      })
    }
    .padding('20px')
  }
}