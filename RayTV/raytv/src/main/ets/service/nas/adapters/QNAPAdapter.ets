// QNAPAdapter.ets - 威联通协议适配器
import { NASDevice, NASFileItem } from '../types/NASDeviceTypes';
import { BaseNASProtocolAdapter, NASFileType } from '../NASProtocolAdapter';
import HttpService from '../../HttpService';
import Logger from '../../common/util/Logger';

export class QNAPAdapter extends BaseNASProtocolAdapter {
  protocol: string = 'qnap';
  private httpService: HttpService;
  private logger: Logger;
  private connections: Map<string, boolean> = new Map();

  constructor() {
    super();
    this.httpService = HttpService.getInstance();
    this.logger = new Logger('QNAPAdapter');
  }

  async connect(device: NASDevice): Promise<boolean> {
    try {
      this.logger.info(`连接威联通设备: ${device.name} (${device.ip}:${device.port})`);
      
      // 测试连接
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/cgi-bin/system_api.cgi`, {
        params: {
          cmd: 'getSystemInfo'
        },
        timeout: 5000
      });
      
      if (response && response.statusCode === 200) {
        this.connections.set(device.id, true);
        this.logger.info(`成功连接威联通设备: ${device.name}`);
        return true;
      }
      
      this.logger.warn(`连接威联通设备失败: ${device.name}`);
      return false;
    } catch (error) {
      this.logger.error(`连接威联通设备失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  async disconnect(device: NASDevice): Promise<boolean> {
    try {
      this.connections.delete(device.id);
      this.logger.info(`断开威联通设备连接: ${device.name}`);
      return true;
    } catch (error) {
      this.logger.error(`断开威联通设备连接失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  isConnected(device: NASDevice): boolean {
    return this.connections.get(device.id) || false;
  }

  async listDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/cgi-bin/filemanager/utilRequest.cgi`, {
        params: {
          cmd: 'get_file_list',
          path: path,
          user: device.authConfig?.username || 'admin',
          pass: device.authConfig?.password || ''
        },
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        return response.result.files.map((file: { id: string; name: string; path: string; type: string; size: number; modify_time: number; mime_type: string }) => ({
          id: file.id,
          name: file.name,
          path: file.path,
          type: file.type === 'dir' ? 'directory' : 'file',
          size: file.size,
          modifiedTime: new Date(file.modify_time * 1000).getTime(),
          mimeType: file.mime_type,
          isVideo: file.mime_type?.startsWith('video/') || false,
          isAudio: file.mime_type?.startsWith('audio/') || false,
          isImage: file.mime_type?.startsWith('image/') || false
        }));
      }
      return [];
    } catch (error) {
      this.logger.error(`列出威联通目录失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  async getFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/cgi-bin/filemanager/utilRequest.cgi`, {
        params: {
          cmd: 'get_file_info',
          path: path,
          user: device.authConfig?.username || 'admin',
          pass: device.authConfig?.password || ''
        },
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const file: { id: string; name: string; path: string; type: string; size: number; modify_time: number; mime_type: string } = response.result;
        return {
          id: file.id,
          name: file.name,
          path: file.path,
          type: file.type === 'dir' ? 'directory' : 'file',
          size: file.size,
          modifiedTime: new Date(file.modify_time * 1000).getTime(),
          mimeType: file.mime_type,
          isVideo: file.mime_type?.startsWith('video/') || false,
          isAudio: file.mime_type?.startsWith('audio/') || false,
          isImage: file.mime_type?.startsWith('image/') || false
        };
      }
      throw new Error('获取文件信息失败');
    } catch (error) {
      this.logger.error(`获取威联通文件信息失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  async readFile(device: NASDevice, path: string, offset?: number, length?: number): Promise<ArrayBuffer> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/cgi-bin/filemanager/utilRequest.cgi`, {
        params: {
          cmd: 'download',
          path: path,
          user: device.authConfig?.username || 'admin',
          pass: device.authConfig?.password || ''
        },
        timeout: 30000
      });
      
      if (response && response.statusCode === 200) {
        // 实际项目中需要将响应转换为ArrayBuffer
        return new ArrayBuffer(0);
      }
      throw new Error('读取文件失败');
    } catch (error) {
      this.logger.error(`读取威联通文件失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  getConfigOptions(): Record<string, string | number | boolean> {
    return {
      enableAuth: true,
      username: 'admin',
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
export default new QNAPAdapter();