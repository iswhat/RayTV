// NASProtocolTest.ets - 不同协议连接测试
// 测试各种NAS设备协议的连接和操作功能

import Logger from '../src/main/ets/common/util/Logger';
import NASDiscoveryService from '../src/main/ets/service/nas/NASDiscoveryService';
import NASFileService from '../src/main/ets/service/nas/NASFileService';
import { NASDevice, NASAuthConfig } from '../src/main/ets/service/nas/types/NASDeviceTypes';

class NASProtocolTest {
  private logger: Logger = new Logger('NASProtocolTest');
  private discoveryService: typeof NASDiscoveryService = NASDiscoveryService;
  private fileService: typeof NASFileService = NASFileService;
  
  // 测试SMB协议
  public async testSMBProtocol(): Promise<void> {
    this.logger.info('开始测试SMB协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test SMB NAS',
        '192.168.1.100',
        445,
        'smb',
        {
          enableAuth: false
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`SMB协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`SMB视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('SMB协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试华为HiLink协议
  public async testHuaweiProtocol(): Promise<void> {
    this.logger.info('开始测试华为HiLink协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test Huawei NAS',
        '192.168.1.101',
        80,
        'huawei',
        {
          enableAuth: true,
          username: 'admin',
          password: 'password'
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`华为HiLink协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`华为视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('华为HiLink协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试WebDAV协议
  public async testWebDAVProtocol(): Promise<void> {
    this.logger.info('开始测试WebDAV协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test WebDAV NAS',
        '192.168.1.102',
        8080,
        'webdav',
        {
          enableAuth: false
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`WebDAV协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`WebDAV视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('WebDAV协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试HTTP协议
  public async testHTTPProtocol(): Promise<void> {
    this.logger.info('开始测试HTTP协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test HTTP NAS',
        '192.168.1.103',
        80,
        'http',
        {
          enableAuth: false
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`HTTP协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`HTTP视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('HTTP协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试极空间ZSpace协议
  public async testZSpaceProtocol(): Promise<void> {
    this.logger.info('开始测试极空间ZSpace协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test ZSpace NAS',
        '192.168.1.104',
        80,
        'zspace',
        {
          enableAuth: true,
          username: 'admin',
          password: 'password'
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`极空间ZSpace协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`极空间视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('极空间ZSpace协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试小米Mi Home协议
  public async testMiHomeProtocol(): Promise<void> {
    this.logger.info('开始测试小米Mi Home协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test Mi Home NAS',
        '192.168.1.105',
        80,
        'mihome',
        {
          enableAuth: true,
          username: 'admin',
          password: 'password'
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`小米Mi Home协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`小米视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('小米Mi Home协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试群晖Synology协议
  public async testSynologyProtocol(): Promise<void> {
    this.logger.info('开始测试群晖Synology协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test Synology NAS',
        '192.168.1.106',
        5000,
        'synology',
        {
          enableAuth: true,
          username: 'admin',
          password: 'password'
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`群晖Synology协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`群晖视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('群晖Synology协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试绿联UGreen协议
  public async testUGreenProtocol(): Promise<void> {
    this.logger.info('开始测试绿联UGreen协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test UGreen NAS',
        '192.168.1.107',
        80,
        'ugreen',
        {
          enableAuth: true,
          username: 'admin',
          password: 'password'
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`绿联UGreen协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`绿联视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('绿联UGreen协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 测试威联通QNAP协议
  public async testQNAPProtocol(): Promise<void> {
    this.logger.info('开始测试威联通QNAP协议...');
    
    try {
      const device = await this.discoveryService.addDeviceManually(
        'Test QNAP NAS',
        '192.168.1.108',
        8080,
        'qnap',
        {
          enableAuth: true,
          username: 'admin',
          password: 'password'
        }
      );
      
      // 测试目录浏览
      const files = await this.fileService.listDirectory(device.id, '/');
      this.logger.info(`威联通QNAP协议测试完成，浏览根目录找到 ${files.length} 个文件/目录`);
      
      // 测试获取文件URL（用于播放）
      if (files.length > 0) {
        const file = files.find(f => f.type === 'file' && f.isVideo);
        if (file) {
          const fileUrl = this.fileService.getFileUrl(device.id, file.path);
          this.logger.info(`威联通视频文件播放URL: ${fileUrl}`);
        }
      }
      
    } catch (error) {
      this.logger.error('威联通QNAP协议测试失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  // 运行所有协议测试
  public async runAllProtocolTests(): Promise<void> {
    this.logger.info('开始运行所有NAS协议测试...');
    
    await this.testSMBProtocol();
    await this.testHuaweiProtocol();
    await this.testWebDAVProtocol();
    await this.testHTTPProtocol();
    await this.testZSpaceProtocol();
    await this.testMiHomeProtocol();
    await this.testSynologyProtocol();
    await this.testUGreenProtocol();
    await this.testQNAPProtocol();
    
    this.logger.info('所有NAS协议测试完成');
  }
}

// 运行测试
const test = new NASProtocolTest();
test.runAllProtocolTests().catch(error => {
  console.error('协议测试运行失败:', error);
});

export default NASProtocolTest;
