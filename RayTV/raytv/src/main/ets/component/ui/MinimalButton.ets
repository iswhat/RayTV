/**
 * 最小化按钮组件
 * 最基础的按钮实现
 */
import { Component, State, Prop } from '@ohos/arkui'

@Component
export struct MinimalButton {
  @Prop text: string = 'Button'
  @Prop onPress: () => void = () => {}
  
  @State isPressed: boolean = false
  
  build() {
    Stack({
      onClick: () => {
        if (!this.isPressed) {
          this.onPress()
        }
      }
    })
    .width('100%')
    .height('40px')
    .backgroundColor(this.isPressed ? '#0062CC' : '#007AFF')
    .borderRadius('8px')
    {
      Text(this.text)
        .fontSize('16px')
        .color('#FFFFFF')
        .fontWeight('500')
    }
    .onTouchDown(() => {
      this.isPressed = true
    })
    .onTouchUp(() => {
      this.isPressed = false
    })
    .onTouchCancel(() => {
      this.isPressed = false
    })
  }
}