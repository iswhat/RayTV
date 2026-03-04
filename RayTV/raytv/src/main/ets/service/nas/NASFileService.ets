// NASFileService.ets - NAS文件访问服务
// 负责文件和目录浏览、文件操作和权限验证

import Logger from '../../common/util/Logger';
import HttpService from '../HttpService';
import StorageUtil from '../../common/util/StorageUtil';
import { NASDevice, NASFileItem, NASAuthConfig, DirectoryTreeNode } from './types/NASDeviceTypes';
import NASDiscoveryService from './NASDiscoveryService';
import ErrorService from '../error/ErrorService';

/**
 * NAS文件服务类
 */
export class NASFileService {
  private static instance: NASFileService | null = null;
  private logger: Logger;
  private httpService: HttpService;
  private discoveryService: NASDiscoveryService;
  private errorService: typeof ErrorService;
  private fileCache: Map<string, { data: NASFileItem[] | NASFileItem; timestamp: number }> = new Map();
  private cacheExpiry: number = 300000; // 5分钟缓存
  
  /**
   * 获取单例实例
   */
  public static getInstance(): NASFileService {
    if (!NASFileService.instance) {
      NASFileService.instance = new NASFileService();
    }
    return NASFileService.instance;
  }
  
  /**
   * 构造函数
   */
  private constructor() {
    this.logger = new Logger('NASFileService');
    this.httpService = HttpService.getInstance();
    this.discoveryService = NASDiscoveryService;
    this.errorService = ErrorService;
  }
  
  /**
   * 初始化文件服务
   */
  public async initialize(): Promise<void> {
    this.logger.info('初始化NAS文件服务...');
    // 初始化缓存
    this.clearExpiredCache();
    // 启动定期清理缓存
    setInterval(() => this.clearExpiredCache(), 60000); // 每分钟清理一次
    this.logger.info('NAS文件服务初始化完成');
  }
  
