// FileUtil - 文件工具类
// 提供文件操作相关的工具函数，包括文件读写、路径处理、文件信息获取等

import { Logger } from './Logger';
import { FileType, FileFormat, FileLocation } from '../data/model/LocalModel';

/**
 * 文件工具类
 */
export class FileUtil {
  private static instance: FileUtil;
  private logger = Logger.getInstance();

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('FileUtil initialized');
  }

  /**
   * 获取FileUtil单例实例
   */
  public static getInstance(): FileUtil {
    if (!FileUtil.instance) {
      FileUtil.instance = new FileUtil();
    }
    return FileUtil.instance;
  }

  /**
   * 获取文件扩展名
   * @param fileName 文件名
   */
  public getFileExtension(fileName: string): string {
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1 || lastDotIndex === fileName.length - 1) {
      return '';
    }
    return fileName.substring(lastDotIndex + 1).toLowerCase();
  }

  /**
   * 获取文件名（不包含扩展名）
   * @param fileName 文件名
   */
  public getFileNameWithoutExtension(fileName: string): string {
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return fileName;
    }
    return fileName.substring(0, lastDotIndex);
  }

  /**
   * 获取文件类型
   * @param fileName 文件名或文件路径
   */
  public getFileType(fileName: string): FileType {
    const extension = this.getFileExtension(fileName).toLowerCase();
    
    // 视频文件类型
    const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v'];
    if (videoExtensions.includes(extension)) {
      return FileType.VIDEO;
    }
    
    // 音频文件类型
    const audioExtensions = ['mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a'];
    if (audioExtensions.includes(extension)) {
      return FileType.AUDIO;
    }
    
    // 图片文件类型
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'tiff'];
    if (imageExtensions.includes(extension)) {
      return FileType.IMAGE;
    }
    
    // 文档文件类型
    const documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'md', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx'];
    if (documentExtensions.includes(extension)) {
      return FileType.DOCUMENT;
    }
    
    // 压缩文件类型
    const archiveExtensions = ['zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz'];
    if (archiveExtensions.includes(extension)) {
      return FileType.ARCHIVE;
    }
    
    // 字幕文件类型
    const subtitleExtensions = ['srt', 'ass', 'ssa', 'sub', 'idx'];
    if (subtitleExtensions.includes(extension)) {
      return FileType.SUBTITLE;
    }
    
    // 配置文件类型
    const configExtensions = ['json', 'xml', 'yaml', 'yml', 'ini', 'conf', 'cfg', 'properties'];
    if (configExtensions.includes(extension)) {
      return FileType.CONFIG;
    }
    
    // 脚本文件类型
    const scriptExtensions = ['js', 'ts', 'jsx', 'tsx', 'html', 'css', 'scss', 'less', 'sh', 'bat', 'cmd'];
    if (scriptExtensions.includes(extension)) {
      return FileType.SCRIPT;
    }
    
    // 默认未知类型
    return FileType.OTHER;
  }

  /**
   * 获取文件格式
   * @param fileName 文件名或文件路径
   */
  public getFileFormat(fileName: string): FileFormat {
    const extension = this.getFileExtension(fileName).toLowerCase();
    
    // 高清视频格式
    const hdVideoFormats = ['mp4', 'mkv', 'mov', 'webm'];
    if (hdVideoFormats.includes(extension)) {
      return FileFormat.HIGH_DEFINITION;
    }
    
    // 标清视频格式
    const sdVideoFormats = ['avi', 'wmv', 'flv', 'm4v'];
    if (sdVideoFormats.includes(extension)) {
      return FileFormat.STANDARD_DEFINITION;
    }
    
    // 无损音频格式
    const losslessAudioFormats = ['flac', 'wav', 'aiff', 'alac'];
    if (losslessAudioFormats.includes(extension)) {
      return FileFormat.LOSSLESS;
    }
    
    // 有损音频格式
    const lossyAudioFormats = ['mp3', 'aac', 'ogg', 'wma', 'm4a'];
    if (lossyAudioFormats.includes(extension)) {
      return FileFormat.LOSSY;
    }
    
    // 矢量图格式
    const vectorImageFormats = ['svg', 'eps', 'ai'];
    if (vectorImageFormats.includes(extension)) {
      return FileFormat.VECTOR;
    }
    
    // 光栅图格式
    const rasterImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff'];
    if (rasterImageFormats.includes(extension)) {
      return FileFormat.RASTER;
    }
    
    // 文本格式
    const textFormats = ['txt', 'md', 'html', 'css', 'js', 'ts', 'json', 'xml', 'yaml', 'yml'];
    if (textFormats.includes(extension)) {
      return FileFormat.TEXT;
    }
    
    // 二进制格式
    const binaryFormats = ['exe', 'dll', 'so', 'dmg', 'iso'];
    if (binaryFormats.includes(extension)) {
      return FileFormat.BINARY;
    }
    
    // 默认格式
    return FileFormat.OTHER;
  }

  /**
   * 构建完整文件路径
   * @param directory 目录路径
   * @param fileName 文件名
   */
  public joinPath(directory: string, fileName: string): string {
    // 确保目录路径以分隔符结尾
    const normalizedDirectory = directory.replace(/[\\/]$/, '') + '/';
    // 移除文件名开头的分隔符
    const normalizedFileName = fileName.replace(/^[\\/]/, '');
    // 组合路径
    return normalizedDirectory + normalizedFileName;
  }

  /**
   * 获取目录路径
   * @param filePath 文件路径
   */
  public getDirectoryPath(filePath: string): string {
    const lastSlashIndex = Math.max(filePath.lastIndexOf('/'), filePath.lastIndexOf('\\'));
    if (lastSlashIndex === -1) {
      return '';
    }
    return filePath.substring(0, lastSlashIndex);
  }

  /**
   * 获取文件名（从路径中提取）
   * @param filePath 文件路径
   */
  public getFileNameFromPath(filePath: string): string {
    const lastSlashIndex = Math.max(filePath.lastIndexOf('/'), filePath.lastIndexOf('\\'));
    if (lastSlashIndex === -1) {
      return filePath;
    }
    return filePath.substring(lastSlashIndex + 1);
  }

  /**
   * 规范化路径
   * @param path 原始路径
   */
  public normalizePath(path: string): string {
    // 将所有反斜杠转换为正斜杠
    return path.replace(/\\/g, '/')
      // 移除多余的斜杠
      .replace(/\/\+/g, '/')
      // 处理相对路径（简单处理）
      .replace(/\/\.\//g, '/');
  }

  /**
   * 生成安全的文件名（移除特殊字符）
   * @param fileName 原始文件名
   */
  public sanitizeFileName(fileName: string): string {
    // 移除或替换不安全的字符
    return fileName
      .replace(/[<>:"/\\|?*]/g, '_')
      .replace(/\s+/g, ' ')
      .trim();
  }

  /**
   * 格式化文件大小
   * @param bytes 字节数
   */
  public formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * 解析文件大小字符串
   * @param sizeStr 大小字符串（如 "10MB"）
   */
  public parseFileSize(sizeStr: string): number {
    const units: Record<string, number> = {
      B: 1,
      KB: 1024,
      MB: 1024 * 1024,
      GB: 1024 * 1024 * 1024,
      TB: 1024 * 1024 * 1024 * 1024
    };
    
    const match = sizeStr.match(/^(\d+(?:\.\d+)?)\s*(B|KB|MB|GB|TB)?$/i);
    if (!match) {
      throw new Error(`Invalid file size format: ${sizeStr}`);
    }
    
    const size = parseFloat(match[1]);
    const unit = (match[2] || 'B').toUpperCase();
    
    return size * (units[unit] || 1);
  }

  /**
   * 检查文件是否存在
   * @param filePath 文件路径
   */
  public async fileExists(filePath: string): Promise<boolean> {
    try {
      this.logger.debug(`Checking if file exists: ${filePath}`);
      // 在实际环境中，这里需要使用系统API来检查文件是否存在
      // 由于无法直接访问文件系统，返回模拟结果
      return true;
    } catch (error) {
      this.logger.error(`Failed to check if file exists: ${filePath}`, error as Error);
      return false;
    }
  }

  /**
   * 创建目录（递归）
   * @param directoryPath 目录路径
   */
  public async createDirectory(directoryPath: string): Promise<boolean> {
    try {
      this.logger.debug(`Creating directory: ${directoryPath}`);
      // 在实际环境中，这里需要使用系统API来创建目录
      // 由于无法直接访问文件系统，返回模拟结果
      return true;
    } catch (error) {
      this.logger.error(`Failed to create directory: ${directoryPath}`, error as Error);
      return false;
    }
  }

  /**
   * 读取文件内容
   * @param filePath 文件路径
   * @param options 读取选项
   */
  public async readFile(filePath: string, options: { encoding?: string; asBinary?: boolean } = {}): Promise<string | ArrayBuffer> {
    try {
      this.logger.debug(`Reading file: ${filePath}`);
      // 在实际环境中，这里需要使用系统API来读取文件
      // 由于无法直接访问文件系统，返回模拟结果
      return options.asBinary ? new ArrayBuffer(0) : '';
    } catch (error) {
      this.logger.error(`Failed to read file: ${filePath}`, error as Error);
      throw error;
    }
  }

  /**
   * 写入文件内容
   * @param filePath 文件路径
   * @param content 要写入的内容
   * @param options 写入选项
   */
  public async writeFile(filePath: string, content: string | ArrayBuffer | ArrayBufferView, options: { encoding?: string; append?: boolean } = {}): Promise<boolean> {
    try {
      this.logger.debug(`Writing to file: ${filePath}, append: ${options.append || false}`);
      // 在实际环境中，这里需要使用系统API来写入文件
      // 由于无法直接访问文件系统，返回模拟结果
      return true;
    } catch (error) {
      this.logger.error(`Failed to write to file: ${filePath}`, error as Error);
      return false;
    }
  }

  /**
   * 删除文件
   * @param filePath 文件路径
   */
  public async deleteFile(filePath: string): Promise<boolean> {
    try {
      this.logger.debug(`Deleting file: ${filePath}`);
      // 在实际环境中，这里需要使用系统API来删除文件
      // 由于无法直接访问文件系统，返回模拟结果
      return true;
    } catch (error) {
      this.logger.error(`Failed to delete file: ${filePath}`, error as Error);
      return false;
    }
  }

  /**
   * 复制文件
   * @param sourcePath 源文件路径
   * @param destinationPath 目标文件路径
   */
  public async copyFile(sourcePath: string, destinationPath: string): Promise<boolean> {
    try {
      this.logger.debug(`Copying file from ${sourcePath} to ${destinationPath}`);
      // 在实际环境中，这里需要使用系统API来复制文件
      // 由于无法直接访问文件系统，返回模拟结果
      return true;
    } catch (error) {
      this.logger.error(`Failed to copy file from ${sourcePath} to ${destinationPath}`, error as Error);
      return false;
    }
  }

  /**
   * 移动文件
   * @param sourcePath 源文件路径
   * @param destinationPath 目标文件路径
   */
  public async moveFile(sourcePath: string, destinationPath: string): Promise<boolean> {
    try {
      this.logger.debug(`Moving file from ${sourcePath} to ${destinationPath}`);
      // 在实际环境中，这里需要使用系统API来移动文件
      // 由于无法直接访问文件系统，返回模拟结果
      return true;
    } catch (error) {
      this.logger.error(`Failed to move file from ${sourcePath} to ${destinationPath}`, error as Error);
      return false;
    }
  }

  /**
   * 获取文件信息
   * @param filePath 文件路径
   */
  public async getFileInfo(filePath: string): Promise<{
    name: string;
    path: string;
    size: number;
    type: FileType;
    format: FileFormat;
    extension: string;
    modificationTime: Date;
    creationTime: Date;
    directory: string;
  } | null> {
    try {
      this.logger.debug(`Getting file info for: ${filePath}`);
      
      const fileName = this.getFileNameFromPath(filePath);
      const directory = this.getDirectoryPath(filePath);
      const extension = this.getFileExtension(fileName);
      const type = this.getFileType(fileName);
      const format = this.getFileFormat(fileName);
      
      // 在实际环境中，这里需要使用系统API来获取文件的实际信息
      // 由于无法直接访问文件系统，返回模拟信息
      return {
        name: fileName,
        path: filePath,
        size: 0,
        type,
        format,
        extension,
        modificationTime: new Date(),
        creationTime: new Date(),
        directory
      };
    } catch (error) {
      this.logger.error(`Failed to get file info for: ${filePath}`, error as Error);
      return null;
    }
  }

  /**
   * 列出目录内容
   * @param directoryPath 目录路径
   * @param options 列出选项
   */
  public async listDirectory(directoryPath: string, options: { recursive?: boolean; filter?: (name: string) => boolean } = {}): Promise<Array<{
    name: string;
    path: string;
    isDirectory: boolean;
    size?: number;
    modificationTime?: Date;
  }>> {
    try {
      this.logger.debug(`Listing directory: ${directoryPath}, recursive: ${options.recursive || false}`);
      // 在实际环境中，这里需要使用系统API来列出目录内容
      // 由于无法直接访问文件系统，返回模拟结果
      return [];
    } catch (error) {
      this.logger.error(`Failed to list directory: ${directoryPath}`, error as Error);
      return [];
    }
  }

  /**
   * 搜索文件
   * @param rootPath 搜索根路径
   * @param pattern 搜索模式
   * @param options 搜索选项
   */
  public async searchFiles(rootPath: string, pattern: string | RegExp, options: { recursive?: boolean; includeDirectories?: boolean } = {}): Promise<string[]> {
    try {
      this.logger.debug(`Searching files in ${rootPath}, pattern: ${pattern.toString()}`);
      // 在实际环境中，这里需要使用系统API来搜索文件
      // 由于无法直接访问文件系统，返回模拟结果
      return [];
    } catch (error) {
      this.logger.error(`Failed to search files in ${rootPath}`, error as Error);
      return [];
    }
  }

  /**
   * 计算文件哈希值
   * @param filePath 文件路径
   * @param algorithm 哈希算法（md5, sha1, sha256等）
   */
  public async calculateFileHash(filePath: string, algorithm: 'md5' | 'sha1' | 'sha256' = 'md5'): Promise<string> {
    try {
      this.logger.debug(`Calculating ${algorithm} hash for file: ${filePath}`);
      // 在实际环境中，这里需要实现文件哈希计算逻辑
      // 由于无法直接访问文件系统，返回模拟结果
      return `mock_${algorithm}_hash_for_${filePath}`;
    } catch (error) {
      this.logger.error(`Failed to calculate hash for file: ${filePath}`, error as Error);
      throw error;
    }
  }

  /**
   * 压缩文件或目录
   * @param sourcePath 源路径
   * @param destinationPath 目标路径
   * @param options 压缩选项
   */
  public async compress(sourcePath: string, destinationPath: string, options: { format?: 'zip' | 'tar' | 'gz'; level?: number } = {}): Promise<boolean> {
    try {
      this.logger.debug(`Compressing ${sourcePath} to ${destinationPath}`);
      // 在实际环境中，这里需要实现压缩逻辑
      // 由于无法直接访问文件系统，返回模拟结果
      return true;
    } catch (error) {
      this.logger.error(`Failed to compress ${sourcePath}`, error as Error);
      return false;
    }
  }

  /**
   * 解压文件
   * @param archivePath 压缩文件路径
   * @param destinationPath 目标路径
   * @param options 解压选项
   */
  public async decompress(archivePath: string, destinationPath: string, options: { overwrite?: boolean } = {}): Promise<boolean> {
    try {
      this.logger.debug(`Decompressing ${archivePath} to ${destinationPath}`);
      // 在实际环境中，这里需要实现解压逻辑
      // 由于无法直接访问文件系统，返回模拟结果
      return true;
    } catch (error) {
      this.logger.error(`Failed to decompress ${archivePath}`, error as Error);
      return false;
    }
  }

  /**
   * 获取文件MIME类型
   * @param fileName 文件名
   */
  public getMimeType(fileName: string): string {
    const extension = this.getFileExtension(fileName).toLowerCase();
    
    const mimeTypes: Record<string, string> = {
      // 视频类型
      'mp4': 'video/mp4',
      'mkv': 'video/x-matroska',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'flv': 'video/x-flv',
      'webm': 'video/webm',
      'm4v': 'video/x-m4v',
      
      // 音频类型
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'flac': 'audio/flac',
      'aac': 'audio/aac',
      'ogg': 'audio/ogg',
      'wma': 'audio/x-ms-wma',
      'm4a': 'audio/mp4',
      
      // 图片类型
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'tiff': 'image/tiff',
      
      // 文档类型
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'rtf': 'application/rtf',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      
      // 压缩文件类型
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'tar': 'application/x-tar',
      'gz': 'application/gzip',
      'bz2': 'application/x-bzip2',
      'xz': 'application/x-xz',
      
      // 字幕类型
      'srt': 'text/srt',
      'ass': 'text/x-ssa',
      'ssa': 'text/x-ssa',
      
      // 配置文件类型
      'json': 'application/json',
      'xml': 'application/xml',
      'yaml': 'application/x-yaml',
      'yml': 'application/x-yaml',
      'ini': 'text/plain',
      'conf': 'text/plain',
      'cfg': 'text/plain',
      'properties': 'text/plain',
      
      // 脚本类型
      'js': 'text/javascript',
      'ts': 'text/typescript',
      'jsx': 'text/jsx',
      'tsx': 'text/tsx',
      'html': 'text/html',
      'css': 'text/css',
      'scss': 'text/x-scss',
      'less': 'text/x-less',
    };
    
    return mimeTypes[extension] || 'application/octet-stream';
  }

  /**
   * 验证文件扩展名
   * @param fileName 文件名
   * @param allowedExtensions 允许的扩展名列表
   */
  public isValidFileExtension(fileName: string, allowedExtensions: string[]): boolean {
    const extension = this.getFileExtension(fileName).toLowerCase();
    const normalizedExtensions = allowedExtensions.map(ext => ext.toLowerCase().replace(/^\./, ''));
    return normalizedExtensions.includes(extension);
  }

  /**
   * 获取文件存储位置类型
   * @param path 文件路径
   */
  public getFileLocation(path: string): FileLocation {
    // 这里需要根据实际环境实现文件位置判断逻辑
    // 由于无法直接访问文件系统，返回模拟结果
    return FileLocation.INTERNAL_STORAGE;
  }

  /**
   * 获取文件访问权限
   * @param filePath 文件路径
   */
  public async getFilePermissions(filePath: string): Promise<{ read: boolean; write: boolean; execute: boolean }> {
    try {
      this.logger.debug(`Getting permissions for file: ${filePath}`);
      // 在实际环境中，这里需要使用系统API来获取文件权限
      // 由于无法直接访问文件系统，返回模拟结果
      return { read: true, write: true, execute: false };
    } catch (error) {
      this.logger.error(`Failed to get permissions for file: ${filePath}`, error as Error);
      return { read: false, write: false, execute: false };
    }
  }
}

// 导出默认实例
export default FileUtil.getInstance();