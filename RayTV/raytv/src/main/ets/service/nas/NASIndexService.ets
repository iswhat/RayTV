import { NASDevice, NASFileItem } from './types/NASDeviceTypes';
import { NASFileService } from './NASFileService';

// 视频文件扩展名
const VIDEO_EXTENSIONS = [
  '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv',
  '.mpg', '.mpeg', '.m4v', '.webm', '.ts', '.m2ts'
];

// 视频元数据接口
export interface VideoMetadata {
  title: string;
  year?: number;
  duration?: number;
  resolution?: string;
  codec?: string;
  bitrate?: number;
  thumbnailPath?: string;
}

// 索引项接口
export interface IndexItem {
  id: string;
  deviceId: string;
  filePath: string;
  fileName: string;
  fileSize: number;
  lastModified: number;
  metadata: VideoMetadata;
  directory: string;
  isIndexed: boolean;
  indexTime: number;
}

// 索引状态接口
export interface IndexStatus {
  deviceId: string;
  status: 'idle' | 'scanning' | 'paused' | 'completed' | 'error';
  progress: number;
  totalFiles: number;
  indexedFiles: number;
  error?: string;
  lastUpdated: number;
}

// NAS索引管理服务
export class NASIndexService {
  private static instance: NASIndexService;
  private fileService: NASFileService;
  private indexCache: Map<string, IndexItem[]> = new Map();
  private indexStatus: Map<string, IndexStatus> = new Map();
  private scanTasks: Map<string, Promise<void>> = new Map();
  private metadataCache: Map<string, VideoMetadata> = new Map();

  private constructor() {
    this.fileService = NASFileService.getInstance();
  }

  public static getInstance(): NASIndexService {
    if (!NASIndexService.instance) {
      NASIndexService.instance = new NASIndexService();
    }
    return NASIndexService.instance;
  }

  // 开始索引NAS设备
  public async startIndexing(device: NASDevice): Promise<void> {
    if (this.scanTasks.has(device.id)) {
      throw new Error(`Indexing already in progress for device ${device.id}`);
    }

    this.updateIndexStatus(device.id, 'scanning', 0, 0, 0);

    const task = this.scanDevice(device);
    this.scanTasks.set(device.id, task);

    try {
      await task;
      this.updateIndexStatus(device.id, 'completed', 100, 0, 0);
    } catch (error) {
      this.updateIndexStatus(device.id, 'error', 0, 0, 0, error.message);
    } finally {
      this.scanTasks.delete(device.id);
    }
  }

  // 暂停索引
  public pauseIndexing(deviceId: string): void {
    const status = this.indexStatus.get(deviceId);
    if (status && status.status === 'scanning') {
      this.updateIndexStatus(deviceId, 'paused', status.progress, status.totalFiles, status.indexedFiles);
    }
  }

  // 恢复索引
  public async resumeIndexing(device: NASDevice): Promise<void> {
    const status = this.indexStatus.get(device.id);
    if (status && status.status === 'paused') {
      this.updateIndexStatus(device.id, 'scanning', status.progress, status.totalFiles, status.indexedFiles);
      await this.scanDevice(device);
    }
  }

  // 停止索引
  public stopIndexing(deviceId: string): void {
    this.scanTasks.delete(deviceId);
    this.updateIndexStatus(deviceId, 'idle', 0, 0, 0);
  }

  // 获取索引状态
  public getIndexStatus(deviceId: string): IndexStatus | undefined {
    return this.indexStatus.get(deviceId);
  }

  // 获取所有设备的索引状态
  public getAllIndexStatus(): IndexStatus[] {
    return Array.from(this.indexStatus.values());
  }

  // 获取设备的索引数据
  public getDeviceIndex(deviceId: string): IndexItem[] {
    return this.indexCache.get(deviceId) || [];
  }

  // 按目录获取索引数据
  public getIndexByDirectory(deviceId: string, directory: string): IndexItem[] {
    const deviceIndex = this.indexCache.get(deviceId) || [];
    return deviceIndex.filter(item => item.directory === directory);
  }

