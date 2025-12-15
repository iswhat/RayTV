// FileUtil - 文件操作工具
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import Logger from './Logger';
import UIAbilityContext from '@ohos.app.ability.UIAbilityContext';
import JsonUtil, { safeStringify } from './JsonUtil';

const TAG = 'FileUtil';

/**
 * 文件操作工具�? * 提供文件的读写、创建、删除等基本操作
 */
export default class FileUtil {
  /**
   * 读取文件内容
   * @param filePath 文件路径
   * @returns 文件内容字符�?   */
  public static async readFile(filePath: string): Promise<string> {
    try {
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const fileInfo = await fs.stat(filePath);
      const buffer = new ArrayBuffer(fileInfo.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);
      // 修复any类型问题，使用显式的类型转换
      const uint8Array = new Uint8Array(buffer);
      let result = '';
      for (let i = 0; i < uint8Array.length; i++) {
        result += String.fromCharCode(uint8Array[i]);
      }
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to read file: ${filePath}, error: ${errorMessage}`);
      throw new Error(`Failed to read file: ${filePath}. ${errorMessage}`);
    }
  }

  /**
   * 写入文件内容
   * @param filePath 文件路径
   * @param content 文件内容
   */
  public static async writeFile(filePath: string, content: string): Promise<void> {
    try {
      // 确保目录存在
      await FileUtil.ensureDirExists(filePath.substring(0, filePath.lastIndexOf('/')));
      
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNCATE);
      // 修复any类型问题，使用显式的类型转换
      const buffer = new ArrayBuffer(content.length);
      const view = new Uint8Array(buffer);
      for (let i = 0; i < content.length; i++) {
        view[i] = content.charCodeAt(i);
      }
      await fs.write(file.fd, buffer);
      await fs.close(file.fd);
      Logger.getInstance().info(`${TAG} - File written successfully: ${filePath}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to write file: ${filePath}, error: ${errorMessage}`);
      throw new Error(`Failed to write file: ${filePath}. ${errorMessage}`);
    }
  }

  /**
   * 追加内容到文�?   * @param filePath 文件路径
   * @param content 追加的内�?   */
  public static async appendFile(filePath: string, content: string): Promise<void> {
    try {
      // 确保目录存在
      await FileUtil.ensureDirExists(filePath.substring(0, filePath.lastIndexOf('/')));
      
      // 检查文件是否存在，如果不存在则创建
      if (!(await FileUtil.exists(filePath))) {
        await FileUtil.writeFile(filePath, content);
        return;
      }
      
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE);
      await fs.seek(file.fd, { offset: 0, whence: fs.SeekMode.SEEK_END });
      // 将字符串转换为ArrayBuffer
      const buffer = new ArrayBuffer(content.length);
      const view = new Uint8Array(buffer);
      for (let i = 0; i < content.length; i++) {
        view[i] = content.charCodeAt(i);
      }
      await fs.write(file.fd, buffer);
      await fs.close(file.fd);
      Logger.getInstance().info(`${TAG} - Content appended to file: ${filePath}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to append to file: ${filePath}, error: ${errorMessage}`);
      throw new Error(`Failed to append to file: ${filePath}. ${errorMessage}`);
    }
  }

  /**
   * 删除文件
   * @param filePath 文件路径
   */
  public static async deleteFile(filePath: string): Promise<void> {
    try {
      if (await FileUtil.exists(filePath)) {
        await fs.unlink(filePath);
        Logger.getInstance().info(`${TAG} - File deleted successfully: ${filePath}`);
      } else {
        Logger.getInstance().warn(`${TAG} - File not found: ${filePath}`);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to delete file: ${filePath}, error: ${errorMessage}`);
      throw new Error(`Failed to delete file: ${filePath}. ${errorMessage}`);
    }
  }

  /**
   * 创建目录
   * @param dirPath 目录路径
   */
  public static async mkdir(dirPath: string): Promise<void> {
    try {
      await fs.mkdir(dirPath, 0o777);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to create directory ${dirPath}: ${errorMessage}`);
      throw new Error(`Failed to create directory ${dirPath}: ${errorMessage}`);
    }
  }

  /**
   * 确保目录存在，如果不存在则创�?   * @param dirPath 目录路径
   */
  public static async ensureDirExists(dirPath: string): Promise<void> {
    try {
      await fs.mkdir(dirPath, 0o777, true);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to ensure directory exists ${dirPath}: ${errorMessage}`);
      throw new Error(`Failed to ensure directory exists ${dirPath}: ${errorMessage}`);
    }
  }

  /**
   * 判断文件或目录是否存�?   * @param path 路径
   * @returns 是否存在
   */
  public static async exists(path: string): Promise<boolean> {
    try {
      await fs.stat(path);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 获取文件信息
   * @param filePath 文件路径
   * @returns 文件信息
   */
  public static async getFileStat(filePath: string): Promise<fs.Stat> {
    try {
      return await fs.stat(filePath);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to get file stat ${filePath}: ${errorMessage}`);
      throw new Error(`Failed to get file stat ${filePath}: ${errorMessage}`);
    }
  }

  /**
   * 列出目录下的文件
   * @param dirPath 目录路径
   * @returns 文件列表
   */
  public static async listFiles(dirPath: string): Promise<string[]> {
    try {
      return await fs.listDir(dirPath);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to list files in directory ${dirPath}: ${errorMessage}`);
      throw new Error(`Failed to list files in directory ${dirPath}: ${errorMessage}`);
    }
  }

  /**
   * 复制文件
   * @param srcPath 源文件路�?   * @param destPath 目标文件路径
   */
  public static async copyFile(srcPath: string, destPath: string): Promise<void> {
    try {
      // 确保目标目录存在
      await FileUtil.ensureDirExists(FileUtil.getParentPath(destPath));
      await fs.copyFile(srcPath, destPath);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to copy file from ${srcPath} to ${destPath}: ${errorMessage}`);
      throw new Error(`Failed to copy file from ${srcPath} to ${destPath}: ${errorMessage}`);
    }
  }

  /**
   * 移动文件
   * @param srcPath 源文件路�?   * @param destPath 目标文件路径
   */
  public static async moveFile(srcPath: string, destPath: string): Promise<void> {
    try {
      // 确保目标目录存在
      await FileUtil.ensureDirExists(FileUtil.getParentPath(destPath));
      await fs.rename(srcPath, destPath);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to move file from ${srcPath} to ${destPath}: ${errorMessage}`);
      throw new Error(`Failed to move file from ${srcPath} to ${destPath}: ${errorMessage}`);
    }
  }

  /**
   * 获取文件扩展�?   * @param filename 文件�?   * @returns 文件扩展�?   */
  public static getFileExtension(filename: string): string {
    const lastDotIndex = filename.lastIndexOf('.');
    return lastDotIndex > 0 ? filename.slice(lastDotIndex + 1).toLowerCase() : '';
  }

  /**
   * 获取文件名（不含扩展名）
   * @param filename 文件�?   * @returns 文件名（不含扩展名）
   */
  public static getFileNameWithoutExtension(filename: string): string {
    const lastDotIndex = filename.lastIndexOf('.');
    return lastDotIndex > 0 ? filename.slice(0, lastDotIndex) : filename;
  }

  /**
   * 获取父目录路�?   * @param path 文件或目录路�?   * @returns 父目录路�?   */
  public static getParentPath(path: string): string {
    const parts = path.split('/').filter(Boolean);
    parts.pop();
    return parts.length > 0 ? parts.join('/') : '/';
  }

  /**
   * 获取文件�?   * @param path 文件路径
   * @returns 文件�?   */
  public static getFileName(path: string): string {
    const parts = path.split('/').filter(Boolean);
    return parts.length > 0 ? parts[parts.length - 1] : '';
  }

  /**
   * 清空目录内容
   * @param dirPath 目录路径
   */
  public static async clearDirectory(dirPath: string): Promise<void> {
    try {
      if (!(await FileUtil.exists(dirPath))) {
        return;
      }
      
      const files = await FileUtil.listFiles(dirPath);
      for (const file of files) {
        const filePath = `${dirPath}/${file}`;
        const stat = await FileUtil.getFileStat(filePath);
        if (stat.isDirectory()) {
          await FileUtil.clearDirectory(filePath);
          await fs.rmdir(filePath);
        } else {
          await fs.unlink(filePath);
        }
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to clear directory ${dirPath}: ${errorMessage}`);
      throw new Error(`Failed to clear directory ${dirPath}: ${errorMessage}`);
    }
  }

  /**
   * 获取应用程序数据目录
   * @returns 应用程序数据目录路径
   */
  public static async getApplicationDataDir(): Promise<string> {
    try {
      // 使用新的API方式获取应用上下�?      // 获取应用程序上下�?      const context = common.getApplicationContext() as UIAbilityContext;
      return context.filesDir;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to get application data directory: ${errorMessage}`);
      // 如果获取失败，返回一个默认路�?      return '/data/app/';
    }
  }

  /**
   * 检查文件是否存�?   * @param filePath 文件路径
   * @returns 文件是否存在
   */
  public static async isFileExists(filePath: string): Promise<boolean> {
    return await FileUtil.exists(filePath);
  }
}
