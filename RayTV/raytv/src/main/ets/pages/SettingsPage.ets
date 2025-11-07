import { ScrollView, Text, Button, Switch, List, ListItem, Divider, Image, Dialog, Toast } from '@kit.ArkUI';
import { Router } from '@ohos.router';
import Logger from '../common/util/Logger';
import { configService } from '../service/config/ConfigService';
import { mediaService } from '../service/media/MediaService';

/**
 * 设置页面组件
 * 实现应用配置管理，包括主题、语言、缓存、播放等设置
 */
@Component
struct SettingsPage {
  private readonly TAG: string = 'SettingsPage';
  
  // 状态管理
  @State themeMode: 'light' | 'dark' | 'auto' = 'auto';
  @State language: 'zh' | 'en' = 'zh';
  @State autoPlay: boolean = true;
  @State autoNextEpisode: boolean = true;
  @State rememberProgress: boolean = true;
  @State enableHardwareAcceleration: boolean = true;
  @State cacheStrategy: 'memory' | 'disk' | 'none' = 'disk';
  @State maxCacheSize: number = 1024; // MB
  @State currentCacheSize: number = 0;
  @State enableUpdateCheck: boolean = true;
  @State notificationsEnabled: boolean = true;
  @State version: string = '1.0.0';
  
  // 广告屏蔽设置
  @State enableAdBlock: boolean = true;
  @State blockVideoAds: boolean = true;
  @State blockPopupAds: boolean = true;
  
  // 壁纸设置
  @State enableWallpaper: boolean = false;
  @State wallpaperType: 'none' | 'image' | 'video' = 'none';
  
  // 鸿蒙特有功能设置
  @State enableVoiceAssistant: boolean = true;
  @State enableDeviceFlow: boolean = true;
  
  // 对话框状态
  @State showClearCacheDialog: boolean = false;
  @State showAboutDialog: boolean = false;
  
