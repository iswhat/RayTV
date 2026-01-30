/**
 * 文件工具类 | File utility class
 * 提供文件操作相关的工具函数 | Provides file operation utility functions
 */

/**
 * 文件工具类 | File utility class
 */
export default class FileUtil {
  private static readonly TAG: string = 'FileUtil';

  /**
   * 获取文件扩展名 | Gets file extension
   * @param fileName 文件名 | File name
   * @returns 文件扩展名 | File extension
   */
  public static getFileExtension(fileName: string): string {
    if (!fileName) {
      return '';
    }
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return '';
    }
    return fileName.substring(lastDotIndex + 1).toLowerCase();
  }

  /**
   * 获取文件名（不含扩展名） | Gets file name without extension
   * @param fileName 文件名 | File name
   * @returns 文件名（不含扩展名） | File name without extension
   */
  public static getFileNameWithoutExtension(fileName: string): string {
    if (!fileName) {
      return '';
    }
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return fileName;
    }
    return fileName.substring(0, lastDotIndex);
  }

  /**
   * 获取文件大小的可读格式 | Gets readable file size
   * @param bytes 文件大小（字节） | File size in bytes
   * @returns 可读的文件大小 | Readable file size
   */
  public static getReadableFileSize(bytes: number): string {
    if (bytes === 0) {
      return '0 B';
    }

    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * 检查文件是否为图片 | Checks if file is image
   * @param fileName 文件名 | File name
   * @returns 是否为图片 | Is image
   */
  public static isImageFile(fileName: string): boolean {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    const ext = FileUtil.getFileExtension(fileName);
    return imageExtensions.includes(ext);
  }

  /**
   * 检查文件是否为视频 | Checks if file is video
   * @param fileName 文件名 | File name
   * @returns 是否为视频 | Is video
   */
  public static isVideoFile(fileName: string): boolean {
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm', 'm4v'];
    const ext = FileUtil.getFileExtension(fileName);
    return videoExtensions.includes(ext);
  }

  /**
   * 检查文件是否为音频 | Checks if file is audio
   * @param fileName 文件名 | File name
   * @returns 是否为音频 | Is audio
   */
  public static isAudioFile(fileName: string): boolean {
    const audioExtensions = ['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma'];
    const ext = FileUtil.getFileExtension(fileName);
    return audioExtensions.includes(ext);
  }

  /**
   * 检查文件是否为文本 | Checks if file is text
   * @param fileName 文件名 | File name
   * @returns 是否为文本 | Is text
   */
  public static isTextFile(fileName: string): boolean {
    const textExtensions = ['txt', 'md', 'json', 'xml', 'html', 'css', 'js', 'ts', 'ets'];
    const ext = FileUtil.getFileExtension(fileName);
    return textExtensions.includes(ext);
  }

  /**
   * 生成唯一文件名 | Generates unique file name
   * @param originalName 原始文件名 | Original file name
   * @returns 唯一文件名 | Unique file name
   */
  public static generateUniqueFileName(originalName: string): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 1000);
    const ext = FileUtil.getFileExtension(originalName);
    const baseName = FileUtil.getFileNameWithoutExtension(originalName);
    return baseName + '_' + timestamp + '_' + random + (ext ? '.' + ext : '');
  }

  /**
   * 清理文件名（移除特殊字符） | Cleans file name (removes special characters)
   * @param fileName 文件名 | File name
   * @returns 清理后的文件名 | Cleaned file name
   */
  public static cleanFileName(fileName: string): string {
    if (!fileName) {
      return '';
    }
    // 移除特殊字符，只保留字母、数字、下划线、中划线和点 | Remove special characters, keep only letters, numbers, underscores, hyphens and dots
    return fileName.replace(/[^a-zA-Z0-9_一-龥.-]/g, '_');
  }

  /**
   * 规范化路径 | Normalizes path
   * @param path 文件路径 | File path
   * @returns 规范化后的路径 | Normalized path
   */
  public static normalizePath(path: string): string {
    if (!path) {
      return '';
    }
    // 将反斜杠替换为正斜杠，移除重复斜杠 | Replace backslashes with forward slashes, remove duplicate slashes
    return path.replace(/[\\]/g, '/').replace(/\/+/g, '/');
  }

  /**
   * 获取路径中的文件名 | Gets file name from path
   * @param path 文件路径 | File path
   * @returns 文件名 | File name
   */
  public static getFileNameFromPath(path: string): string {
    if (!path) {
      return '';
    }
    const normalizedPath = FileUtil.normalizePath(path);
    const lastSlashIndex = normalizedPath.lastIndexOf('/');
    if (lastSlashIndex === -1) {
      return normalizedPath;
    }
    return normalizedPath.substring(lastSlashIndex + 1);
  }

  /**
   * 获取路径中的目录名 | Gets directory name from path
   * @param path 文件路径 | File path
   * @returns 目录名 | Directory name
   */
  public static getDirectoryFromPath(path: string): string {
    if (!path) {
      return '';
    }
    const normalizedPath = FileUtil.normalizePath(path);
    const lastSlashIndex = normalizedPath.lastIndexOf('/');
    if (lastSlashIndex === -1) {
      return '.';
    }
    return normalizedPath.substring(0, lastSlashIndex);
  }
}
