// 检查SQLiteDatabaseRepository是否实现了DatabaseRepository接口的所有方法
import DatabaseRepository from './raytv/src/main/ets/data/repository/DatabaseRepository';
import SQLiteDatabaseRepository from './raytv/src/main/ets/data/repository/SQLiteDatabaseRepository';

// 获取DatabaseRepository的所有方法名
const dbRepoMethods = Object.getOwnPropertyNames(DatabaseRepository.prototype);

// 获取SQLiteDatabaseRepository的所有方法名
const sqliteRepoMethods = Object.getOwnPropertyNames(SQLiteDatabaseRepository.prototype);

// 检查哪些方法没有实现
const missingMethods = dbRepoMethods.filter(method => 
  !sqliteRepoMethods.includes(method) && method !== 'constructor'
);

console.log('DatabaseRepository方法:', dbRepoMethods);
console.log('SQLiteDatabaseRepository方法:', sqliteRepoMethods);
console.log('缺少的方法:', missingMethods);
