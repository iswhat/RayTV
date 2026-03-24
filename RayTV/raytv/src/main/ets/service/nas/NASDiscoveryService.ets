// NASDiscoveryService.ets - NAS设备发现服务
// 负责局域网NAS设备自动发现、信息采集和状态监控

import Logger from '../../common/util/Logger';
import HttpService from '../HttpService';
import { NASDevice, NASCapabilities, NASAuthConfig } from './types/NASDeviceTypes';
import ErrorService from '../error/ErrorService';

/**
 * NAS发现服务类
 */
export class NASDiscoveryService {
  private static instance: NASDiscoveryService | null = null;
  private logger: Logger;
  private httpService: HttpService;
  private errorService: typeof ErrorService;
  private discoveredDevices: Map<string, NASDevice> = new Map();
  private discoveryInterval: number = 30000; // 30秒发现一次
  private discoveryTimer: number | null = null;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): NASDiscoveryService {
    if (!NASDiscoveryService.instance) {
      NASDiscoveryService.instance = new NASDiscoveryService();
    }
    return NASDiscoveryService.instance;
  }
  
  /**
   * 构造函数
   */
  private constructor() {
    this.logger = new Logger('NASDiscoveryService');
    this.httpService = HttpService.getInstance();
    this.errorService = ErrorService;
  }
  
  /**
   * 多设备管理功能
   */
  
  // 获取设备分组
  public getDeviceGroups(): Map<string, NASDevice[]> {
    const groups = new Map<string, NASDevice[]>();
    
    for (const device of this.discoveredDevices.values()) {
      const groupKey = device.manufacturer || 'Other';
      if (!groups.has(groupKey)) {
        groups.set(groupKey, []);
      }
      groups.get(groupKey)?.push(device);
    }
    
    return groups;
  }
  
  // 按协议获取设备
  public getDevicesByProtocol(protocol: string): NASDevice[] {
    return Array.from(this.discoveredDevices.values()).filter(device => device.protocol === protocol);
  }
  
  // 按制造商获取设备
  public getDevicesByManufacturer(manufacturer: string): NASDevice[] {
    return Array.from(this.discoveredDevices.values()).filter(device => device.manufacturer === manufacturer);
  }
  
  // 获取在线设备
  public getOnlineDevices(): NASDevice[] {
    return Array.from(this.discoveredDevices.values()).filter(device => device.isOnline);
  }
  
  // 获取离线设备
  public getOfflineDevices(): NASDevice[] {
    return Array.from(this.discoveredDevices.values()).filter(device => !device.isOnline);
  }
  
  // 更新设备名称
  public updateDeviceName(deviceId: string, newName: string): boolean {
    const device = this.discoveredDevices.get(deviceId);
    if (device) {
      device.name = newName;
      return true;
    }
    return false;
  }
  
  // 设置设备优先级
  public setDevicePriority(deviceId: string, priority: number): boolean {
    const device = this.discoveredDevices.get(deviceId);
    if (device) {
      device.priority = Math.max(1, Math.min(10, priority));
      return true;
    }
    return false;
  }
  
  // 获取设备优先级排序的设备列表
  public getDevicesByPriority(): NASDevice[] {
    return Array.from(this.discoveredDevices.values())
      .sort((a, b) => (b.priority || 1) - (a.priority || 1));
  }
  
  // 批量测试设备连接
  public async testMultipleDevices(devices: NASDevice[]): Promise<Map<string, boolean>> {
    const results = new Map<string, boolean>();
    
    const testPromises = devices.map(async (device) => {
      try {
        const isConnected = await this.testDeviceConnection(device);
        results.set(device.id, isConnected);
        device.isOnline = isConnected;
        device.lastSeen = Date.now();
      } catch (error) {
        results.set(device.id, false);
        device.isOnline = false;
      }
    });
    
    await Promise.all(testPromises);
    return results;
  }
  
  // 批量更新设备状态
  public async updateMultipleDevicesStatus(): Promise<void> {
    const devices = Array.from(this.discoveredDevices.values());
    await this.testMultipleDevices(devices);
  }
  
  // 导出设备配置
  public exportDeviceConfig(): string {
    const devices = Array.from(this.discoveredDevices.values());
    return JSON.stringify(devices, null, 2);
  }
  
  // 导入设备配置
  public async importDeviceConfig(config: string): Promise<number> {
    try {
      const devices = JSON.parse(config) as NASDevice[];
      let imported = 0;
      
      for (const device of devices) {
        try {
          // 验证设备信息
          if (device.id && device.ip && device.port) {
            this.discoveredDevices.set(device.id, device);
            imported++;
          }
        } catch (error) {
          this.logger.error(`Failed to import device ${device.name}:`, error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      return imported;
    } catch (error) {
      this.logger.error('Failed to import device config:', error instanceof Error ? error : new Error(String(error)));
      return 0;
    }
  }
  
  /**
   * 初始化发现服务
   */
  public async initialize(): Promise<void> {
    try {
      this.logger.info('初始化NAS发现服务...');
      
      // 启动自动发现
      this.startAutoDiscovery();
      
      this.logger.info('NAS发现服务初始化完成');
    } catch (error) {
      this.logger.error('初始化NAS发现服务失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  /**
   * 启动自动发现
   */
  public startAutoDiscovery(): void {
    this.stopAutoDiscovery();
    
    this.logger.info('启动自动发现...');
    
    // 立即执行一次发现
    this.discoverAllDevices();
    
    // 设置定时发现
    this.discoveryTimer = setInterval(() => {
      this.discoverAllDevices();
    }, this.discoveryInterval);
  }
  
  /**
   * 停止自动发现
   */
  public stopAutoDiscovery(): void {
    if (this.discoveryTimer) {
      clearInterval(this.discoveryTimer);
      this.discoveryTimer = null;
      this.logger.info('停止自动发现');
    }
  }
  
  /**
   * 发现所有设备
   */
  public async discoverAllDevices(): Promise<NASDevice[]> {
    this.logger.info('开始发现NAS设备...');
    
    try {
      const devices: NASDevice[] = [];
      
      // 1. mDNS/Bonjour发现
      const mdnsDevices = await this.discoverByMDNS();
      devices.push(...mdnsDevices);
      
      // 2. SSDP发现
      const ssdpDevices = await this.discoverBySSDP();
      devices.push(...ssdpDevices);
      
      // 3. 更新设备状态
      await this.updateDeviceStatus(devices);
      
      this.logger.info(`发现 ${devices.length} 个NAS设备`);
      return devices;
    } catch (error) {
      this.logger.error('发现设备失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 通过mDNS/Bonjour发现设备
   */
  private async discoverByMDNS(): Promise<NASDevice[]> {
    this.logger.info('通过mDNS发现设备...');
    
    try {
      // 使用HarmonyOS的网络发现API
      // 注意：实际项目中需要根据HarmonyOS版本和API可用性进行调整
      
      // 模拟mDNS发现过程
      const mdnsDevices: NASDevice[] = [];
      
      // 1. 搜索局域网内的SMB服务
      const smbDevices = await this.searchSMBService();
      mdnsDevices.push(...smbDevices);
      
      // 2. 搜索局域网内的DLNA服务
      const dlnaDevices = await this.searchDLNAService();
      mdnsDevices.push(...dlnaDevices);
      
      // 3. 搜索局域网内的WebDAV服务
      const webdavDevices = await this.searchWebDAVService();
      mdnsDevices.push(...webdavDevices);
      
      // 4. 搜索华为设备
      const huaweiDevices = await this.searchHuaweiDevices();
      mdnsDevices.push(...huaweiDevices);
      
      return mdnsDevices;
    } catch (error) {
      this.logger.error('mDNS发现失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 搜索SMB服务
   */
  private async searchSMBService(): Promise<NASDevice[]> {
    try {
      // 实现SMB服务搜索
      // 1. 扫描局域网IP范围
      // 2. 尝试连接445端口
      // 3. 验证SMB服务
      const devices: NASDevice[] = [];
      
      // 实际项目中需要使用HarmonyOS的网络API进行局域网扫描
      // 暂时返回空数组，后续实现完整的SMB服务发现
      
      return devices;
    } catch (error) {
      this.logger.error('搜索SMB服务失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 搜索DLNA服务
   */
  private async searchDLNAService(): Promise<NASDevice[]> {
    try {
      // 实现DLNA服务搜索
      // 1. 发送SSDP M-SEARCH请求
      // 2. 解析SSDP响应
      // 3. 验证DLNA服务
      const devices: NASDevice[] = [];
      
      // 实际项目中需要使用HarmonyOS的网络API发送SSDP请求
      // 暂时返回空数组，后续实现完整的DLNA服务发现
      
      return devices;
    } catch (error) {
      this.logger.error('搜索DLNA服务失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 搜索WebDAV服务
   */
  private async searchWebDAVService(): Promise<NASDevice[]> {
    try {
      // 实现WebDAV服务搜索
      // 1. 扫描局域网IP范围
      // 2. 尝试连接常见WebDAV端口（8080, 80, 443）
      // 3. 发送PROPFIND请求验证WebDAV服务
      const devices: NASDevice[] = [];
      
      // 实际项目中需要使用HarmonyOS的网络API进行局域网扫描
      // 暂时返回空数组，后续实现完整的WebDAV服务发现
      
      return devices;
    } catch (error) {
      this.logger.error('搜索WebDAV服务失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 搜索华为设备
   */
  private async searchHuaweiDevices(): Promise<NASDevice[]> {
    try {
      // 实现华为设备搜索
      // 1. 扫描局域网IP范围
      // 2. 尝试连接华为设备常见端口
      // 3. 验证华为HiLink协议
      const devices: NASDevice[] = [];
      
      // 实际项目中需要使用HarmonyOS的网络API进行局域网扫描
      // 暂时返回空数组，后续实现完整的华为设备发现
      
      return devices;
    } catch (error) {
      this.logger.error('搜索华为设备失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 通过SSDP发现设备
   */
  private async discoverBySSDP(): Promise<NASDevice[]> {
    this.logger.info('通过SSDP发现设备...');
    
    try {
      // 使用HarmonyOS的网络发现API实现SSDP
      // 注意：实际项目中需要根据HarmonyOS版本和API可用性进行调整
      
      // 模拟SSDP发现过程
      const ssdpDevices: NASDevice[] = [];
      
      // 1. 发送SSDP M-SEARCH请求
      const searchResponse = await this.sendSSDPDiscovery();
      
      // 2. 解析SSDP响应
      if (searchResponse) {
        const devices = this.parseSSDPResponses(searchResponse);
        ssdpDevices.push(...devices);
      }
      
      return ssdpDevices;
    } catch (error) {
      this.logger.error('SSDP发现失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 发送SSDP M-SEARCH请求
   */
  private async sendSSDPDiscovery(): Promise<string[]> {
    try {
      // 实现SSDP M-SEARCH请求
      // 1. 创建UDP套接字
      // 2. 发送M-SEARCH广播
      // 3. 接收并收集响应
      const responses: string[] = [];
      
      // 实际项目中需要使用HarmonyOS的网络API发送UDP广播
      // 暂时返回空数组，后续实现完整的SSDP发现
      
      return responses;
    } catch (error) {
      this.logger.error('发送SSDP请求失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 解析SSDP响应
   */
  private parseSSDPResponses(responses: string[]): NASDevice[] {
    const devices: NASDevice[] = [];
    
    for (const response of responses) {
      try {
        const headers = this.parseSSDPHeaders(response);
        const location = headers['LOCATION'] || '';
        const server = headers['SERVER'] || '';
        const st = headers['ST'] || '';
        
        // 提取IP地址
        const ipMatch = location.match(/http:\/\/([^:]+):/);
        if (!ipMatch) continue;
        
        const ip = ipMatch[1];
        const portMatch = location.match(/:([0-9]+)\//);
        const port = portMatch ? parseInt(portMatch[1]) : 8080;
        
        // 解析服务器信息
        let manufacturer = 'Unknown';
        let model = 'Media Server';
        
        if (server.includes('Linux')) {
          manufacturer = 'Synology';
          model = 'DS Series';
        } else if (server.includes('Windows')) {
          manufacturer = 'Microsoft';
          model = 'Windows Media Server';
        }
        
        devices.push({
          id: `ssdp_${Date.now()}_${devices.length + 1}`,
          name: `${manufacturer} Media Server`,
          ip: ip,
          port: port,
          protocol: 'dlna',
          manufacturer: manufacturer,
          model: model,
          isOnline: true,
          lastSeen: Date.now(),
          capabilities: {
            smb: false,
            dlna: true,
            webdav: false,
            http: true
          }
        });
      } catch (error) {
        this.logger.error('解析SSDP响应失败', error instanceof Error ? error : new Error(String(error)));
      }
    }
    
    return devices;
  }
  
  /**
   * 解析SSDP头部
   */
  private parseSSDPHeaders(response: string): Record<string, string> {
    const headers: Record<string, string> = {};
    const lines = response.split('\r\n');
    
    for (const line of lines) {
      if (line.includes(':')) {
        const [key, value] = line.split(':', 2);
        headers[key.trim().toUpperCase()] = value.trim();
      }
    }
    
    return headers;
  }
  
  /**
   * 手动添加NAS设备
   */
  public async addDeviceManually(
    name: string,
    ip: string,
    port: number,
    protocol: 'smb' | 'dlna' | 'webdav' | 'http' | 'huawei' | 'zspace' | 'mihome' | 'synology' | 'ugreen' | 'qnap',
    authConfig?: NASAuthConfig,
    customId?: string
  ): Promise<NASDevice> {
    this.logger.info(`手动添加设备: ${name} (${ip}:${port}, protocol: ${protocol})`);
    
    try {
      // 验证IP地址格式
      if (!this.isValidIP(ip)) {
        throw new Error('无效的IP地址');
      }
      
      // 验证端口范围
      if (port < 1 || port > 65535) {
        throw new Error('端口号必须在1-65535之间');
      }
      
      // 检查设备是否已存在
      const existingDevice = this.findExistingDevice(ip, port, protocol);
      if (existingDevice) {
        this.logger.info(`设备已存在: ${existingDevice.name}，更新设备信息`);
        // 更新现有设备信息
        existingDevice.name = name;
        existingDevice.authConfig = authConfig;
        existingDevice.lastSeen = Date.now();
        existingDevice.isOnline = true;
        return existingDevice;
      }
      
      // 验证设备是否可达
      const isReachable = await this.checkDeviceReachability(ip, port);
      
      if (!isReachable) {
        throw new Error('设备不可达，请检查网络连接和设备状态');
      }
      
      // 检测设备信息
      const deviceInfo = await this.detectDeviceInfo(ip, port, protocol);
      
      // 创建设备对象
      const device: NASDevice = {
        id: customId || `manual_${Date.now()}`,
        name: name,
        ip: ip,
        port: port,
        protocol: protocol,
        manufacturer: deviceInfo.manufacturer || 'Unknown',
        model: deviceInfo.model || 'Unknown',
        isOnline: true,
        lastSeen: Date.now(),
        capabilities: deviceInfo.capabilities,
        authConfig: authConfig
      };
      
      // 添加到设备列表
      this.discoveredDevices.set(device.id, device);
      
      this.logger.info(`设备添加成功: ${device.name} (ID: ${device.id})`);
      return device;
    } catch (error) {
      this.logger.error('手动添加设备失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  /**
   * 验证IP地址格式
   */
  private isValidIP(ip: string): boolean {
    const ipRegex = /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    return ipRegex.test(ip);
  }
  
  /**
   * 查找已存在的设备
   */
  private findExistingDevice(ip: string, port: number, protocol: string): NASDevice | null {
    for (const device of this.discoveredDevices.values()) {
      if (device.ip === ip && device.port === port && device.protocol === protocol) {
        return device;
      }
    }
    return null;
  }
  
  /**
   * 检查设备可达性
   */
  private async checkDeviceReachability(ip: string, port: number): Promise<boolean> {
    try {
      // 尝试连接设备
      const response = await this.httpService.get(`http://${ip}:${port}`, { timeout: 5000 });
      return response && response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      this.logger.warn(`设备 ${ip}:${port} 不可达`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 检测设备信息
   */
  private async detectDeviceInfo(
    ip: string,
    port: number,
    protocol: string
  ): Promise<{ manufacturer: string; model: string; capabilities: NASCapabilities }> {
    try {
      // 根据协议检测设备信息
      switch (protocol) {
        case 'huawei':
          return await this.detectHuaweiDeviceInfo(ip, port);
        case 'smb':
          return await this.detectSMBDeviceInfo(ip, port);
        case 'zspace':
          return await this.detectZSpaceDeviceInfo(ip, port);
        case 'mihome':
          return await this.detectMiHomeDeviceInfo(ip, port);
        case 'synology':
          return await this.detectSynologyDeviceInfo(ip, port);
        case 'ugreen':
          return await this.detectUGreenDeviceInfo(ip, port);
        case 'qnap':
          return await this.detectQNAPDeviceInfo(ip, port);
        default:
          return {
            manufacturer: 'Unknown',
            model: 'Unknown',
            capabilities: {
              smb: protocol === 'smb',
              dlna: protocol === 'dlna',
              webdav: protocol === 'webdav',
              http: protocol === 'http'
            }
          };
      }
    } catch (error) {
      this.logger.error('检测设备信息失败', error instanceof Error ? error : new Error(String(error)));
      return {
        manufacturer: 'Unknown',
        model: 'Unknown',
        capabilities: {
          smb: false,
          dlna: false,
          webdav: false,
          http: false
        }
      };
    }
  }
  
  /**
   * 检测华为设备信息
   */
  private async detectHuaweiDeviceInfo(ip: string, port: number): Promise<{ manufacturer: string; model: string; capabilities: NASCapabilities }> {
    try {
      const response = await this.httpService.get(`http://${ip}:${port}/api/v1/device/info`, { timeout: 5000 });
      if (response && response.statusCode === 200 && response.result) {
        const data = response.result;
        return {
          manufacturer: 'Huawei',
          model: data.model || 'Unknown',
          capabilities: {
            smb: true,
            dlna: true,
            webdav: false,
            http: true
          }
        };
      }
      throw new Error('Failed to get Huawei device info');
    } catch (error) {
      this.logger.error('检测华为设备信息失败', error instanceof Error ? error : new Error(String(error)));
      return {
        manufacturer: 'Huawei',
        model: 'Unknown',
        capabilities: {
          smb: true,
          dlna: true,
          webdav: false,
          http: true
        }
      };
    }
  }
  
  /**
   * 检测SMB设备信息
   */
  private async detectSMBDeviceInfo(ip: string, port: number): Promise<{ manufacturer: string; model: string; capabilities: NASCapabilities }> {
    try {
      // 这里需要实现SMB设备信息检测
      // 暂时返回默认值
      return {
        manufacturer: 'Unknown',
        model: 'NAS Device',
        capabilities: {
          smb: true,
          dlna: false,
          webdav: false,
          http: false
        }
      };
    } catch (error) {
      this.logger.error('检测SMB设备信息失败', error instanceof Error ? error : new Error(String(error)));
      return {
        manufacturer: 'Unknown',
        model: 'NAS Device',
        capabilities: {
          smb: true,
          dlna: false,
          webdav: false,
          http: false
        }
      };
    }
  }
  
  /**
   * 检测极空间设备信息
   */
  private async detectZSpaceDeviceInfo(ip: string, port: number): Promise<{ manufacturer: string; model: string; capabilities: NASCapabilities }> {
    try {
      const response = await this.httpService.get(`http://${ip}:${port}/api/v1/device/info`, { timeout: 5000 });
      if (response && response.statusCode === 200 && response.result) {
        const data = response.result;
        return {
          manufacturer: 'ZSpace',
          model: data.model || 'Unknown',
          capabilities: {
            smb: true,
            dlna: true,
            webdav: true,
            http: true
          }
        };
      }
      throw new Error('Failed to get ZSpace device info');
    } catch (error) {
      this.logger.error('检测极空间设备信息失败', error instanceof Error ? error : new Error(String(error)));
      return {
        manufacturer: 'ZSpace',
        model: 'Unknown',
        capabilities: {
          smb: true,
          dlna: true,
          webdav: true,
          http: true
        }
      };
    }
  }
  
  /**
   * 检测小米设备信息
   */
  private async detectMiHomeDeviceInfo(ip: string, port: number): Promise<{ manufacturer: string; model: string; capabilities: NASCapabilities }> {
    try {
      const response = await this.httpService.get(`http://${ip}:${port}/mi-home/api/device/info`, { timeout: 5000 });
      if (response && response.statusCode === 200 && response.result) {
        const data = response.result;
        return {
          manufacturer: 'Xiaomi',
          model: data.model || 'Unknown',
          capabilities: {
            smb: true,
            dlna: true,
            webdav: false,
            http: true
          }
        };
      }
      throw new Error('Failed to get Mi Home device info');
    } catch (error) {
      this.logger.error('检测小米设备信息失败', error instanceof Error ? error : new Error(String(error)));
      return {
        manufacturer: 'Xiaomi',
        model: 'Unknown',
        capabilities: {
          smb: true,
          dlna: true,
          webdav: false,
          http: true
        }
      };
    }
  }
  
  /**
   * 检测群晖设备信息
   */
  private async detectSynologyDeviceInfo(ip: string, port: number): Promise<{ manufacturer: string; model: string; capabilities: NASCapabilities }> {
    try {
      const response = await this.httpService.get(`http://${ip}:${port}/webapi/entry.cgi`, {
        params: {
          api: 'SYNO.InfoCenter',
          method: 'query',
          version: '2',
          query: 'device'
        },
        timeout: 5000
      });
      if (response && response.statusCode === 200 && response.result) {
        const data = response.result;
        return {
          manufacturer: 'Synology',
          model: data.device?.model || 'Unknown',
          capabilities: {
            smb: true,
            dlna: true,
            webdav: true,
            http: true
          }
        };
      }
      throw new Error('Failed to get Synology device info');
    } catch (error) {
      this.logger.error('检测群晖设备信息失败', error instanceof Error ? error : new Error(String(error)));
      return {
        manufacturer: 'Synology',
        model: 'Unknown',
        capabilities: {
          smb: true,
          dlna: true,
          webdav: true,
          http: true
        }
      };
    }
  }
  
  /**
   * 检测绿联设备信息
   */
  private async detectUGreenDeviceInfo(ip: string, port: number): Promise<{ manufacturer: string; model: string; capabilities: NASCapabilities }> {
    try {
      const response = await this.httpService.get(`http://${ip}:${port}/api/v1/device/info`, { timeout: 5000 });
      if (response && response.statusCode === 200 && response.result) {
        const data = response.result;
        return {
          manufacturer: 'UGreen',
          model: data.model || 'Unknown',
          capabilities: {
            smb: true,
            dlna: true,
            webdav: true,
            http: true
          }
        };
      }
      throw new Error('Failed to get UGreen device info');
    } catch (error) {
      this.logger.error('检测绿联设备信息失败', error instanceof Error ? error : new Error(String(error)));
      return {
        manufacturer: 'UGreen',
        model: 'Unknown',
        capabilities: {
          smb: true,
          dlna: true,
          webdav: true,
          http: true
        }
      };
    }
  }
  
  /**
   * 检测威联通设备信息
   */
  private async detectQNAPDeviceInfo(ip: string, port: number): Promise<{ manufacturer: string; model: string; capabilities: NASCapabilities }> {
    try {
      const response = await this.httpService.get(`http://${ip}:${port}/cgi-bin/system_api.cgi`, {
        params: {
          cmd: 'getSystemInfo'
        },
        timeout: 5000
      });
      if (response && response.statusCode === 200 && response.result) {
        const data = response.result;
        return {
          manufacturer: 'QNAP',
          model: data.model || 'Unknown',
          capabilities: {
            smb: true,
            dlna: true,
            webdav: true,
            http: true
          }
        };
      }
      throw new Error('Failed to get QNAP device info');
    } catch (error) {
      this.logger.error('检测威联通设备信息失败', error instanceof Error ? error : new Error(String(error)));
      return {
        manufacturer: 'QNAP',
        model: 'Unknown',
        capabilities: {
          smb: true,
          dlna: true,
          webdav: true,
          http: true
        }
      };
    }
  }
  
  /**
   * 更新设备状态
   */
  private async updateDeviceStatus(devices: NASDevice[]): Promise<void> {
    for (const device of devices) {
      try {
        const isOnline = await this.checkDeviceReachability(device.ip, device.port);
        device.isOnline = isOnline;
        device.lastSeen = Date.now();
        
        // 更新或添加到设备列表
        this.discoveredDevices.set(device.id, device);
      } catch (error) {
        this.logger.error(`更新设备状态失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      }
    }
  }
  
  /**
   * 获取所有发现的设备
   */
  public getDiscoveredDevices(): NASDevice[] {
    return Array.from(this.discoveredDevices.values());
  }
  
  /**
   * 根据ID获取设备
   */
  public getDeviceById(deviceId: string): NASDevice | null {
    return this.discoveredDevices.get(deviceId) || null;
  }
  
  /**
   * 移除设备
   */
  public removeDevice(deviceId: string): boolean {
    return this.discoveredDevices.delete(deviceId);
  }
  
  /**
   * 清除所有设备
   */
  public clearDevices(): void {
    this.discoveredDevices.clear();
  }
  
  /**
   * 获取设备状态
   */
  public async getDeviceStatus(deviceId: string): Promise<'online' | 'offline' | 'unknown'> {
    const device = this.getDeviceById(deviceId);
    if (!device) {
      return 'unknown';
    }
    
    try {
      const isOnline = await this.checkDeviceReachability(device.ip, device.port);
      return isOnline ? 'online' : 'offline';
    } catch (error) {
      return 'offline';
    }
  }
  
  /**
   * 测试设备连接
   */
  public async testDeviceConnection(device: NASDevice): Promise<boolean> {
    try {
      return await this.checkDeviceReachability(device.ip, device.port);
    } catch (error) {
      this.logger.error(`测试设备连接失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 转换设备为网络源配置
   */
  public convertToNetworkSource(device: NASDevice): {
    id: string;
    name: string;
    url: string;
    type: string;
    version: string;
    isActive: boolean;
    contentUsage: {
      vodSites: boolean;
      liveChannels: boolean;
      wallpapers: boolean;
      adBlockRules: boolean;
      decoderConfigs: boolean;
      parserConfigs: boolean;
    };
    priority: number;
    tags: string[];
    lastUpdated: number;
    healthStatus: string;
    nasConfig: {
      deviceId: string;
      deviceName: string;
      protocol: string;
      ipAddress: string;
      port: number;
      enableAuth: boolean;
      username?: string;
      password?: string;
    };
  } {
    return {
      id: `nas_${device.id}`,
      name: device.name,
      url: `nas://${device.ip}:${device.port}`,
      type: 'nas',
      version: '1.0.0',
      isActive: true,
      contentUsage: {
        vodSites: true,
        liveChannels: false,
        wallpapers: false,
        adBlockRules: false,
        decoderConfigs: false,
        parserConfigs: false
      },
      priority: 1,
      tags: ['NAS', device.manufacturer],
      lastUpdated: Date.now(),
      healthStatus: device.isOnline ? 'healthy' : 'unreachable',
      nasConfig: {
        deviceId: device.id,
        deviceName: device.name,
        protocol: device.protocol,
        ipAddress: device.ip,
        port: device.port,
        enableAuth: !!device.authConfig,
        username: device.authConfig?.username,
        password: device.authConfig?.password
      }
    };
  }
  
  /**
   * 销毁服务
   */
  public destroy(): void {
    this.stopAutoDiscovery();
    this.clearDevices();
    this.logger.info('NAS发现服务已销毁');
  }
}

// 导出单例实例
export default NASDiscoveryService.getInstance();
