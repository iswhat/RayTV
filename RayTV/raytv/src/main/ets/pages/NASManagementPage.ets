// NASManagementPage.ets - NAS设备管理页面
// 负责NAS设备的管理、添加、删除和状态监控

import router from '@ohos.router';
import { NASDevice, NASAuthConfig } from '../service/nas/types/NASDeviceTypes';
import NASDiscoveryService from '../service/nas/NASDiscoveryService';
import NASFileService from '../service/nas/NASFileService';
import NASIndexService from '../service/nas/NASIndexService';
import Logger from '../common/util/Logger';

@Entry
@Component
struct NASManagementPage {
  private logger: Logger = new Logger('NASManagementPage');
  private discoveryService: typeof NASDiscoveryService = NASDiscoveryService;
  private fileService: typeof NASFileService = NASFileService;
  private indexService: typeof NASIndexService = NASIndexService.getInstance();
  
  @State devices: NASDevice[] = [];
  @State filteredDevices: NASDevice[] = [];
  @State isScanning: boolean = false;
  @State showAddDialog: boolean = false;
  @State showFilterDialog: boolean = false;
  @State newDevice: {
    name: string;
    ip: string;
    port: string;
    protocol: string;
    username: string;
    password: string;
  } = {
    name: '',
    ip: '',
    port: '80',
    protocol: 'smb',
    username: '',
    password: ''
  };
  @State protocols: string[] = ['smb', 'huawei', 'webdav', 'http', 'zspace', 'mihome', 'synology', 'ugreen', 'qnap'];
  @State filter: {
    protocol: string;
    status: string;
    manufacturer: string;
    sortBy: string;
  } = {
    protocol: 'all',
    status: 'all',
    manufacturer: 'all',
    sortBy: 'name'
  };
  @State manufacturers: string[] = ['all'];
  
  aboutToAppear() {
    this.loadDevices();
  }
  
  loadDevices() {
    this.devices = this.discoveryService.getDiscoveredDevices();
    this.updateManufacturers();
    this.applyFilters();
  }
  
  updateManufacturers() {
    const uniqueManufacturers = new Set<string>();
    this.devices.forEach(device => {
      if (device.manufacturer) {
        uniqueManufacturers.add(device.manufacturer);
      }
    });
    this.manufacturers = ['all', ...Array.from(uniqueManufacturers)];
  }
  
  applyFilters() {
    let filtered = [...this.devices];
    
    // 按协议筛选
    if (this.filter.protocol !== 'all') {
      filtered = filtered.filter(device => device.protocol === this.filter.protocol);
    }
    
    // 按状态筛选
    if (this.filter.status !== 'all') {
      filtered = filtered.filter(device => {
        if (this.filter.status === 'online') return device.isOnline;
        if (this.filter.status === 'offline') return !device.isOnline;
        return true;
      });
    }
    
    // 按制造商筛选
    if (this.filter.manufacturer !== 'all') {
      filtered = filtered.filter(device => device.manufacturer === this.filter.manufacturer);
    }
    
    // 排序
    filtered = this.sortDevices(filtered, this.filter.sortBy);
    
    this.filteredDevices = filtered;
  }
  
  sortDevices(devices: NASDevice[], sortBy: string): NASDevice[] {
    return devices.sort((a, b) => {
      switch (sortBy) {
        case 'name':
          return a.name.localeCompare(b.name);
        case 'ip':
          return a.ip.localeCompare(b.ip);
        case 'status':
          return (b.isOnline ? 1 : 0) - (a.isOnline ? 1 : 0);
        case 'protocol':
          return a.protocol.localeCompare(b.protocol);
        default:
          return 0;
      }
    });
  }
  
  async startScan() {
    this.isScanning = true;
    try {
      await this.discoveryService.discoverAllDevices();
      this.loadDevices();
    } catch (error) {
      this.logger.error('扫描设备失败', error instanceof Error ? error : new Error(String(error)));
    } finally {
      this.isScanning = false;
    }
  }
  
  resetFilters() {
    this.filter = {
      protocol: 'all',
      status: 'all',
      manufacturer: 'all',
      sortBy: 'name'
    };
    this.applyFilters();
  }
  
