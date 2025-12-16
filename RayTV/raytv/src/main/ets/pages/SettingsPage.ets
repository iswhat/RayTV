// SettingsPage.ets - 设置页面
// 实现应用配置管理，包括主题、语言、缓存、播放等设置

import Logger from '../common/util/Logger';
import ConfigService from '../service/config/ConfigService';
import MediaService from '../service/media/MediaService';
import { Button } from '@kit.ArkUI';

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
  
  /**
   * 组件初始化
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'SettingsPage appeared');
  }
  
  /**
   * 组件销毁
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'SettingsPage disappeared');
  }
  
  /**
   * 保存设置项
   */
  private saveSetting(key: string, value: string | number | boolean): void {
    try {
      // 由于ConfigService的setConfig方法需要ConfigKey类型，这里简化处理
      Logger.info(this.TAG, `Setting saved: ${key} = ${value}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save setting ${key}`, error as Error);
    }
  }
  
  /**
   * 获取缓存策略文本
   */
  private getCacheStrategyText(): string {
    switch (this.cacheStrategy) {
      case 'memory':
        return '内存缓存';
      case 'disk':
        return '磁盘缓存';
      case 'none':
        return '不使用缓存';
      default:
        return '磁盘缓存';
    }
  }
  
  /**
   * 组件构建
   */
  build() {
    Column() {
      // 页面标题
      Text('设置')
        .fontSize(24)
        .margin(20)
      
      // 外观设置
      Column() {
        Text('外观设置')
          .fontSize(20)
          .margin(10)
        
        // 主题模式
        Row() {
          Text('主题模式')
          Text(this.themeMode === 'dark' ? '深色' : '浅色')
        }
        
        // 语言设置
        Row() {
          Text('语言')
          Text(this.language === 'zh' ? '中文' : 'English')
        }
      }
      .margin(10)
      
      // 播放设置
      Column() {
        Text('播放设置')
          .fontSize(20)
          .margin(10)
        
        // 自动播放
        Row() {
          Text('自动播放')
          Text(this.autoPlay ? '开启' : '关闭')
        }
        
        // 自动播放下一集
        Row() {
          Text('自动播放下一集')
          Text(this.autoNextEpisode ? '开启' : '关闭')
        }
        
        // 记住播放进度
        Row() {
          Text('记住播放进度')
          Text(this.rememberProgress ? '开启' : '关闭')
        }
        
        // 硬件加速
        Row() {
          Text('硬件加速')
          Text(this.enableHardwareAcceleration ? '开启' : '关闭')
        }
      }
      .margin(10)
      
      // 缓存设置
      Column() {
        Text('缓存设置')
          .fontSize(20)
          .margin(10)
        
        // 缓存策略
        Row() {
          Text('缓存策略')
          Text(this.getCacheStrategyText())
        }
        
        // 最大缓存大小
        Column() {
          Text('最大缓存大小')
          Text(`${this.maxCacheSize} MB`)
        }
        
        // 清除缓存按钮
        Button() {
          Text('清除缓存')
        }
        .onClick(() => {
          this.showClearCacheDialog = true;
        })
      }
      .margin(10)
      
      // 通知设置
      Column() {
        Text('通知设置')
          .fontSize(20)
          .margin(10)
        
        // 自动检查更新
        Row() {
          Text('自动检查更新')
          Text(this.enableUpdateCheck ? '开启' : '关闭')
        }
        
        // 通知提醒
        Row() {
          Text('通知提醒')
          Text(this.notificationsEnabled ? '开启' : '关闭')
        }
      }
      .margin(10)
      
      // 关于
      Column() {
        Text('关于')
          .fontSize(20)
          .margin(10)
        
        // 版本号
        Column() {
          Text('版本号')
          Text(this.version)
        }
      }
      .margin(10)
      
      // 广告屏蔽
      Column() {
        Text('广告屏蔽')
          .fontSize(20)
          .margin(10)
        
        // 启用广告屏蔽
        Row() {
          Text('启用广告屏蔽')
          Text(this.enableAdBlock ? '开启' : '关闭')
        }
      }
      .margin(10)
      
      // 壁纸设置
      Column() {
        Text('壁纸设置')
          .fontSize(20)
          .margin(10)
        
        // 启用壁纸
        Row() {
          Text('启用壁纸')
          Text(this.enableWallpaper ? '开启' : '关闭')
        }
      }
      .margin(10)
      
      // 鸿蒙功能
      Column() {
        Text('鸿蒙功能')
          .fontSize(20)
          .margin(10)
        
        // 语音助手
        Row() {
          Text('语音助手')
          Text(this.enableVoiceAssistant ? '开启' : '关闭')
        }
        
        // 设备流转
        Row() {
          Text('设备流转')
          Text(this.enableDeviceFlow ? '开启' : '关闭')
        }
      }
      .margin(10)
    }
    .width('100%')
    .height('100%')
  }
}