/**
 * 基础按钮组件
 * 使用最基础的ArkTS语法
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct BasicButton {
  @Prop text: string = 'Button'
  @Prop onPress: () => void = () => {}
  
  private handleClick(): void {
    this.onPress()
  }
  
  build() {
    Stack()
    {
      Text(this.text)
    }
    .onClick(() => this.handleClick())
  }
}