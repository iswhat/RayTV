/**
 * Network Source Detail Popup - 网络源详情弹窗
 *
 * 用于显示和编辑单个网络源的详细信息、内容使用开关等
 */

import { NetworkSourceConfig, ContentUsage } from '../service/pool/SourcePoolManager';
import NetworkSourceManager from '../service/config/NetworkSourceManager';
import ContentAccessService from '../service/content/ContentAccessService';

// ========================================
// 弹窗状态接口
// ========================================

export interface SourceDetailPopupState {
  visible: boolean;
  source: NetworkSourceConfig | null;
  loading: boolean;
  healthChecking: boolean;
  contentStats: {
    vodSites?: number;
    liveChannels?: number;
    wallpapers?: number;
    adBlockRules?: number;
    decoderConfigs?: number;
    parserConfigs?: number;
  };
}

/**
 * 网络源详情弹窗组件
 */
@Component
export struct NetworkSourceDetailPopup {
  source: NetworkSourceConfig | null = null;
  networkSourceManager: NetworkSourceManager;
  private contentService: ContentAccessService = ContentAccessService.getInstance();
  onClose: () => void = () => {};
  onSave: (source: NetworkSourceConfig) => Promise<void> = async () => {};
  onDelete: (sourceId: string) => Promise<void> = async () => {};

  @State loading: boolean = false;
  @State healthChecking: boolean = false;
  @State contentStats: Record<string, number> = {};
  @State tempSource: NetworkSourceConfig | null = null;
  @State showLoadError: boolean = false;
  @State errorMessage: string = '';

  aboutToAppear() {
    this.tempSource = this.source ? { ...this.source } : null;
    this.loadContentStats();
  }

  /**
   * 加载内容统计
   */
  private async loadContentStats(): Promise<void> {
    if (!this.tempSource) return;

    this.loading = true;
    this.showLoadError = false;
    this.errorMessage = '';

    try {
      // 从 ContentAccessService 获取实际统计信息
      const vodSites: VodSiteWithSource[] = this.contentService.getAllVodSites();
      const liveChannels: LiveSource[] = this.contentService.getAllLiveChannels();
      const wallpapers: WallpaperWithSource[] = this.contentService.getAllWallpapers();
      const adBlockRules: AdBlockRule[] = this.contentService.getAdBlockRules();
      const decoderConfigs: Object[] = this.contentService.getDecoderConfigs();
      const parserConfigs: Object[] = this.contentService.getParserConfigs();

      this.contentStats = {
        vodSites: vodSites.length,
        liveChannels: liveChannels.length,
        wallpapers: wallpapers.length,
        adBlockRules: adBlockRules.length,
        decoderConfigs: decoderConfigs.length,
        parserConfigs: parserConfigs.length
      };
    } catch (error) {
      console.error('Failed to load content stats:', error);
      this.showLoadError = true;
      this.errorMessage = '加载内容统计失败';
      // 失败时使用默认值
      this.contentStats = {
        vodSites: 0,
        liveChannels: 0,
        wallpapers: 0,
        adBlockRules: 0,
        decoderConfigs: 0,
        parserConfigs: 0
      };
    } finally {
      this.loading = false;
    }
  }
  
  /**
   * 切换内容使用开关
   */
  private async toggleContentUsage(key: keyof ContentUsage, value: boolean): Promise<void> {
    if (!this.tempSource) return;
    
    this.tempSource.contentUsage[key] = value;
  }
  
  /**
   * 添加标签
   */
  private addTag(): void {
    if (!this.tempSource) return;
    
    if (!this.tempSource.tags) {
      this.tempSource.tags = [];
    }
    
    // 模拟添加标签
    this.tempSource.tags.push('新标签');
  }
  
  /**
   * 移除标签
   */
  private removeTag(tag: string): void {
    if (!this.tempSource) return;
    
    if (this.tempSource.tags) {
      this.tempSource.tags = this.tempSource.tags.filter(t => t !== tag);
    }
  }
  
  /**
   * 测试连接
   */
  private async testConnection(): Promise<void> {
    if (!this.tempSource) return;
    
    this.healthChecking = true;
    
    try {
      const healthStatus: 'healthy' | 'degraded' | 'unreachable' = await this.networkSourceManager.checkSourceHealth(this.tempSource.id);
      this.tempSource.healthStatus = healthStatus;
    } catch (error: Error) {
      console.error('Failed to test connection:', error);
      this.tempSource.healthStatus = 'unreachable';
    } finally {
      this.healthChecking = false;
    }
  }
  
  /**
   * 保存配置
   */
  private async saveConfig(): Promise<void> {
    if (!this.tempSource) return;
    
    await this.onSave(this.tempSource);
    this.onClose();
  }
  
  /**
   * 删除源
   */
  private async deleteSource(): Promise<void> {
    if (!this.tempSource) return;
    
    await this.onDelete(this.tempSource.id);
    this.onClose();
  }
  
