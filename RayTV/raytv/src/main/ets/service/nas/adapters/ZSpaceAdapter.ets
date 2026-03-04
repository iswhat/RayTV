// ZSpaceAdapter.ets - 极空间协议适配器
import { NASDevice, NASFileItem } from '../types/NASDeviceTypes';
import { BaseNASProtocolAdapter, NASFileType } from '../NASProtocolAdapter';
import HttpService from '../../HttpService';
import Logger from '../../common/util/Logger';

export class ZSpaceAdapter extends BaseNASProtocolAdapter {
  protocol: string = 'zspace';
  private httpService: HttpService;
  private logger: Logger;
  private connections: Map<string, boolean> = new Map();

  constructor() {
    super();
    this.httpService = HttpService.getInstance();
    this.logger = new Logger('ZSpaceAdapter');
  }

  async connect(device: NASDevice): Promise<boolean> {
    try {
      this.logger.info(`连接极空间设备: ${device.name} (${device.ip}:${device.port})`);
      
      // 测试连接
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/device/info`, {
        timeout: 5000
      });
      
      if (response && response.statusCode === 200) {
        this.connections.set(device.id, true);
        this.logger.info(`成功连接极空间设备: ${device.name}`);
        return true;
      }
      
      this.logger.warn(`连接极空间设备失败: ${device.name}`);
      return false;
    } catch (error) {
      this.logger.error(`连接极空间设备失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  async disconnect(device: NASDevice): Promise<boolean> {
    try {
      this.connections.delete(device.id);
      this.logger.info(`断开极空间设备连接: ${device.name}`);
      return true;
    } catch (error) {
      this.logger.error(`断开极空间设备连接失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  isConnected(device: NASDevice): boolean {
    return this.connections.get(device.id) || false;
  }

  async listDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/list`, {
        params: { path },
        headers: this.getAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        return response.result.files.map((file: { id: string; name: string; path: string; type: string; size: number; modifiedTime: string; mimeType: string; duration?: number; resolution?: string }) => ({
          id: file.id,
          name: file.name,
          path: file.path,
          type: file.type,
          size: file.size,
          modifiedTime: new Date(file.modifiedTime).getTime(),
          mimeType: file.mimeType,
          duration: file.duration,
          resolution: file.resolution,
          isVideo: file.mimeType?.startsWith('video/') || false,
          isAudio: file.mimeType?.startsWith('audio/') || false,
          isImage: file.mimeType?.startsWith('image/') || false
        }));
      }
      return [];
    } catch (error) {
      this.logger.error(`列出极空间目录失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  async getFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/info`, {
        params: { path },
        headers: this.getAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const file: { id: string; name: string; path: string; type: string; size: number; modifiedTime: string; mimeType: string; duration?: number; resolution?: string } = response.result;
        return {
          id: file.id,
          name: file.name,
          path: file.path,
          type: file.type,
          size: file.size,
          modifiedTime: new Date(file.modifiedTime).getTime(),
          mimeType: file.mimeType,
          duration: file.duration,
          resolution: file.resolution,
          isVideo: file.mimeType?.startsWith('video/') || false,
          isAudio: file.mimeType?.startsWith('audio/') || false,
          isImage: file.mimeType?.startsWith('image/') || false
        };
      }
      throw new Error('获取文件信息失败');
    } catch (error) {
      this.logger.error(`获取极空间文件信息失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  async readFile(device: NASDevice, path: string, offset?: number, length?: number): Promise<ArrayBuffer> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/read`, {
        params: { path, offset, length },
        headers: this.getAuthHeaders(device),
        timeout: 30000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        // 实际项目中需要将响应转换为ArrayBuffer
        return new ArrayBuffer(0);
      }
      throw new Error('读取文件失败');
    } catch (error) {
      this.logger.error(`读取极空间文件失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  private getAuthHeaders(device: NASDevice): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    if (device.authConfig?.enableAuth) {
      headers['Authorization'] = `Bearer ${this.getToken(device)}`;
    }
    
    return headers;
  }

  private getToken(device: NASDevice): string {
    // 实际项目中需要实现token获取逻辑
    return 'mock_zspace_token';
  }

  getConfigOptions(): Record<string, string | number | boolean> {
    return {
      enableAuth: false,
      username: '',
      password: ''
    };
  }

  validateConfig(config: Record<string, string | number | boolean>): boolean {
    if (config.enableAuth) {
      return !!config.username && !!config.password;
    }
    return true;
  }
}

// 导出适配器实例
export default new ZSpaceAdapter();