/**
 * 基础演示页面
 * 展示最基础的组件使用
 */
import { Column, Text, Scroll } from '@ohos/arkui'
import { BasicButton } from '../component/ui/BasicButton'
import { BasicCard } from '../component/ui/BasicCard'

@Entry
@Component
struct BasicDemoPage {
  build() {
    Scroll() {
      Column() {
        Text('基础组件演示')
          .margin({ bottom: '20px' })
        
        BasicCard({
          title: '按钮演示'
        }) {
          Column() {
            BasicButton({
              text: '测试',
              onPress: () => {
                console.log('按钮点击')
              }
            })
            .margin({ bottom: '12px' })
            
            BasicButton({
              text: '按钮2',
              onPress: () => {
                console.log('按钮2点击')
              }
            })
          }
        }
        
        BasicCard({
          title: '卡片演示'
        }) {
          Column() {
            Text('卡片内容')
          }
        }
        .margin({ top: '16px' })
      }
      .padding('20px')
    }
  }
}