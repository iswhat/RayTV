# Ohpm Registry Configuration Guide

## Problem
The command failed with exit code 255 when using registry: `https://repo.harmonyos.com/hpm/`

## Solution

### Correct Registry URLs

Based on your `oh-package-lock.json5`, the correct registry is:
```
https://ohpm.openharmony.cn/ohpm/
```

### Manual Fix Steps

1. **Configure ohpm registry:**
   ```bash
   "C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm.bat" config set registry https://ohpm.openharmony.cn/ohpm/
   ```

2. **Clean cache:**
   ```bash
   "C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm.bat" cache clean --all
   ```

3. **Reinstall dependencies:**
   ```bash
   "C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm.bat" install --all
   ```

### Alternative Command (without custom registry)

Simply run without specifying registry - it will use the configured default:
```bash
"C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm.bat" install
```

### Verify Installation

Check if dependencies are installed:
```bash
"C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm.bat" list
```

Your dependencies should already be in:
- `D:\tv\RayTV\oh_modules\@ohos\hamock\`
- `D:\tv\RayTV\oh_modules\@ohos\hypium\`

## Notes

- The registry `https://repo.harmonyos.com/hpm/` may be unavailable or deprecated
- Use `https://ohpm.openharmony.cn/ohpm/` instead (official OpenHarmony registry)
- Dependencies are already installed based on existing `oh-package-lock.json5`
