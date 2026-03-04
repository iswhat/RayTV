import { NASDevice, NASFileItem } from './types/NASDeviceTypes';

// NAS文件类型枚举
export enum NASFileType {
  FILE = 'file',
  DIRECTORY = 'directory'
}

// NAS协议适配器接口
export interface NASProtocolAdapter {
  // 协议类型
  protocol: string;

  // 连接设备
  connect(device: NASDevice): Promise<boolean>;

  // 断开连接
  disconnect(device: NASDevice): Promise<boolean>;

  // 检查连接状态
  isConnected(device: NASDevice): boolean;

  // 列出目录内容
  listDirectory(device: NASDevice, path: string): Promise<NASFileItem[]>;

  // 获取文件信息
  getFileInfo(device: NASDevice, path: string): Promise<NASFileItem>;

  // 读取文件内容
  readFile(device: NASDevice, path: string, offset?: number, length?: number): Promise<ArrayBuffer>;

  // 下载文件
  downloadFile(device: NASDevice, path: string, localPath: string): Promise<boolean>;

  // 搜索文件
  searchFiles(device: NASDevice, keyword: string, path?: string): Promise<NASFileItem[]>;

  // 获取文件缩略图
  getThumbnail(device: NASDevice, path: string, width?: number, height?: number): Promise<ArrayBuffer>;

  // 获取设备信息
  getDeviceInfo(device: NASDevice): Promise<{
    id: string;
    name: string;
    protocol: string;
    address: string;
    port: number;
  }>;

  // 测试连接
  testConnection(device: NASDevice): Promise<boolean>;

  // 获取协议特定的配置选项
  getConfigOptions(): Record<string, string | number | boolean>;

  // 验证配置
  validateConfig(config: Record<string, string | number | boolean>): boolean;
}

// 协议适配器工厂类
export class NASProtocolAdapterFactory {
  private static adapters: Map<string, NASProtocolAdapter> = new Map();

  // 注册协议适配器
  public static registerAdapter(protocol: string, adapter: NASProtocolAdapter): void {
    this.adapters.set(protocol, adapter);
  }

  // 获取协议适配器
  public static getAdapter(protocol: string): NASProtocolAdapter | undefined {
    return this.adapters.get(protocol);
  }

  // 获取所有支持的协议
  public static getSupportedProtocols(): string[] {
    return Array.from(this.adapters.keys());
  }

  // 检查协议是否支持
  public static isProtocolSupported(protocol: string): boolean {
    return this.adapters.has(protocol);
  }
}

// 基础协议适配器实现（提供默认实现）
export abstract class BaseNASProtocolAdapter implements NASProtocolAdapter {
  abstract protocol: string;

  abstract connect(device: NASDevice): Promise<boolean>;
  abstract disconnect(device: NASDevice): Promise<boolean>;
  abstract isConnected(device: NASDevice): boolean;
  abstract listDirectory(device: NASDevice, path: string): Promise<NASFileInfo[]>;
  abstract getFileInfo(device: NASDevice, path: string): Promise<NASFileInfo>;
  abstract readFile(device: NASDevice, path: string, offset?: number, length?: number): Promise<ArrayBuffer>;

  // 默认实现
  async downloadFile(device: NASDevice, path: string, localPath: string): Promise<boolean> {
    // 默认实现：读取文件内容并保存到本地
    try {
      const content = await this.readFile(device, path);
      // 实际项目中需要实现文件写入
      return true;
    } catch (error) {
      console.error(`Error downloading file: ${error}`);
      return false;
    }
  }

  async searchFiles(device: NASDevice, keyword: string, path: string = '/'): Promise<NASFileInfo[]> {
    // 默认实现：遍历目录搜索
    const results: NASFileInfo[] = [];
    await this.searchFilesRecursive(device, path, keyword, results);
    return results;
  }

  private async searchFilesRecursive(
    device: NASDevice, 
    currentPath: string, 
    keyword: string, 
    results: NASFileInfo[]
  ): Promise<void> {
    try {
      const entries = await this.listDirectory(device, currentPath);
      for (const entry of entries) {
        if (entry.name.toLowerCase().includes(keyword.toLowerCase())) {
          results.push(entry);
        }
        if (entry.type === NASFileType.DIRECTORY) {
          await this.searchFilesRecursive(device, entry.path, keyword, results);
        }
      }
    } catch (error) {
      console.error(`Error searching files in ${currentPath}: ${error}`);
    }
  }

  async getThumbnail(device: NASDevice, path: string, width: number = 128, height: number = 72): Promise<ArrayBuffer> {
    // 默认实现：返回空缓冲区
    return new ArrayBuffer(0);
  }

  async getDeviceInfo(device: NASDevice): Promise<{
    id: string;
    name: string;
    protocol: string;
    address: string;
    port: number;
    [key: string]: any;
  }> {
    // 默认实现：返回设备基本信息
    return {
      id: device.id,
      name: device.name,
      protocol: this.protocol,
      address: device.ip,
      port: device.port
    };
  }

  async testConnection(device: NASDevice): Promise<boolean> {
    // 默认实现：尝试连接并断开
    try {
      const connected = await this.connect(device);
      if (connected) {
        await this.disconnect(device);
        return true;
      }
      return false;
    } catch (error) {
      console.error(`Connection test failed: ${error}`);
      return false;
    }
  }

  getConfigOptions(): Record<string, string | number | boolean> {
    // 默认实现：返回空配置
    return {};
  }

  validateConfig(config: Record<string, string | number | boolean>): boolean {
    // 默认实现：总是验证通过
    return true;
  }
}
