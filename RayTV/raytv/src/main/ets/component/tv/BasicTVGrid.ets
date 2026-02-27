/**
 * 基础TV网格组件
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct BasicTVGrid {
  @Prop items: any[] = []
  @Prop onItemClick: (item: any) => void = () => {}
  
  build() {
    Grid()
    {
      ForEach(this.items, (item: any, index: number) => {
        Stack()
        {
          Text(item.title || `Item ${index + 1}`)
        }
        .onClick(() => this.onItemClick(item))
      })
    }
  }
}