  build() {
    if (this.tempSource) {
      Column() {
        // 半透明背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onClose();
          })
        
        // 弹窗内容
        Column() {
          // 标题栏
          Row() {
            Text('源配置详情')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
            
            Blank()
            
            Button() {
              Text('关闭')
                .fontSize(16)
                .fontColor('#666666')
            }
            .backgroundColor('transparent')
            .onClick(() => {
              this.onClose();
            })
          }
          .width('100%')
          .padding(20)
          .borderBottomWidth(1)
          .borderBottomColor('#E0E0E0')
          
          Scroll() {
            Column() {
              // 基本信息
              this.renderBasicInfo();
              
              // 内容使用开关
              this.renderContentUsage();
              
              // 标签
              this.renderTags();
              
              // 操作按钮
              this.renderActions();
            }
            .padding(20)
          }
          .layoutWeight(1)
        }
        .width('80%')
        .maxWidth(600)
        .height('80%')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.15)' })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .position({ x: 0, y: 0 })
    }
  }
  
  /**
   * 渲染基本信息
   */
  @Builder
  private renderBasicInfo() {
    Column() {
      Text('基本信息')
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#333333')
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)
      
      Column() {
        this.renderInfoRow('名称:', this.source.name);
        this.renderInfoRow('URL:', this.source.url);
        this.renderInfoRow('版本:', this.source.version);
        this.renderInfoRow('优先级:', this.source.priority.toString());
        
        // 健康状态
        Row() {
          Text('状态:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)
          
          Row() {
            Text(this.getHealthStatusText(this.source.healthStatus))
              .fontSize(14)
              .fontColor(this.getHealthStatusColor(this.source.healthStatus))
          }
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(this.getHealthStatusColor(this.source.healthStatus))
        }
        .width('100%')
        .margin({ top: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .margin({ bottom: 20 })
    }
  }
  
  /**
   * 渲染内容使用开关
   */
  @Builder
  private renderContentUsage() {
    Column() {
      Text('内容使用开关')
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#333333')
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)
      
      Column() {
        this.renderUsageToggle('点播站点列表', 'vodSites', this.contentStats.vodSites);
        this.renderUsageToggle('直播频道列表', 'liveChannels', this.contentStats.liveChannels);
        this.renderUsageToggle('壁纸资源', 'wallpapers', this.contentStats.wallpapers);
        this.renderUsageToggle('广告过滤规则', 'adBlockRules', this.contentStats.adBlockRules);
        this.renderUsageToggle('解码配置', 'decoderConfigs', this.contentStats.decoderConfigs);
        this.renderUsageToggle('解析器配置', 'parserConfigs', this.contentStats.parserConfigs);
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .margin({ bottom: 20 })
    }
  }
  
  /**
   * 渲染标签
   */
  @Builder
  private renderTags() {
    Column() {
      Text('标签/标记 (用于来源显示)')
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#333333')
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)
      
      if (this.source.tags && this.source.tags.length > 0) {
        Row() {
          ForEach(this.source.tags, (tag: string) => {
            Row() {
              Text(tag)
                .fontSize(14)
                .fontColor('#333333')
                .margin({ right: 8 })
              
              Button() {
                Text('✕')
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .width(20)
              .height(20)
              .backgroundColor('#E0E0E0')
              .borderRadius(10)
              .onClick(() => {
                this.removeTag(tag);
              })
            }
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#E8F5E9')
            .borderRadius(16)
            .margin({ right: 8 })
          }, (tag: string) => tag)
        }
        .width('100%')
        .margin({ bottom: 10 })
      }
      
      Button() {
        Text('+ 添加标签')
          .fontSize(14)
          .fontColor('#4CAF50')
      }
      .backgroundColor('transparent')
      .onClick(() => {
        this.addTag();
      })
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .margin({ bottom: 20 })
  }
  
  /**
   * 渲染操作按钮
   */
  @Builder
  private renderActions() {
    Row() {
      Button() {
        Text(this.healthChecking ? '测试中...' : '测试连接')
          .fontSize(16)
          .fontColor('#FFFFFF')
      }
      .width(120)
      .height(44)
      .backgroundColor('#2196F3')
      .borderRadius(8)
      .margin({ right: 10 })
      .onClick(() => {
        this.testConnection();
      })
      .enabled(!this.healthChecking)
      
      Button() {
        Text('保存配置')
          .fontSize(16)
          .fontColor('#FFFFFF')
      }
      .width(120)
      .height(44)
      .backgroundColor('#4CAF50')
      .borderRadius(8)
      .margin({ right: 10 })
      .onClick(() => {
        this.saveConfig();
      })
      
      Button() {
        Text('删除源')
          .fontSize(16)
          .fontColor('#FFFFFF')
      }
      .width(100)
      .height(44)
      .backgroundColor('#F44336')
      .borderRadius(8)
      .onClick(() => {
        this.deleteSource();
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  /**
   * 渲染信息行
   */
  @Builder
  private renderInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .width(80)
      
      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 10 })
  }
  
  /**
   * 渲染使用开关
   */
  @Builder
  private renderUsageToggle(label: string, key: keyof ContentUsage, count?: number) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
      
      if (count !== undefined) {
        Text(`当前提供: ${count}个`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ right: 10 })
      }
      
      Button() {
        Text(this.source.contentUsage[key] ? '✓' : '')
          .fontSize(16)
          .fontColor('#FFFFFF')
      }
      .width(44)
      .height(26)
      .backgroundColor(this.source.contentUsage[key] ? '#4CAF50' : '#E0E0E0')
      .borderRadius(13)
      .onClick(() => {
        this.toggleContentUsage(key, !this.source.contentUsage[key]);
      })
    }
    .width('100%')
    .margin({ bottom: 10 })
  }
  
  /**
   * 获取健康状态文本
   */
  private getHealthStatusText(status: string): string {
    switch (status) {
      case 'healthy':
        return '健康';
      case 'degraded':
        return '降级';
      case 'unreachable':
        return '不可达';
      default:
        return '未知';
    }
  }
  
  /**
   * 获取健康状态颜色
   */
  private getHealthStatusColor(status: string): string {
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

export default NetworkSourceDetailPopup;
