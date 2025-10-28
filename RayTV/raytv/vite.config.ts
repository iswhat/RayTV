import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src/main/ets'),
      '@components': path.resolve(__dirname, 'src/main/ets/components'),
      '@common': path.resolve(__dirname, 'src/main/ets/common'),
      '@service': path.resolve(__dirname, 'src/main/ets/service'),
      '@store': path.resolve(__dirname, 'src/main/ets/store')
    }
  },
  server: {
    port: 3000,
    host: '0.0.0.0',
    hmr: true
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    },
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          redux: ['redux', 'react-redux'],
          taro: ['@tarojs/taro', '@tarojs/components']
        }
      }
    }
  },
  css: {
    preprocessorOptions: {
      less: {
        javascriptEnabled: true,
        additionalData: `@import "${path.resolve(__dirname, 'src/main/ets/common/style/variables.less')}";`
      }
    }
  }
});