// NASDirectoryBrowser.ets - NAS目录浏览页面
// 负责浏览NAS设备的目录结构和文件列表

import router from '@ohos.router';
import { NASFileItem } from '../service/nas/types/NASDeviceTypes';
import NASFileService from '../service/nas/NASFileService';
import NASIndexService from '../service/nas/NASIndexService';
import Logger from '../common/util/Logger';

@Entry
@Component
struct NASDirectoryBrowser {
  private logger: Logger = new Logger('NASDirectoryBrowser');
  private fileService: typeof NASFileService = NASFileService;
  private indexService: typeof NASIndexService = NASIndexService.getInstance();
  
  @State deviceId: string = router.getParams()?.deviceId || '';
  @State deviceName: string = router.getParams()?.deviceName || 'NAS设备';
  @State currentPath: string = '/';
  @State files: NASFileItem[] = [];
  @State isLoading: boolean = false;
  @State showIndexDialog: boolean = false;
  @State indexProgress: number = 0;
  
  aboutToAppear() {
    this.loadDirectory('/');
  }
  
  async loadDirectory(path: string) {
    this.isLoading = true;
    try {
      this.files = await this.fileService.listDirectory(this.deviceId, path, {
        filterByType: 'all',
        sortBy: 'name',
        sortOrder: 'asc'
      });
      this.currentPath = path;
    } catch (error) {
      this.logger.error('加载目录失败', error instanceof Error ? error : new Error(String(error)));
    } finally {
      this.isLoading = false;
    }
  }
  
  navigateToParent() {
    const parentPath = this.fileService.getParentPath(this.currentPath);
    if (parentPath !== this.currentPath) {
      this.loadDirectory(parentPath);
    }
  }
  
  navigateToDirectory(path: string) {
    this.loadDirectory(path);
  }
  
  playFile(file: NASFileItem) {
    // 获取文件播放URL
    const fileUrl = this.fileService.getFileUrl(this.deviceId, file.path);
    
    // 跳转到播放页面
    router.push({
      url: '/pages/PlaybackPage',
      params: {
        url: fileUrl,
        title: file.name,
        type: 'video'
      }
    });
  }
  
  async startIndexing() {
    this.showIndexDialog = true;
    this.indexProgress = 0;
    
    try {
      // 这里需要实现索引进度监听
      // 暂时模拟索引过程
      for (let i = 0; i <= 100; i += 10) {
        this.indexProgress = i;
        await new Promise(resolve => setTimeout(resolve, 500));
      }
      
      // 完成索引
      this.showIndexDialog = false;
    } catch (error) {
      this.logger.error('索引失败', error instanceof Error ? error : new Error(String(error)));
      this.showIndexDialog = false;
    }
  }
  
  renderFileItem(file: NASFileItem) {
    return (
      <ListItem 
        key={file.id} 
        onClick={() => file.type === 'directory' ? this.navigateToDirectory(file.path) : this.playFile(file)}
      >
        <Row style={{ width: '100%', alignItems: 'center' }}>
          <Image 
            src={file.type === 'directory' ? 'folder' : 'video'} 
            style={{ width: 48, height: 48, marginRight: 16 }}
          />
          <Column style={{ flex: 1 }}>
            <Text style={{ fontSize: 16, fontWeight: '500' }}>{file.name}</Text>
            {file.type === 'file' && (
              <Text style={{ fontSize: 12, color: '#666' }}>
                {this.formatFileSize(file.size || 0)} · {file.mimeType || '未知类型'}
              </Text>
            )}
          </Column>
          {file.type === 'file' && file.isVideo && (
            <Button 
              type="circle" 
              icon="play"
              onClick={(e) => {
                e.stopPropagation();
                this.playFile(file);
              }}
            />
          )}
        </Row>
      </ListItem>
    );
  }
  
  formatFileSize(size: number): string {
    if (size < 1024) return size + ' B';
    if (size < 1024 * 1024) return (size / 1024).toFixed(2) + ' KB';
    if (size < 1024 * 1024 * 1024) return (size / (1024 * 1024)).toFixed(2) + ' MB';
    return (size / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
  }
  
  build() {
    return (
      <Page>
        <NavigationBar 
          title={this.deviceName}
          onBack={() => router.back()}
          showIndexButton={true}
          onIndex={() => this.startIndexing()}
        />
        
        <ScrollView style={{ flex: 1 }}>
          <Stack style={{ padding: 20 }}>
            <Column style={{ width: '100%' }}>
              {/* 路径导航 */}
              <Row style={{ marginBottom: 20, alignItems: 'center' }}>
                <Button 
                  type="text" 
                  label="根目录" 
                  onClick={() => this.loadDirectory('/')}
                  style={{ marginRight: 8 }}
                />
                {this.currentPath !== '/' && (
                  <>
                    <Text style={{ marginRight: 8 }}>/</Text>
                    <Button 
                      type="text" 
                      label="返回上级" 
                      onClick={() => this.navigateToParent()}
                    />
                  </>
                )}
              </Row>
              
              {/* 当前路径 */}
              <Text style={{ marginBottom: 15, fontSize: 14, color: '#666' }}>
                当前路径: {this.currentPath}
              </Text>
              
              {/* 文件列表 */}
              {this.isLoading ? (
                <Text style={{ textAlign: 'center', padding: 40 }}>加载中...</Text>
              ) : (
                <List style={{ width: '100%' }}>
                  {this.files.length > 0 ? (
                    this.files.map(file => this.renderFileItem(file))
                  ) : (
                    <ListItem>
                      <Text style={{ textAlign: 'center', width: '100%', color: '#666' }}>
                        该目录为空
                      </Text>
                    </ListItem>
                  )}
                </List>
              )}
            </Column>
          </Stack>
        </ScrollView>
        
        {/* 索引对话框 */}
        {this.showIndexDialog && (
          <Dialog
            show={this.showIndexDialog}
            title="正在索引"
            onCancel={() => this.showIndexDialog = false}
          >
            <Column style={{ padding: 20 }}>
              <Progress 
                value={this.indexProgress} 
                max={100} 
                style={{ width: '100%', height: 20, marginBottom: 20 }}
              />
              <Text style={{ textAlign: 'center' }}>正在索引视频文件...</Text>
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
  private onBack: () => void;
  private showIndexButton: boolean = false;
  private onIndex: () => void;
  
  constructor(
    title: string,
    onBack: () => void,
    showIndexButton: boolean = false,
    onIndex: () => void = () => {}
  ) {
    this.title = title;
    this.onBack = onBack;
    this.showIndexButton = showIndexButton;
    this.onIndex = onIndex;
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
          onClick={this.onBack}
          style={{ position: 'absolute', left: 16 }}
        />
        <Text style={{ fontSize: 18, fontWeight: 'bold' }}>{this.title}</Text>
        {this.showIndexButton && (
          <Button 
            type="circle" 
            icon="search"
            onClick={this.onIndex}
            style={{ position: 'absolute', right: 16 }}
          />
        )}
      </Row>
    );
  }
}
