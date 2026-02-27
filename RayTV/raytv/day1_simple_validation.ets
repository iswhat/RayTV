/**
 * Day 1 简化验证脚本
 * 
 * @file day1_simple_validation.ets
 * @description 使用ArkTS语法验证Day 1核心功能
 */

import { EnhancedContainer } from './src/main/ets/common/di/EnhancedContainer';
import { MainViewModel } from './src/main/ets/presentation/viewmodel/MainViewModel';

@Entry
@Component
struct Day1Validation {
  @State validationResults: string[] = [];
  @State isRunning: boolean = false;

  aboutToAppear() {
    this.runValidation();
  }

  async runValidation() {
    this.isRunning = true;
    this.validationResults = ['🚀 开始Day 1功能验证...'];
    
    try {
      // 验证DI容器
      await this.validateDIContainer();
      
      // 验证ViewModel
      await this.validateViewModel();
      
      // 验证集成
      await this.validateIntegration();
      
      this.validationResults.push('🎉 所有验证完成！');
      
    } catch (error) {
      this.validationResults.push(`❌ 验证过程中出现错误: ${error}`);
    } finally {
      this.isRunning = false;
    }
  }

  async validateDIContainer() {
    this.validationResults.push('\n🧪 验证DI容器功能...');
    
    try {
      const container = EnhancedContainer.getInstance();
      
      // 测试服务注册
      container.register('TestService', class {
        getValue() { return 'success'; }
        getServiceName() { return 'TestService'; }
        getServiceVersion() { return '1.0.0'; }
      });
      
      // 测试服务解析
      const service = container.resolve<any>('TestService');
      if (service.getValue() === 'success') {
        this.validationResults.push('✅ DI容器基础功能正常');
      } else {
        this.validationResults.push('❌ DI容器功能异常');
      }
      
    } catch (error) {
      this.validationResults.push(`❌ DI容器验证失败: ${error}`);
    }
  }

  async validateViewModel() {
    this.validationResults.push('\n🧪 验证ViewModel功能...');
    
    try {
      const viewModel = new MainViewModel();
      await viewModel.initialize();
      
      // 测试状态更新
      viewModel.setStateProperty('searchQuery', 'test');
      const state = viewModel.getState();
      
      if (state.searchQuery === 'test') {
        this.validationResults.push('✅ ViewModel状态管理正常');
      } else {
        this.validationResults.push('❌ ViewModel状态管理异常');
      }
      
      viewModel.dispose();
      
    } catch (error) {
      this.validationResults.push(`❌ ViewModel验证失败: ${error}`);
    }
  }

  async validateIntegration() {
    this.validationResults.push('\n🧪 验证组件集成...');
    
    try {
      // 测试DI容器和ViewModel集成
      const container = EnhancedContainer.getInstance();
      const viewModel = new MainViewModel();
      
      // 模拟依赖注入
      viewModel['getService'] = (token: any) => container.resolve(token);
      
      await viewModel.initialize();
      this.validationResults.push('✅ 组件集成正常');
      
      viewModel.dispose();
      
    } catch (error) {
      this.validationResults.push(`❌ 集成验证失败: ${error}`);
    }
  }

  build() {
    Column() {
      Text('RayTV Day 1 超级冲刺验证')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      if (this.isRunning) {
        Text('⏳ 验证进行中...')
          .fontSize(16)
          .fontColor('#FF9900')
          .margin({ bottom: 20 })
      }

      Scroller() {
        Column() {
          ForEach(this.validationResults, (result: string, index: number) => {
            Text(result)
              .fontSize(14)
              .textAlign(TextAlign.Start)
              .width('100%')
              .padding(8)
              .backgroundColor(index % 2 === 0 ? '#F5F5F5' : '#FFFFFF')
              .borderRadius(4)
          })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .backgroundColor('#FAFAFA')

      Button('重新运行验证')
        .width('80%')
        .height(48)
        .backgroundColor('#007AFF')
        .fontColor(Color.White)
        .borderRadius(8)
        .onClick(() => {
          this.runValidation();
        })
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
  }
}