  // 初始化
  /**
   * 页面加载时调用
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'SettingsPage appeared');
    this.loadSettings();
    this.calculateCacheSize();
  }

  /**
   * 页面卸载时调用
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'SettingsPage disappeared');
  }
  
  /**
   * 加载设置
   */
  private loadSettings(): void {
    try {
      // 从配置服务加载设置
      // 使用Promise链来加载所有设置
      configService.getConfig('themeMode', 'auto')
        .then(themeMode => {
          this.themeMode = themeMode;
          return configService.getConfig('language', 'zh');
        })
        .then(language => {
          this.language = language;
          return configService.getConfig('autoPlay', true);
        })
        .then(autoPlay => {
          this.autoPlay = autoPlay;
          return configService.getConfig('autoNextEpisode', true);
        })
        .then(autoNextEpisode => {
          this.autoNextEpisode = autoNextEpisode;
          return configService.getConfig('rememberProgress', true);
        })
        .then(rememberProgress => {
          this.rememberProgress = rememberProgress;
          return configService.getConfig('enableHardwareAcceleration', true);
        })
        .then(enableHardwareAcceleration => {
          this.enableHardwareAcceleration = enableHardwareAcceleration;
          return configService.getConfig('cacheStrategy', 'disk');
        })
        .then(cacheStrategy => {
          this.cacheStrategy = cacheStrategy;
          return configService.getConfig('maxCacheSize', 1024);
        })
        .then(maxCacheSize => {
          this.maxCacheSize = maxCacheSize;
          return configService.getConfig('enableUpdateCheck', true);
        })
        .then(enableUpdateCheck => {
          this.enableUpdateCheck = enableUpdateCheck;
          return configService.getConfig('notificationsEnabled', true);
        })
        .then(notificationsEnabled => {
          this.notificationsEnabled = notificationsEnabled;
          return configService.getConfig('enableAdBlock', true);
        })
        .then(enableAdBlock => {
          this.enableAdBlock = enableAdBlock;
          return configService.getConfig('blockVideoAds', true);
        })
        .then(blockVideoAds => {
          this.blockVideoAds = blockVideoAds;
          return configService.getConfig('blockPopupAds', true);
        })
        .then(blockPopupAds => {
          this.blockPopupAds = blockPopupAds;
          return configService.getConfig('enableWallpaper', false);
        })
        .then(enableWallpaper => {
          this.enableWallpaper = enableWallpaper;
          return configService.getConfig('wallpaperType', 'none');
        })
        .then(wallpaperType => {
          this.wallpaperType = wallpaperType;
          return configService.getConfig('enableVoiceAssistant', true);
        })
        .then(enableVoiceAssistant => {
          this.enableVoiceAssistant = enableVoiceAssistant;
          return configService.getConfig('enableDeviceFlow', true);
        })
        .then(enableDeviceFlow => {
          this.enableDeviceFlow = enableDeviceFlow;
          // 获取应用版本
          return this.getAppVersion();
        })
        .then(version => {
          this.version = version;
          Logger.info(this.TAG, 'Settings loaded successfully');
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to load settings: ${error}`);
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load settings: ${error}`);
    }
  }
  
  /**
   * 保存设置
   */
  private saveSetting(key: string, value: any): void {
    try {
      configService.setConfig(key, value)
        .then(() => {
          Logger.info(this.TAG, `Setting saved: ${key} = ${value}`);
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to save setting ${key}: ${error}`);
          Toast.show({ message: '保存设置失败' });
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to save setting ${key}: ${error}`);
      Toast.show({ message: '保存设置失败' });
    }
  }
  
  /**
   * 计算缓存大小
   */
  private calculateCacheSize(): void {
    try {
      // 这里应该调用缓存管理服务计算缓存大小
      // 暂时使用模拟数据
      this.currentCacheSize = 235; // MB
      Logger.info(this.TAG, `Cache size calculated: ${this.currentCacheSize} MB`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to calculate cache size: ${error}`);
    }
  }
  
  /**
   * 清除缓存
   */
  private clearCache(): void {
    try {
      // 调用相关服务清除缓存
      mediaService.clearCache()
        .then(() => {
          // 更新缓存大小
          this.currentCacheSize = 0;
          this.showClearCacheDialog = false;
          
          Logger.info(this.TAG, 'Cache cleared successfully');
          Toast.show({ message: '缓存已清除' });
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to clear cache: ${error}`);
          Toast.show({ message: '清除缓存失败' });
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear cache: ${error}`);
      Toast.show({ message: '清除缓存失败' });
    }
  }
  
  /**
   * 获取应用版本
   */
  private getAppVersion(): string {
    try {
      // 这里应该从应用配置中获取版本号
      // 暂时返回固定版本
      return '1.0.0';
    } catch (error) {
      Logger.error(this.TAG, `Failed to get app version: ${error}`);
      return '1.0.0';
    }
  }
  
  /**
   * 检查更新
   */
  private checkForUpdates(): void {
    try {
      // 调用更新检查服务
      Logger.info(this.TAG, 'Checking for updates...');
      
      // 模拟检查更新
      Toast.show({ message: '当前已是最新版本' });
    } catch (error) {
      Logger.error(this.TAG, `Failed to check for updates: ${error}`);
      Toast.show({ message: '检查更新失败' });
    }
  }
  
  /**
   * 重置所有设置
   */
  private resetSettings(): void {
    try {
      // 重置配置服务中的所有设置
      configService.resetAllConfigs()
        .then(() => {
          // 重新加载设置
          this.loadSettings();
          
          Logger.info(this.TAG, 'Settings reset to default');
          Toast.show({ message: '已重置为默认设置' });
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to reset settings: ${error}`);
          Toast.show({ message: '重置设置失败' });
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to reset settings: ${error}`);
      Toast.show({ message: '重置设置失败' });
    }
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    Router.back();
  }
  
  /**
   * 处理主题切换
   */
  private handleThemeChange(theme: 'light' | 'dark' | 'auto'): void {
    this.themeMode = theme;
    this.saveSetting('themeMode', theme);
    // 这里应该应用主题切换
  }
  
  /**
   * 渲染头部
   */
  @Builder
  private renderHeader(): void {
    Stack.create();
    Stack.width('100%');
    Stack.height('80vp');
    Stack.backgroundColor('#00AA00');
    Stack.justifyContent(FlexAlign.Center);
    Stack.alignItems(FlexAlign.Start);
    Stack.padding({ left: '20vp' });
    
    Button.create();
    Button.width('60vp');
    Button.height('60vp');
    Button.backgroundColor('transparent');
    Button.justifyContent(FlexAlign.Center);
    Button.alignItems(FlexAlign.Center);
    Button.onClick(this.handleBack);
    Text.create();
    Text.fontSize('30vp');
    Text.text("←");
    Text.fontColor('#FFFFFF');
    Text.pop();
    Button.pop();
    
    Text.create();
    Text.fontSize('32vp');
    Text.fontColor('#FFFFFF');
    Text.fontWeight(FontWeight.Bold);
    Text.text("设置");
    Text.margin({ left: '20vp' });
    Text.pop();
    
    Stack.pop();
  }
  
  /**
   * 渲染设置分组
   */
  @Builder
  private renderSettingGroup(title: string, content: () => void): void {
    Column.create();
    Column.width('100%');
    Column.margin({ top: '20vp' });
    
    Text.create();
    Text.fontSize('24vp');
    Text.fontColor('#333333');
    Text.fontWeight(FontWeight.Bold);
    Text.margin({ left: '20vp', bottom: '10vp' });
    Text.text(title);
    Text.pop();
    
    content();
    
    Column.pop();
  }
  
  /**
   * 渲染开关设置项
   */
  @Builder
  private renderSwitchItem(label: string, checked: boolean, onValueChange: (value: boolean) => void, description?: string): void {
    Stack.create();
    Stack.width('90%');
    Stack.height('100vp');
    Stack.margin({ left: '5%', right: '5%', bottom: '10vp' });
    Stack.backgroundColor('#FFFFFF');
    Stack.borderRadius('12vp');
    Stack.padding({ left: '20vp', right: '20vp' });
    Stack.justifyContent(FlexAlign.Center);
    Stack.shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 });
    
    Flex.create();
    Flex.width('100%');
    Flex.justifyContent(FlexAlign.SpaceBetween);
    Flex.alignItems(FlexAlign.Center);
    
    Flex.create();
    Flex.direction(FlexDirection.Column);
    
    Text.create();
    Text.fontSize('20vp');
    Text.fontColor('#333333');
    Text.text(label);
    Text.pop();
    
    if (description) {
      Text.create();
      Text.fontSize('14vp');
      Text.fontColor('#666666');
      Text.margin({ top: '5vp' });
      Text.text(description);
      Text.pop();
    }
    
    Flex.pop();
    
    Switch.create();
    Switch.checked(checked);
    Switch.onValueChange(onValueChange);
    Switch.trackColor({ checked: '#00AA00', unchecked: '#DDDDDD' });
    Switch.thumbColor('#FFFFFF');
    Switch.width('80vp');
    Switch.height('40vp');
    Switch.pop();
    
    Flex.pop();
    Stack.pop();
  }
  
  /**
   * 渲染选项设置项
   */
  @Builder
  private renderOptionItem(label: string, value: string, onClick: () => void, icon?: string): void {
    Stack.create();
    Stack.width('90%');
    Stack.height('100vp');
    Stack.margin({ left: '5%', right: '5%', bottom: '10vp' });
    Stack.backgroundColor('#FFFFFF');
    Stack.borderRadius('12vp');
    Stack.padding({ left: '20vp', right: '20vp' });
    Stack.justifyContent(FlexAlign.Center);
    Stack.shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 });
    Stack.onClick(onClick);
    
    Flex.create();
    Flex.width('100%');
    Flex.justifyContent(FlexAlign.SpaceBetween);
    Flex.alignItems(FlexAlign.Center);
    
    Flex.create();
    Flex.alignItems(FlexAlign.Center);
    
    if (icon) {
      Text.create();
      Text.fontSize('24vp');
      Text.margin({ right: '15vp' });
      Text.text(icon);
      Text.pop();
    }
    
    Flex.create();
    Flex.direction(FlexDirection.Column);
    
    Text.create();
    Text.fontSize('20vp');
    Text.fontColor('#333333');
    Text.text(label);
    Text.pop();
    
    if (value) {
      Text.create();
      Text.fontSize('16vp');
      Text.fontColor('#666666');
      Text.margin({ top: '5vp' });
      Text.text(value);
      Text.pop();
    }
    
    Flex.pop();
    Flex.pop();
    
    Flex.create();
    Flex.alignItems(FlexAlign.Center);
    
    if (value) {
      Text.create();
      Text.fontSize('16vp');
      Text.fontColor('#666666');
      Text.margin({ right: '10vp' });
      Text.text(value);
      Text.pop();
    }
    
    Text.create();
    Text.fontSize('20vp');
    Text.fontColor('#999999');
    Text.text("→");
    Text.pop();
    
    Flex.pop();
    
    Flex.pop();
    Stack.pop();
  }
  
  /**
   * 渲染主题设置
   */
  @Builder
  private renderThemeSettings(): void {
    this.renderSettingGroup('外观设置', () => {
      Stack.create();
      Stack.width('90%');
      Stack.height('140vp');
      Stack.margin({ left: '5%', right: '5%', bottom: '10vp' });
      Stack.backgroundColor('#FFFFFF');
      Stack.borderRadius('12vp');
      Stack.padding({ left: '20vp', right: '20vp' });
      Stack.justifyContent(FlexAlign.Center);
      Stack.shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 });
      
      Column.create();
      Column.width('100%');
      
      Text.create();
      Text.fontSize('20vp');
      Text.fontColor('#333333');
      Text.margin({ bottom: '20vp' });
      Text.text("主题模式");
      Text.pop();
      
      Flex.create();
      Flex.width('100%');
      Flex.justifyContent(FlexAlign.SpaceBetween);
      
      Button.create();
      Button.width('30%');
      Button.height('50vp');
      Button.backgroundColor(this.themeMode === 'light' ? '#00AA00' : '#F0F0F0');
      Button.borderRadius('8vp');
      Button.onClick(() => this.handleThemeChange('light'));
      Text.create();
      Text.fontSize('16vp');
      Text.fontColor(this.themeMode === 'light' ? '#FFFFFF' : '#333333');
      Text.text("浅色");
      Text.pop();
      Button.pop();
      
      Button.create();
      Button.width('30%');
      Button.height('50vp');
      Button.backgroundColor(this.themeMode === 'dark' ? '#00AA00' : '#F0F0F0');
      Button.borderRadius('8vp');
      Button.onClick(() => this.handleThemeChange('dark'));
      Text.create();
      Text.fontSize('16vp');
      Text.fontColor(this.themeMode === 'dark' ? '#FFFFFF' : '#333333');
      Text.text("深色");
      Text.pop();
      Button.pop();
      
      Button.create();
      Button.width('30%');
      Button.height('50vp');
      Button.backgroundColor(this.themeMode === 'auto' ? '#00AA00' : '#F0F0F0');
      Button.borderRadius('8vp');
      Button.onClick(() => this.handleThemeChange('auto'));
      Text.create();
      Text.fontSize('16vp');
      Text.fontColor(this.themeMode === 'auto' ? '#FFFFFF' : '#333333');
      Text.text("自动");
      Text.pop();
      Button.pop();
      
      Flex.pop();
      Column.pop();
      Stack.pop();
      
      this.renderOptionItem(
        '语言', 
        this.language === 'zh' ? '简体中文' : 'English', 
        () => {}
      );
    });
  }
  
  /**
   * 渲染播放设置
   */
  @Builder
  private renderPlaybackSettings(): void {
    this.renderSettingGroup('播放设置', () => {
      this.renderSwitchItem(
        '自动播放', 
        this.autoPlay, 
        (value) => {
          this.autoPlay = value;
          this.saveSetting('autoPlay', value);
        },
        '进入播放页后自动开始播放'
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderSwitchItem(
        '自动播放下一集',
        this.autoNextEpisode, 
        (value) => {
          this.autoNextEpisode = value;
          this.saveSetting('autoNextEpisode', value);
        }
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderSwitchItem(
        '记住播放进度', 
        this.rememberProgress, 
        (value) => {
          this.rememberProgress = value;
          this.saveSetting('rememberProgress', value);
        }
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderSwitchItem(
        '硬件加速', 
        this.enableHardwareAcceleration, 
        (value) => {
          this.enableHardwareAcceleration = value;
          this.saveSetting('enableHardwareAcceleration', value);
        },
        '使用硬件加速提高播放流畅度'
      );
    });
  }
  
  /**
   * 渲染缓存设置
   */
  @Builder
  private renderCacheSettings(): void {
    this.renderSettingGroup('缓存设置', () => {
      this.renderOptionItem(
        '缓存策略', 
        this.getCacheStrategyText(), 
        () => {}
      );
      
      Stack.create();
      Stack.width('90%');
      Stack.height('100vp');
      Stack.margin({ left: '5%', right: '5%', bottom: '10vp' });
      Stack.backgroundColor('#FFFFFF');
      Stack.borderRadius('12vp');
      Stack.padding({ left: '20vp', right: '20vp' });
      Stack.justifyContent(FlexAlign.Center);
      Stack.shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 });
      
      Flex.create();
      Flex.width('100%');
      Flex.justifyContent(FlexAlign.SpaceBetween);
      Flex.alignItems(FlexAlign.Center);
      
      Text.create();
      Text.fontSize('20vp');
      Text.fontColor('#333333');
      Text.text("最大缓存大小");
      Text.pop();
      
      Text.create();
      Text.fontSize('18vp');
      Text.fontColor('#00AA00');
      Text.fontWeight(FontWeight.Bold);
      Text.text(this.maxCacheSize + " MB");
      Text.pop();
      
      Flex.pop();
      Stack.pop();
      
      this.renderOptionItem(
        '清除缓存', 
        `${this.currentCacheSize} MB`, 
        () => { this.showClearCacheDialog = true; },
        '🗑️'
      );
    });
  }
  
  /**
   * 渲染通知设置
   */
  @Builder
  private renderNotificationSettings(): void {
    this.renderSettingGroup('通知设置', () => {
      this.renderSwitchItem(
        '开启通知', 
        this.notificationsEnabled, 
        (value) => {
          this.notificationsEnabled = value;
          this.saveSetting('notificationsEnabled', value);
        }
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderSwitchItem(
        '检查更新', 
        this.enableUpdateCheck, 
        (value) => {
          this.enableUpdateCheck = value;
          this.saveSetting('enableUpdateCheck', value);
        }
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderOptionItem(
        '检查更新', 
        '', 
        this.checkForUpdates,
        '🔄'
      );
    });
  }
  
  /**
   * 渲染广告屏蔽设置
   */
  @Builder
  private renderAdBlockSettings(): void {
    this.renderSettingGroup('广告屏蔽', () => {
      this.renderSwitchItem(
        '启用广告屏蔽', 
        this.enableAdBlock, 
        (value) => {
          this.enableAdBlock = value;
          this.saveSetting('enableAdBlock', value);
        },
        '屏蔽视频中的广告内容'
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderSwitchItem(
        '屏蔽视频广告', 
        this.blockVideoAds, 
        (value) => {
          this.blockVideoAds = value;
          this.saveSetting('blockVideoAds', value);
        },
        '过滤播放过程中的广告片段'
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderSwitchItem(
        '屏蔽弹窗广告', 
        this.blockPopupAds, 
        (value) => {
          this.blockPopupAds = value;
          this.saveSetting('blockPopupAds', value);
        },
        '拦截页面中的弹窗广告'
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderOptionItem(
        '更新广告规则', 
        '', 
        this.updateAdBlockRules,
        '🔄'
      );
    });
  }
  
  /**
   * 渲染壁纸设置
   */
  @Builder
  private renderWallpaperSettings(): void {
    this.renderSettingGroup('壁纸设置', () => {
      this.renderSwitchItem(
        '启用壁纸', 
        this.enableWallpaper, 
        (value) => {
          this.enableWallpaper = value;
          this.saveSetting('enableWallpaper', value);
        },
        '自定义应用背景壁纸'
      );
      
      this.renderOptionItem(
        '壁纸类型', 
        this.getWallpaperTypeText(), 
        () => {}
      );
      
      this.renderOptionItem(
        '选择壁纸', 
        '', 
        this.selectWallpaper,
        '🖼️'
      );
    });
  }
  
  /**
   * 渲染鸿蒙特有功能设置
   */
  @Builder
  private renderHarmonyFeaturesSettings(): void {
    this.renderSettingGroup('鸿蒙功能', () => {
      this.renderSwitchItem(
        '小艺语音助手', 
        this.enableVoiceAssistant, 
        (value) => {
          this.enableVoiceAssistant = value;
          this.saveSetting('enableVoiceAssistant', value);
        },
        '通过语音控制应用功能'
      );
      
      Divider.create();
      Divider.pop();
      
      this.renderSwitchItem(
        '设备流转', 
        this.enableDeviceFlow, 
        (value) => {
          this.enableDeviceFlow = value;
          this.saveSetting('enableDeviceFlow', value);
        },
        '在不同设备间无缝切换播放'
      );
    });
  }
  
  /**
   * 更新广告规则
   */
  private updateAdBlockRules(): void {
    try {
      Logger.info(this.TAG, 'Updating ad block rules...');
      // 这里应该调用广告屏蔽服务更新规则
      Toast.show({ message: '广告规则更新成功' });
    } catch (error) {
      Logger.error(this.TAG, `Failed to update ad block rules: ${error}`);
      Toast.show({ message: '更新广告规则失败' });
    }
  }
  
  /**
   * 选择壁纸
   */
  private selectWallpaper(): void {
    try {
      Logger.info(this.TAG, 'Selecting wallpaper...');
      // 这里应该打开壁纸选择界面
      Toast.show({ message: '请选择壁纸' });
    } catch (error) {
      Logger.error(this.TAG, `Failed to select wallpaper: ${error}`);
      Toast.show({ message: '选择壁纸失败' });
    }
  }
  
  /**
   * 获取壁纸类型文本
   */
  private getWallpaperTypeText(): string {
    switch (this.wallpaperType) {
      case 'none':
        return '无壁纸';
      case 'image':
        return '图片壁纸';
      case 'video':
        return '视频壁纸';
      default:
        return '无壁纸';
    }
  }
  
  /**
   * 渲染关于设置
   */
  @Builder
  private renderAboutSettings(): void {
    this.renderSettingGroup('关于', () => {
      this.renderOptionItem(
        '关于应用', 
        '', 
        () => { this.showAboutDialog = true; },
        'ℹ️'
      );
      
      Stack.create();
      Stack.width('90%');
      Stack.height('100vp');
      Stack.margin({ left: '5%', right: '5%', bottom: '10vp' });
      Stack.backgroundColor('#FFFFFF');
      Stack.borderRadius('12vp');
      Stack.padding({ left: '20vp', right: '20vp' });
      Stack.justifyContent(FlexAlign.Center);
      Stack.shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 });
      
      Flex.create();
      Flex.width('100%');
      Flex.justifyContent(FlexAlign.SpaceBetween);
      Flex.alignItems(FlexAlign.Center);
      
      Text.create();
      Text.fontSize('20vp');
      Text.fontColor('#333333');
      Text.text("版本");
      Text.pop();
      
      Text.create();
      Text.fontSize('18vp');
      Text.fontColor('#00AA00');
      Text.fontWeight(FontWeight.Bold);
      Text.text("v" + this.version);
      Text.pop();
      
      Flex.pop();
      Stack.pop();
      
      this.renderOptionItem(
        '用户协议', 
        '', 
        () => {},
        '📄'
      );
      
      this.renderOptionItem(
        '隐私政策', 
        '', 
        () => {},
        '🔒'
      );
      
      Button.create();
      Button.width('90%');
      Button.height('80vp');
      Button.margin({ left: '5%', right: '5%', top: '10vp', bottom: '20vp' });
      Button.backgroundColor('#00AA00');
      Button.borderRadius('12vp');
      Button.onClick(this.resetSettings);
      Text.create();
      Text.fontSize('20vp');
      Text.fontColor('#FFFFFF');
      Text.fontWeight(FontWeight.Bold);
      Text.content("恢复默认设置");
      Text.pop();
      Button.pop();
    });
  }
  
  /**
   * 获取缓存策略文本
   */
  private getCacheStrategyText(): string {
    switch (this.cacheStrategy) {
      case 'memory':
        return '仅内存';
      case 'disk':
        return '磁盘';
      case 'none':
        return '无缓存';
      default:
        return '磁盘';
    }
  }
  
  /**
   * 渲染清除缓存对话框
   */
  @Builder
  private renderClearCacheDialog(): void {
    Dialog.create();
    Dialog.open(this.showClearCacheDialog);
    Dialog.onCancel(() => { this.showClearCacheDialog = false; });
    Dialog.onClose(() => { this.showClearCacheDialog = false; });
    Stack.create();
    Stack.width('80%');
    Stack.height('280vp');
    Stack.backgroundColor('#FFFFFF');
    Stack.borderRadius('16vp');
    Stack.padding({ left: '20vp', right: '20vp', top: '30vp', bottom: '20vp' });
    Stack.justifyContent(FlexAlign.SpaceBetween);
    
    Column.create();
    Column.alignItems(FlexAlign.Center);
    
    Text.create();
    Text.fontSize('24vp');
    Text.fontColor('#333333');
    Text.fontWeight(FontWeight.Bold);
    Text.margin({ bottom: '20vp' });
    Text.content("清除缓存");
    Text.pop();
    
    Text.create();
    Text.fontSize('18vp');
    Text.fontColor('#666666');
    Text.textAlign(TextAlign.Center);
    Text.content("确定要清除所有缓存吗？这将删除所有离线内容。");
    Text.pop();
    
    Column.pop();
    
    Flex.create();
    Flex.width('100%');
    Flex.justifyContent(FlexAlign.SpaceBetween);
    
    Button.create();
    Button.width('48%');
    Button.height('60vp');
    Button.backgroundColor('#F0F0F0');
    Button.borderRadius('30vp');
    Button.onClick(() => { this.showClearCacheDialog = false; });
    Text.create();
    Text.fontSize('18vp');
    Text.fontColor('#333333');
    Text.content("取消");
    Text.pop();
    Button.pop();
    
    Button.create();
    Button.width('48%');
    Button.height('60vp');
    Button.backgroundColor('#00AA00');
    Button.borderRadius('30vp');
    Button.onClick(this.clearCache);
    Text.create();
    Text.fontSize('18vp');
    Text.fontColor('#FFFFFF');
    Text.content("确定");
    Text.pop();
    Button.pop();
    
    Flex.pop();
    Stack.pop();
    Dialog.pop();
  }
  
  /**
   * 渲染关于对话框
   */
  @Builder
  private renderAboutDialog(): void {
    Dialog.create();
    Dialog.open(this.showAboutDialog);
    Dialog.onCancel(() => { this.showAboutDialog = false; });
    Dialog.onClose(() => { this.showAboutDialog = false; });
    Stack.create();
    Stack.width('85%');
    Stack.height('400vp');
    Stack.backgroundColor('#FFFFFF');
    Stack.borderRadius('16vp');
    Stack.padding({ left: '20vp', right: '20vp', top: '30vp', bottom: '20vp' });
    Stack.justifyContent(FlexAlign.Center);
    Stack.alignItems(FlexAlign.Center);
    
    Column.create();
    Column.alignItems(FlexAlign.Center);
    
    Stack.create();
    Stack.width('120vp');
    Stack.height('120vp');
    Stack.backgroundColor('#00AA00');
    Stack.borderRadius('24vp');
    Stack.justifyContent(FlexAlign.Center);
    Stack.alignItems(FlexAlign.Center);
    Text.create();
    Text.fontSize('60vp');
    Text.fontColor('#FFFFFF');
    Text.text('RT');
    Text.pop();
    Stack.pop();
    
    Text.create();
    Text.fontSize('28vp');
    Text.fontColor('#333333');
    Text.fontWeight(FontWeight.Bold);
    Text.margin({ top: '20vp' });
    Text.content("RayTV");
    Text.pop();
    
    Text.create();
    Text.fontSize('18vp');
    Text.fontColor('#00AA00');
    Text.margin({ top: '10vp' });
    Text.content("版本 v" + this.version);
    Text.pop();
    
    Text.create();
    Text.fontSize('16vp');
    Text.fontColor('#666666');
    Text.textAlign(TextAlign.Center);
    Text.margin({ top: '20vp', left: '10vp', right: '10vp' });
    Text.content("一款功能强大的媒体播放器应用，为您提供优质的观影体验。");
    Text.pop();
    
    Text.create();
    Text.fontSize('14vp');
    Text.fontColor('#999999');
    Text.margin({ top: '20vp' });
    Text.content("© 2024 RayTV Team");
    Text.pop();
    
    Button.create();
    Button.width('60%');
    Button.height('60vp');
    Button.backgroundColor('#00AA00');
    Button.borderRadius('30vp');
    Button.margin({ top: '20vp' });
    Button.onClick(() => { this.showAboutDialog = false; });
    Text.create();
    Text.fontSize('18vp');
    Text.fontColor('#FFFFFF');
    Text.content("确定");
    Text.pop();
    Button.pop();
    
    Column.pop();
    Stack.pop();
    Dialog.pop();
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack.create();
    Stack.width('100%');
    Stack.height('100%');
    Stack.backgroundColor('#F5F5F5');
    
    // 页面头部
    this.renderHeader();
    
    // 设置内容
    ScrollView.create();
    ScrollView.width('100%');
    ScrollView.height('100%');
    ScrollView.scrollBar(ScrollBarState.Auto);
    ScrollView.padding({ top: '10vp', bottom: '30vp' });
    
    // 创建设置项网格布局
    Column.create();
    Column.width('100%');
    
    // 渲染各种设置分组
    this.renderThemeSettings();
    this.renderPlaybackSettings();
    this.renderAdBlockSettings();
    this.renderWallpaperSettings();
    this.renderHarmonyFeaturesSettings();
    this.renderCacheSettings();
    this.renderNotificationSettings();
    this.renderAboutSettings();
    
    // 底部空间
    Blank.create();
    Blank.height('30vp');
    Blank.pop();
    
    Column.pop();
    ScrollView.pop();
    
    // 对话框
    this.renderClearCacheDialog();
    this.renderAboutDialog();
    
    Stack.pop();
  }
}

export default SettingsPage;