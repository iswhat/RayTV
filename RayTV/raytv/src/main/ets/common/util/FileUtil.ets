// FileUtil - 文件操作工具类
import fs from '@ohos.file.fs';
import Logger from './Logger';

const TAG = 'FileUtil';

/**
 * 文件操作工具类
 * 提供文件的读写、创建、删除等基本操作
 */
export default class FileUtil {
  /**
   * 读取文件内容
   * @param filePath 文件路径
   * @returns 文件内容
   */
  public static async readFile(filePath: string): Promise<string> {
    try {
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const fileStat = await fs.stat(filePath);
      const buf = new ArrayBuffer(fileStat.size);
      await fs.read(file.fd, buf);
      await fs.close(file.fd);
      return String.fromCharCode(...new Uint8Array(buf));
    } catch (error) {
      Logger.error(TAG, `Failed to read file ${filePath}: ${error}`);
      throw error;
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
      await this.ensureDirExists(this.getParentPath(filePath));
      
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      const buf = new TextEncoder().encode(content);
      await fs.write(file.fd, buf.buffer);
      await fs.close(file.fd);
    } catch (error) {
      Logger.error(TAG, `Failed to write file ${filePath}: ${error}`);
      throw error;
    }
  }

  /**
   * 追加内容到文件
   * @param filePath 文件路径
   * @param content 追加内容
   */
  public static async appendFile(filePath: string, content: string): Promise<void> {
    try {
      // 确保目录存在
      await this.ensureDirExists(this.getParentPath(filePath));
      
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.APPEND);
      const buf = new TextEncoder().encode(content);
      await fs.write(file.fd, buf.buffer);
      await fs.close(file.fd);
    } catch (error) {
      Logger.error(TAG, `Failed to append file ${filePath}: ${error}`);
      throw error;
    }
  }

  /**
   * 删除文件
   * @param filePath 文件路径
   */
  public static async deleteFile(filePath: string): Promise<void> {
    try {
      if (await this.exists(filePath)) {
        await fs.unlink(filePath);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to delete file ${filePath}: ${error}`);
      throw error;
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
      Logger.error(TAG, `Failed to create directory ${dirPath}: ${error}`);
      throw error;
    }
  }

  /**
   * 确保目录存在，如果不存在则创建
   * @param dirPath 目录路径
   */
  public static async ensureDirExists(dirPath: string): Promise<void> {
    try {
      if (!(await this.exists(dirPath))) {
        await fs.mkdir(dirPath, 0o777, true);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to ensure directory exists ${dirPath}: ${error}`);
      throw error;
    }
  }

  /**
   * 判断文件或目录是否存在
   * @param path 路径
   * @returns 是否存在
   */
  public static async exists(path: string): Promise<boolean> {
    try {
      await fs.stat(path);
      return true;
    } catch (error) {
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
      Logger.error(TAG, `Failed to get file stat ${filePath}: ${error}`);
      throw error;
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
      Logger.error(TAG, `Failed to list files in directory ${dirPath}: ${error}`);
      throw error;
    }
  }

  /**
   * 复制文件
   * @param srcPath 源文件路径
   * @param destPath 目标文件路径
   */
  public static async copyFile(srcPath: string, destPath: string): Promise<void> {
    try {
      // 确保目标目录存在
      await this.ensureDirExists(this.getParentPath(destPath));
      await fs.copyFile(srcPath, destPath);
    } catch (error) {
      Logger.error(TAG, `Failed to copy file from ${srcPath} to ${destPath}: ${error}`);
      throw error;
    }
  }

  /**
   * 移动文件
   * @param srcPath 源文件路径
   * @param destPath 目标文件路径
   */
  public static async moveFile(srcPath: string, destPath: string): Promise<void> {
    try {
      // 确保目标目录存在
      await this.ensureDirExists(this.getParentPath(destPath));
      await fs.rename(srcPath, destPath);
    } catch (error) {
      Logger.error(TAG, `Failed to move file from ${srcPath} to ${destPath}: ${error}`);
      throw error;
    }
  }

  /**
   * 获取文件扩展名
   * @param filename 文件名
   * @returns 文件扩展名
   */
  public static getFileExtension(filename: string): string {
    const lastDotIndex = filename.lastIndexOf('.');
    return lastDotIndex > 0 ? filename.slice(lastDotIndex + 1).toLowerCase() : '';
  }

  /**
   * 获取文件名（不含扩展名）
   * @param filename 文件名
   * @returns 文件名（不含扩展名）
   */
  public static getFileNameWithoutExtension(filename: string): string {
    const lastDotIndex = filename.lastIndexOf('.');
    return lastDotIndex > 0 ? filename.slice(0, lastDotIndex) : filename;
  }

  /**
   * 获取父目录路径
   * @param path 文件或目录路径
   * @returns 父目录路径
   */
  public static getParentPath(path: string): string {
    const parts = path.split('/').filter(Boolean);
    parts.pop();
    return parts.length > 0 ? parts.join('/') : '/';
  }

  /**
   * 获取文件名
   * @param path 文件路径
   * @returns 文件名
   */
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
      if (!(await this.exists(dirPath))) {
        return;
      }
      
      const files = await this.listFiles(dirPath);
      for (const file of files) {
        const filePath = `${dirPath}/${file}`;
        const stat = await this.getFileStat(filePath);
        if (stat.isDirectory()) {
          await this.clearDirectory(filePath);
          await fs.rmdir(filePath);
        } else {
          await fs.unlink(filePath);
        }
      }
    } catch (error) {
      Logger.error(TAG, `Failed to clear directory ${dirPath}: ${error}`);
      throw error;
    }
  }
}