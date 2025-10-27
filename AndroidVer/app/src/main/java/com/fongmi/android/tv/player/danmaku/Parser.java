package com.fongmi.android.tv.player.danmaku;

import com.fongmi.android.tv.bean.DanmakuData;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import master.flame.danmaku.danmaku.model.BaseDanmaku;
import master.flame.danmaku.danmaku.model.IDanmakus;
import master.flame.danmaku.danmaku.model.android.Danmakus;
import master.flame.danmaku.danmaku.parser.BaseDanmakuParser;
import master.flame.danmaku.danmaku.parser.android.AndroidFileSource;
import master.flame.danmaku.danmaku.util.DanmakuUtils;

public class Parser extends BaseDanmakuParser {

    private static final Pattern XML = Pattern.compile("p=\"([^\"]+)\"[^>]*>([^<]+)<");
    private static final Pattern TXT = Pattern.compile("\\[(.*?)\\](.*)");

    @Override
    public Danmakus parse() {
        String line;
        Pattern pattern = null;
        if (mDataSource == null) return null;
        List<DanmakuData> items = new ArrayList<>();
        AndroidFileSource source = (AndroidFileSource) mDataSource;
        try (BufferedReader br = new BufferedReader(new InputStreamReader(source.data()))) {
            while ((line = br.readLine()) != null) {
                if (pattern == null) pattern = line.startsWith("<") ? XML : TXT;
                Matcher matcher = pattern.matcher(line);
                while (matcher.find() && matcher.groupCount() == 2) {
                    try {
                        items.add(new DanmakuData(matcher, mDispDensity));
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
            Danmakus result = new Danmakus(IDanmakus.ST_BY_TIME);
            for (int i = 0; i < items.size(); i++) {
                DanmakuData data = items.get(i);
                int type = data.getType();
                if (type == 2 || type == 3) type = 1;
                BaseDanmaku item = mContext.mDanmakuFactory.createDanmaku(type, mContext);
                if (item == null || item.getType() == BaseDanmaku.TYPE_SPECIAL) continue;
                DanmakuUtils.fillText(item, data.getText());
                item.textShadowColor = data.getShadow();
                item.textColor = data.getColor();
                item.flags = mContext.mGlobalFlagValues;
                item.textSize = data.getSize();
                item.setTime(data.getTime());
                item.setTimer(mTimer);
                item.index = i;
                synchronized (result.obtainSynchronizer()) {
                    result.addItem(item);
                }
            }
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}