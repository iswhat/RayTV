// PlayerController.ets - 播放器控制界面组件
import { PlaybackStatus } from '../../data/service/PlayerService';

interface PlayerControllerProps {
  status: PlaybackStatus;
  currentTime: number;
  totalTime: number;
  volume: number;
  isMuted: boolean;
  isFullscreen: boolean;
  isBuffering: boolean;
  title?: string;
  subtitle?: string;
  onPlayPause: () => void;
  onSeek: (time: number) => void;
  onVolumeChange: (volume: number) => void;
  onToggleMute: () => void;
  onToggleFullscreen: () => void;
  onBack: () => void;
  showController: boolean;
}

@Component
export default struct PlayerController {
  private props: PlayerControllerProps;
  private controllerTimeout: number | null = null;
  private isSeeking: boolean = false;
  private seekTime: number = 0;
  
  constructor(props: PlayerControllerProps) {
    this.props = props;
  }
  
  // 格式化时间显示
  formatTime(timeInSeconds: number): string {
    const hours = Math.floor(timeInSeconds / 3600);
    const minutes = Math.floor((timeInSeconds % 3600) / 60);
    const seconds = Math.floor(timeInSeconds % 60);
    
    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    } else {
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
  }
  
  // 计算进度百分比
  getProgressPercentage(): number {
    if (this.props.totalTime === 0) return 0;
    const time = this.isSeeking ? this.seekTime : this.props.currentTime;
    return (time / this.props.totalTime) * 100;
  }
  
  // 处理进度条拖动开始
  onProgressBarStart() {
    this.isSeeking = true;
    this.seekTime = this.props.currentTime;
  }
  
  // 处理进度条拖动
  onProgressBarMove(event: SliderChangeEvent) {
    this.seekTime = (event.progress / 100) * this.props.totalTime;
  }
  
  // 处理进度条拖动结束
  onProgressBarEnd(event: SliderChangeEvent) {
    this.isSeeking = false;
    const finalTime = (event.progress / 100) * this.props.totalTime;
    this.props.onSeek(finalTime);
  }
  
  build() {
    if (!this.props.showController) return null;
    
    return (
      Stack() {
        // 渐变背景
        LinearGradient()
          .colors(["rgba(0,0,0,0.6)", "rgba(0,0,0,0.2)", "rgba(0,0,0,0.6)"])
          .direction(GradientDirection.TopBottom)
          .width('100%')
          .height('100%')
        
        // 顶部控制栏
        Row() {
          Button() {
            Text('←')
              .fontSize(24)
          }
          .width(48)
          .height(48)
          .backgroundColor('transparent')
          .onClick(() => this.props.onBack())
          
          Column() {
            if (this.props.title) {
              Text(this.props.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            if (this.props.subtitle) {
              Text(this.props.subtitle)
                .fontSize(14)
                .color('#ccc')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .flexGrow(1)
          .marginLeft(16)
          
          Button() {
            Text(this.props.isFullscreen ? '⤢' : '⤡')
              .fontSize(24)
          }
          .width(48)
          .height(48)
          .backgroundColor('transparent')
          .onClick(() => this.props.onToggleFullscreen())
        }
        .width('100%')
        .padding(16)
        .alignItems(VerticalAlign.Center)
        
        // 中央播放按钮
        if (this.props.isBuffering) {
          LoadingProgress()
            .width(80)
            .height(80)
            .color('#fff')
        } else {
          Button() {
            Text(this.props.status === PlaybackStatus.PLAYING ? '⏸' : '▶')
              .fontSize(48)
          }
          .width(120)
          .height(120)
          .backgroundColor('rgba(0,0,0,0.5)')
          .borderRadius(60)
          .onClick(() => this.props.onPlayPause())
        }
        
        // 底部控制栏
        Column() {
          // 进度条
          Row() {
            Text(this.formatTime(this.isSeeking ? this.seekTime : this.props.currentTime))
              .fontSize(14)
              .marginRight(12)
              
            Slider({
              value: this.getProgressPercentage(),
              onStart: this.onProgressBarStart.bind(this),
              onChange: this.onProgressBarMove.bind(this),
              onEnd: this.onProgressBarEnd.bind(this),
              min: 0,
              max: 100,
              step: 0.1
            })
            .flexGrow(1)
            .trackColor({ 
              selected: '#37a2da', 
              unselected: 'rgba(255,255,255,0.3)' 
            })
            .blockColor('#fff')
            .height(40)
            
            Text(this.formatTime(this.props.totalTime))
              .fontSize(14)
              .marginLeft(12)
          }
          .width('100%')
          .paddingHorizontal(16)
          
          // 控制按钮
          Row() {
            Button() {
              Text(this.props.isMuted ? '🔇' : '🔊')
                .fontSize(24)
            }
            .width(48)
            .height(48)
            .backgroundColor('transparent')
            .onClick(() => this.props.onToggleMute())
            
            Slider({
              value: this.props.volume * 100,
              onChange: (event) => this.props.onVolumeChange(event.progress / 100),
              min: 0,
              max: 100,
              step: 1
            })
            .width(150)
            .trackColor({ 
              selected: '#37a2da', 
              unselected: 'rgba(255,255,255,0.3)' 
            })
            .blockColor('#fff')
            .height(40)
            .marginLeft(8)
            .marginRight(16)
            
            Button() {
              Text(this.props.status === PlaybackStatus.PLAYING ? '⏸' : '▶')
                .fontSize(24)
            }
            .width(64)
            .height(64)
            .backgroundColor('#37a2da')
            .borderRadius(32)
            .onClick(() => this.props.onPlayPause())
          }
          .width('100%')
          .padding(16)
          .alignItems(VerticalAlign.Center)
        }
        .position({ y: '100%', offsetY: -16 })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .transition({
        type: TransitionType.Insert,
        opacity: 0,
        duration: 300
      })
    );
  }
}