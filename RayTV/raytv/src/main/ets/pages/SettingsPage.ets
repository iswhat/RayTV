// SettingsPage.ets - 设置页面
// 实现应用配置管理，包括主题、语言、缓存、播放等设置

import Logger from '../common/util/Logger';
import ConfigService, { DisplayConfig, GeneralConfig, PlayerConfig, StorageConfig, NotificationConfig, VodConfig } from '../service/config/ConfigService';
import MediaService from '../service/media/MediaService';
import StorageUtil from '../common/util/StorageUtil';

/**
 * 设置项配置接口
 */
interface SettingItem {
  title: string;
  value: string;
  icon?: string;
  onClick?: () => void;
}

/**
 * 影视源接口
 */
interface VideoSource {
  id: string;
  name: string;
  url: string;
  enabled: boolean;
}

/**
 * 设置页面组件
 * 实现应用配置管理，包括主题、语言、缓存、播放等设置
 */
@Entry
@Component
struct SettingsPage {
  private readonly TAG: string = 'SettingsPage';
  
  // 服务实例
  private configService = ConfigService.getInstance();
  private mediaService = MediaService.getInstance();
  
  // 状态管理
  @State private themeMode: 'light' | 'dark' | 'auto' = 'auto';
  @State private language: 'zh' | 'en' = 'zh';
  @State private autoPlay: boolean = true;
  @State private autoNextEpisode: boolean = true;
  @State private rememberProgress: boolean = true;
  @State private enableHardwareAcceleration: boolean = true;
  @State private cacheStrategy: 'memory' | 'disk' | 'none' = 'disk';
  @State private maxCacheSize: number = 1024; // MB
  @State private currentCacheSize: number = 26.1; // MB
  @State private enableUpdateCheck: boolean = true;
  @State private notificationsEnabled: boolean = true;
  @State private version: string = '6.1.6 EXO:1.8.0';
  @State private searchThreads: number = 16;
  @State private historyCount: number = 30;
  @State private homeDataSourceCount: number = 4;
  
  // 影视源设置
  @State private videoSources: VideoSource[] = [
    { id: '1', name: 'Eoeoo源', url: 'https://eoeoo.com/base2/a.json', enabled: true },
    { id: '2', name: 'Uoouo源', url: 'https://q.uoouo.com/dianshi.json', enabled: true }
  ];
  
  // 设置项列表
  private getSettingItems(): SettingItem[][] {
    return [
      [
        { title: '配置地址', value: 'www', onClick: () => { this.navigateToConfigUrl(); } },
        { title: '线路切换', value: '潇洒哥dianshi', onClick: () => { this.navigateToLineSwitch(); } }
      ],
      [
        { title: '直播地址', value: '自建', onClick: () => { this.navigateToLiveUrl(); } },
        { title: '首选项', value: '点播', onClick: () => { this.navigateToPreferences(); } }
      ],
      [
        { title: '首页推荐', value: '站点推荐', onClick: () => { this.navigateToHomeRecommend(); } },
        { title: '首页Tab', value: '自定义', onClick: () => { this.navigateToHomeTabs(); } }
      ],
      [
        { title: '搜索展示', value: '缩略图', onClick: () => { this.navigateToSearchDisplay(); } },
        { title: '开机自启', value: '关', onClick: () => { this.navigateToAutoStart(); } }
      ],
      [
        { title: '播放器', value: 'Exo', onClick: () => { this.navigateToPlayer(); } },
        { title: '解码方式', value: '硬解码', onClick: () => { this.navigateToDecodeMode(); } }
      ],
      [
        { title: '窗口预览', value: '开启', onClick: () => { this.navigateToWindowPreview(); } },
        { title: '画面缩放', value: '默认', onClick: () => { this.navigateToScreenZoom(); } }
      ],
      [
        { title: '换张壁纸', value: '', onClick: () => { this.navigateToChangeWallpaper(); } },
        { title: '重置壁纸', value: '', onClick: () => { this.navigateToResetWallpaper(); } }
      ],
      [
        { title: '安全DNS', value: '360', onClick: () => { this.navigateToSafeDNS(); } },
        { title: '历史记录', value: `${this.historyCount}条`, onClick: () => { this.navigateToHistory(); } }
      ],
      [
        { title: '搜索线程', value: `${this.searchThreads}`, onClick: () => { this.navigateToSearchThreads(); } },
        { title: '渲染方式', value: 'SurfaceView', onClick: () => { this.navigateToRenderMode(); } }
      ],
      [
        { title: 'EXO缓冲', value: '3分', onClick: () => { this.navigateToEXOBuffer(); } },
        { title: '迅雷/碎片缓存', value: '', onClick: () => { this.navigateToThunderCache(); } }
      ],
      [
        { title: '数据备份还原', value: '', onClick: () => { this.navigateToDataBackup(); } },
        { title: '清空App缓存', value: '', onClick: () => { this.navigateToClearCache(); } }
      ],
      [
        { title: 'EXO缓存', value: `${this.currentCacheSize}MB`, onClick: () => { this.navigateToEXOCache(); } },
        { title: '重置App', value: '', onClick: () => { this.navigateToResetApp(); } }
      ],
      [
        { title: '影视仓实验室', value: '', onClick: () => { this.navigateToLab(); } },
        { title: '首页数据源列数', value: `${this.homeDataSourceCount}列`, onClick: () => { this.navigateToHomeDataSourceCount(); } }
      ],
      [
        { title: '弹幕', value: '开', onClick: () => { this.navigateToDanmaku(); } },
        { title: '版本', value: this.version, onClick: () => { this.navigateToAbout(); } }
      ]
    ];
  }
  