  // 搜索索引
  public searchIndex(deviceId: string, keyword: string): IndexItem[] {
    const deviceIndex = this.indexCache.get(deviceId) || [];
    const lowerKeyword = keyword.toLowerCase();
    return deviceIndex.filter(item => 
      item.fileName.toLowerCase().includes(lowerKeyword) ||
      item.metadata.title.toLowerCase().includes(lowerKeyword)
    );
  }

  // 刷新索引（增量更新）
  public async refreshIndex(device: NASDevice): Promise<void> {
    await this.scanDevice(device, true);
  }

  // 清除设备索引
  public clearDeviceIndex(deviceId: string): void {
    this.indexCache.delete(deviceId);
    this.indexStatus.delete(deviceId);
    this.scanTasks.delete(deviceId);
  }

  // 清除所有索引
  public clearAllIndex(): void {
    this.indexCache.clear();
    this.indexStatus.clear();
    this.scanTasks.clear();
    this.metadataCache.clear();
  }

  // 扫描设备
  private async scanDevice(device: NASDevice, isIncremental: boolean = false): Promise<void> {
    const deviceIndex = isIncremental ? this.indexCache.get(device.id) || [] : [];
    let totalFiles = 0;
    let indexedFiles = 0;

    try {
      // 递归扫描目录
      const rootEntries = await this.fileService.listDirectory(device, '/');
      totalFiles = await this.calculateTotalFiles(device, '/');

      await this.scanDirectory(device, '/', deviceIndex, (current) => {
        indexedFiles = current;
        const progress = totalFiles > 0 ? Math.round((current / totalFiles) * 100) : 0;
        this.updateIndexStatus(device.id, 'scanning', progress, totalFiles, current);
      });

      // 更新索引缓存
      this.indexCache.set(device.id, deviceIndex);
    } catch (error) {
      throw new Error(`Failed to scan device: ${error.message}`);
    }
  }

  // 扫描目录
  private async scanDirectory(
    device: NASDevice,
    path: string,
    index: IndexItem[],
    progressCallback: (count: number) => void
  ): Promise<number> {
    let count = 0;

    try {
      const entries = await this.fileService.listDirectory(device, path);

      for (const entry of entries) {
        if (entry.type === 'directory') {
          count += await this.scanDirectory(device, entry.path, index, progressCallback);
        } else if (this.isVideoFile(entry.name)) {
          const indexItem = await this.createIndexItem(device, entry);
          index.push(indexItem);
          count++;
          progressCallback(count);
        }
      }
    } catch (error) {
      console.error(`Error scanning directory ${path}:`, error);
    }

    return count;
  }

  // 计算总文件数
  private async calculateTotalFiles(device: NASDevice, path: string): Promise<number> {
    let count = 0;

    try {
      const entries = await this.fileService.listDirectory(device, path);

      for (const entry of entries) {
        if (entry.type === 'directory') {
          count += await this.calculateTotalFiles(device, entry.path);
        } else if (this.isVideoFile(entry.name)) {
          count++;
        }
      }
    } catch (error) {
      console.error(`Error calculating files in ${path}:`, error);
    }

    return count;
  }

  // 创建索引项
  private async createIndexItem(device: NASDevice, file: NASFileItem): Promise<IndexItem> {
    const metadata = await this.extractMetadata(device, file);
    const directory = this.getDirectoryPath(file.path);

    return {
      id: `${device.id}_${file.path}`,
      deviceId: device.id,
      filePath: file.path,
      fileName: file.name,
      fileSize: file.size || 0,
      lastModified: file.modifiedTime || Date.now(),
      metadata,
      directory,
      isIndexed: true,
      indexTime: Date.now()
    };
  }

  // 提取视频元数据
  private async extractMetadata(device: NASDevice, file: NASFileItem): Promise<VideoMetadata> {
    const cacheKey = `${device.id}_${file.path}`;
    
    // 检查缓存
    if (this.metadataCache.has(cacheKey)) {
      return this.metadataCache.get(cacheKey)!;
    }

    // 从文件名提取基本信息
    const baseMetadata = this.extractMetadataFromFileName(file.name);
    
    // 从文件信息中提取元数据
    const fileMetadata = this.extractMetadataFromFileInfo(file);
    
    // 合并元数据
    const metadata: VideoMetadata = {
      ...baseMetadata,
      ...fileMetadata,
      thumbnailPath: await this.getThumbnailPath(device, file)
    };

    // 缓存元数据
    this.metadataCache.set(cacheKey, metadata);
    return metadata;
  }

