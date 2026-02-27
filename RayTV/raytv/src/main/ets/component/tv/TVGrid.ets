/**
 * TV友好的网格布局组件
 * 专门为遥控器导航优化的网格布局
 */
import { Component, State, Prop, Builder } from '@ohos/arkui'
import { RemoteControlManager } from './RemoteControlManager'

export interface GridItem {
  id: string
  data: any
}

@Component
export struct TVGrid {
  @Prop items: GridItem[] = []
  @Prop columns: number = 3
  @Prop itemHeight: string = '120px'
  @Prop gap: string = '16px'
  @Prop onItemFocus: (item: GridItem) => void = () => {}
  @Prop onItemClick: (item: GridItem) => void = () => {}
  
  @State focusedItemId: string = ''
  
  private remoteManager: RemoteControlManager = RemoteControlManager.getInstance()
  
  aboutToAppear() {
    // 监听焦点变化
    this.remoteManager.addEventListener('focusChange', this.handleFocusChange)
    this.remoteManager.addEventListener('itemClick', this.handleItemClick)
  }
  
  aboutToDisappear() {
    this.remoteManager.removeEventListener('focusChange', this.handleFocusChange)
    this.remoteManager.removeEventListener('itemClick', this.handleItemClick)
  }
  
  private handleFocusChange = (focusedId: string) => {
    // 检查是否是网格中的项目
    const focusedItem = this.items.find(item => item.id === focusedId)
    if (focusedItem) {
      this.focusedItemId = focusedId
      this.onItemFocus(focusedItem)
    }
  }
  
  private handleItemClick = (clickedId: string) => {
    const clickedItem = this.items.find(item => item.id === clickedId)
    if (clickedItem) {
      this.onItemClick(clickedItem)
    }
  }
  
  build() {
    Grid()
    .columnsTemplate(`repeat(${this.columns}, 1fr)`)
    .rowsTemplate('1fr')
    .columnsGap(this.gap)
    .rowsGap(this.gap)
    .width('100%')
    {
      ForEach(this.items, (item: GridItem) => {
        this.renderGridItem(item)
      }, (item: GridItem) => item.id)
    }
  }
  
  @Builder
  private renderGridItem(item: GridItem) {
    // 这里应该使用FocusableContainer或其他可聚焦组件
    Stack()
    .width('100%')
    .height(this.itemHeight)
    .backgroundColor('#F5F5F5')
    .borderRadius('8px')
    .border({
      width: this.focusedItemId === item.id ? '3px' : '1px',
      color: this.focusedItemId === item.id ? '#007AFF' : '#CCCCCC'
    })
    {
      Text(`Item: ${item.id}`)
        .fontSize('16px')
        .color('#333333')
    }
    .onClick(() => {
      this.remoteManager.setFocus(item.id)
      this.onItemClick(item)
    })
  }
}