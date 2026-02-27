import { Component, Text, Row, Column, Button } from '@ohos/arkui';
import Logger from '../../../common/util/Logger';

interface PlaybackSpeedComponentProps {
  showMoreOptions: boolean;
  playbackSpeed: number;
  onSpeedChange: (speed: number) => void;
}

/**
 * 播放速度选项组件 | Playback speed component
 * 展示播放速度选择
 */
@Component
export struct PlaybackSpeedComponent {
  private readonly TAG: string = 'PlaybackSpeedComponent';
  
  props: PlaybackSpeedComponentProps;
  
  build() {
    if (this.props.showMoreOptions) {
      Column() {
        Text('播放速度')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        Row() {
          ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], (speed: number) => {
            Button() {
              Text(`${speed}x`)
                .fontSize(16)
                .fontColor(speed === this.props.playbackSpeed ? '#FFFFFF' : '#333333')
                .fontWeight(speed === this.props.playbackSpeed ? 600 : 400)
            }
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .backgroundColor(speed === this.props.playbackSpeed ? '#4CAF50' : '#F5F5F5')
            .borderRadius(20)
            .margin({ right: 15 })
            .onClick(() => this.props.onSpeedChange(speed))
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, `Speed ${speed}x focused`);
            })
          })
        }
      }
      .width('100%')
      .padding(25)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 15, right: 30, left: 30 })
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })
    }
  }
}
