import Ability from '@ohos.app.ability.Ability';
import Logger from '../common/util/Logger';

/**
 * 备份还原能力实现
 * 用于支持应用数据的备份和还原功能
 */
export default class RayTVBackupAbility extends Ability {
  private readonly TAG: string = 'RayTVBackupAbility';

  /**
   * 处理备份请求
   */
  onBackup(): boolean {
    try {
      // 使用正确的参数格式调用Logger
      Logger.info(`${this.TAG} onBackup`);
      return true;
    } catch (error) {
      // 简化错误处理，不传递Error对象
      Logger.error(`${this.TAG} onBackup failed: ${String(error)}`);
      return false;
    }
  }

  /**
   * 处理还原请求
   */
  onRestore(): boolean {
    try {
      // 使用正确的参数格式调用Logger
      Logger.info(`${this.TAG} onRestore`);
      return true;
    } catch (error) {
      // 简化错误处理，不传递Error对象
      Logger.error(`${this.TAG} onRestore failed: ${String(error)}`);
      return false;
    }
  }

  /**
   * 获取备份数据目录
   */
  getBackupDir(): string {
    try {
      return '';
    } catch (error) {
      // 简化错误处理，不传递Error对象
      Logger.error(`${this.TAG} getBackupDir failed: ${String(error)}`);
      return '';
    }
  }
}