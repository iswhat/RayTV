/**
 * SkipSettings.ets - 跳过设置组件
 * 处理跳过片头片尾相关的设置
 */

import Logger from '../../common/util/Logger';
import { FlexAlign, TextAlign } from '@ohos/arkui';

// 跳过设置组件参数 | Skip settings component parameters
interface SkipSettingsParams {
  showSkipOptions: boolean;
  isSkipOpeningEnabled: boolean;
  isSkipEndingEnabled: boolean;
  skipOpeningTime: number;
  skipEndingTime: number;
  onToggleSkipOpening: () => void;
  onToggleSkipEnding: () => void;
  onSetSkipOpeningTime: () => void;
  onSetSkipEndingTime: () => void;
}

@Component
export struct SkipSettings {
  private readonly TAG: string = 'SkipSettings';
  
  // 参数 | Parameters
  @Prop showSkipOptions: boolean;
  @Prop isSkipOpeningEnabled: boolean;
  @Prop isSkipEndingEnabled: boolean;
  @Prop skipOpeningTime: number;
  @Prop skipEndingTime: number;
  
  // 回调函数 | Callback functions
  private onToggleSkipOpening: () => void;
  private onToggleSkipEnding: () => void;
  private onSetSkipOpeningTime: () => void;
  private onSetSkipEndingTime: () => void;
  
  // 构造函数 | Constructor
  constructor(params: SkipSettingsParams) {
    this.showSkipOptions = params.showSkipOptions;
    this.isSkipOpeningEnabled = params.isSkipOpeningEnabled;
    this.isSkipEndingEnabled = params.isSkipEndingEnabled;
    this.skipOpeningTime = params.skipOpeningTime;
    this.skipEndingTime = params.skipEndingTime;
    this.onToggleSkipOpening = params.onToggleSkipOpening;
    this.onToggleSkipEnding = params.onToggleSkipEnding;
    this.onSetSkipOpeningTime = params.onSetSkipOpeningTime;
    this.onSetSkipEndingTime = params.onSetSkipEndingTime;
  }
  
  // 格式化时间 | Format time
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  
  build() {
    if (this.showSkipOptions) {
      Column() {
        Text('跳过设置')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        // 跳过片头设置 | Skip opening settings
        Column() {
          Text('跳过片头')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          Row() {
            Button() {
              Text(this.isSkipOpeningEnabled ? '已开启' : '未开启')
                .fontSize(14)
                .fontColor(this.isSkipOpeningEnabled ? '#4CAF50' : '#9E9E9E')
                .fontWeight(500)
            }
            .width(120)
            .height(40)
            .backgroundColor(this.isSkipOpeningEnabled ? '#E8F5E9' : '#F5F5F5')
            .borderRadius(8)
            .margin({ left: 10, right: 15 })
            .onClick(() => this.onToggleSkipOpening())
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Skip opening toggle focused');
            })
            
            Button() {
              Text('设置当前点')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(500)
            }
            .width(150)
            .height(40)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .onClick(() => this.onSetSkipOpeningTime())
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Set opening point button focused');
            })
          }
          
          Text(`当前跳过时间: ${this.formatTime(this.skipOpeningTime)}`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8, left: 10 })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 跳过片尾设置 | Skip ending settings
        Column() {
          Text('跳过片尾')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          Row() {
            Button() {
              Text(this.isSkipEndingEnabled ? '已开启' : '未开启')
                .fontSize(14)
                .fontColor(this.isSkipEndingEnabled ? '#4CAF50' : '#9E9E9E')
                .fontWeight(500)
            }
            .width(120)
            .height(40)
            .backgroundColor(this.isSkipEndingEnabled ? '#E8F5E9' : '#F5F5F5')
            .borderRadius(8)
            .margin({ left: 10, right: 15 })
            .onClick(() => this.onToggleSkipEnding())
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Skip ending toggle focused');
            })
            
            Button() {
              Text('设置当前点')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(500)
            }
            .width(150)
            .height(40)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .onClick(() => this.onSetSkipEndingTime())
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Set ending point button focused');
            })
          }
          
          Text(`当前跳过时间: ${this.formatTime(this.skipEndingTime)}`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8, left: 10 })
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
