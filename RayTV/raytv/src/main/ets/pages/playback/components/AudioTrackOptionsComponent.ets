import { Component, Text, Column, Button } from '@ohos/arkui';
import { AudioTrack } from '../types/PlaybackTypes';
import Logger from '../../../common/util/Logger';

interface AudioTrackOptionsComponentProps {
  showAudioTrackOptions: boolean;
  audioTracks: AudioTrack[];
  selectedAudioTrack: AudioTrack | null;
  onAudioTrackSelect: (track: AudioTrack) => void;
}

/**
 * 音轨选项组件 | Audio track options component
 * 展示音轨列表和选择功能
 */
@Component
export struct AudioTrackOptionsComponent {
  private readonly TAG: string = 'AudioTrackOptionsComponent';
  
  props: AudioTrackOptionsComponentProps;
  
  build() {
    if (this.props.showAudioTrackOptions) {
      Column() {
        Text('音轨选择')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        if (this.props.audioTracks.length === 0) {
          Text('未检测到多音轨')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 10 })
        } else {
          ForEach(this.props.audioTracks, (track: AudioTrack) => {
            Button() {
              Text(track.name || `音轨 ${track.id}`)
                .fontSize(14)
                .fontColor(track.id === this.props.selectedAudioTrack?.id ? '#FFFFFF' : '#333333')
                .fontWeight(track.id === this.props.selectedAudioTrack?.id ? 600 : 400)
            }
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .backgroundColor(track.id === this.props.selectedAudioTrack?.id ? '#4CAF50' : '#F5F5F5')
            .borderRadius(12)
            .margin({ bottom: 8, left: 10, right: 10 })
            .onClick(() => this.props.onAudioTrackSelect(track))
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, `Audio track focused: ${track.name}`);
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
