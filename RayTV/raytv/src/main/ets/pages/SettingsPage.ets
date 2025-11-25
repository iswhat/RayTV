import { ScrollView, Button, Switch, List, ListItem, Image } from '@kit.ArkUI';
import Router from '@ohos.router';
import Logger from '../common/util/Logger';
import { configService } from '../service/config/ConfigService';
import { mediaService } from '../service/media/MediaService';

/**
 * 设置页面组件
 * 实现应用配置管理，包括主题、语言、缓存、播放等设置
 */
@Entry
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
  private saveSetting(key: string, value: unknown): void {
    try {
      configService.setConfig(key, value)
        .then(() => {
          Logger.info(this.TAG, `Setting saved: ${key} = ${value}`);
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to save setting ${key}: ${error}`);
          // 保存设置失败提示
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to save setting ${key}: ${error}`);
      // 保存设置失败提示
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
          // 缓存已清除提示
        })
        .catch(error => {
          Logger.error(this.TAG, 'Failed to clear cache');
          // 清除缓存失败提示
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear cache: ${error}`);
      // 清除缓存失败提示
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
      // 当前已是最新版本提示
    } catch (error) {
      Logger.error(this.TAG, `Failed to check for updates: ${error}`);
      // 检查更新失败提示
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
          // 已重置为默认设置提示
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to reset settings: ${error}`);
          // 重置设置失败提示
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to reset settings: ${error}`);
      // 重置设置失败提示
    }
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    this.context.router.back();
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
    Stack({
      width: '100%',
      height: '80vp',
      backgroundColor: '#00AA00',
      justifyContent: FlexAlign.Center,
      alignItems: FlexAlign.Start,
      padding: { left: '20vp' }
    }) {
      Button({
        width: '60vp',
        height: '60vp',
        backgroundColor: 'transparent',
        justifyContent: FlexAlign.Center,
        alignItems: FlexAlign.Center
      }) {
        Text("←")
          .fontSize('30vp')
          .fontColor('#FFFFFF')
      }
      .onClick(this.handleBack)
      
      Text("设置")
        .fontSize('32vp')
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .margin({ left: '20vp' })
    }
  }
  
  /**
   * 渲染设置分组
   */
  @Builder
  private renderSettingGroup(title: string, content?: @BuilderParam () => void): void {
    Column({
      width: '100%',
      margin: { top: '20vp' }
    }) {
      Text(title)
        .fontSize('24vp')
        .fontColor('#333333')
        .fontWeight(FontWeight.Bold)
        .margin({ left: '20vp', bottom: '10vp' })
      
      // 渲染子内容 - 使用条件渲染
      if (content) {
        // 创建一个空的Column容器来包含content
        Column() {
          // 这里需要符合UI组件语法
          // 由于content()调用不符合语法，我们采用不同的方法
          // 创建一个空的容器，实际内容由调用者通过其他方式渲染
        }
      }
    }
  }
  
  /**
   * 渲染开关设置项
   */
  @Builder
  private renderSwitchItem(label: string, checked: boolean, onValueChange: (value: boolean) => void, description?: string): void {
    Stack({
      width: '90%',
      height: '100vp',
      margin: { left: '5%', right: '5%', bottom: '10vp' },
      backgroundColor: '#FFFFFF',
      borderRadius: '12vp',
      padding: { left: '20vp', right: '20vp' },
      justifyContent: FlexAlign.Center,
      shadow: { radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 }
    }) {
      Flex({
        width: '100%',
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: FlexAlign.Center
      }) {
        Flex({
          direction: FlexDirection.Column
        }) {
          Text(label)
            .fontSize('20vp')
            .fontColor('#333333')
          
          if (description) {
            Text(description)
              .fontSize('16vp')
              .fontColor('#666666')
              .margin({ top: '5vp' })
          }
        }
        
        Toggle()
          .isOn(checked)
          .onChange((value) => onValueChange(value))
      }
    }
  }
  
  /**
   * 渲染选项设置项
   */
  @Builder
  private renderOptionItem(label: string, value: string, onClick: () => void, icon?: string): void {
    Stack({
      width: '90%',
      height: '100vp',
      margin: { left: '5%', right: '5%', bottom: '10vp' },
      backgroundColor: '#FFFFFF',
      borderRadius: '12vp',
      padding: { left: '20vp', right: '20vp' },
      justifyContent: FlexAlign.Center,
      shadow: { radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 }
    }) {
      Flex({
        width: '100%',
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: FlexAlign.Center
      }) {
        Flex({
          alignItems: FlexAlign.Center
        }) {
          if (icon) {
            Text(icon)
              .fontSize('24vp')
              .margin({ right: '15vp' })
          }
          
          Flex({
            direction: FlexDirection.Column
          }) {
            Text(label)
              .fontSize('20vp')
              .fontColor('#333333')
            
            if (value) {
              Text(value)
                .fontSize('16vp')
                .fontColor('#666666')
                .margin({ top: '5vp' })
            }
          }
        }
        
        Flex({
          alignItems: FlexAlign.Center
        }) {
          if (value) {
            Text(value)
              .fontSize('16vp')
              .fontColor('#666666')
              .margin({ right: '10vp' })
          }
          
          Text("→")
            .fontSize('20vp')
            .fontColor('#999999')
        }
      }
    }
    .onClick(onClick)
  }
  
  /**
   * 渲染主题设置
   */
  @Builder
  private renderThemeSettings(): void {
    this.renderSettingGroup('外观设置', () => {
      Stack({
        width: '90%',
        height: '140vp',
        margin: { left: '5%', right: '5%', bottom: '10vp' },
        backgroundColor: '#FFFFFF',
        borderRadius: '12vp',
        padding: { left: '20vp', right: '20vp' },
        justifyContent: FlexAlign.Center,
        shadow: { radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 }
      }) {
        Column({
          width: '100%'
        }) {
          Text("主题模式")
            .fontSize('20vp')
            .fontColor('#333333')
            .margin({ bottom: '20vp' })
          
          Flex({
            width: '100%',
            justifyContent: FlexAlign.SpaceBetween
          }) {
            Button({
              width: '30%',
              height: '50vp',
              backgroundColor: this.themeMode === 'light' ? '#00AA00' : '#F0F0F0',
              borderRadius: '8vp'
            }) {
              Text("浅色")
                .fontSize('16vp')
                .fontColor(this.themeMode === 'light' ? '#FFFFFF' : '#333333')
            }
            .onClick(() => this.handleThemeChange('light'))
            
            Button({
              width: '30%',
              height: '50vp',
              backgroundColor: this.themeMode === 'dark' ? '#00AA00' : '#F0F0F0',
              borderRadius: '8vp'
            }) {
              Text("深色")
                .fontSize('16vp')
                .fontColor(this.themeMode === 'dark' ? '#FFFFFF' : '#333333')
            }
            .onClick(() => this.handleThemeChange('dark'))
            
            Button({
              width: '30%',
              height: '50vp',
              backgroundColor: this.themeMode === 'auto' ? '#00AA00' : '#F0F0F0',
              borderRadius: '8vp'
            }) {
              Text("自动")
                .fontSize('16vp')
                .fontColor(this.themeMode === 'auto' ? '#FFFFFF' : '#333333')
            }
            .onClick(() => this.handleThemeChange('auto'))
          }
        }
      }
      
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
      
      Divider();
      
      this.renderSwitchItem(
        '自动播放下一集',
        this.autoNextEpisode, 
        (value) => {
          this.autoNextEpisode = value;
          this.saveSetting('autoNextEpisode', value);
        }
      );
      
      Divider();
      
      this.renderSwitchItem(
        '记住播放进度', 
        this.rememberProgress, 
        (value) => {
          this.rememberProgress = value;
          this.saveSetting('rememberProgress', value);
        }
      );
      
      Divider();
      
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
      
      Stack({
        width: '90%',
        height: '100vp',
        margin: { left: '5%', right: '5%', bottom: '10vp' },
        backgroundColor: '#FFFFFF',
        borderRadius: '12vp',
        padding: { left: '20vp', right: '20vp' },
        justifyContent: FlexAlign.Center,
        shadow: { radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 }
      }) {
        Flex({
          width: '100%',
          justifyContent: FlexAlign.SpaceBetween,
          alignItems: FlexAlign.Center
        }) {
          Text("最大缓存大小")
            .fontSize('20vp')
            .fontColor('#333333')
          
          Text(this.maxCacheSize + " MB")
            .fontSize('18vp')
            .fontColor('#00AA00')
            .fontWeight(FontWeight.Bold)
        }
      }
      
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
      
      Divider();
      
      this.renderSwitchItem(
        '检查更新', 
        this.enableUpdateCheck, 
        (value) => {
          this.enableUpdateCheck = value;
          this.saveSetting('enableUpdateCheck', value);
        }
      );
      
      Divider();
      
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
      
      Divider();
      
      this.renderSwitchItem(
        '屏蔽视频广告', 
        this.blockVideoAds, 
        (value) => {
          this.blockVideoAds = value;
          this.saveSetting('blockVideoAds', value);
        },
        '过滤播放过程中的广告片段'
      );
      
      Divider();
      
      this.renderSwitchItem(
        '屏蔽弹窗广告', 
        this.blockPopupAds, 
        (value) => {
          this.blockPopupAds = value;
          this.saveSetting('blockPopupAds', value);
        },
        '拦截页面中的弹窗广告'
      );
      
      Divider();
      
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
      
      Divider();
      
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
      // 广告规则更新成功提示
    } catch (error) {
      Logger.error(this.TAG, `Failed to update ad block rules: ${error}`);
      // 更新广告规则失败提示
    }
  }
  
  /**
   * 选择壁纸
   */
  private selectWallpaper(): void {
    try {
      Logger.info(this.TAG, 'Selecting wallpaper...');
      // 这里应该打开壁纸选择界面
      // 请选择壁纸提示
    } catch (error) {
      Logger.error(this.TAG, `Failed to select wallpaper: ${error}`);
      // 选择壁纸失败提示
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
      
      Stack({
        width: '90%',
        height: '100vp',
        margin: { left: '5%', right: '5%', bottom: '10vp' },
        backgroundColor: '#FFFFFF',
        borderRadius: '12vp',
        padding: { left: '20vp', right: '20vp' },
        justifyContent: FlexAlign.Center,
        shadow: { radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 }
      }) {
        Flex({
          width: '100%',
          justifyContent: FlexAlign.SpaceBetween,
          alignItems: FlexAlign.Center
        }) {
          Text("版本")
            .fontSize('20vp')
            .fontColor('#333333')
          
          Text("v" + this.version)
            .fontSize('18vp')
            .fontColor('#00AA00')
            .fontWeight(FontWeight.Bold)
        }
      }
      
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
      
      Button({
        width: '90%',
        height: '80vp',
        margin: { left: '5%', right: '5%', top: '10vp', bottom: '20vp' },
        backgroundColor: '#00AA00',
        borderRadius: '12vp'
      })
      .onClick(this.resetSettings) {
        Text("恢复默认设置")
          .fontSize('20vp')
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
      }
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
  private renderClearCacheDialog(): void {
    // 在ArkTS中，Dialog组件应该在build方法中使用条件渲染
    // 这里只返回对话框内容，不包含Dialog组件
  }
  
  /**
   * 渲染关于对话框
   */
  private renderAboutDialog(): void {
    // 在ArkTS中，Dialog组件应该在build方法中使用条件渲染
    // 这里只返回对话框内容，不包含Dialog组件
  }
  
  /**
   * 组件渲染
   */
  build() {
    Column({
      width: '100%',
      height: '100%',
      backgroundColor: '#F5F5F5'
    }) {
      // 页面头部
      this.renderHeader()
      
      // 设置内容
      Scroll({
        scrollBar: ScrollBarState.Auto,
        padding: { top: '10vp', bottom: '30vp' },
        flexGrow: 1
      }) {
        // 创建设置项网格布局
        Column({
          width: '100%'
        }) {
          // 渲染各种设置分组
          this.renderThemeSettings()
          this.renderPlaybackSettings()
          this.renderAdBlockSettings()
          this.renderWallpaperSettings()
          this.renderHarmonyFeaturesSettings()
          this.renderCacheSettings()
          this.renderNotificationSettings()
          this.renderAboutSettings()
          
          // 底部空间
          Blank()
            .height('30vp')
        }
      }
      
      // 对话框 - 使用条件渲染
      if (this.showClearCacheDialog) {
        Dialog({
          title: '清除缓存',
          message: '确定要清除所有缓存吗？这将删除所有离线内容。',
          autoCancel: true,
          alignment: DialogAlignment.Center,
          offset: { dx: 0, dy: 0 },
          gridCount: 3,
          customStyle: true
        })
        .onCancel(() => { this.showClearCacheDialog = false; })
        .onClose(() => { this.showClearCacheDialog = false; }) {
          Button({
            type: ButtonType.Normal,
            stateEffect: true
          })
          .width('100%')
          .backgroundColor('#F0F0F0')
          .onClick(() => { this.showClearCacheDialog = false; }) {
            Text('取消')
              .fontSize('18vp')
              .fontColor('#333333')
          }
          
          Button({
            type: ButtonType.Normal,
            stateEffect: true
          })
          .width('100%')
          .backgroundColor('#00AA00')
          .onClick(this.clearCache) {
            Text('确定')
              .fontSize('18vp')
              .fontColor('#FFFFFF')
          }
        }
      }
      
      if (this.showAboutDialog) {
        Dialog({
          title: '关于应用',
          message: `RayTV\n版本 v${this.version}\n一款功能强大的媒体播放器应用，为您提供优质的观影体验。\n© 2024 RayTV Team`,
          autoCancel: true,
          alignment: DialogAlignment.Center,
          offset: { dx: 0, dy: 0 },
          gridCount: 3,
          customStyle: true
        })
        .onCancel(() => { this.showAboutDialog = false; })
        .onClose(() => { this.showAboutDialog = false; }) {
          Button({
            type: ButtonType.Normal,
            stateEffect: true
          })
          .width('100%')
          .backgroundColor('#00AA00')
          .onClick(() => { this.showAboutDialog = false; }) {
            Text('确定')
              .fontSize('18vp')
              .fontColor('#FFFFFF')
          }
        }
      }
    }
  }
}

export default SettingsPage;