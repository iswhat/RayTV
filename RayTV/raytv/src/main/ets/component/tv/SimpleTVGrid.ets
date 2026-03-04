/**
 * 简化版TV网格组件
 */
import { Component, State, Prop } from '@ohos/arkui'

export interface GridItem {
  id: string;
  title: string;
  cover?: string;
  description?: string;
  rating?: string;
  tags?: string[];
  isFavorite?: boolean;
}

@Component
export struct SimpleTVGrid {
  @Prop items: GridItem[] = []
  @Prop columns: number = 3
  @Prop onItemClick: (item: GridItem) => void = () => {}
  
  build() {
    Grid()
    .columnsTemplate(`repeat(${this.columns}, 1fr)`)
    .rowsTemplate('1fr')
    .columnsGap('16px')
    .rowsGap('16px')
    .width('100%')
    {
      ForEach(this.items, (item: GridItem, index: number) => {
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