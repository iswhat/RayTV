if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MediaDetailPage_Params {
}
export class MediaDetailPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MediaDetailPage_Params) {
    }
    updateStateVars(params: MediaDetailPage_Params) {
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
            Column.debugLine("raytv/src/main/ets/pages/MediaDetailPage.ets(5:5)", "raytv");
        }, Column);
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "MediaDetailPage";
    }
}
export default MediaDetailPage;
registerNamedRoute(() => new MediaDetailPage(undefined, {}), "", { bundleName: "com.raytv.app", moduleName: "raytv", pagePath: "pages/MediaDetailPage", pageFullPath: "raytv/src/main/ets/pages/MediaDetailPage", integratedHsp: "false", moduleType: "followWithHap" });
