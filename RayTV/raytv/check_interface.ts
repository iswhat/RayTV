// 检查SQLiteDatabaseRepository是否正确实现了DatabaseRepository接口
import DatabaseRepository from './src/main/ets/data/repository/DatabaseRepository';
import SQLiteDatabaseRepository from './src/main/ets/data/repository/SQLiteDatabaseRepository';

// 这个文件用于检查类型错误，不需要实际运行
const dbRepository: DatabaseRepository = new SQLiteDatabaseRepository();
console.log('接口实现检查通过');