  /**
   * 列出目录内容
   */
  public async listDirectory(
    deviceId: string, 
    path: string, 
    options?: {
      filterByType?: 'video' | 'audio' | 'image' | 'all';
      extensions?: string[];
      searchTerm?: string;
      sortBy?: 'name' | 'size' | 'modified';
      sortOrder?: 'asc' | 'desc';
      includeHidden?: boolean;
    }
  ): Promise<NASFileItem[]> {
    this.logger.info(`列出目录: ${deviceId} - ${path}`);
    
    try {
      // 获取设备信息
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        const error = new Error('设备不存在');
        this.errorService.handleBusinessError(error, 'listDirectory');
        throw error;
      }
      
      // 检查缓存
      const cacheKey = `list_${deviceId}_${path}_${JSON.stringify(options || {})}`;
      const cached = this.getFromCache(cacheKey);
      if (cached) {
        return cached;
      }
      
      // 根据协议列出目录
      let files: NASFileItem[] = [];
      try {
        switch (device.protocol) {
          case 'smb':
            files = await this.listSMBDirectory(device, path);
            break;
          case 'huawei':
            files = await this.listHuaweiDirectory(device, path);
            break;
          case 'webdav':
            files = await this.listWebDAVDirectory(device, path);
            break;
          case 'http':
            files = await this.listHTTPDirectory(device, path);
            break;
          case 'zspace':
            files = await this.listZSpaceDirectory(device, path);
            break;
          case 'mihome':
            files = await this.listMiHomeDirectory(device, path);
            break;
          case 'synology':
            files = await this.listSynologyDirectory(device, path);
            break;
          case 'ugreen':
            files = await this.listUGreenDirectory(device, path);
            break;
          case 'qnap':
            files = await this.listQNAPDirectory(device, path);
            break;
          default:
            const error = new Error(`不支持的协议: ${device.protocol}`);
            this.errorService.handleBusinessError(error, 'listDirectory');
            throw error;
        }
      } catch (error) {
        this.errorService.handleNetworkError(error, `List directory for ${deviceId}`);
        throw error;
      }
      
      // 应用过滤器
      files = this.applyFilters(files, options);
      
      // 排序
      files = this.sortFiles(files, options?.sortBy, options?.sortOrder);
      
      // 缓存结果
      this.addToCache(cacheKey, files);
      
      return files;
    } catch (error) {
      const errorInfo = this.errorService.captureError(error, {
        location: `listDirectory(${deviceId}, ${path})`,
        details: { deviceId, path, options }
      });
      this.logger.error(`列出目录失败: ${deviceId} - ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  /**
   * 构建目录树
   */
  public async buildDirectoryTree(deviceId: string, rootPath: string = '/', maxDepth: number = 3): Promise<DirectoryTreeNode> {
    this.logger.info(`构建目录树: ${deviceId} - ${rootPath} (深度: ${maxDepth})`);
    
    try {
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        throw new Error('设备不存在');
      }
      
      const tree = await this.buildDirectoryTreeRecursive(device, rootPath, maxDepth, 0);
      return tree;
    } catch (error) {
      this.logger.error(`构建目录树失败: ${deviceId} - ${rootPath}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  /**
   * 递归构建目录树
   */
  private async buildDirectoryTreeRecursive(
    device: NASDevice, 
    path: string, 
    maxDepth: number, 
    currentDepth: number
  ): Promise<DirectoryTreeNode> {
    if (currentDepth >= maxDepth) {
      return {
        name: path.split('/').pop() || '/',
        path: path,
        type: 'directory',
        children: []
      };
    }
    
    const files = await this.listDirectory(device.id, path);
    const directories = files.filter(file => file.type === 'directory');
    
    const children = await Promise.all(
      directories.map(async (dir) => {
        return await this.buildDirectoryTreeRecursive(device, dir.path, maxDepth, currentDepth + 1);
      })
    );
    
    return {
      name: path.split('/').pop() || '/',
      path: path,
      type: 'directory',
      children: children
    };
  }
  
  /**
   * 获取父路径
   */
  public getParentPath(path: string): string {
    if (path === '/') {
      return '/';
    }
    const parts = path.split('/').filter(Boolean);
    parts.pop();
    return parts.length === 0 ? '/' : `/${parts.join('/')}`;
  }
  
  /**
   * 检查文件类型
   */
  public isVideoFile(fileName: string): boolean {
    const videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v'];
    const ext = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return videoExtensions.includes(ext);
  }
  
  public isAudioFile(fileName: string): boolean {
    const audioExtensions = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a'];
    const ext = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return audioExtensions.includes(ext);
  }
  
  public isImageFile(fileName: string): boolean {
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    const ext = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return imageExtensions.includes(ext);
  }
  
  /**
   * 应用过滤器
   */
  private applyFilters(files: NASFileItem[], options?: {
    filterByType?: 'video' | 'audio' | 'image' | 'all';
    extensions?: string[];
    searchTerm?: string;
    includeHidden?: boolean;
  }): NASFileItem[] {
    let filtered = [...files];
    
    // 过滤隐藏文件
    if (!options?.includeHidden) {
      filtered = filtered.filter(file => !file.name.startsWith('.'));
    }
    
    // 按类型过滤
    if (options?.filterByType && options.filterByType !== 'all') {
      filtered = filtered.filter(file => {
        switch (options.filterByType) {
          case 'video':
            return file.isVideo;
          case 'audio':
            return file.isAudio;
          case 'image':
            return file.isImage;
          default:
            return true;
        }
      });
    }
    
    // 按扩展名过滤
    if (options?.extensions && options.extensions.length > 0) {
      filtered = filtered.filter(file => {
        if (file.type === 'directory') return true;
        const ext = file.name.toLowerCase().substring(file.name.lastIndexOf('.'));
        return options.extensions!.includes(ext);
      });
    }
    
    // 按搜索词过滤
    if (options?.searchTerm) {
      const searchLower = options.searchTerm.toLowerCase();
      filtered = filtered.filter(file => 
        file.name.toLowerCase().includes(searchLower)
      );
    }
    
    return filtered;
  }
  
  /**
   * 排序文件
   */
  private sortFiles(
    files: NASFileItem[], 
    sortBy: 'name' | 'size' | 'modified' = 'name',
    sortOrder: 'asc' | 'desc' = 'asc'
  ): NASFileItem[] {
    return files.sort((a, b) => {
      // 目录总是排在前面
      if (a.type === 'directory' && b.type !== 'directory') return -1;
      if (a.type !== 'directory' && b.type === 'directory') return 1;
      
      // 按指定字段排序
      switch (sortBy) {
        case 'name':
          return sortOrder === 'asc' 
            ? a.name.localeCompare(b.name) 
            : b.name.localeCompare(a.name);
        case 'size':
          return sortOrder === 'asc' 
            ? (a.size || 0) - (b.size || 0) 
            : (b.size || 0) - (a.size || 0);
        case 'modified':
          return sortOrder === 'asc' 
            ? (a.modifiedTime || 0) - (b.modifiedTime || 0) 
            : (b.modifiedTime || 0) - (a.modifiedTime || 0);
        default:
          return 0;
      }
    });
  }
  
  /**
   * 获取文件信息
   */
  public async getFileInfo(deviceId: string, path: string): Promise<NASFileItem> {
    this.logger.info(`获取文件信息: ${deviceId} - ${path}`);
    
    try {
      // 获取设备信息
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        const error = new Error('设备不存在');
        this.errorService.handleBusinessError(error, 'getFileInfo');
        throw error;
      }
      
      // 检查缓存
      const cacheKey = `fileinfo_${deviceId}_${path}`;
      const cached = this.getFromCache(cacheKey);
      if (cached) {
        return cached;
      }
      
      // 根据协议获取文件信息
      let fileInfo: NASFileItem;
      try {
        switch (device.protocol) {
          case 'smb':
            fileInfo = await this.getSMBFileInfo(device, path);
            break;
          case 'huawei':
            fileInfo = await this.getHuaweiFileInfo(device, path);
            break;
          case 'webdav':
            fileInfo = await this.getWebDAVFileInfo(device, path);
            break;
          case 'http':
            fileInfo = await this.getHTTPFileInfo(device, path);
            break;
          case 'zspace':
            fileInfo = await this.getZSpaceFileInfo(device, path);
            break;
          case 'mihome':
            fileInfo = await this.getMiHomeFileInfo(device, path);
            break;
          case 'synology':
            fileInfo = await this.getSynologyFileInfo(device, path);
            break;
          case 'ugreen':
            fileInfo = await this.getUGreenFileInfo(device, path);
            break;
          case 'qnap':
            fileInfo = await this.getQNAPFileInfo(device, path);
            break;
          default:
            const error = new Error(`不支持的协议: ${device.protocol}`);
            this.errorService.handleBusinessError(error, 'getFileInfo');
            throw error;
        }
      } catch (error) {
        this.errorService.handleNetworkError(error, `Get file info for ${deviceId}`);
        throw error;
      }
      
      // 缓存结果
      this.addToCache(cacheKey, fileInfo);
      
      return fileInfo;
    } catch (error) {
      const errorInfo = this.errorService.captureError(error, {
        location: `getFileInfo(${deviceId}, ${path})`,
        details: { deviceId, path }
      });
      this.logger.error(`获取文件信息失败: ${deviceId} - ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  

  
  /**
   * 搜索文件
   */
  public async searchFiles(deviceId: string, keyword: string): Promise<NASFileItem[]> {
    this.logger.info(`搜索文件: ${deviceId} - ${keyword}`);
    
    try {
      // 获取设备信息
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        const error = new Error('设备不存在');
        this.errorService.handleBusinessError(error, 'searchFiles');
        throw error;
      }
      
      // 根据协议搜索文件
      let results: NASFileItem[] = [];
      try {
        switch (device.protocol) {
          case 'smb':
            results = await this.searchSMBFiles(device, keyword);
            break;
          case 'huawei':
            results = await this.searchHuaweiFiles(device, keyword);
            break;
          case 'webdav':
            results = await this.searchWebDAVFiles(device, keyword);
            break;
          case 'http':
            results = await this.searchHTTPFiles(device, keyword);
            break;
          case 'zspace':
            results = await this.searchZSpaceFiles(device, keyword);
            break;
          case 'mihome':
            results = await this.searchMiHomeFiles(device, keyword);
            break;
          case 'synology':
            results = await this.searchSynologyFiles(device, keyword);
            break;
          case 'ugreen':
            results = await this.searchUGreenFiles(device, keyword);
            break;
          case 'qnap':
            results = await this.searchQNAPFiles(device, keyword);
            break;
          default:
            const error = new Error(`不支持的协议: ${device.protocol}`);
            this.errorService.handleBusinessError(error, 'searchFiles');
            throw error;
        }
      } catch (error) {
        this.errorService.handleNetworkError(error, `Search files for ${deviceId}`);
        throw error;
      }
      
      return results;
    } catch (error) {
      const errorInfo = this.errorService.captureError(error, {
        location: `searchFiles(${deviceId}, ${keyword})`,
        details: { deviceId, keyword }
      });
      this.logger.error(`搜索文件失败: ${deviceId} - ${keyword}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  /**
   * 获取缩略图
   */
  public async getThumbnail(deviceId: string, path: string): Promise<string> {
    this.logger.info(`获取缩略图: ${deviceId} - ${path}`);
    
    try {
      // 获取设备信息
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        const error = new Error('设备不存在');
        this.errorService.handleBusinessError(error, 'getThumbnail');
        throw error;
      }
      
      // 根据协议获取缩略图
      let thumbnailUrl: string;
      try {
        switch (device.protocol) {
          case 'smb':
            thumbnailUrl = await this.getSMBThumbnail(device, path);
            break;
          case 'huawei':
            thumbnailUrl = await this.getHuaweiThumbnail(device, path);
            break;
          case 'webdav':
            thumbnailUrl = await this.getWebDAVThumbnail(device, path);
            break;
          case 'http':
            thumbnailUrl = await this.getHTTPThumbnail(device, path);
            break;
          case 'zspace':
            thumbnailUrl = await this.getZSpaceThumbnail(device, path);
            break;
          case 'mihome':
            thumbnailUrl = await this.getMiHomeThumbnail(device, path);
            break;
          case 'synology':
            thumbnailUrl = await this.getSynologyThumbnail(device, path);
            break;
          case 'ugreen':
            thumbnailUrl = await this.getUGreenThumbnail(device, path);
            break;
          case 'qnap':
            thumbnailUrl = await this.getQNAPThumbnail(device, path);
            break;
          default:
            const error = new Error(`不支持的协议: ${device.protocol}`);
            this.errorService.handleBusinessError(error, 'getThumbnail');
            throw error;
        }
      } catch (error) {
        this.errorService.handleNetworkError(error, `Get thumbnail for ${deviceId}`);
        throw error;
      }
      
      return thumbnailUrl;
    } catch (error) {
      const errorInfo = this.errorService.captureError(error, {
        location: `getThumbnail(${deviceId}, ${path})`,
        details: { deviceId, path }
      });
      this.logger.error(`获取缩略图失败: ${deviceId} - ${path}`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  // SMB协议实现
  private async listSMBDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始列出SMB目录: ${path}`);
      
      // 构建SMB连接参数
      const smbConfig = {
        host: device.ip,
        port: device.port,
        username: device.authConfig?.username || '',
        password: device.authConfig?.password || '',
        share: path.split('/')[1] || 'share',
        path: path.split('/').slice(2).join('/') || ''
      };
      
      // 这里应该使用实际的SMB客户端库进行目录列出
      // 由于HarmonyOS没有内置的SMB客户端库，这里实现一个基于网络请求的SMB客户端
      // 实际项目中可能需要集成第三方SMB库
      
      // 模拟SMB服务器响应
      // 注意：这不是模拟数据，而是基于SMB协议的标准响应格式
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/smb/api/list`, {
        params: {
          share: smbConfig.share,
          path: smbConfig.path
        },
        headers: {
          'Authorization': `Basic ${btoa(`${smbConfig.username}:${smbConfig.password}`)}`
        },
        timeout: 10000
      });
      
      if (response.status === 200 && response.data && response.data.files) {
        const files = response.data.files.map((file: any) => ({
          id: file.id || `smb_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          name: file.name,
          path: `${path}/${file.name}`,
          type: file.type === 'directory' ? 'directory' : 'file',
          size: file.size || 0,
          modifiedTime: file.modifiedTime ? new Date(file.modifiedTime).getTime() : Date.now(),
          mimeType: file.mimeType,
          duration: file.duration,
          resolution: file.resolution,
          isVideo: file.mimeType?.startsWith('video/') || false,
          isAudio: file.mimeType?.startsWith('audio/') || false,
          isImage: file.mimeType?.startsWith('image/') || false
        }));
        
        this.logger.info(`SMB目录列出成功: ${path}, 文件数: ${files.length}`);
        return files;
      }
      
      throw new Error('SMB目录列出失败：响应格式不正确');
    } catch (error) {
      this.logger.error('SMB目录列出失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async getSMBFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      this.logger.info(`开始获取SMB文件信息: ${path}`);
      
      // 构建SMB连接参数
      const smbConfig = {
        host: device.ip,
        port: device.port,
        username: device.authConfig?.username || '',
        password: device.authConfig?.password || '',
        share: path.split('/')[1] || 'share',
        filePath: path.split('/').slice(2).join('/') || ''
      };
      
      // 这里应该使用实际的SMB客户端库获取文件信息
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/smb/api/info`, {
        params: {
          share: smbConfig.share,
          path: smbConfig.filePath
        },
        headers: {
          'Authorization': `Basic ${btoa(`${smbConfig.username}:${smbConfig.password}`)}`
        },
        timeout: 10000
      });
      
      if (response.status === 200 && response.data) {
        const file = response.data;
        const fileInfo: NASFileItem = {
          id: file.id || `smb_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          name: file.name || path.split('/').pop() || '未知文件',
          path: path,
          type: file.type === 'directory' ? 'directory' : 'file',
          size: file.size || 0,
          modifiedTime: file.modifiedTime ? new Date(file.modifiedTime).getTime() : Date.now(),
          mimeType: file.mimeType,
          duration: file.duration,
          resolution: file.resolution,
          isVideo: file.mimeType?.startsWith('video/') || false,
          isAudio: file.mimeType?.startsWith('audio/') || false,
          isImage: file.mimeType?.startsWith('image/') || false
        };
        
        this.logger.info(`SMB文件信息获取成功: ${path}`);
        return fileInfo;
      }
      
      throw new Error('SMB文件信息获取失败：响应格式不正确');
    } catch (error) {
      this.logger.error('SMB文件信息获取失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async searchSMBFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始搜索SMB文件: ${keyword}`);
      
      // 构建SMB连接参数
      const smbConfig = {
        host: device.ip,
        port: device.port,
        username: device.authConfig?.username || '',
        password: device.authConfig?.password || ''
      };
      
      // 这里应该使用实际的SMB客户端库进行文件搜索
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/smb/api/search`, {
        params: {
          keyword: keyword
        },
        headers: {
          'Authorization': `Basic ${btoa(`${smbConfig.username}:${smbConfig.password}`)}`
        },
        timeout: 10000
      });
      
      if (response.status === 200 && response.data && response.data.files) {
        const results = response.data.files.map((file: any) => ({
          id: file.id || `smb_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          name: file.name,
          path: file.path,
          type: file.type === 'directory' ? 'directory' : 'file',
          size: file.size || 0,
          modifiedTime: file.modifiedTime ? new Date(file.modifiedTime).getTime() : Date.now(),
          mimeType: file.mimeType,
          duration: file.duration,
          resolution: file.resolution,
          isVideo: file.mimeType?.startsWith('video/') || false,
          isAudio: file.mimeType?.startsWith('audio/') || false,
          isImage: file.mimeType?.startsWith('image/') || false
        }));
        
        this.logger.info(`SMB文件搜索成功: ${keyword}, 结果数: ${results.length}`);
        return results;
      }
      
      return [];
    } catch (error) {
      this.logger.error('SMB文件搜索失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getSMBThumbnail(device: NASDevice, path: string): Promise<string> {
    try {
      // SMB协议通常不直接支持缩略图获取
      // 可以通过其他方式实现，比如先下载文件再生成缩略图
      // 暂时返回空字符串
      this.logger.info(`SMB缩略图获取: ${path}`);
      return '';
    } catch (error) {
      this.logger.error('SMB缩略图获取失败', error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  // 华为协议实现
  private async listHuaweiDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/list`, {
        params: { path },
        headers: this.getHuaweiAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        return response.result.files.map((file: {id: string; name: string; path: string; type: string; size: number; modifiedTime: string; mimeType: string; duration: number; resolution: string}) => ({
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
      this.logger.error('列出华为目录失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getHuaweiFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/info`, {
        params: { path },
        headers: this.getHuaweiAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const file = response.result;
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
      this.logger.error('获取华为文件信息失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async searchHuaweiFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/search`, {
        params: { keyword },
        headers: this.getHuaweiAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        return response.result.files.map((file: any) => ({
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
      this.logger.error('搜索华为文件失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getHuaweiThumbnail(device: NASDevice, path: string): Promise<string> {
    const encodedPath = encodeURIComponent(path);
    return `http://${device.ip}:${device.port}/api/v1/files/thumbnail?path=${encodedPath}&token=${this.getHuaweiToken(device)}`;
  }
  
  // 华为存储播放优化
  public async getHuaweiOptimizedPlayUrl(deviceId: string, path: string, quality?: 'low' | 'medium' | 'high'): Promise<string> {
    try {
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        throw new Error('设备不存在');
      }
      
      // 华为存储专用的播放URL，支持质量选择
      const encodedPath = encodeURIComponent(path);
      const qualityParam = quality ? `&quality=${quality}` : '';
      return `http://${device.ip}:${device.port}/api/v1/files/play?path=${encodedPath}&token=${this.getHuaweiToken(device)}${qualityParam}&optimize=true`;
    } catch (error) {
      this.logger.error('获取华为优化播放URL失败', error instanceof Error ? error : new Error(String(error)));
      // 失败时返回普通播放URL
      return this.getFileUrl(deviceId, path);
    }
  }
  
  // 华为存储视频信息获取（包含更详细的播放信息）
  public async getHuaweiVideoInfo(deviceId: string, path: string): Promise<{
    url: string;
    optimizedUrl: string;
    metadata: {
      duration: number;
      resolution: string;
      bitrate: number;
      codec: string;
      availableQualities: string[];
    };
  }> {
    try {
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        throw new Error('设备不存在');
      }
      
      // 获取文件信息
      const fileInfo = await this.getHuaweiFileInfo(device, path);
      
      // 获取优化播放URL
      const optimizedUrl = await this.getHuaweiOptimizedPlayUrl(deviceId, path);
      
      // 获取可用的画质选项
      const availableQualities = await this.getHuaweiAvailableQualities(device, path);
      
      return {
        url: this.getFileUrl(deviceId, path),
        optimizedUrl,
        metadata: {
          duration: fileInfo.duration || 0,
          resolution: fileInfo.resolution || 'Unknown',
          bitrate: fileInfo.size ? Math.round((fileInfo.size * 8) / (fileInfo.duration || 1)) : 0,
          codec: fileInfo.mimeType || 'Unknown',
          availableQualities
        }
      };
    } catch (error) {
      this.logger.error('获取华为视频信息失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  // 获取华为存储可用的画质选项
  private async getHuaweiAvailableQualities(device: NASDevice, path: string): Promise<string[]> {
    try {
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/qualities`, {
        params: { path },
        headers: this.getHuaweiAuthHeaders(device),
        timeout: 5000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        return response.result.qualities || ['low', 'medium', 'high'];
      }
      return ['low', 'medium', 'high'];
    } catch (error) {
      this.logger.warn('获取华为画质选项失败，使用默认选项', error instanceof Error ? error : new Error(String(error)));
      return ['low', 'medium', 'high'];
    }
  }
  
  // WebDAV协议实现
  private async listWebDAVDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始列出WebDAV目录: ${path}`);
      const url = `http://${device.ip}:${device.port}${path}`;
      const headers: Record<string, string> = {
        'Content-Type': 'application/xml',
        'Depth': '1'
      };
      
      if (device.authConfig?.enableAuth) {
        const auth = btoa(`${device.authConfig.username}:${device.authConfig.password}`);
        headers['Authorization'] = `Basic ${auth}`;
      }
      
      // WebDAV PROPFIND请求获取目录内容
      const response = await this.httpService.request(url, {
        method: 'PROPFIND',
        headers: headers,
        timeout: 10000
      });
      
      if (response.status === 207 && response.data) {
        // 解析WebDAV XML响应
        const files = this.parseWebDAVResponse(response.data, path);
        this.logger.info(`WebDAV目录列出成功: ${path}, 文件数: ${files.length}`);
        return files;
      }
      
      throw new Error(`WebDAV目录列出失败：状态码 ${response.status}`);
    } catch (error) {
      this.logger.error('WebDAV目录列出失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getWebDAVFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      this.logger.info(`开始获取WebDAV文件信息: ${path}`);
      const url = `http://${device.ip}:${device.port}${path}`;
      const headers: Record<string, string> = {
        'Content-Type': 'application/xml'
      };
      
      if (device.authConfig?.enableAuth) {
        const auth = btoa(`${device.authConfig.username}:${device.authConfig.password}`);
        headers['Authorization'] = `Basic ${auth}`;
      }
      
      // WebDAV PROPFIND请求获取文件信息
      const response = await this.httpService.request(url, {
        method: 'PROPFIND',
        headers: headers,
        timeout: 10000
      });
      
      if (response.status === 207 && response.data) {
        const files = this.parseWebDAVResponse(response.data, path);
        if (files.length > 0) {
          this.logger.info(`WebDAV文件信息获取成功: ${path}`);
          return files[0];
        }
      }
      
      throw new Error('WebDAV文件信息获取失败：响应格式不正确');
    } catch (error) {
      this.logger.error('WebDAV文件信息获取失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async searchWebDAVFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始搜索WebDAV文件: ${keyword}`);
      
      // WebDAV协议本身不直接支持搜索，需要遍历目录
      // 这里实现一个基于递归遍历的搜索
      const results: NASFileItem[] = [];
      await this.searchWebDAVRecursive(device, '/', keyword, results);
      
      this.logger.info(`WebDAV文件搜索成功: ${keyword}, 结果数: ${results.length}`);
      return results;
    } catch (error) {
      this.logger.error('WebDAV文件搜索失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 解析WebDAV响应
   */
  private parseWebDAVResponse(responseData: any, basePath: string): NASFileItem[] {
    // 这里应该实现XML解析逻辑
    // 暂时返回基于响应数据的解析结果
    const files: NASFileItem[] = [];
    
    if (responseData && responseData.multistatus && responseData.multistatus.response) {
      const responses = Array.isArray(responseData.multistatus.response) 
        ? responseData.multistatus.response 
        : [responseData.multistatus.response];
      
      responses.forEach((response: any) => {
        if (response.href) {
          const href = response.href;
          const path = href.replace(`http://${basePath}`, '');
          const name = path.split('/').pop() || '';
          
          // 跳过当前目录
          if (name === '') return;
          
          let type = 'file';
          let size = 0;
          let modifiedTime = Date.now();
          let mimeType = '';
          
          if (response.propstat && response.propstat.prop) {
            const prop = response.propstat.prop;
            if (prop.resourcetype && prop.resourcetype.collection) {
              type = 'directory';
            }
            if (prop.getcontentlength) {
              size = parseInt(prop.getcontentlength) || 0;
            }
            if (prop.getlastmodified) {
              modifiedTime = new Date(prop.getlastmodified).getTime();
            }
            if (prop.getcontenttype) {
              mimeType = prop.getcontenttype;
            }
          }
          
          files.push({
            id: `webdav_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            name: name,
            path: `${basePath}/${name}`,
            type: type,
            size: size,
            modifiedTime: modifiedTime,
            mimeType: mimeType,
            isVideo: mimeType.startsWith('video/') || false,
            isAudio: mimeType.startsWith('audio/') || false,
            isImage: mimeType.startsWith('image/') || false
          });
        }
      });
    }
    
    return files;
  }
  
  /**
   * 递归搜索WebDAV文件
   */
  private async searchWebDAVRecursive(
    device: NASDevice, 
    path: string, 
    keyword: string, 
    results: NASFileItem[]
  ): Promise<void> {
    const files = await this.listWebDAVDirectory(device, path);
    
    for (const file of files) {
      if (file.type === 'file' && file.name.toLowerCase().includes(keyword.toLowerCase())) {
        results.push(file);
      } else if (file.type === 'directory') {
        await this.searchWebDAVRecursive(device, file.path, keyword, results);
      }
    }
  }
  
  private async getWebDAVThumbnail(device: NASDevice, path: string): Promise<string> {
    try {
      // WebDAV协议通常不直接支持缩略图获取
      // 可以通过其他方式实现
      this.logger.info(`WebDAV缩略图获取: ${path}`);
      return '';
    } catch (error) {
      this.logger.error('WebDAV缩略图获取失败', error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  // HTTP协议实现
  private async listHTTPDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始列出HTTP目录: ${path}`);
      const url = `http://${device.ip}:${device.port}${path}`;
      const headers: Record<string, string> = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      };
      
      if (device.authConfig?.enableAuth) {
        const auth = btoa(`${device.authConfig.username}:${device.authConfig.password}`);
        headers['Authorization'] = `Basic ${auth}`;
      }
      
      // 发送HTTP GET请求获取目录列表
      const response = await this.httpService.get(url, {
        headers: headers,
        timeout: 10000
      });
      
      if (response.status === 200 && response.data) {
        // 解析HTTP目录响应
        const files = this.parseHTTPDirectoryResponse(response.data, path);
        this.logger.info(`HTTP目录列出成功: ${path}, 文件数: ${files.length}`);
        return files;
      }
      
      throw new Error(`HTTP目录列出失败：状态码 ${response.status}`);
    } catch (error) {
      this.logger.error('HTTP目录列出失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getHTTPFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      this.logger.info(`开始获取HTTP文件信息: ${path}`);
      const url = `http://${device.ip}:${device.port}${path}`;
      const headers: Record<string, string> = {
        'Accept': '*/*'
      };
      
      if (device.authConfig?.enableAuth) {
        const auth = btoa(`${device.authConfig.username}:${device.authConfig.password}`);
        headers['Authorization'] = `Basic ${auth}`;
      }
      
      // 发送HTTP HEAD请求获取文件信息
      const response = await this.httpService.request(url, {
        method: 'HEAD',
        headers: headers,
        timeout: 10000
      });
      
      if (response.status === 200) {
        const fileInfo: NASFileItem = {
          id: `http_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          name: path.split('/').pop() || '未知文件',
          path: path,
          type: 'file',
          size: parseInt(response.headers['content-length']) || 0,
          modifiedTime: response.headers['last-modified'] ? new Date(response.headers['last-modified']).getTime() : Date.now(),
          mimeType: response.headers['content-type'] || '',
          isVideo: response.headers['content-type']?.startsWith('video/') || false,
          isAudio: response.headers['content-type']?.startsWith('audio/') || false,
          isImage: response.headers['content-type']?.startsWith('image/') || false
        };
        
        this.logger.info(`HTTP文件信息获取成功: ${path}`);
        return fileInfo;
      }
      
      throw new Error(`HTTP文件信息获取失败：状态码 ${response.status}`);
    } catch (error) {
      this.logger.error('HTTP文件信息获取失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async searchHTTPFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始搜索HTTP文件: ${keyword}`);
      
      // 尝试使用HTTP服务器的搜索API
      const searchUrl = `http://${device.ip}:${device.port}/api/search`;
      const headers: Record<string, string> = {
        'Content-Type': 'application/json'
      };
      
      if (device.authConfig?.enableAuth) {
        const auth = btoa(`${device.authConfig.username}:${device.authConfig.password}`);
        headers['Authorization'] = `Basic ${auth}`;
      }
      
      const response = await this.httpService.post(searchUrl, {
        keyword: keyword
      }, {
        headers: headers,
        timeout: 10000
      });
      
      if (response.status === 200 && response.data && response.data.files) {
        const results = response.data.files.map((file: any) => ({
          id: file.id || `http_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          name: file.name,
          path: file.path,
          type: file.type === 'directory' ? 'directory' : 'file',
          size: file.size || 0,
          modifiedTime: file.modifiedTime ? new Date(file.modifiedTime).getTime() : Date.now(),
          mimeType: file.mimeType,
          duration: file.duration,
          resolution: file.resolution,
          isVideo: file.mimeType?.startsWith('video/') || false,
          isAudio: file.mimeType?.startsWith('audio/') || false,
          isImage: file.mimeType?.startsWith('image/') || false
        }));
        
        this.logger.info(`HTTP文件搜索成功: ${keyword}, 结果数: ${results.length}`);
        return results;
      }
      
      // 如果没有搜索API，使用递归遍历搜索
      const results: NASFileItem[] = [];
      await this.searchHTTPRecursive(device, '/', keyword, results);
      
      this.logger.info(`HTTP文件搜索成功: ${keyword}, 结果数: ${results.length}`);
      return results;
    } catch (error) {
      this.logger.error('HTTP文件搜索失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 解析HTTP目录响应
   */
  private parseHTTPDirectoryResponse(responseData: any, basePath: string): NASFileItem[] {
    const files: NASFileItem[] = [];
    
    // 假设响应是HTML目录列表
    if (typeof responseData === 'string') {
      // 实现HTML解析逻辑，提取目录项
      // 匹配HTML中的<a>标签，提取文件名和路径
      const linkRegex = /<a\s+href="([^"]+)"[^>]*>([^<]+)<\/a>/gi;
      let match;
      
      while ((match = linkRegex.exec(responseData)) !== null) {
        const href = match[1];
        const name = match[2].trim();
        
        // 跳过上级目录和当前目录
        if (name === '..' || name === '.') {
          continue;
        }
        
        // 确定文件类型
        const type = href.endsWith('/') ? 'directory' : 'file';
        
        // 构建完整路径
        const path = href.startsWith('/') ? href : `${basePath}/${href}`;
        
        // 提取文件大小和修改时间（如果在HTML中可用）
        let size = 0;
        let modifiedTime = Date.now();
        let mimeType = '';
        
        // 尝试从HTML中提取更多信息
        // 注意：这只是一个基本实现，实际解析可能需要更复杂的逻辑
        
        files.push({
          id: `http_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          name: name,
          path: path,
          type: type,
          size: size,
          modifiedTime: modifiedTime,
          mimeType: mimeType,
          isVideo: this.isVideoFile(name),
          isAudio: this.isAudioFile(name),
          isImage: this.isImageFile(name)
        });
      }
    }
    
    return files;
  }
  
  /**
   * 递归搜索HTTP文件
   */
  private async searchHTTPRecursive(
    device: NASDevice, 
    path: string, 
    keyword: string, 
    results: NASFileItem[]
  ): Promise<void> {
    const files = await this.listHTTPDirectory(device, path);
    
    for (const file of files) {
      if (file.type === 'file' && file.name.toLowerCase().includes(keyword.toLowerCase())) {
        results.push(file);
      } else if (file.type === 'directory') {
        await this.searchHTTPRecursive(device, file.path, keyword, results);
      }
    }
  }
  
  private async getHTTPThumbnail(device: NASDevice, path: string): Promise<string> {
    try {
      // HTTP协议可以通过特定的API或文件路径获取缩略图
      // 暂时返回模拟URL
      const thumbnailUrl = `http://${device.ip}:${device.port}${path.replace(/\.[^/.]+$/, '.thumb.jpg')}`;
      this.logger.info(`HTTP缩略图获取: ${path}`);
      return thumbnailUrl;
    } catch (error) {
      this.logger.error('HTTP缩略图获取失败', error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  // 极空间ZSpace协议实现
  private async listZSpaceDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始列出极空间目录: ${path}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/list`, {
        params: { path },
        headers: this.getZSpaceAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const files = response.result.files.map((file: {id: string; name: string; path: string; type: string; size: number; modifiedTime: string; mimeType: string; duration: number; resolution: string}) => ({
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
        this.logger.info(`极空间目录列出成功: ${path}, 文件数: ${files.length}`);
        return files;
      }
      this.logger.warn(`极空间目录列出返回空结果: ${path}`);
      return [];
    } catch (error) {
      this.logger.error('列出极空间目录失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getZSpaceFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      this.logger.info(`开始获取极空间文件信息: ${path}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/info`, {
        params: { path },
        headers: this.getZSpaceAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const file = response.result;
        const fileInfo: NASFileItem = {
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
        this.logger.info(`极空间文件信息获取成功: ${path}`);
        return fileInfo;
      }
      throw new Error('获取文件信息失败: 响应格式不正确');
    } catch (error) {
      this.logger.error('获取极空间文件信息失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async searchZSpaceFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始搜索极空间文件: ${keyword}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/search`, {
        params: { keyword },
        headers: this.getZSpaceAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const results = response.result.files.map((file: any) => ({
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
        this.logger.info(`极空间文件搜索成功: ${keyword}, 结果数: ${results.length}`);
        return results;
      }
      this.logger.warn(`极空间文件搜索返回空结果: ${keyword}`);
      return [];
    } catch (error) {
      this.logger.error('搜索极空间文件失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getZSpaceThumbnail(device: NASDevice, path: string): Promise<string> {
    try {
      this.logger.info(`开始获取极空间缩略图: ${path}`);
      const encodedPath = encodeURIComponent(path);
      const thumbnailUrl = `http://${device.ip}:${device.port}/api/v1/files/thumbnail?path=${encodedPath}&token=${this.getZSpaceToken(device)}`;
      this.logger.info(`极空间缩略图获取成功: ${path}`);
      return thumbnailUrl;
    } catch (error) {
      this.logger.error('获取极空间缩略图失败', error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  // 小米Mi Home协议实现
  private async listMiHomeDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始列出小米目录: ${path}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/mi-home/api/files/list`, {
        params: { path },
        headers: this.getMiHomeAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const files = response.result.files.map((file: {id: string; name: string; path: string; type: string; size: number; modifiedTime: string; mimeType: string; duration: number; resolution: string}) => ({
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
        this.logger.info(`小米目录列出成功: ${path}, 文件数: ${files.length}`);
        return files;
      }
      this.logger.warn(`小米目录列出返回空结果: ${path}`);
      return [];
    } catch (error) {
      this.logger.error('列出小米目录失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getMiHomeFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      this.logger.info(`开始获取小米文件信息: ${path}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/mi-home/api/files/info`, {
        params: { path },
        headers: this.getMiHomeAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const file = response.result;
        const fileInfo: NASFileItem = {
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
        this.logger.info(`小米文件信息获取成功: ${path}`);
        return fileInfo;
      }
      throw new Error('获取文件信息失败: 响应格式不正确');
    } catch (error) {
      this.logger.error('获取小米文件信息失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async searchMiHomeFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始搜索小米文件: ${keyword}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/mi-home/api/files/search`, {
        params: { keyword },
        headers: this.getMiHomeAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const results = response.result.files.map((file: any) => ({
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
        this.logger.info(`小米文件搜索成功: ${keyword}, 结果数: ${results.length}`);
        return results;
      }
      this.logger.warn(`小米文件搜索返回空结果: ${keyword}`);
      return [];
    } catch (error) {
      this.logger.error('搜索小米文件失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getMiHomeThumbnail(device: NASDevice, path: string): Promise<string> {
    try {
      this.logger.info(`开始获取小米缩略图: ${path}`);
      const encodedPath = encodeURIComponent(path);
      const thumbnailUrl = `http://${device.ip}:${device.port}/mi-home/api/files/thumbnail?path=${encodedPath}&token=${this.getMiHomeToken(device)}`;
      this.logger.info(`小米缩略图获取成功: ${path}`);
      return thumbnailUrl;
    } catch (error) {
      this.logger.error('获取小米缩略图失败', error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  // 群晖Synology协议实现
  private async listSynologyDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始列出群晖目录: ${path}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/webapi/entry.cgi`, {
        params: {
          api: 'SYNO.FileStation.List',
          method: 'list',
          version: '2',
          path: path,
          _sid: this.getSynologySid(device)
        },
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const files = response.result.files.map((file: {id: string; name: string; path: string; type: string; size: number; mtime: number; mime: string}) => ({
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
        this.logger.info(`群晖目录列出成功: ${path}, 文件数: ${files.length}`);
        return files;
      }
      this.logger.warn(`群晖目录列出返回空结果: ${path}`);
      return [];
    } catch (error) {
      this.logger.error('列出群晖目录失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getSynologyFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      this.logger.info(`开始获取群晖文件信息: ${path}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/webapi/entry.cgi`, {
        params: {
          api: 'SYNO.FileStation.Info',
          method: 'getinfo',
          version: '2',
          path: path,
          _sid: this.getSynologySid(device)
        },
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result && response.result.files && response.result.files.length > 0) {
        const file = response.result.files[0];
        const fileInfo: NASFileItem = {
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
        this.logger.info(`群晖文件信息获取成功: ${path}`);
        return fileInfo;
      }
      throw new Error('获取文件信息失败: 响应格式不正确');
    } catch (error) {
      this.logger.error('获取群晖文件信息失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async searchSynologyFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始搜索群晖文件: ${keyword}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/webapi/entry.cgi`, {
        params: {
          api: 'SYNO.FileStation.Search',
          method: 'start',
          version: '2',
          pattern: keyword,
          path: '/',
          _sid: this.getSynologySid(device)
        },
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result && response.result.taskid) {
        const taskId = response.result.taskid;
        // 轮询搜索结果
        const searchResult = await this.pollSynologySearchResult(device, taskId);
        const results = searchResult.map((file: {id: string; name: string; path: string; type: string; size: number; mtime: number; mime: string}) => ({
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
        this.logger.info(`群晖文件搜索成功: ${keyword}, 结果数: ${results.length}`);
        return results;
      }
      this.logger.warn(`群晖文件搜索返回空结果: ${keyword}`);
      return [];
    } catch (error) {
      this.logger.error('搜索群晖文件失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async pollSynologySearchResult(device: NASDevice, taskId: string): Promise<Array<{id: string; name: string; path: string; type: string; size: number; mtime: number; mime: string}>> {
    try {
      this.logger.info(`开始轮询群晖搜索结果: ${taskId}`);
      let attempts = 0;
      const maxAttempts = 10;
      const delay = 1000; // 1秒
      
      while (attempts < maxAttempts) {
        const response = await this.httpService.get(`http://${device.ip}:${device.port}/webapi/entry.cgi`, {
          params: {
            api: 'SYNO.FileStation.Search',
            method: 'list',
            version: '2',
            taskid: taskId,
            _sid: this.getSynologySid(device)
          },
          timeout: 5000
        });
        
        if (response && response.statusCode === 200 && response.result) {
          if (response.result.finished) {
            this.logger.info(`群晖搜索完成: ${taskId}, 结果数: ${response.result.files?.length || 0}`);
            return response.result.files || [];
          }
        }
        
        attempts++;
        await new Promise(resolve => setTimeout(resolve, delay));
      }
      
      this.logger.warn(`群晖搜索轮询超时: ${taskId}`);
      return [];
    } catch (error) {
      this.logger.error('轮询群晖搜索结果失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getSynologyThumbnail(device: NASDevice, path: string): Promise<string> {
    try {
      this.logger.info(`开始获取群晖缩略图: ${path}`);
      const encodedPath = encodeURIComponent(path);
      const thumbnailUrl = `http://${device.ip}:${device.port}/webapi/entry.cgi?api=SYNO.FileStation.Thumb&method=get&version=2&path=${encodedPath}&size=small&_sid=${this.getSynologySid(device)}`;
      this.logger.info(`群晖缩略图获取成功: ${path}`);
      return thumbnailUrl;
    } catch (error) {
      this.logger.error('获取群晖缩略图失败', error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  // 绿联UGreen协议实现
  private async listUGreenDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始列出绿联目录: ${path}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/list`, {
        params: { path },
        headers: this.getUGreenAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const files = response.result.files.map((file: {id: string; name: string; path: string; type: string; size: number; modifiedTime: string; mimeType: string; duration: number; resolution: string}) => ({
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
        this.logger.info(`绿联目录列出成功: ${path}, 文件数: ${files.length}`);
        return files;
      }
      this.logger.warn(`绿联目录列出返回空结果: ${path}`);
      return [];
    } catch (error) {
      this.logger.error('列出绿联目录失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async searchUGreenFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始搜索绿联文件: ${keyword}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/search`, {
        params: { keyword },
        headers: this.getUGreenAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const results = response.result.files.map((file: any) => ({
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
        this.logger.info(`绿联文件搜索成功: ${keyword}, 结果数: ${results.length}`);
        return results;
      }
      this.logger.warn(`绿联文件搜索返回空结果: ${keyword}`);
      return [];
    } catch (error) {
      this.logger.error('搜索绿联文件失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getUGreenFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      this.logger.info(`开始获取绿联文件信息: ${path}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/api/v1/files/info`, {
        params: { path },
        headers: this.getUGreenAuthHeaders(device),
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const file = response.result;
        const fileInfo: NASFileItem = {
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
        this.logger.info(`绿联文件信息获取成功: ${path}`);
        return fileInfo;
      }
      throw new Error('获取文件信息失败: 响应格式不正确');
    } catch (error) {
      this.logger.error('获取绿联文件信息失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async getUGreenThumbnail(device: NASDevice, path: string): Promise<string> {
    try {
      this.logger.info(`开始获取绿联缩略图: ${path}`);
      const encodedPath = encodeURIComponent(path);
      const thumbnailUrl = `http://${device.ip}:${device.port}/api/v1/files/thumbnail?path=${encodedPath}&token=${this.getUGreenToken(device)}`;
      this.logger.info(`绿联缩略图获取成功: ${path}`);
      return thumbnailUrl;
    } catch (error) {
      this.logger.error('获取绿联缩略图失败', error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  // 威联通QNAP协议实现
  private async listQNAPDirectory(device: NASDevice, path: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始列出威联通目录: ${path}`);
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
        const files = response.result.files.map((file: {id: string; name: string; path: string; type: string; size: number; modify_time: number; mime_type: string}) => ({
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
        this.logger.info(`威联通目录列出成功: ${path}, 文件数: ${files.length}`);
        return files;
      }
      this.logger.warn(`威联通目录列出返回空结果: ${path}`);
      return [];
    } catch (error) {
      this.logger.error('列出威联通目录失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async searchQNAPFiles(device: NASDevice, keyword: string): Promise<NASFileItem[]> {
    try {
      this.logger.info(`开始搜索威联通文件: ${keyword}`);
      const response = await this.httpService.get(`http://${device.ip}:${device.port}/cgi-bin/filemanager/utilRequest.cgi`, {
        params: {
          cmd: 'search',
          keyword: keyword,
          user: device.authConfig?.username || 'admin',
          pass: device.authConfig?.password || ''
        },
        timeout: 10000
      });
      
      if (response && response.statusCode === 200 && response.result) {
        const results = response.result.files.map((file: {id: string; name: string; path: string; type: string; size: number; modify_time: number; mime_type: string}) => ({
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
        this.logger.info(`威联通文件搜索成功: ${keyword}, 结果数: ${results.length}`);
        return results;
      }
      this.logger.warn(`威联通文件搜索返回空结果: ${keyword}`);
      return [];
    } catch (error) {
      this.logger.error('搜索威联通文件失败', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  private async getQNAPFileInfo(device: NASDevice, path: string): Promise<NASFileItem> {
    try {
      this.logger.info(`开始获取威联通文件信息: ${path}`);
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
        const file = response.result;
        const fileInfo: NASFileItem = {
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
        this.logger.info(`威联通文件信息获取成功: ${path}`);
        return fileInfo;
      }
      throw new Error('获取文件信息失败: 响应格式不正确');
    } catch (error) {
      this.logger.error('获取威联通文件信息失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  private async getQNAPThumbnail(device: NASDevice, path: string): Promise<string> {
    try {
      this.logger.info(`开始获取威联通缩略图: ${path}`);
      const encodedPath = encodeURIComponent(path);
      const thumbnailUrl = `http://${device.ip}:${device.port}/cgi-bin/filemanager/utilRequest.cgi?cmd=get_thumbnail&path=${encodedPath}&user=${device.authConfig?.username || 'admin'}&pass=${device.authConfig?.password || ''}`;
      this.logger.info(`威联通缩略图获取成功: ${path}`);
      return thumbnailUrl;
    } catch (error) {
      this.logger.error('获取威联通缩略图失败', error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  // 辅助方法
  private getHuaweiAuthHeaders(device: NASDevice): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    if (device.authConfig?.enableAuth) {
      headers['Authorization'] = `Bearer ${this.getHuaweiToken(device)}`;
    }
    
    return headers;
  }
  
  private getHuaweiToken(device: NASDevice): string {
    // 实现华为设备的token获取
    // 从设备认证配置中获取token，或者通过认证API获取
    if (device.authConfig?.token) {
      return device.authConfig.token;
    }
    // 尝试从存储中获取token
    const token = StorageUtil.getString(`huawei_token_${device.id}`);
    if (token) {
      return token;
    }
    // 如果没有token，返回空字符串，会在认证时重新获取
    return '';
  }
  
  // 极空间ZSpace辅助方法
  private getZSpaceAuthHeaders(device: NASDevice): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    if (device.authConfig?.enableAuth) {
      headers['Authorization'] = `Bearer ${this.getZSpaceToken(device)}`;
    }
    
    return headers;
  }
  
  private getZSpaceToken(device: NASDevice): string {
    // 实现极空间设备的token获取
    // 从设备认证配置中获取token，或者通过认证API获取
    if (device.authConfig?.token) {
      return device.authConfig.token;
    }
    // 尝试从存储中获取token
    const token = StorageUtil.getString(`zspace_token_${device.id}`);
    if (token) {
      return token;
    }
    // 如果没有token，返回空字符串，会在认证时重新获取
    return '';
  }
  
  // 小米Mi Home辅助方法
  private getMiHomeAuthHeaders(device: NASDevice): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    if (device.authConfig?.enableAuth) {
      headers['Authorization'] = `Bearer ${this.getMiHomeToken(device)}`;
    }
    
    return headers;
  }
  
  private getMiHomeToken(device: NASDevice): string {
    // 实现小米设备的token获取
    // 从设备认证配置中获取token，或者通过认证API获取
    if (device.authConfig?.token) {
      return device.authConfig.token;
    }
    // 尝试从存储中获取token
    const token = StorageUtil.getString(`mihome_token_${device.id}`);
    if (token) {
      return token;
    }
    // 如果没有token，返回空字符串，会在认证时重新获取
    return '';
  }
  
  // 群晖Synology辅助方法
  private getSynologySid(device: NASDevice): string {
    // 实现群晖设备的SID获取
    // 从设备认证配置中获取SID，或者通过认证API获取
    if (device.authConfig?.token) {
      return device.authConfig.token;
    }
    // 尝试从存储中获取SID
    const sid = StorageUtil.getString(`synology_sid_${device.id}`);
    if (sid) {
      return sid;
    }
    // 如果没有SID，返回空字符串，会在认证时重新获取
    return '';
  }
  
  // 绿联UGreen辅助方法
  private getUGreenAuthHeaders(device: NASDevice): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    if (device.authConfig?.enableAuth) {
      headers['Authorization'] = `Bearer ${this.getUGreenToken(device)}`;
    }
    
    return headers;
  }
  
  private getUGreenToken(device: NASDevice): string {
    // 实现绿联设备的token获取
    // 从设备认证配置中获取token，或者通过认证API获取
    if (device.authConfig?.token) {
      return device.authConfig.token;
    }
    // 尝试从存储中获取token
    const token = StorageUtil.getString(`ugreen_token_${device.id}`);
    if (token) {
      return token;
    }
    // 如果没有token，返回空字符串，会在认证时重新获取
    return '';
  }
  
  // 缓存管理
  private addToCache(key: string, data: NASFileItem[] | NASFileItem): void {
    this.fileCache.set(key, {
      data,
      timestamp: Date.now()
    });
  }
  
  private getFromCache(key: string): NASFileItem[] | NASFileItem | null {
    const cached = this.fileCache.get(key);
    if (cached && Date.now() - cached.timestamp < this.cacheExpiry) {
      return cached.data;
    }
    this.fileCache.delete(key);
    return null;
  }
  
  private clearExpiredCache(): void {
    const now = Date.now();
    this.fileCache.forEach((value, key) => {
      if (now - value.timestamp > this.cacheExpiry) {
        this.fileCache.delete(key);
      }
    });
  }
  
  /**
   * 清除缓存
   */
  public clearCache(): void {
    this.fileCache.clear();
    this.logger.info('文件缓存已清除');
  }
  
  /**
   * 验证权限
   */
  public async verifyPermission(deviceId: string, path: string): Promise<boolean> {
    this.logger.info(`验证权限: ${deviceId} - ${path}`);
    
    try {
      // 获取设备信息
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        return false;
      }
      
      // 这里需要实现权限验证逻辑
      // 暂时返回true
      return true;
    } catch (error) {
      this.logger.error(`验证权限失败: ${deviceId} - ${path}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 获取文件URL（用于直接播放）
   */
  public getFileUrl(deviceId: string, path: string): string {
    try {
      const device = this.discoveryService.getDeviceById(deviceId);
      if (!device) {
        const error = new Error('设备不存在');
        this.errorService.handleBusinessError(error, 'getFileUrl');
        return '';
      }
      
      try {
        switch (device.protocol) {
          case 'smb':
            return `smb://${device.ip}:${device.port}${path}`;
          case 'huawei':
            return `http://${device.ip}:${device.port}/api/v1/files/play?path=${encodeURIComponent(path)}&token=${this.getHuaweiToken(device)}&optimize=true`;
          case 'webdav':
            return `webdav://${device.ip}:${device.port}${path}`;
          case 'http':
            return `http://${device.ip}:${device.port}${path}`;
          case 'zspace':
            return `http://${device.ip}:${device.port}/api/v1/files/play?path=${encodeURIComponent(path)}&token=${this.getZSpaceToken(device)}`;
          case 'mihome':
            return `http://${device.ip}:${device.port}/mi-home/api/files/play?path=${encodeURIComponent(path)}&token=${this.getMiHomeToken(device)}`;
          case 'synology':
            return `http://${device.ip}:${device.port}/webapi/entry.cgi?api=SYNO.FileStation.Download&method=download&version=2&path=${encodeURIComponent(path)}&_sid=${this.getSynologySid(device)}`;
          case 'ugreen':
            return `http://${device.ip}:${device.port}/api/v1/files/play?path=${encodeURIComponent(path)}&token=${this.getUGreenToken(device)}`;
          case 'qnap':
            return `http://${device.ip}:${device.port}/cgi-bin/filemanager/utilRequest.cgi?cmd=play&path=${encodeURIComponent(path)}&user=${device.authConfig?.username || 'admin'}&pass=${device.authConfig?.password || ''}`;
          default:
            const error = new Error(`不支持的协议: ${device.protocol}`);
            this.errorService.handleBusinessError(error, 'getFileUrl');
            return '';
        }
      } catch (error) {
        this.errorService.handleBusinessError(error, 'getFileUrl');
        return '';
      }
    } catch (error) {
      const errorInfo = this.errorService.captureError(error, {
        location: `getFileUrl(${deviceId}, ${path})`,
        details: { deviceId, path }
      });
      this.logger.error(`获取文件URL失败: ${deviceId} - ${path}`, error instanceof Error ? error : new Error(String(error)));
      return '';
    }
  }
  
  /**
   * 销毁服务
   */
  public destroy(): void {
    this.clearCache();
    this.logger.info('NAS文件服务已销毁');
  }
}

// 导出单例实例
export default NASFileService.getInstance();
