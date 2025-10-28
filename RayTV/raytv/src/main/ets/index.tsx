import React from 'react';
import ReactDOM from 'react-dom/client';
import { Provider } from 'react-redux';
import { ConfigProvider } from '@ray-js/components';
import App from './App';
import store from './store';
import './common/style/global.less';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

// 应用配置主题
const themeConfig = {
  token: {
    colorPrimary: '#007AFF',
    colorBackground: '#F5F5F5',
    colorText: '#333333',
    colorTextSecondary: '#666666',
    colorBorder: '#E0E0E0',
    fontSizeBase: 16,
    fontSizeSmall: 14,
    fontSizeLarge: 18,
  },
};

root.render(
  <React.StrictMode>
    <Provider store={store}>
      <ConfigProvider theme={themeConfig}>
        <App />
      </ConfigProvider>
    </Provider>
  </React.StrictMode>
);

// 监听页面卸载事件，清理资源
window.addEventListener('beforeunload', () => {
  // 在这里进行必要的资源清理
  console.log('RayTV is closing...');
});