  // 从文件名提取元数据
  private extractMetadataFromFileName(fileName: string): VideoMetadata {
    // 移除扩展名
    const nameWithoutExt = fileName.replace(/\.[^/.]+$/, '');
    // 替换下划线和连字符为空格
    let title = nameWithoutExt.replace(/[_-]/g, ' ');
    
    // 提取年份
    const yearMatch = title.match(/\((\d{4})\)|\[(\d{4})\]/);
    const year = yearMatch ? parseInt(yearMatch[1] || yearMatch[2]) : undefined;
    if (yearMatch) {
      title = title.replace(yearMatch[0], '').trim();
    }
    
    // 提取分辨率
    const resolutionMatch = title.match(/\b(\d{3,4}p|\d{3,4}x\d{3,4})\b/i);
    const resolution = resolutionMatch ? resolutionMatch[0] : undefined;
    if (resolutionMatch) {
      title = title.replace(resolutionMatch[0], '').trim();
    }
    
    // 提取编码格式
    const codecMatch = title.match(/\b(H.264|H.265|HEVC|AVC|VP9|VP8|AV1)\b/i);
    const codec = codecMatch ? codecMatch[0] : undefined;
    if (codecMatch) {
      title = title.replace(codecMatch[0], '').trim();
    }
    
    // 移除剩余的特殊字符和括号内容
    title = title.replace(/\[.*?\]/g, '').trim();
    title = title.replace(/\(.*?\)/g, '').trim();
    
    return {
      title: title || fileName,
      year,
      resolution,
      codec
    };
  }

  // 从文件信息中提取元数据
  private extractMetadataFromFileInfo(file: NASFileItem): Partial<VideoMetadata> {
    const metadata: Partial<VideoMetadata> = {};
    
    // 从文件信息中提取时长
    if (file.duration) {
      metadata.duration = file.duration;
    }
    
    // 从文件信息中提取分辨率
    if (file.resolution) {
      metadata.resolution = file.resolution;
    }
    
    // 从文件信息中提取编码格式（简单处理）
    if (file.mimeType) {
      if (file.mimeType.includes('h264') || file.mimeType.includes('avc')) {
        metadata.codec = 'H.264';
      } else if (file.mimeType.includes('h265') || file.mimeType.includes('hevc')) {
        metadata.codec = 'H.265';
      } else if (file.mimeType.includes('vp9')) {
        metadata.codec = 'VP9';
      } else if (file.mimeType.includes('vp8')) {
        metadata.codec = 'VP8';
      } else if (file.mimeType.includes('av1')) {
        metadata.codec = 'AV1';
      }
    }
    
    return metadata;
  }

  // 获取缩略图路径
  private async getThumbnailPath(device: NASDevice, file: NASFileItem): Promise<string | undefined> {
    try {
      const thumbnailUrl = await this.fileService.getThumbnail(device.id, file.path);
      return thumbnailUrl || undefined;
    } catch (error) {
      console.error('获取缩略图失败:', error);
      return undefined;
    }
  }

  // 获取目录路径
  private getDirectoryPath(filePath: string): string {
    const parts = filePath.split('/');
    parts.pop(); // 移除文件名
    return parts.join('/') || '/';
  }

  // 检查是否为视频文件
  private isVideoFile(fileName: string): boolean {
    const ext = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return VIDEO_EXTENSIONS.includes(ext);
  }

  // 更新索引状态
  private updateIndexStatus(
    deviceId: string,
    status: 'idle' | 'scanning' | 'paused' | 'completed' | 'error',
    progress: number,
    totalFiles: number,
    indexedFiles: number,
    error?: string
  ): void {
    this.indexStatus.set(deviceId, {
      deviceId,
      status,
      progress,
      totalFiles,
      indexedFiles,
      error,
      lastUpdated: Date.now()
    });
  }
}
