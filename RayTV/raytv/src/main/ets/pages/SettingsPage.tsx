// 设置页面组件
// 提供应用配置、站点管理、缓存清理等功能

import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, Switch, TouchableOpacity, StyleSheet, Alert } from '@ohos.universal';
import { AppNavigator } from '../navigation/AppNavigator';
import { ConfigService } from '../service/config/ConfigService';
import { StorageUtil } from '../common/util/StorageUtil';
import { AnalyticsService } from '../service/analytics/AnalyticsService';
import { CrawlerService } from '../service/spider/CrawlerService';
import { AppConfig, PlayerConfig, DanmakuConfig, NetworkConfig, SecurityConfig, DisplayConfig, HarmonyConfig } from '../data/bean/Config';
import { SiteInfo } from '../data/bean/Site';

const SettingsPage: React.FC = () => {
  const [appConfig, setAppConfig] = useState<AppConfig>({
    autoPlayNext: true,
    rememberLastPosition: true,
    enableDanmaku: true,
    enableAnalytics: true,
    enableAdBlock: true,
    defaultPlayer: 'system',
    theme: 'default',
    fontSize: 16
  });
  
  const [playerConfig, setPlayerConfig] = useState<PlayerConfig>({
    autoPlay: true,
    autoPause: true,
    hardwareDecode: true,
    autoRotate: true,
    screenBrightness: 0.8,
    volume: 1.0
  });
  
  const [danmakuConfig, setDanmakuConfig] = useState<DanmakuConfig>({
    enabled: true,
    opacity: 0.8,
    fontSize: 16,
    speed: 1,
    showOwn: true
  });
  
  const [networkConfig, setNetworkConfig] = useState<NetworkConfig>({
    timeout: 30000,
    retryCount: 3,
    useProxy: false,
    proxyUrl: '',
    userAgent: '',
    customHeaders: {}
  });
  
  const [securityConfig, setSecurityConfig] = useState<SecurityConfig>({
    enableAdBlock: true,
    enableTrackingProtection: true,
    enableContentFilter: true,
    contentFilterLevel: 'medium'
  });
  
  const [displayConfig, setDisplayConfig] = useState<DisplayConfig>({
    theme: 'default',
    fontSize: 16,
    showPreviewImage: true,
    showRating: true,
    showUpdateInfo: true,
    showSourceInfo: true
  });
  
  const [harmonyConfig, setHarmonyConfig] = useState<HarmonyConfig>({
    enableMultiWindow: true,
    enableFloatingWindow: true,
    enableDarkMode: false,
    enableSystemUI: true,
    useHarmonyComponents: true
  });
  
  const [activeSites, setActiveSites] = useState<SiteInfo[]>([]);
  const [cacheSize, setCacheSize] = useState<string>('计算中...');
  const [appVersion, setAppVersion] = useState('1.0.0');
  
  const appNavigator = AppNavigator.getInstance();
  const configService = ConfigService.getInstance();
  const storageUtil = StorageUtil.getInstance();
  const analyticsService = AnalyticsService.getInstance();
  const crawlerService = CrawlerService.getInstance();

  useEffect(() => {
    analyticsService.trackPageView('SettingsPage');
    loadConfigs();
    loadSites();
    calculateCacheSize();
  }, []);

  const loadConfigs = async () => {
    try {
      // 加载各项配置
      const [app, player, danmaku, network, security, display, harmony] = await Promise.all([
        configService.getAppConfig(),
        configService.getPlayerConfig(),
        configService.getDanmakuConfig(),
        configService.getNetworkConfig(),
        configService.getSecurityConfig(),
        configService.getDisplayConfig(),
        configService.getHarmonyConfig()
      ]);
      
      setAppConfig(app);
      setPlayerConfig(player);
      setDanmakuConfig(danmaku);
      setNetworkConfig(network);
      setSecurityConfig(security);
      setDisplayConfig(display);
      setHarmonyConfig(harmony);
    } catch (error) {
      console.error('Failed to load configs:', error);
    }
  };

  const loadSites = async () => {
    try {
      const sites = await crawlerService.getAllSites();
      setActiveSites(sites);
    } catch (error) {
      console.error('Failed to load sites:', error);
      // 加载模拟站点数据
      setActiveSites(getMockSites());
    }
  };

  const calculateCacheSize = async () => {
    try {
      const size = await storageUtil.getCacheSize();
      setCacheSize(formatSize(size));
    } catch (error) {
      console.error('Failed to calculate cache size:', error);
      setCacheSize('未知');
    }
  };

  const formatSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    else if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(2)} KB`;
    else if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    else return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
  };

  const handleConfigChange = async <K extends keyof any, V>(
    config: Record<K, V>,
    key: K,
    value: V,
    setConfigFn: (config: Record<K, V>) => void,
    saveConfigFn: (config: Record<K, V>) => Promise<void>
  ) => {
    try {
      const newConfig = { ...config, [key]: value };
      setConfigFn(newConfig);
      await saveConfigFn(newConfig);
    } catch (error) {
      console.error(`Failed to save config for ${key}:`, error);
      Alert.alert('错误', '保存配置失败');
    }
  };

  const handleSiteToggle = async (siteKey: string, enabled: boolean) => {
    try {
      await crawlerService.setSiteStatus(siteKey, enabled);
      setActiveSites(prev => 
        prev.map(site => site.key === siteKey ? { ...site, enabled } : site)
      );
    } catch (error) {
      console.error(`Failed to toggle site ${siteKey}:`, error);
      Alert.alert('错误', '更新站点状态失败');
    }
  };

  const clearCache = async () => {
    try {
      Alert.alert(
        '清除缓存',
        '确定要清除所有缓存数据吗？',
        [
          { text: '取消', style: 'cancel' },
          {
            text: '确定',
            style: 'destructive',
            onPress: async () => {
              await storageUtil.clearCache();
              setCacheSize('0 B');
              Alert.alert('成功', '缓存已清除');
            }
          }
        ]
      );
    } catch (error) {
      console.error('Failed to clear cache:', error);
      Alert.alert('错误', '清除缓存失败');
    }
  };

  const clearHistory = async () => {
    try {
      Alert.alert(
        '清除历史记录',
        '确定要清除所有观看历史吗？',
        [
          { text: '取消', style: 'cancel' },
          {
            text: '确定',
            style: 'destructive',
            onPress: async () => {
              await storageUtil.clearPlayHistory();
              Alert.alert('成功', '历史记录已清除');
            }
          }
        ]
      );
    } catch (error) {
      console.error('Failed to clear history:', error);
      Alert.alert('错误', '清除历史记录失败');
    }
  };

  const navigateToImportSite = () => {
    Alert.alert('提示', '导入站点功能开发中');
  };

  const navigateToAbout = () => {
    Alert.alert(
      '关于 RayTV',
      `版本: ${appVersion}\n\nRayTV 是一个开源的视频播放应用，基于鸿蒙OS开发。\n\n© 2023 RayTV 团队`,
      [{ text: '确定' }]
    );
  };

  const resetAllSettings = () => {
    Alert.alert(
      '重置所有设置',
      '确定要将所有设置恢复为默认值吗？',
      [
        { text: '取消', style: 'cancel' },
        {
          text: '确定',
          style: 'destructive',
          onPress: async () => {
            try {
              await configService.resetAllConfigs();
              loadConfigs();
              Alert.alert('成功', '设置已重置');
            } catch (error) {
              console.error('Failed to reset settings:', error);
              Alert.alert('错误', '重置设置失败');
            }
          }
        }
      ]
    );
  };

  const getMockSites = (): SiteInfo[] => [
    {
      key: 'demo_site_1',
      name: '示例站点1',
      type: 'vod',
      url: 'https://example.com/vod1',
      enabled: true,
      updateTime: new Date().toISOString(),
      version: '1.0'
    },
    {
      key: 'demo_site_2',
      name: '示例站点2',
      type: 'live',
      url: 'https://example.com/live1',
      enabled: true,
      updateTime: new Date().toISOString(),
      version: '1.0'
    },
    {
      key: 'demo_site_3',
      name: '示例站点3',
      type: 'mixed',
      url: 'https://example.com/mixed1',
      enabled: false,
      updateTime: new Date().toISOString(),
      version: '1.0'
    }
  ];

  const renderSettingItem = (
    title: string,
    description: string,
    value: React.ReactNode,
    onPress?: () => void
  ) => {
    return (
      <TouchableOpacity
        style={styles.settingItem}
        onPress={onPress}
        disabled={!onPress}
      >
        <View style={styles.settingInfo}>
          <Text style={styles.settingTitle}>{title}</Text>
          {description ? (
            <Text style={styles.settingDescription}>{description}</Text>
          ) : null}
        </View>
        <View style={styles.settingValue}>
          {value}
        </View>
      </TouchableOpacity>
    );
  };

  const renderSection = (title: string, children: React.ReactNode) => {
    return (
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{title}</Text>
        <View style={styles.sectionContent}>
          {children}
        </View>
      </View>
    );
  };

  return (
    <ScrollView style={styles.container}>
      {/* 应用设置 */}
      {renderSection('应用设置', (
        <>
          {renderSettingItem(
            '自动播放下一集',
            '播放完当前集后自动播放下一集',
            <Switch
              value={appConfig.autoPlayNext}
              onChange={(value) => handleConfigChange(
                appConfig, 'autoPlayNext', value,
                setAppConfig, configService.setAppConfig
              )}
            />
          )}
          
          {renderSettingItem(
            '记住播放位置',
            '下次播放时从上次的位置继续',
            <Switch
              value={appConfig.rememberLastPosition}
              onChange={(value) => handleConfigChange(
                appConfig, 'rememberLastPosition', value,
                setAppConfig, configService.setAppConfig
              )}
            />
          )}
          
          {renderSettingItem(
            '默认播放器',
            '选择默认使用的视频播放器',
            <Text style={styles.valueText}>{appConfig.defaultPlayer === 'system' ? '系统播放器' : '内置播放器'}</Text>,
            () => {
              // 在实际项目中，这里会弹出选择器
              Alert.alert('提示', '播放器选择功能开发中');
            }
          )}
        </>
      ))}

      {/* 播放器设置 */}
      {renderSection('播放器设置', (
        <>
          {renderSettingItem(
            '自动播放',
            '进入播放页面后自动开始播放',
            <Switch
              value={playerConfig.autoPlay}
              onChange={(value) => handleConfigChange(
                playerConfig, 'autoPlay', value,
                setPlayerConfig, configService.setPlayerConfig
              )}
            />
          )}
          
          {renderSettingItem(
            '硬件解码',
            '使用硬件加速解码视频',
            <Switch
              value={playerConfig.hardwareDecode}
              onChange={(value) => handleConfigChange(
                playerConfig, 'hardwareDecode', value,
                setPlayerConfig, configService.setPlayerConfig
              )}
            />
          )}
          
          {renderSettingItem(
            '自动旋转',
            '根据设备方向自动旋转屏幕',
            <Switch
              value={playerConfig.autoRotate}
              onChange={(value) => handleConfigChange(
                playerConfig, 'autoRotate', value,
                setPlayerConfig, configService.setPlayerConfig
              )}
            />
          )}
        </>
      ))}

      {/* 弹幕设置 */}
      {renderSection('弹幕设置', (
        <>
          {renderSettingItem(
            '启用弹幕',
            '在视频播放时显示弹幕',
            <Switch
              value={danmakuConfig.enabled}
              onChange={(value) => handleConfigChange(
                danmakuConfig, 'enabled', value,
                setDanmakuConfig, configService.setDanmakuConfig
              )}
            />
          )}
          
          {renderSettingItem(
            '弹幕透明度',
            `当前: ${Math.round(danmakuConfig.opacity * 100)}%`,
            <Text style={styles.valueText}>调整</Text>,
            () => {
              // 在实际项目中，这里会弹出滑块
              Alert.alert('提示', '弹幕透明度调节功能开发中');
            }
          )}
          
          {renderSettingItem(
            '弹幕速度',
            `当前: ${danmakuConfig.speed}x`,
            <Text style={styles.valueText}>调整</Text>,
            () => {
              // 在实际项目中，这里会弹出选择器
              Alert.alert('提示', '弹幕速度调节功能开发中');
            }
          )}
        </>
      ))}

      {/* 网络设置 */}
      {renderSection('网络设置', (
        <>
          {renderSettingItem(
            '请求超时时间',
            `当前: ${networkConfig.timeout / 1000}秒`,
            <Text style={styles.valueText}>调整</Text>,
            () => {
              // 在实际项目中，这里会弹出输入框
              Alert.alert('提示', '超时时间设置功能开发中');
            }
          )}
          
          {renderSettingItem(
            '重试次数',
            `当前: ${networkConfig.retryCount}次`,
            <Text style={styles.valueText}>调整</Text>,
            () => {
              // 在实际项目中，这里会弹出选择器
              Alert.alert('提示', '重试次数设置功能开发中');
            }
          )}
          
          {renderSettingItem(
            '使用代理',
            '通过代理服务器访问网络',
            <Switch
              value={networkConfig.useProxy}
              onChange={(value) => handleConfigChange(
                networkConfig, 'useProxy', value,
                setNetworkConfig, configService.setNetworkConfig
              )}
            />
          )}
        </>
      ))}

      {/* 安全设置 */}
      {renderSection('安全设置', (
        <>
          {renderSettingItem(
            '启用广告拦截',
            '阻止视频播放中的广告',
            <Switch
              value={securityConfig.enableAdBlock}
              onChange={(value) => handleConfigChange(
                securityConfig, 'enableAdBlock', value,
                setSecurityConfig, configService.setSecurityConfig
              )}
            />
          )}
          
          {renderSettingItem(
            '启用内容过滤',
            '过滤不适宜内容',
            <Switch
              value={securityConfig.enableContentFilter}
              onChange={(value) => handleConfigChange(
                securityConfig, 'enableContentFilter', value,
                setSecurityConfig, configService.setSecurityConfig
              )}
            />
          )}
        </>
      ))}

      {/* 鸿蒙OS特有设置 */}
      {renderSection('鸿蒙OS特有设置', (
        <>
          {renderSettingItem(
            '多窗口支持',
            '启用鸿蒙OS多窗口功能',
            <Switch
              value={harmonyConfig.enableMultiWindow}
              onChange={(value) => handleConfigChange(
                harmonyConfig, 'enableMultiWindow', value,
                setHarmonyConfig, configService.setHarmonyConfig
              )}
            />
          )}
          
          {renderSettingItem(
            '悬浮窗口',
            '支持小窗模式播放视频',
            <Switch
              value={harmonyConfig.enableFloatingWindow}
              onChange={(value) => handleConfigChange(
                harmonyConfig, 'enableFloatingWindow', value,
                setHarmonyConfig, configService.setHarmonyConfig
              )}
            />
          )}
          
          {renderSettingItem(
            '深色模式',
            '跟随系统深色模式',
            <Switch
              value={harmonyConfig.enableDarkMode}
              onChange={(value) => handleConfigChange(
                harmonyConfig, 'enableDarkMode', value,
                setHarmonyConfig, configService.setHarmonyConfig
              )}
            />
          )}
        </>
      ))}

      {/* 站点管理 */}
      {renderSection('站点管理', (
        <>
          {activeSites.map((site) => (
            <View key={site.key} style={styles.settingItem}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingTitle}>{site.name}</Text>
                <Text style={styles.settingDescription}>
                  {site.type === 'vod' ? '视频点播' : site.type === 'live' ? '电视直播' : '混合'} · 版本 {site.version}
                </Text>
              </View>
              <Switch
                value={site.enabled}
                onChange={(value) => handleSiteToggle(site.key, value)}
              />
            </View>
          ))}
          
          <TouchableOpacity style={styles.addSiteButton} onPress={navigateToImportSite}>
            <Text style={styles.addSiteButtonText}>+ 导入站点</Text>
          </TouchableOpacity>
        </>
      ))}

      {/* 数据管理 */}
      {renderSection('数据管理', (
        <>
          {renderSettingItem(
            '缓存大小',
            '应用缓存占用空间',
            <Text style={styles.valueText}>{cacheSize}</Text>,
            clearCache
          )}
          
          {renderSettingItem(
            '清除观看历史',
            '删除所有观看记录',
            <Text style={styles.valueText}>清除</Text>,
            clearHistory
          )}
          
          {renderSettingItem(
            '重置所有设置',
            '恢复应用默认配置',
            <Text style={[styles.valueText, styles.dangerText]}>重置</Text>,
            resetAllSettings
          )}
        </>
      ))}

      {/* 关于 */}
      {renderSection('关于', (
        <>
          {renderSettingItem(
            '版本信息',
            `RayTV v${appVersion}`,
            <Text style={styles.valueText}>查看</Text>,
            navigateToAbout
          )}
          
          {renderSettingItem(
            '开源协议',
            'MIT License',
            <Text style={styles.valueText}>详情</Text>,
            () => {
              Alert.alert('提示', '开源协议信息开发中');
            }
          )}
          
          {renderSettingItem(
            '检查更新',
            `当前版本 ${appVersion}`,
            <Text style={styles.valueText}>检查</Text>,
            () => {
              Alert.alert('提示', '正在检查更新...\n\n当前已是最新版本');
            }
          )}
        </>
      ))}

      {/* 底部空间 */}
      <View style={styles.footer}>
        <Text style={styles.footerText}>RayTV © 2023</Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  section: {
    marginTop: 16,
    marginBottom: 8,
  },
  sectionTitle: {
    fontSize: 14,
    color: '#999',
    marginLeft: 16,
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  sectionContent: {
    backgroundColor: '#fff',
  },
  settingItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  settingInfo: {
    flex: 1,
    marginRight: 16,
  },
  settingTitle: {
    fontSize: 16,
    color: '#333',
    marginBottom: 4,
  },
  settingDescription: {
    fontSize: 14,
    color: '#999',
  },
  settingValue: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  valueText: {
    fontSize: 14,
    color: '#999',
  },
  dangerText: {
    color: '#ff4757',
  },
  addSiteButton: {
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addSiteButtonText: {
    fontSize: 16,
    color: '#007aff',
    fontWeight: '500',
  },
  footer: {
    padding: 24,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 14,
    color: '#999',
  },
});

export default SettingsPage;