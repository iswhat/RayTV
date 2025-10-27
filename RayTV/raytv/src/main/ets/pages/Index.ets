// Index.ets - 应用主入口页面
import HomePage from '../presentation/page/HomePage';

@Entry
@Component
struct Index {
  build() {
    Stack() {
      HomePage()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }
}