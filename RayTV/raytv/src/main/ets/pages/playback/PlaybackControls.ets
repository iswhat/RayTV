/**
 * PlaybackControls.ets - 播放控制组件
 * 处理视频播放控制相关的功能
 */

import { PlaybackService } from '../../service/playback/PlaybackService';
import { TimerManager } from '../../common/util/TimerManager';
import Logger from '../../common/util/Logger';
import { KeyEvent, FocusStyle, FlexAlign, FlexDirection, TextAlign } from '@ohos/arkui';
import { AudioTrack } from '../PlaybackPage';

// 播放控制组件参数 | Playback controls component parameters
interface PlaybackControlsParams {
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  progress: number;
  showControls: boolean;
  selectedSubtitle: any;
  showSkipOptions: boolean;
  showSubtitleOptions: boolean;
  showAudioTrackOptions: boolean;
  audioTracks: AudioTrack[];
  selectedAudioTrack: AudioTrack | null;
  videoPlayerHeight: number;
  onPlayPause: () => void;
  onFastForward: (seconds: number) => void;
  onRewind: (seconds: number) => void;
  onShowSkipOptions: () => void;
  onShowSubtitleOptions: () => void;
  onShowAudioTrackOptions: () => void;
  onKeyEvent: (e: KeyEvent) => boolean;
}

@Component
export struct PlaybackControls {
  private readonly TAG: string = 'PlaybackControls';
  
  // 参数 | Parameters
  @Prop isPlaying: boolean;
  @Prop currentTime: number;
  @Prop duration: number;
  @Prop progress: number;
  @Prop showControls: boolean;
  @Prop selectedSubtitle: any;
  @Prop showSkipOptions: boolean;
  @Prop showSubtitleOptions: boolean;
  @Prop showAudioTrackOptions: boolean;
  @Prop audioTracks: AudioTrack[];
  @Prop selectedAudioTrack: AudioTrack | null;
  @Prop videoPlayerHeight: number;
  
  // 回调函数 | Callback functions
  private onPlayPause: () => void;
  private onFastForward: (seconds: number) => void;
  private onRewind: (seconds: number) => void;
  private onShowSkipOptions: () => void;
  private onShowSubtitleOptions: () => void;
  private onShowAudioTrackOptions: () => void;
  private onKeyEvent: (e: KeyEvent) => boolean;
  
  // 构造函数 | Constructor
  constructor(params: PlaybackControlsParams) {
    this.isPlaying = params.isPlaying;
    this.currentTime = params.currentTime;
    this.duration = params.duration;
    this.progress = params.progress;
    this.showControls = params.showControls;
    this.selectedSubtitle = params.selectedSubtitle;
    this.showSkipOptions = params.showSkipOptions;
    this.showSubtitleOptions = params.showSubtitleOptions;
    this.showAudioTrackOptions = params.showAudioTrackOptions;
    this.audioTracks = params.audioTracks;
    this.selectedAudioTrack = params.selectedAudioTrack;
    this.videoPlayerHeight = params.videoPlayerHeight;
    this.onPlayPause = params.onPlayPause;
    this.onFastForward = params.onFastForward;
    this.onRewind = params.onRewind;
    this.onShowSkipOptions = params.onShowSkipOptions;
    this.onShowSubtitleOptions = params.onShowSubtitleOptions;
    this.onShowAudioTrackOptions = params.onShowAudioTrackOptions;
    this.onKeyEvent = params.onKeyEvent;
  }
  
  // 焦点样式 | Focus style
  private focusStyle: FocusStyle = {
    border: {
      width: 3,
      color: '#4CAF50',
      radius: 8
    },
    shadow: {
      color: '#4CAF50',
      radius: 10,
      offsetX: 0,
      offsetY: 0
    }
  };
  
