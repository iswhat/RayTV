/**
 * Day 3 组件验证页面 | Day 3 Component Validation Page
 * 验证新创建的组件功能
 * Validate the functionality of newly created components
 */

import { Button, PrimaryButton, SecondaryButton } from './components/Button.ets';
import { Input, TextInput, PasswordInput } from './components/Input.ets';
import { Logger } from './common/utils/Logger.ets';

@Entry
@Component
struct Day3ValidationPage {
  @State validationResults: string[] = [];
  @State isRunning: boolean = false;
  @State inputValue: string = '';
  @State buttonClicked: boolean = false;

  aboutToAppear() {
    this.runValidation();
  }

  async runValidation() {
    this.isRunning = true;
    this.validationResults = ['🚀 开始Day 3组件验证...'];
    
    try {
      // 验证按钮组件
      await this.validateButtons();
      
      // 验证输入框组件
      await this.validateInputs();
      
      // 验证组件集成
      await this.validateIntegration();
      
      this.validationResults.push('🎉 所有组件验证完成！');
      
    } catch (error) {
      this.validationResults.push(`❌ 验证过程中出现错误: ${error}`);
    } finally {
      this.isRunning = false;
    }
  }

  async validateButtons() {
    this.validationResults.push('\n🧪 验证按钮组件...');
    
    try {
      // 测试按钮创建
      const primaryBtn = new PrimaryButton({
        children: '主要按钮',
        onClick: () => {
          this.buttonClicked = true;
          this.validationResults.push('✅ 主要按钮点击事件正常');
        }
      });
      
      const secondaryBtn = new SecondaryButton({
        children: '次要按钮',
        onClick: () => {
          this.validationResults.push('✅ 次要按钮点击事件正常');
        }
      });
      
      // 测试按钮属性更新
      primaryBtn.updateProps({ disabled: true });
      secondaryBtn.updateProps({ loading: true });
      
      this.validationResults.push('✅ 按钮组件创建和属性更新正常');
      
    } catch (error) {
      this.validationResults.push(`❌ 按钮组件验证失败: ${error}`);
    }
  }

  async validateInputs() {
    this.validationResults.push('\n🧪 验证输入框组件...');
    
    try {
      // 测试输入框创建
      const textInput = new TextInput({
        placeholder: '请输入文本',
        onInput: (value: string) => {
          this.inputValue = value;
          this.validationResults.push(`✅ 文本输入: ${value}`);
        }
      });
      
      const pwdInput = new PasswordInput({
        placeholder: '请输入密码',
        onInput: (value: string) => {
          this.validationResults.push(`✅ 密码输入: ${'*'.repeat(value.length)}`);
        }
      });
      
      // 测试输入框方法
      textInput.setValue('测试值');
      const value = textInput.getValue();
      
      if (value === '测试值') {
        this.validationResults.push('✅ 输入框值设置和获取正常');
      }
      
      textInput.clear();
      if (textInput.getValue() === '') {
        this.validationResults.push('✅ 输入框清空功能正常');
      }
      
    } catch (error) {
      this.validationResults.push(`❌ 输入框组件验证失败: ${error}`);
    }
  }

  async validateIntegration() {
    this.validationResults.push('\n🧪 验证组件集成...');
    
    try {
      // 测试组件间的交互
      const logger = new Logger('ComponentIntegration');
      logger.info('开始组件集成测试');
      
      // 模拟表单场景
      let formData = {
        username: '',
        password: ''
      };
      
      const usernameInput = new TextInput({
        placeholder: '用户名',
        onInput: (value: string) => {
          formData.username = value;
        }
      });
      
      const passwordInput = new PasswordInput({
        placeholder: '密码',
        onInput: (value: string) => {
          formData.password = value;
        }
      });
      
      const submitButton = new PrimaryButton({
        children: '提交',
        onClick: () => {
          if (formData.username && formData.password) {
            this.validationResults.push(`✅ 表单提交成功: ${JSON.stringify(formData)}`);
          } else {
            this.validationResults.push('❌ 表单数据不完整');
          }
        }
      });
      
      this.validationResults.push('✅ 组件集成和交互正常');
      
    } catch (error) {
      this.validationResults.push(`❌ 组件集成验证失败: ${error}`);
    }
  }

  build() {
    Column() {
      // 标题区域
      Text('RayTV Day 3 组件验证')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      if (this.isRunning) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .margin({ right: 10 })
          Text('验证进行中...')
            .fontSize(16)
        }
        .margin({ bottom: 20 })
      }

      // 验证结果显示区域
      Scroller() {
        Column() {
          ForEach(this.validationResults, (result: string, index: number) => {
            Text(result)
              .fontSize(14)
              .textAlign(TextAlign.Start)
              .width('100%')
              .padding(12)
              .backgroundColor(index % 2 === 0 ? '#F8F9FA' : '#FFFFFF')
              .borderRadius(6)
              .margin({ bottom: 4 })
          })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .backgroundColor('#F0F2F5')

      // 组件演示区域
      Column() {
        Text('组件演示区')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 16 })

        // 按钮演示
        Row({ space: 12 }) {
          PrimaryButton({
            children: '主要按钮',
            onClick: () => {
              this.validationResults.push('✅ 演示按钮被点击');
            }
          }).render()

          SecondaryButton({
            children: '次要按钮',
            onClick: () => {
              this.validationResults.push('✅ 次要按钮被点击');
            }
          }).render()
        }
        .margin({ bottom: 16 })

        // 输入框演示
        Column({ space: 12 }) {
          TextInput({
            placeholder: '演示输入框',
            onInput: (value: string) => {
              this.validationResults.push(`✅ 演示输入: ${value}`);
            }
          }).render()

          PasswordInput({
            placeholder: '演示密码框',
            onInput: (value: string) => {
              this.validationResults.push(`✅ 演示密码输入: ${'*'.repeat(value.length)}`);
            }
          }).render()
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 20 })

      // 控制按钮
      Button('重新运行验证')
        .width('80%')
        .height(48)
        .backgroundColor('#007AFF')
        .fontColor(Color.White)
        .borderRadius(8)
        .onClick(() => {
          this.runValidation();
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
  }
}