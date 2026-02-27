/**
 * 简化版TV网格组件
 */
import { Component, State, Prop } from '@ohos/arkui'

@Component
export struct SimpleTVGrid {
  @Prop items: any[] = []
  @Prop columns: number = 3
  @Prop onItemClick: (item: any) => void = () => {}
  
  build() {
    Grid()
    .columnsTemplate(`repeat(${this.columns}, 1fr)`)
    .rowsTemplate('1fr')
    .columnsGap('16px')
    .rowsGap('16px')
    .width('100%')
    {
      ForEach(this.items, (item: any, index: number) => {
        Stack()
        .width('100%')
        .height('120px')
        .backgroundColor('#F5F5F5')
        .borderRadius('8px')
        {
          Text(item.title || `Item ${index + 1}`)
            .fontSize('16px')
            .color('#333333')
        }
        .onClick(() => this.onItemClick(item))
      })
    }
  }
}