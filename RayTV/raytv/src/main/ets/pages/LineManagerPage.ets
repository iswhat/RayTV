// LineManagerPage.ets - 线路管理页面
// 实现线路列表展示和切换功能

import Logger from '../common/util/Logger';
import LineManagerPageStyles from './LineManagerPageStyles';

/**
 * 线路信息接口
 */
interface LineInfo {
  id: string;
  name: string;
  url: string;
  isCurrent: boolean;
  description?: string;
  responseTime?: number;
}

/**
 * 线路管理页面组件
 */
@Entry
@Component
struct LineManagerPage {
  private readonly TAG: string = 'LineManagerPage';
  
  // 状态管理
  @State lines: LineInfo[] = [
    { id: '1', name: '默认线路', url: 'https://example.com/api', isCurrent: true, description: '默认使用的线路' },
    { id: '2', name: '备用线路1', url: 'https://backup1.example.com/api', isCurrent: false, description: '备用线路1' },
    { id: '3', name: '备用线路2', url: 'https://backup2.example.com/api', isCurrent: false, description: '备用线路2' }
  ];
  
  /**
   * 切换当前线路
   */
  private switchLine(lineId: string) {
    // 更新线路状态
    this.lines = this.lines.map(line => ({
      ...line,
      isCurrent: line.id === lineId
    }));
    Logger.info(this.TAG, `Switched to line: ${lineId}`);
  }
  
  /**
   * 渲染线路项
   */
  @Builder
  renderLineItem(line: LineInfo) {
    Column() {
      Row() {
        Text(line.name)
          .fontSize(16)
          .fontWeight(700)
          .fontColor('#333')
          .flexGrow(1)
        
        if (line.isCurrent) {
          Row() {
            Text('当前线路')
              .fontSize(12)
              .fontWeight(700)
              .fontColor('#fff')
          }
          .backgroundColor('#4CAF50')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(4)
        }
      }
      .margin({ bottom: 8 })
      
      Text(line.url)
        .fontSize(14)
        .fontColor('#666')
        .margin({ bottom: 8 })
      
      if (line.description) {
        Text(line.description)
          .fontSize(14)
          .fontColor('#666')
          .fontStyle(FontStyle.Italic)
          .margin({ bottom: 12 })
      }
      
      Row() {
        Button('切换线路')
          .backgroundColor(line.isCurrent ? '#9E9E9E' : '#4CAF50')
          .fontColor('#fff')
          .borderRadius(8)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .fontSize(14)
          .enabled(!line.isCurrent)
          .onClick(() => this.switchLine(line.id))
        
        Button('测试线路')
          .backgroundColor('#2196F3')
          .fontColor('#fff')
          .borderRadius(8)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .fontSize(14)
          .margin({ left: 10 })
          .onClick(() => {
            Logger.info(this.TAG, `Testing line: ${line.id}`);
          })
      }
    }
    .padding(16)
    .backgroundColor('#fff')
    .borderRadius(8)
    .margin({ bottom: 12, left: 12, right: 12 })
    .borderWidth(line.isCurrent ? 2 : 0)
    .borderColor(line.isCurrent ? '#4CAF50' : '#fff')
  }
  
  /**
   * 组件构建
   */
  build() {
    Column() {
      // 页面标题
      Text('线路管理')
        .fontSize(24)
        .fontWeight(700)
        .fontColor('#333')
        .margin({ top: 20, bottom: 10 })
        .textAlign(TextAlign.Center)
      
      // 线路列表
      Scroll() {
        Column() {
          ForEach(this.lines, (line: LineInfo) => {
            this.renderLineItem(line)
          }, (line: LineInfo) => line.id)
        }
      }
      .flexGrow(1)
      
      // 添加线路按钮
      Button('添加线路')
        .backgroundColor('#4CAF50')
        .fontColor('#fff')
        .borderRadius(8)
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .margin({ left: 12, right: 12, bottom: 20 })
        .fontSize(16)
        .onClick(() => {
          Logger.info(this.TAG, 'Add line clicked');
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}