  // 格式化时间 | Format time
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  
  build() {
    if (this.showControls) {
      Column() {
        // 顶部进度条区域 | Top progress bar area
        Column() {
          Row() {
            Text(this.formatTime(this.currentTime))
              .fontSize(16)
              .fontColor('#FFFFFF')
              .margin({ right: 16 })
            
            // 进度条轨道 | Progress bar track
            Column() {
              Row() {
                Column()
                  .width(`${this.progress}%`)
                  .height('100%')
                  .backgroundColor('#4CAF50')
                  .borderRadius(4)
                Column()
                  .width(`${100 - this.progress}%`)
                  .height('100%')
                  .backgroundColor('rgba(255, 255, 255, 0.3)')
                  .borderRadius(4)
              }
              .width('100%')
              .height(8)
              .borderRadius(4)
              .backgroundColor('rgba(0, 0, 0, 0.3)')
            }
            .flexGrow(1)
            .margin({ right: 16 })
            
            Text(this.formatTime(this.duration))
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .padding({ left: 40, right: 40, top: 40 })
        }
        .flexGrow(1)
        
        // 底部控制按钮区域 | Bottom control buttons area
        Column() {
          // 主要控制按钮 | Main control buttons
          Row() {
            // 快退按钮 | Rewind button
            Button() {
              Text('<< 10s')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(600)
            }
            .width(120)
            .height(60)
            .backgroundColor('rgba(33, 150, 243, 0.9)')
            .borderRadius(12)
            .margin({ left: 40 })
            .onClick(() => this.onRewind(10))
            .focusable(true)
            .focusStyle(this.focusStyle)
            .onFocus(() => {
              Logger.info(this.TAG, 'Rewind button focused');
            })
            .keyEventListener((e) => this.onKeyEvent(e))
            
            // 播放/暂停按钮 | Play/pause button
            Button() {
              Text(this.isPlaying ? '⏸' : '▶')
                .fontSize(24)
                .fontColor('#FFFFFF')
            }
            .width(80)
            .height(80)
            .backgroundColor('rgba(76, 175, 80, 0.9)')
            .borderRadius(40)
            .margin({ left: 30 })
            .onClick(() => this.onPlayPause())
            .focusable(true)
            .focusStyle(this.focusStyle)
            .onFocus(() => {
              Logger.info(this.TAG, 'Play/pause button focused');
            })
            .keyEventListener((e) => this.onKeyEvent(e))
            
            // 快进按钮 | Fast forward button
            Button() {
              Text('30s >>')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(600)
            }
            .width(120)
            .height(60)
            .backgroundColor('rgba(33, 150, 243, 0.9)')
            .borderRadius(12)
            .margin({ left: 30 })
            .onClick(() => this.onFastForward(30))
            .focusable(true)
            .focusStyle(this.focusStyle)
            .onFocus(() => {
              Logger.info(this.TAG, 'Fast forward button focused');
            })
            .keyEventListener((e) => this.onKeyEvent(e))
            
            // 中间空白区域 | Middle space
            Column()
              .flexGrow(1)
            
            // 跳过按钮 | Skip button
            Button() {
              Text('跳过')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(600)
            }
            .width(100)
            .height(56)
            .backgroundColor('rgba(156, 39, 176, 0.9)')
            .borderRadius(12)
            .margin({ right: 24 })
            .onClick(() => this.onShowSkipOptions())
            .focusable(true)
            .focusStyle(this.focusStyle)
            .onFocus(() => {
              Logger.info(this.TAG, 'Skip button focused');
            })
            .keyEventListener((e) => this.onKeyEvent(e))
            
            // 音轨按钮 | Audio track button
            Button() {
              Text(this.selectedAudioTrack ? '音轨' : '无音轨')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(600)
            }
            .width(100)
            .height(56)
            .backgroundColor(this.selectedAudioTrack ? 'rgba(76, 175, 80, 0.9)' : 'rgba(158, 158, 158, 0.9)')
            .borderRadius(12)
            .margin({ right: 24 })
            .onClick(() => this.onShowAudioTrackOptions())
            .focusable(true)
            .focusStyle(this.focusStyle)
            .onFocus(() => {
              Logger.info(this.TAG, 'Audio track button focused');
            })
            .keyEventListener((e) => this.onKeyEvent(e))
            
            // 字幕按钮 | Subtitle button
            Button() {
              Text(this.selectedSubtitle ? '字幕' : '无字幕')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(600)
            }
            .width(100)
            .height(56)
            .backgroundColor(this.selectedSubtitle ? 'rgba(76, 175, 80, 0.9)' : 'rgba(158, 158, 158, 0.9)')
            .borderRadius(12)
            .margin({ right: 40 })
            .onClick(() => this.onShowSubtitleOptions())
            .focusable(true)
            .focusStyle(this.focusStyle)
            .onFocus(() => {
              Logger.info(this.TAG, 'Subtitle button focused');
            })
            .keyEventListener((e) => this.onKeyEvent(e))
          }
          .width('100%')
          .padding({ bottom: 40 })
        }
      }
      .width('100%')
      .height(this.videoPlayerHeight)
      .backgroundColor('rgba(0, 0, 0, 0.6)')
      .animation({
        duration: 300,
        curve: 'ease-in-out'
      })
    }
  }
}
