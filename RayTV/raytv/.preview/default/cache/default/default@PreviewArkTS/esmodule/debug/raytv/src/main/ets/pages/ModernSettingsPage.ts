if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ModernSettingsPage_Params {
}
export class ModernSettingsPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ModernSettingsPage_Params) {
    }
    updateStateVars(params: ModernSettingsPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/pages/ModernSettingsPage.ets(5:5)", "raytv");
        }, Column);
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ModernSettingsPage";
    }
}
export default ModernSettingsPage;
registerNamedRoute(() => new ModernSettingsPage(undefined, {}), "", { bundleName: "com.raytv.app", moduleName: "raytv", pagePath: "pages/ModernSettingsPage", pageFullPath: "raytv/src/main/ets/pages/ModernSettingsPage", integratedHsp: "false", moduleType: "followWithHap" });
