import TypeUtils from "@bundle:com.raytv.app/raytv/ets/common/util/ark/TypeUtils";
/**
 * 简单的对象接口 Simple object interface
 */
export interface SimpleObject {
    key: string;
    value: string | number | boolean | null | undefined;
}
/**
 * ObjectUtils 类 - 提供对象操作工具方法
 * ObjectUtils class - provides object operation utility methods
 */
export class ObjectUtilsClass {
    /**
     * 检查对象是否包含指定属性 Checks if object contains specified property
     */
    hasProperty(obj: Record<string, string | number | boolean | null | undefined>, key: string): boolean {
        if (!TypeUtils.isObject(obj)) {
            return false;
        }
        return Object.getOwnPropertyNames(obj).includes(key);
    }
    /**
     * 获取对象的所有键 Gets all keys of object
     */
    getKeys(obj: Record<string, string | number | boolean | null | undefined>): string[] {
        if (!TypeUtils.isObject(obj)) {
            return [];
        }
        return Object.getOwnPropertyNames(obj);
    }
    /**
     * 获取对象的属性值 Gets property value of object
     */
    getProperty(obj: Record<string, string | number | boolean | null | undefined>, key: string): string | number | boolean | null | undefined {
        if (!TypeUtils.isObject(obj)) {
            return undefined;
        }
        return obj[key];
    }
    /**
     * 设置对象的属性值 Sets property value of object
     */
    setProperty(obj: Record<string, string | number | boolean | null | undefined>, key: string, value: string | number | boolean | null | undefined): boolean {
        if (!TypeUtils.isObject(obj)) {
            return false;
        }
        try {
            obj[key] = value;
            return true;
        }
        catch {
            return false;
        }
    }
    /**
     * 合并对象 Merges objects (shallow merge)
     * 注意：ArkTS 限制，仅支持浅合并 Note: ArkTS limitation, only supports shallow merge
     */
    merge(target: Record<string, string | number | boolean | null | undefined>, ...sources: Array<Record<string, string | number | boolean | null | undefined>>): Record<string, string | number | boolean | null | undefined> {
        if (!TypeUtils.isObject(target)) {
            return {};
        }
        const result: Record<string, string | number | boolean | null | undefined> = {};
        // 复制目标对象的属性 Copy target object properties
        const targetKeys = this.getKeys(target);
        for (let i = 0; i < targetKeys.length; i++) {
            const key = targetKeys[i];
            result[key] = target[key];
        }
        // 合并源对象的属性 Merge source object properties
        for (let i = 0; i < sources.length; i++) {
            const source = sources[i];
            if (TypeUtils.isObject(source)) {
                const sourceKeys = this.getKeys(source);
                for (let j = 0; j < sourceKeys.length; j++) {
                    const key = sourceKeys[j];
                    result[key] = source[key];
                }
            }
        }
        return result;
    }
}
// 导出单例实例 Export singleton instance
const ObjectUtils = new ObjectUtilsClass();
export default ObjectUtils;
