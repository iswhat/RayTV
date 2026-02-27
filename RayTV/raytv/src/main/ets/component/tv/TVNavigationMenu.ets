/**
 * TV导航菜单组件
 * 为TV遥控器优化的垂直导航菜单
 */
import { Component, State, Prop } from '@ohos/arkui'
import { RemoteControlManager } from './RemoteControlManager'

export interface MenuItem {
  id: string
  label: string
  icon?: string
  disabled?: boolean
}

@Component
export struct TVNavigationMenu {
  @Prop items: MenuItem[] = []
  @Prop onItemSelected: (item: MenuItem) => void = () => {}
  @Prop width: string = '200px'
  
  @State selectedIndex: number = 0
  @State focusedIndex: number = 0
  
  private remoteManager: RemoteControlManager = RemoteControlManager.getInstance()
  
  aboutToAppear() {
    // 监听遥控器事件
    this.remoteManager.addEventListener('focusChange', this.handleFocusChange)
    this.remoteManager.addEventListener('itemClick', this.handleItemClick)
  }
  
  aboutToDisappear() {
    this.remoteManager.removeEventListener('focusChange', this.handleFocusChange)
    this.remoteManager.removeEventListener('itemClick', this.handleItemClick)
  }
  
  private handleFocusChange = (focusedId: string) => {
    // 根据ID找到对应的索引
    const index = this.items.findIndex((item, idx) => `menu_${idx}` === focusedId)
    if (index !== -1 && index !== this.focusedIndex) {
      this.focusedIndex = index
    }
  }
  
  private handleItemClick = (clickedId: string) => {
    const index = this.items.findIndex((item, idx) => `menu_${idx}` === clickedId)
    if (index !== -1) {
      this.selectItem(index)
    }
  }
  
  private selectItem(index: number): void {
    if (index >= 0 && index < this.items.length && !this.items[index].disabled) {
      this.selectedIndex = index
      this.onItemSelected(this.items[index])
    }
  }
  
  private handleKeyDown(key: string): void {
    switch (key) {
      case 'up':
        this.navigateUp()
        break
      case 'down':
        this.navigateDown()
        break
      case 'enter':
        this.selectCurrentItem()
        break
    }
  }
  
  private navigateUp(): void {
    if (this.focusedIndex > 0) {
      this.focusedIndex--
      this.remoteManager.setFocus(`menu_${this.focusedIndex}`)
    }
  }
  
  private navigateDown(): void {
    if (this.focusedIndex < this.items.length - 1) {
      this.focusedIndex++
      this.remoteManager.setFocus(`menu_${this.focusedIndex}`)
    }
  }
  
  private selectCurrentItem(): void {
    this.selectItem(this.focusedIndex)
  }
  
  build() {
    Column()
    .width(this.width)
    .backgroundColor('#FFFFFF')
    .borderRadius('12px')
    .elevation(4)
    {
      ForEach(this.items, (item: MenuItem, index: number) => {
        this.renderMenuItem(item, index)
      }, (item: MenuItem) => item.id)
    }
  }
  
  @Builder
  private renderMenuItem(item: MenuItem, index: number) {
    Stack()
    .width('100%')
    .height('50px')
    .backgroundColor(index === this.selectedIndex ? '#007AFF' : 
                     index === this.focusedIndex ? '#E5E5EA' : '#FFFFFF')
    .padding('12px')
    {
      Row() {
        if (item.icon) {
          Text(item.icon)
            .fontSize('18px')
            .margin({ right: '8px' })
        }
        
        Text(item.label)
          .fontSize('16px')
          .color(item.disabled ? '#CCCCCC' : 
                 index === this.selectedIndex ? '#FFFFFF' : '#333333')
          .layoutWeight(1)
      }
      .width('100%')
    }
    .onClick(() => {
      if (!item.disabled) {
        this.remoteManager.setFocus(`menu_${index}`)
        this.selectItem(index)
      }
    })
  }
}