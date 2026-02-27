/**
 * 纯净演示页面
 * 使用最基础的组件
 */
import { Column, Text, Scroll } from '@ohos/arkui'
import { PureButton } from '../component/ui/PureButton'
import { PureCard } from '../component/ui/PureCard'

@Entry
@Component
struct PureDemoPage {
  build() {
    Scroll() {
      Column() {
        Text('纯净组件演示')
          .fontSize('24px')
          .fontWeight('bold')
          .margin({ bottom: '20px' })
        
        PureCard({
          title: '按钮演示'
        }) {
          Column() {
            PureButton({
              text: '测试按钮',
              onPress: () => {
                console.log('按钮被点击')
              }
            })
            .margin({ bottom: '12px' })
            
            PureButton({
              text: '另一个按钮',
              onPress: () => {
                console.log('第二个按钮被点击')
              }
            })
          }
          .width('100%')
        }
        
        PureCard({
          title: '卡片演示'
        }) {
          Column() {
            Text('这是卡片的基本内容')
              .fontSize('14px')
          }
          .width('100%')
        }
        .margin({ top: '16px' })
      }
      .width('100%')
      .padding('20px')
    }
    .width('100%')
    .height('100%')
  }
}