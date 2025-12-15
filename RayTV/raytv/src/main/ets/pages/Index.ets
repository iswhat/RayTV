// Index.ets - 应用主入口页�?import { Stack } from '@kit.ArkUI';
import HomePage from './HomePage';

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
