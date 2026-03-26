/**
 * Content Source Badge - 内容来源标识组件
 *
 * 用于在各个页面显示内容项的来源信息
 * 支持显示源名称、源标签、优先级等
 */

// ========================================
// Badge 样式配置
// ========================================

/**
 * 内边距配置接口
 */
export interface PaddingConfig {
  left: number;
  right: number;
  top: number;
  bottom: number;
}

export interface SourceBadgeStyle {
  showSourceName: boolean;
  showTags: boolean;
  showPriority: boolean;
  badgeColor: string;
  textColor: string;
  fontSize: number;
  padding: PaddingConfig;
  borderRadius: number;
}

const DEFAULT_PADDING: PaddingConfig = {
  left: 8,
  right: 8,
  top: 4,
  bottom: 4
};

const DEFAULT_STYLE: SourceBadgeStyle = {
  showSourceName: true,
  showTags: true,
  showPriority: false,
  badgeColor: '#E3F2FD',
  textColor: '#1976D2',
  fontSize: 12,
  padding: DEFAULT_PADDING,
  borderRadius: 4
};

/**
 * 内容来源标识组件
 */
@Component
export struct ContentSourceBadge {
  sourceName: string = '';
  sourceTags: string[] = [];
  sourcePriority: number = 1;
  style: SourceBadgeStyle = DEFAULT_STYLE;
  
  build() {
    if (this.sourceName) {
      Row() {
        // 源名称
        if (this.style.showSourceName) {
          Text(this.sourceName)
            .fontSize(this.style.fontSize)
            .fontColor(this.style.textColor)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        
        // 标签
        if (this.style.showTags && this.sourceTags.length > 0) {
          ForEach(this.sourceTags.slice(0, 2), (tag: string, index: number) => {
            Text(` ${tag}`)
              .fontSize(this.style.fontSize - 1)
              .fontColor(this.style.textColor)
              .opacity(0.8)
          }, (tag: string, index: number) => `${tag}_${index}`)
        }
        
        // 优先级
        if (this.style.showPriority) {
          Text(` P${this.sourcePriority}`)
            .fontSize(this.style.fontSize - 1)
            .fontColor(this.style.textColor)
            .opacity(0.6)
        }
      }
      .padding({
        left: this.style.padding.left,
        right: this.style.padding.right,
        top: this.style.padding.top,
        bottom: this.style.padding.bottom
      })
      .backgroundColor(this.style.badgeColor)
      .borderRadius(this.style.borderRadius)
    }
  }
}

/**
 * 多源组合徽章组件
 * /**
 * 源信息接口
 */
export interface SourceInfo {
  name: string;
  tags?: string[];
}

/**
 * 当内容来自多个源时显示的组合徽章
 */
@Component
export struct MultiSourceBadge {
  sources: Array<SourceInfo> = [];
  style: SourceBadgeStyle = DEFAULT_STYLE;
  maxShow: number = 2;
  
  build() {
    Row() {
      // 显示前 N 个源
      ForEach(this.sources.slice(0, this.maxShow), (source: SourceInfo, index: number) => {
        Row() {
          Text(source.name)
            .fontSize(this.style.fontSize)
            .fontColor(this.style.textColor)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          
          if (source.tags && source.tags.length > 0) {
            Text(` ${source.tags[0]}`)
              .fontSize(this.style.fontSize - 1)
              .fontColor(this.style.textColor)
              .opacity(0.8)
          }
        }
        .padding({
          left: this.style.padding.left,
          right: this.style.padding.right,
          top: this.style.padding.top,
          bottom: this.style.padding.bottom
        })
        .backgroundColor(this.style.badgeColor)
        .borderRadius(this.style.borderRadius)
        .margin({ right: 6 })
      }, (source: SourceInfo, index: number) => `${source.name}_${index}`)
      
      // 如果还有更多源，显示"+N"
      if (this.sources.length > this.maxShow) {
        Row() {
          Text(`+${this.sources.length - this.maxShow}`)
            .fontSize(this.style.fontSize)
            .fontColor(this.style.textColor)
        }
        .padding({
          left: this.style.padding.left,
          right: this.style.padding.right,
          top: this.style.padding.top,
          bottom: this.style.padding.bottom
        })
        .backgroundColor(this.style.badgeColor)
        .borderRadius(this.style.borderRadius)
      }
    }
  }
}

/**
 * 源卡片组件
 * 
 * 用于在设置页面等地方显示源信息的卡片
 */
@Component
export struct SourceCard {
  sourceName: string = '';
  sourceId: string = '';
  sourceUrl: string = '';
  isActive: boolean = true;
  healthStatus: 'healthy' | 'degraded' | 'unreachable' = 'healthy';
  priority: number = 1;
  tags: string[] = [];
  contentUsage: Record<string, boolean> = {};
  onClick?: () => void;
  onToggle?: (isActive: boolean) => void;
  
  build() {
    Column() {
      // 源信息头部
      Row() {
        // 状态指示灯
        Row()
          .width(10)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.getHealthColor(this.healthStatus))
          .margin({ right: 12 })
        
        // 源名称
        Column() {
          Text(this.sourceName)
            .fontSize(16)
            .fontWeight(600)
            .fontColor('#333333')
            .maxLines(1)
          
          Text(this.sourceUrl)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        
        // 优先级
        if (this.priority > 1) {
          Text(`P${this.priority}`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ right: 12 })
            .padding({ left: 6, right: 6, top: 3, bottom: 3 })
            .backgroundColor('#E0E0E0')
            .borderRadius(10)
        }
        
        // 开关
        Button() {
          Text(this.isActive ? '✓' : '')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width(44)
        .height(26)
        .backgroundColor(this.isActive ? '#4CAF50' : '#E0E0E0')
        .borderRadius(13)
        .onClick(() => {
          if (this.onToggle) {
            this.onToggle(!this.isActive);
          }
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 内容使用开关
      Column() {
        this.renderUsageItem('点播', 'vodSites');
        this.renderUsageItem('直播', 'liveChannels');
        this.renderUsageItem('壁纸', 'wallpapers');
        this.renderUsageItem('广告过滤', 'adBlockRules');
        this.renderUsageItem('解码', 'decoderConfigs');
        this.renderUsageItem('解析器', 'parserConfigs');
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)
      .margin({ bottom: 12 })
      
      // 标签
      if (this.tags.length > 0) {
        Row() {
          ForEach(this.tags.slice(0, 4), (tag: string, index: number) => {
            Text(tag)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ right: 6 })
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#E8F5E9')
              .borderRadius(12)
          }, (tag: string, index: number) => `${tag}_${index}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 })
    .onClick(() => {
      if (this.onClick) {
        this.onClick();
      }
    })
  }
  
  @Builder
  private renderUsageItem(label: string, key: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .width(80)
      
      if (this.contentUsage[key]) {
        Text('✓')
          .fontSize(14)
          .fontColor('#4CAF50')
          .width(20)
      } else {
        Text('✗')
          .fontSize(14)
          .fontColor('#E0E0E0')
          .width(20)
      }
    }
    .width('100%')
    .margin({ bottom: 6 })
  }
  
  private getHealthColor(status: string): string {
    switch (status) {
      case 'healthy':
        return '#4CAF50';
      case 'degraded':
        return '#FF9800';
      case 'unreachable':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }
}

export default ContentSourceBadge;
