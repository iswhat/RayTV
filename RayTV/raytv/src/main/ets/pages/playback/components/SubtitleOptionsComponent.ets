import { Component, FlexAlign, Text, Row, Column, Button } from '@ohos/arkui';
import { SubtitleTrack } from '../../../service/media/SubtitleService';
import Logger from '../../../common/util/Logger';

interface SubtitleOptionsComponentProps {
  showSubtitleOptions: boolean;
  subtitleTracks: SubtitleTrack[];
  selectedSubtitle: SubtitleTrack | null;
  isSearchingSubtitles: boolean;
  onSubtitleSelect: (track: SubtitleTrack) => void;
  onSubtitleStyleChange: () => void;
}

/**
 * 字幕选项组件 | Subtitle options component
 * 展示字幕轨道列表和样式设置
 */
@Component
export struct SubtitleOptionsComponent {
  private readonly TAG: string = 'SubtitleOptionsComponent';
  
  props: SubtitleOptionsComponentProps;
  
  build() {
    if (this.props.showSubtitleOptions) {
      Column() {
        Text('字幕选项')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        // 字幕轨道列表 | Subtitle track list
        Column() {
          Text('可用字幕')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          if (this.props.isSearchingSubtitles) {
            Text('搜索字幕中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 10 })
          } else if (this.props.subtitleTracks.length === 0) {
            Text('未找到字幕')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 10 })
          } else {
            ForEach(this.props.subtitleTracks, (track: SubtitleTrack) => {
              Button() {
                Text(track.name)
                  .fontSize(14)
                  .fontColor(track.id === this.props.selectedSubtitle?.id ? '#FFFFFF' : '#333333')
                  .fontWeight(track.id === this.props.selectedSubtitle?.id ? 600 : 400)
              }
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor(track.id === this.props.selectedSubtitle?.id ? '#4CAF50' : '#F5F5F5')
              .borderRadius(12)
              .margin({ bottom: 8, left: 10, right: 10 })
              .onClick(() => this.props.onSubtitleSelect(track))
              .focusable(true)
              .onFocus(() => {
                Logger.info(this.TAG, `Subtitle track focused: ${track.name}`);
              })
            })
          }
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 字幕样式设置 | Subtitle style settings
        Column() {
          Text('字幕样式')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          Row() {
            Button() {
              Text('默认样式')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(500)
            }
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .backgroundColor('#2196F3')
            .borderRadius(12)
            .margin({ left: 10, right: 10 })
            .onClick(() => this.props.onSubtitleStyleChange())
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Default style button focused');
            })
          }
        }
        .width('100%')
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
