// NASConcurrentTest.ets - 多NAS设备并发管理测试
// 测试NAS设备的并发管理功能，包括设备添加、删除、状态监控等

import Logger from '../src/main/ets/common/util/Logger';
import NASDiscoveryService from '../src/main/ets/service/nas/NASDiscoveryService';
import NASFileService from '../src/main/ets/service/nas/NASFileService';
import NASIndexService from '../src/main/ets/service/nas/NASIndexService';
import { NASDevice, NASAuthConfig } from '../src/main/ets/service/nas/types/NASDeviceTypes';

class NASConcurrentTest {
  private logger: Logger = new Logger('NASConcurrentTest');
  private discoveryService: typeof NASDiscoveryService = NASDiscoveryService;
  private fileService: typeof NASFileService = NASFileService;
  private indexService: typeof NASIndexService = NASIndexService.getInstance();
  
  // 测试多设备并发添加
  public async testConcurrentDeviceAdd(): Promise<void> {
    this.logger.info('开始测试多设备并发添加...');
    
    try {
      // 模拟添加多个NAS设备
      const devicesToAdd = [
        {
          name: 'Test NAS 1',
          ip: '192.168.1.100',
          port: 445,
          protocol: 'smb' as const,
          authConfig: {
            enableAuth: false
          }
        },
        {
          name: 'Test NAS 2',
          ip: '192.168.1.101',
          port: 80,
          protocol: 'huawei' as const,
          authConfig: {
            enableAuth: true,
            username: 'admin',
            password: 'password'
          }
        },
        {
          name: 'Test NAS 3',
          ip: '192.168.1.102',
          port: 8080,
          protocol: 'webdav' as const,
          authConfig: {
            enableAuth: false
          }
        }
      ];
      
      // 并发添加设备
      const addPromises = devicesToAdd.map(async (device) => {
        try {
          const addedDevice = await this.discoveryService.addDeviceManually(
            device.name,
            device.ip,
            device.port,
            device.protocol,
            device.authConfig
          );
          this.logger.info(`成功添加设备: ${addedDevice.name} (${addedDevice.ip}:${addedDevice.port})`);
          return addedDevice;
        } catch (error) {
          this.logger.error(`添加设备失败: ${device.name}`, error instanceof Error ? error : new Error(String(error)));
          return null;
        }
      });
      
      const results = await Promise.all(addPromises);
      const successfulAdds = results.filter((device): device is NASDevice => device !== null);
      
      this.logger.info(`多设备并发添加测试完成，成功添加 ${successfulAdds.length} 个设备`);
      
    } catch (error) {
      this.logger.error('多设备并发添加测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试多设备并发状态更新
  public async testConcurrentStatusUpdate(): Promise<void> {
    this.logger.info('开始测试多设备并发状态更新...');
    
    try {
      const devices = this.discoveryService.getDiscoveredDevices();
      if (devices.length === 0) {
        this.logger.info('没有设备可测试，跳过状态更新测试');
        return;
      }
      
      // 并发测试设备连接
      const testResults = await this.discoveryService.testMultipleDevices(devices);
      
      let onlineCount = 0;
      let offlineCount = 0;
      
      testResults.forEach((isOnline, deviceId) => {
        if (isOnline) {
          onlineCount++;
        } else {
          offlineCount++;
        }
      });
      
      this.logger.info(`多设备并发状态更新测试完成，在线设备: ${onlineCount}, 离线设备: ${offlineCount}`);
      
    } catch (error) {
      this.logger.error('多设备并发状态更新测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试多设备并发目录浏览
  public async testConcurrentDirectoryBrowsing(): Promise<void> {
    this.logger.info('开始测试多设备并发目录浏览...');
    
    try {
      const devices = this.discoveryService.getDiscoveredDevices();
      if (devices.length === 0) {
        this.logger.info('没有设备可测试，跳过多设备并发目录浏览测试');
        return;
      }
      
      // 并发浏览每个设备的根目录
      const browsePromises = devices.map(async (device) => {
        try {
          const files = await this.fileService.listDirectory(device.id, '/');
          this.logger.info(`成功浏览设备 ${device.name} 的根目录，找到 ${files.length} 个文件/目录`);
          return { device: device.name, success: true, fileCount: files.length };
        } catch (error) {
          this.logger.error(`浏览设备 ${device.name} 失败`, error instanceof Error ? error : new Error(String(error)));
          return { device: device.name, success: false, fileCount: 0 };
        }
      });
      
      const results = await Promise.all(browsePromises);
      const successfulBrowses = results.filter(result => result.success);
      
      this.logger.info(`多设备并发目录浏览测试完成，成功浏览 ${successfulBrowses.length} 个设备`);
      
    } catch (error) {
      this.logger.error('多设备并发目录浏览测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试设备分组管理
  public testDeviceGrouping(): void {
    this.logger.info('开始测试设备分组管理...');
    
    try {
      const deviceGroups = this.discoveryService.getDeviceGroups();
      
      this.logger.info(`设备分组测试完成，共 ${deviceGroups.size} 个分组`);
      
      deviceGroups.forEach((devices, groupName) => {
        this.logger.info(`分组 ${groupName}: ${devices.length} 个设备`);
      });
      
    } catch (error) {
      this.logger.error('设备分组测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试设备优先级管理
  public testDevicePriority(): void {
    this.logger.info('开始测试设备优先级管理...');
    
    try {
      const devices = this.discoveryService.getDiscoveredDevices();
      if (devices.length === 0) {
        this.logger.info('没有设备可测试，跳过优先级管理测试');
        return;
      }
      
      // 设置不同的优先级
      devices.forEach((device, index) => {
        const priority = (index % 5) + 1; // 1-5的优先级
        this.discoveryService.setDevicePriority(device.id, priority);
        this.logger.info(`设置设备 ${device.name} 的优先级为 ${priority}`);
      });
      
      // 按优先级排序
      const prioritizedDevices = this.discoveryService.getDevicesByPriority();
      
      this.logger.info('按优先级排序的设备列表:');
      prioritizedDevices.forEach((device, index) => {
        this.logger.info(`${index + 1}. ${device.name} (优先级: ${device.priority || 1})`);
      });
      
      this.logger.info('设备优先级管理测试完成');
      
    } catch (error) {
      this.logger.error('设备优先级管理测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试设备删除
  public testDeviceRemoval(): void {
    this.logger.info('开始测试设备删除...');
    
    try {
      const devices = this.discoveryService.getDiscoveredDevices();
      if (devices.length === 0) {
        this.logger.info('没有设备可测试，跳过设备删除测试');
        return;
      }
      
      // 删除第一个设备
      const deviceToRemove = devices[0];
      const success = this.discoveryService.removeDevice(deviceToRemove.id);
      
      if (success) {
        this.logger.info(`成功删除设备: ${deviceToRemove.name}`);
      } else {
        this.logger.error(`删除设备失败: ${deviceToRemove.name}`);
      }
      
      const remainingDevices = this.discoveryService.getDiscoveredDevices();
      this.logger.info(`设备删除测试完成，剩余 ${remainingDevices.length} 个设备`);
      
    } catch (error) {
      this.logger.error('设备删除测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 运行所有测试
  public async runAllTests(): Promise<void> {
    this.logger.info('开始运行所有NAS并发管理测试...');
    
    await this.testConcurrentDeviceAdd();
    await this.testConcurrentStatusUpdate();
    await this.testConcurrentDirectoryBrowsing();
    this.testDeviceGrouping();
    this.testDevicePriority();
    this.testDeviceRemoval();
    
    this.logger.info('所有NAS并发管理测试完成');
  }
}

// 运行测试
const test = new NASConcurrentTest();
test.runAllTests().catch(error => {
  console.error('测试运行失败:', error);
});

export default NASConcurrentTest;