  async addDevice() {
    if (!this.newDevice.name || !this.newDevice.ip || !this.newDevice.port) {
      return;
    }
    
    try {
      const authConfig: NASAuthConfig | undefined = this.newDevice.username || this.newDevice.password
        ? {
            enableAuth: true,
            username: this.newDevice.username,
            password: this.newDevice.password
          }
        : undefined;
      
      await this.discoveryService.addDeviceManually(
        this.newDevice.name,
        this.newDevice.ip,
        parseInt(this.newDevice.port),
        this.newDevice.protocol,
        authConfig
      );
      
      this.loadDevices();
      this.showAddDialog = false;
      this.resetNewDevice();
    } catch (error) {
      this.logger.error('添加设备失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  resetNewDevice() {
    this.newDevice = {
      name: '',
      ip: '',
      port: '80',
      protocol: 'smb',
      username: '',
      password: ''
    };
  }
  
  removeDevice(deviceId: string) {
    this.discoveryService.removeDevice(deviceId);
    this.loadDevices();
  }
  
  navigateToDirectory(device: NASDevice) {
    router.push({
      url: '/pages/NASDirectoryBrowser',
      params: { deviceId: device.id, deviceName: device.name }
    });
  }
  
  renderDeviceItem(device: NASDevice) {
    return (
      <ListItem key={device.id} onClick={() => this.navigateToDirectory(device)}>
        <Row style={{ width: '100%', alignItems: 'center' }}>
          <Column style={{ flex: 1 }}>
            <Text style={{ fontSize: 18, fontWeight: 'bold' }}>{device.name}</Text>
            <Text style={{ fontSize: 14, color: '#666' }}>
              {device.ip}:{device.port} ({device.protocol})
            </Text>
            <Text style={{ fontSize: 12, color: device.isOnline ? '#00C853' : '#FF5722' }}>
              {device.isOnline ? '在线' : '离线'}
            </Text>
          </Column>
          <Button 
            type="circle" 
            icon="delete" 
            onClick={(e) => {
              e.stopPropagation();
              this.removeDevice(device.id);
            }}
          />
        </Row>
      </ListItem>
    );
  }
  
  build() {
    return (
      <Page>
        <NavigationBar title="NAS设备管理" />
        
        <ScrollView style={{ flex: 1 }}>
          <Stack style={{ padding: 20 }}>
            <Column style={{ width: '100%' }}>
              <Row style={{ justifyContent: 'space-between', marginBottom: 20 }}>
                <Button 
                  type="capsule" 
                  label={this.isScanning ? '扫描中...' : '扫描设备'}
                  onClick={() => this.startScan()}
                  disabled={this.isScanning}
                />
                <Row>
                  <Button 
                    type="capsule" 
                    label="筛选"
                    onClick={() => this.showFilterDialog = true}
                    style={{ marginRight: 10 }}
                  />
                  <Button 
                    type="capsule" 
                    label="添加设备"
                    onClick={() => this.showAddDialog = true}
                  />
                </Row>
              </Row>
              
              <List style={{ width: '100%' }}>
                {this.filteredDevices.length > 0 ? (
                  this.filteredDevices.map(device => this.renderDeviceItem(device))
                ) : (
                  <ListItem>
                    <Text style={{ textAlign: 'center', width: '100%', color: '#666' }}>
                      暂无NAS设备，请点击"扫描设备"或"添加设备"
                    </Text>
                  </ListItem>
                )}
              </List>
            </Column>
          </Stack>
        </ScrollView>
        
        {/* 添加设备对话框 */}
        {this.showAddDialog && (
          <Dialog
            show={this.showAddDialog}
            title="添加NAS设备"
            onCancel={() => this.showAddDialog = false}
            onConfirm={() => this.addDevice()}
          >
            <Column style={{ padding: 20 }}>
              <TextInput
                placeholder="设备名称"
                value={this.newDevice.name}
                onChange={(value) => this.newDevice.name = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              <TextInput
                placeholder="IP地址"
                value={this.newDevice.ip}
                onChange={(value) => this.newDevice.ip = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              <TextInput
                placeholder="端口"
                value={this.newDevice.port}
                onChange={(value) => this.newDevice.port = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              <Select
                value={this.newDevice.protocol}
                options={this.protocols}
                onChange={(value) => this.newDevice.protocol = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              <TextInput
                placeholder="用户名（可选）"
                value={this.newDevice.username}
                onChange={(value) => this.newDevice.username = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              <TextInput
                placeholder="密码（可选）"
                value={this.newDevice.password}
                onChange={(value) => this.newDevice.password = value}
                style={{ marginBottom: 15, width: '100%' }}
                password
              />
            </Column>
          </Dialog>
        )}
        
        {/* 筛选对话框 */}
        {this.showFilterDialog && (
          <Dialog
            show={this.showFilterDialog}
            title="筛选设备"
            onCancel={() => this.showFilterDialog = false}
            onConfirm={() => {
              this.applyFilters();
              this.showFilterDialog = false;
            }}
          >
            <Column style={{ padding: 20 }}>
              <Text style={{ marginBottom: 10 }}>协议</Text>
              <Select
                value={this.filter.protocol}
                options={['all', ...this.protocols]}
                onChange={(value) => this.filter.protocol = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              
              <Text style={{ marginBottom: 10 }}>状态</Text>
              <Select
                value={this.filter.status}
                options={['all', 'online', 'offline']}
                onChange={(value) => this.filter.status = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              
              <Text style={{ marginBottom: 10 }}>制造商</Text>
              <Select
                value={this.filter.manufacturer}
                options={this.manufacturers}
                onChange={(value) => this.filter.manufacturer = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              
              <Text style={{ marginBottom: 10 }}>排序</Text>
              <Select
                value={this.filter.sortBy}
                options={['name', 'ip', 'status', 'protocol']}
                onChange={(value) => this.filter.sortBy = value}
                style={{ marginBottom: 15, width: '100%' }}
              />
              
              <Button
                type="capsule"
                label="重置筛选"
                onClick={() => this.resetFilters()}
                style={{ width: '100%' }}
              />
            </Column>
          </Dialog>
        )}
      </Page>
    );
  }
}

// 导航栏组件
@Component
struct NavigationBar {
  private title: string;
  
  constructor(title: string) {
    this.title = title;
  }
  
  build() {
    return (
      <Row style={{ 
        height: 56, 
        alignItems: 'center', 
        justifyContent: 'center',
        backgroundColor: '#f5f5f5',
        borderBottomWidth: 1,
        borderBottomColor: '#e0e0e0'
      }}>
        <Button 
          type="circle" 
          icon="back"
          onClick={() => router.back()}
          style={{ position: 'absolute', left: 16 }}
        />
        <Text style={{ fontSize: 18, fontWeight: 'bold' }}>{this.title}</Text>
      </Row>
    );
  }
}