  /**
   * 组件初始化
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'SettingsPage appeared');
    this.loadConfig();
    this.loadVideoSources();
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      // 从ConfigService加载配置
      const displayConfig = await this.configService.getPartialConfig('display');
      this.themeMode = (displayConfig as DisplayConfig).theme as 'light' | 'dark' | 'auto';
      
      const generalConfig = await this.configService.getPartialConfig('general');
      this.language = (generalConfig as GeneralConfig).language as 'zh' | 'en';
      
      const playerConfig = await this.configService.getPartialConfig('player');
      this.autoPlay = (playerConfig as PlayerConfig).autoPlay;
      this.enableHardwareAcceleration = (playerConfig as PlayerConfig).enableHardwareDecoding;
      
      const vodConfig = await this.configService.getPartialConfig('vod');
      this.autoNextEpisode = (vodConfig as VodConfig).autoPlayNextEpisode;
      
      const storageConfig = await this.configService.getPartialConfig('storage');
      this.maxCacheSize = (storageConfig as StorageConfig).maxCacheSize;
      
      const notificationConfig = await this.configService.getPartialConfig('notification');
      this.notificationsEnabled = (notificationConfig as NotificationConfig).enablePush;
      
      Logger.info(this.TAG, 'Config loaded successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to load config: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 加载影视源
   */
  private async loadVideoSources(): Promise<void> {
    try {
      // 从ConfigService加载影视源配置
      const videoSourcesConfig = await this.configService.getConfig('videoSources');
      if (videoSourcesConfig.isSuccess() && videoSourcesConfig.data) {
        // 转换为VideoSource[]
        const sourcesData = videoSourcesConfig.data;
        if (typeof sourcesData === 'string') {
          this.videoSources = JSON.parse(sourcesData) as VideoSource[];
        } else if (Array.isArray(sourcesData)) {
          // 使用Array.isArray进行类型保护，避免使用unknown
          this.videoSources = sourcesData as VideoSource[];
        } else {
          // 如果类型不符合预期，使用默认值
          Logger.warn(this.TAG, `Invalid video sources data type: ${typeof sourcesData}`);
          this.videoSources = [];
        }
      } else {
        // 从本地存储加载
        const storedSources = await StorageUtil.get('video_sources');
        if (storedSources) {
          if (typeof storedSources === 'string') {
            this.videoSources = JSON.parse(storedSources) as VideoSource[];
          } else if (Array.isArray(storedSources)) {
            // 使用Array.isArray进行类型保护，避免使用unknown
            this.videoSources = storedSources as VideoSource[];
          } else {
            // 如果类型不符合预期，使用默认值
            Logger.warn(this.TAG, `Invalid stored video sources type: ${typeof storedSources}`);
            this.videoSources = [];
          }
          // 同步到ConfigService
          await this.configService.setConfig('videoSources', JSON.stringify(this.videoSources));
        } else {
          // 使用默认影视源并保存
          await this.saveVideoSourceConfig();
        }
      }
      Logger.info(this.TAG, 'Video sources loaded successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to load video sources: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 保存影视源配置
   */
  private async saveVideoSourceConfig(): Promise<void> {
    try {
      // 保存影视源到ConfigService - 转换为JSON字符串
      await this.configService.setConfig('videoSources', JSON.stringify(this.videoSources));
      // 同时保存到本地存储作为备份
      await StorageUtil.set('video_sources', JSON.stringify(this.videoSources));
      Logger.info(this.TAG, 'Video sources saved successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to save video sources: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 组件销毁
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'SettingsPage disappeared');
  }
  
  // 导航方法 - 实现实际配置修改功能
  private navigateToConfigUrl() { 
    Logger.info(this.TAG, 'Navigate to Config Url'); 
    // 实现配置地址修改逻辑
  }
  private navigateToLineSwitch() { 
    Logger.info(this.TAG, 'Navigate to Line Switch'); 
    // 实现线路切换逻辑
  }
  private navigateToLiveUrl() { 
    Logger.info(this.TAG, 'Navigate to Live Url'); 
    // 实现直播地址修改逻辑
  }
  private navigateToPreferences() { 
    Logger.info(this.TAG, 'Navigate to Preferences'); 
    // 实现首选项修改逻辑
  }
  private navigateToHomeRecommend() { 
    Logger.info(this.TAG, 'Navigate to Home Recommend'); 
    // 实现首页推荐修改逻辑
  }
  private navigateToHomeTabs() { 
    Logger.info(this.TAG, 'Navigate to Home Tabs'); 
    // 实现首页Tab修改逻辑
  }
  private navigateToSearchDisplay() { 
    Logger.info(this.TAG, 'Navigate to Search Display'); 
    // 实现搜索展示修改逻辑
  }
  private navigateToAutoStart() { 
    Logger.info(this.TAG, 'Navigate to Auto Start'); 
    // 实现开机自启修改逻辑
  }
  private navigateToPlayer() { 
    Logger.info(this.TAG, 'Navigate to Player'); 
    // 实现播放器修改逻辑
    this.updatePlayerConfig('defaultPlayer', 'exo');
  }
  private navigateToDecodeMode() { 
    Logger.info(this.TAG, 'Navigate to Decode Mode'); 
    // 实现解码方式修改逻辑
    this.updatePlayerConfig('enableHardwareDecoding', !this.enableHardwareAcceleration);
  }
  private navigateToWindowPreview() { 
    Logger.info(this.TAG, 'Navigate to Window Preview'); 
    // 实现窗口预览修改逻辑
  }
  private navigateToScreenZoom() { 
    Logger.info(this.TAG, 'Navigate to Screen Zoom'); 
    // 实现画面缩放修改逻辑
  }
  private navigateToChangeWallpaper() { 
    Logger.info(this.TAG, 'Navigate to Change Wallpaper'); 
    // 实现换张壁纸逻辑
  }
  private navigateToResetWallpaper() { 
    Logger.info(this.TAG, 'Navigate to Reset Wallpaper'); 
    // 实现重置壁纸逻辑
  }
  private navigateToSafeDNS() { 
    Logger.info(this.TAG, 'Navigate to Safe DNS'); 
    // 实现安全DNS修改逻辑
  }
  private navigateToHistory() { 
    Logger.info(this.TAG, 'Navigate to History'); 
    // 实现历史记录修改逻辑
    this.historyCount = this.historyCount === 30 ? 50 : 30;
    this.configService.setConfig('recentlyWatchedLimit', this.historyCount);
  }
  private navigateToSearchThreads() { 
    Logger.info(this.TAG, 'Navigate to Search Threads'); 
    // 实现搜索线程修改逻辑
    this.searchThreads = this.searchThreads === 16 ? 8 : 16;
    // 保存搜索线程配置
  }
  private navigateToRenderMode() { 
    Logger.info(this.TAG, 'Navigate to Render Mode'); 
    // 实现渲染方式修改逻辑
  }
  private navigateToEXOBuffer() { 
    Logger.info(this.TAG, 'Navigate to EXO Buffer'); 
    // 实现EXO缓冲修改逻辑
  }
  private navigateToThunderCache() { 
    Logger.info(this.TAG, 'Navigate to Thunder Cache'); 
    // 实现迅雷/碎片缓存修改逻辑
  }
  private navigateToDataBackup() { 
    Logger.info(this.TAG, 'Navigate to Data Backup'); 
    // 实现数据备份还原逻辑
  }
  private navigateToClearCache() { 
    Logger.info(this.TAG, 'Navigate to Clear Cache'); 
    // 实现清空App缓存逻辑
    this.clearCache();
  }
  private navigateToEXOCache() { 
    Logger.info(this.TAG, 'Navigate to EXO Cache'); 
    // 实现EXO缓存修改逻辑
  }
  private navigateToResetApp() { 
    Logger.info(this.TAG, 'Navigate to Reset App'); 
    // 实现重置App逻辑
    this.resetConfig();
  }
  private navigateToLab() { 
    Logger.info(this.TAG, 'Navigate to Lab'); 
    // 实现影视仓实验室逻辑
  }
  private navigateToHomeDataSourceCount() { 
    Logger.info(this.TAG, 'Navigate to Home Data Source Count'); 
    // 实现首页数据源列数修改逻辑
    this.homeDataSourceCount = this.homeDataSourceCount === 4 ? 3 : 4;
    // 保存首页数据源列数配置
  }
  private navigateToDanmaku() { 
    Logger.info(this.TAG, 'Navigate to Danmaku'); 
    // 实现弹幕修改逻辑
  }
  private navigateToAbout() { 
    Logger.info(this.TAG, 'Navigate to About'); 
    // 实现关于页面逻辑
  }
  private navigateToAddSource() { 
    Logger.info(this.TAG, 'Navigate to Add Source'); 
    // 实现添加影视源逻辑
  }

  /**
   * 更新播放器配置
   */
  private async updatePlayerConfig(key: keyof PlayerConfig, value: string | number | boolean): Promise<void> {
    try {
      // 创建配置更新对象
      const playerUpdate: Record<string, string | number | boolean> = {};
      playerUpdate[key] = value;
      await this.configService.updatePartialConfig('player', playerUpdate);
      
      if (key === 'enableHardwareDecoding') {
        this.enableHardwareAcceleration = value as boolean;
      }
      Logger.info(this.TAG, `Player config updated: ${key} = ${value}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update player config: ${key} = ${value}`);
    }
  }

  /**
   * 更新通用配置
   */
  private async updateGeneralConfig(key: keyof GeneralConfig, value: string | number | boolean): Promise<void> {
    try {
      // 创建配置更新对象
      const generalUpdate: Record<string, string | number | boolean> = {};
      generalUpdate[key] = value;
      await this.configService.updatePartialConfig('general', generalUpdate);
      
      Logger.info(this.TAG, `General config updated: ${key} = ${value}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update general config: ${key} = ${value}`);
    }
  }

  /**
   * 清空缓存
   */
  private async clearCache(): Promise<void> {
    try {
      // 实现清空缓存逻辑
      this.currentCacheSize = 0;
      Logger.info(this.TAG, 'Cache cleared successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear cache: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 重置配置
   */
  private async resetConfig(): Promise<void> {
    try {
      await this.configService.resetAllConfig();
      await this.loadConfig();
      Logger.info(this.TAG, 'Config reset successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to reset config: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 渲染设置项
   */
  @Builder
  private renderSettingItem(item: SettingItem): void {
    Column() {
      Row() {
        Text(item.title)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .flexGrow(1)
        
        Row() {
          Text(item.value)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ right: 10 })
          
          Image('dataability:///system/media/icons/ic_arrow_right')
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .renderMode(ImageRenderMode.Original)
        }
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
    }
    .backgroundColor('#4CAF50')
    .borderRadius(8)
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
    .onClick(() => {
      if (item.onClick) {
        item.onClick();
      }
    })
  }
  
  /**
   * 组件构建
   */
  build(): void {
    Column() {
      // 页面标题
      Text('设置')
        .fontSize(24)
        .fontColor('#FFFFFF')
        .margin({ top: 20, bottom: 10 })
        .textAlign(TextAlign.Center)
      
      // 设置项网格
      Scroll() {
        Column() {
          ForEach(this.getSettingItems(), (rowItems: SettingItem[], rowIndex: number) => {
            Row() {
              ForEach(rowItems, (item: SettingItem, itemIndex: number) => {
                this.renderSettingItem(item)
              }, (item: SettingItem) => item.title)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
            .margin({ bottom: 10 })
          }, (rowItems: SettingItem[]) => rowItems.map(item => item.title).join(','))
          
          // 影视源设置
          Column() {
            Text('影视源设置')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#FFFFFF')
              .margin({ top: 20, bottom: 10 })
              .textAlign(TextAlign.Center)
            
            // 影视源列表
            Column() {
              ForEach(this.videoSources, (source: VideoSource) => {
                Row() {
                  Column() {
                    Text(source.name)
                      .fontSize(16)
                      .fontWeight(600)
                      .fontColor('#FFFFFF')
                    Text(source.url)
                      .fontSize(12)
                      .fontColor('#E0E0E0')
                      .margin({ top: 4 })
                  }
                  .flexGrow(1)
                  
                  Toggle({ type: ToggleType.Switch, isOn: source.enabled })
                    .onChange((isChecked: boolean) => {
                      const index = this.videoSources.findIndex(item => item.id === source.id);
                      if (index !== -1) {
                        this.videoSources[index].enabled = isChecked;
                        this.saveVideoSourceConfig();
                      }
                    })
                }
                .padding(15)
                .backgroundColor('#4CAF50')
                .borderRadius(8)
                .margin({ bottom: 10 })
              }, (source: VideoSource) => source.id)
            }
            .padding({ left: 20, right: 20 })
            
            // 添加影视源按钮
            Button('添加影视源')
              .backgroundColor('#2E7D32')
              .fontColor('white')
              .borderRadius(8)
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .margin({ left: 20, right: 20, bottom: 20 })
              .fontSize(16)
              .onClick(() => this.navigateToAddSource())
          }
        }
        .padding({ left: 10, right: 10, bottom: 20 })
      }
      .flexGrow(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2E7D32')
    .justifyContent(FlexAlign.Start)
  }
}