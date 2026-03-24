// Index.ets | 应用主入口页面 | Application main entry page

import router from '@ohos.router';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    // 路由到 HomePage
    router.replaceUrl({
      url: '/pages/HomePage'
    });
  }
  
  build() {
    Column() {
      Text('Loading...')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }
}
