if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Index_Params {
}
import router from "@ohos:router";
class Index extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Index_Params) {
    }
    updateStateVars(params: Index_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    aboutToAppear(): void {
        // 路由到 HomePage
        router.replaceUrl({
            url: '/pages/HomePage'
        });
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/Index.ets(16:5)", "raytv");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#121212');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('Loading...');
            Text.debugLine("raytv/src/main/ets/pages/Index.ets(17:7)", "raytv");
        }, Text);
        Text.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "Index";
    }
}
registerNamedRoute(() => new Index(undefined, {}), "", { bundleName: "com.raytv.app", moduleName: "raytv", pagePath: "pages/Index", pageFullPath: "raytv/src/main/ets/pages/Index", integratedHsp: "false", moduleType: "followWithHap" });
