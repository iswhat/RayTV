// SynologyAdapter.ets - 群晖协议适配器
import { NASDevice, NASFileItem } from '../types/NASDeviceTypes';
import { BaseNASProtocolAdapter, NASFileType } from '../NASProtocolAdapter';
import HttpService from '../../HttpService';
import Logger from '../../common/util/Logger';

export class SynologyAdapter extends BaseNASProtocolAdapter {
  protocol: string = 'synology';
  private httpService: HttpService;
  private logger: Logger;
  private connections: Map<string, boolean> = new Map();
  private sessionIds: Map<string, string> = new Map();

  constructor() {
    super();
    this.httpService = HttpService.getInstance();
    this.logger = new Logger('SynologyAdapter');
  }

  async connect(device: NASDevice): Promise<boolean> {
    try {
      this.logger.info(`连接群晖设备: ${device.name} (${device.ip}:${device.port})`);
      
      // 测试连接
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/webapi/entry.cgi`, {
        params: {
          api: 'SYNO.InfoCenter',
          method: 'query',
          version: '2',
          query: 'device'
        },
        timeout: 5000
      });
      
      if (response && response.statusCode === 200) {
        // 尝试登录获取session ID
        if (device.authConfig?.enableAuth) {
          await this.login(device);
        }
        
        this.connections.set(device.id, true);
        this.logger.info(`成功连接群晖设备: ${device.name}`);
        return true;
      }
      
      this.logger.warn(`连接群晖设备失败: ${device.name}`);
      return false;
    } catch (error) {
      this.logger.error(`连接群晖设备失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  async disconnect(device: NASDevice): Promise<boolean> {
    try {
      // 尝试登出
      if (this.sessionIds.has(device.id)) {
        await this.logout(device);
      }
      
      this.connections.delete(device.id);
      this.sessionIds.delete(device.id);
      this.logger.info(`断开群晖设备连接: ${device.name}`);
      return true;
    } catch (error) {
      this.logger.error(`断开群晖设备连接失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  isConnected(device: NASDevice): boolean {
    return this.connections.get(device.id) || false;
  }

  async listDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      const sid = this.getSessionId(device);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/webapi/entry.cgi`, {
        params: {
          api: 'SYNO.FileStation.List',
          method: 'list',
          version: '2',
          path: path,
          _sid: sid
        },
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        return response.result.files.map((file: { id: string; name: string; path: string; type: string; size: number; mtime: number; mime: string }) => ({
          id: file.id,
          name: file.name,
          path: file.path,
          type: file.type === 'dir' ? 'directory' : 'file',
          size: file.size,
          modifiedTime: new Date(file.mtime * 1000).getTime(),
          mimeType: file.mime,
          isVideo: file.mime?.startsWith('video/') || false,
          isAudio: file.mime?.startsWith('audio/') || false,
          isImage: file.mime?.startsWith('image/') || false
        }));
      }
      return [];
    } catch (error) {
      this.logger.error(`列出群晖目录失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  async getFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      const sid = this.getSessionId(device);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/webapi/entry.cgi`, {
        params: {
          api: 'SYNO.FileStation.Info',
          method: 'getinfo',
          version: '2',
          path: path,
          _sid: sid
        },
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const file: { id: string; name: string; path: string; type: string; size: number; mtime: number; mime: string } = response.result.files[0];
        return {
          id: file.id,
          name: file.name,
          path: file.path,
          type: file.type === 'dir' ? 'directory' : 'file',
          size: file.size,
          modifiedTime: new Date(file.mtime * 1000).getTime(),
          mimeType: file.mime,
          isVideo: file.mime?.startsWith('video/') || false,
          isAudio: file.mime?.startsWith('audio/') || false,
          isImage: file.mime?.startsWith('image/') || false
        };
      }
      throw new Error('获取文件信息失败');
    } catch (error) {
      this.logger.error(`获取群晖文件信息失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  async readFile(device: NASDevice, path: string, offset?: number, length?: number): Promise<ArrayBuffer> {
    try {
      const sid = this.getSessionId(device);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/webapi/entry.cgi`, {
        params: {
          api: 'SYNO.FileStation.Download',
          method: 'download',
          version: '2',
          path: path,
          _sid: sid
        },
        timeout: 30000
      });
      
      if (response && response.statusCode === 200) {
        // 实际项目中需要将响应转换为ArrayBuffer
        return new ArrayBuffer(0);
      }
      throw new Error('读取文件失败');
    } catch (error) {
      this.logger.error(`读取群晖文件失败: ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  private async login(device: NASDevice): Promise<string> {
    try {
      const response = await this.httpService.post(`http://${device.ip}:${device.port}/webapi/auth.cgi`, {
        params: {
          api: 'SYNO.API.Auth',
          method: 'login',
          version: '3',
          account: device.authConfig?.username,
          passwd: device.authConfig?.password,
          session: 'FileStation',
          format: 'sid'
        },
        timeout: 5000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const sid = response.result.sid;
        this.sessionIds.set(device.id, sid);
        return sid;
      }
      throw new Error('登录失败');
    } catch (error) {
      this.logger.error(`群晖设备登录失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  private async logout(device: NASDevice): Promise<void> {
    try {
      const sid = this.sessionIds.get(device.id);
      if (sid) {
        await this.httpService.get(`http://${device.ip}:${device.port}/webapi/auth.cgi`, {
          params: {
            api: 'SYNO.API.Auth',
            method: 'logout',
            version: '3',
            session: 'FileStation',
            _sid: sid
          },
          timeout: 5000
        });
      }
    } catch (error) {
      this.logger.error(`群晖设备登出失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
    }
  }

  private getSessionId(device: NASDevice): string {
    return this.sessionIds.get(device.id) || 'mock_synology_sid';
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
export default new SynologyAdapter();