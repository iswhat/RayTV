package com.fongmi.android.tv.bean;

import android.text.TextUtils;

import androidx.media3.common.C;
import androidx.media3.common.MediaItem;

import com.github.catvod.utils.Json;
import com.google.gson.JsonElement;
import com.google.gson.annotations.SerializedName;

import java.util.UUID;

public class Drm {

    @SerializedName("key")
    private String key;
    @SerializedName("type")
    private String type;
    @SerializedName("forceKey")
    private boolean forceKey;
    @SerializedName("header")
    private JsonElement header;

    public static Drm create(String key, String type) {
        return new Drm(key, type);
    }

    private Drm(String key, String type) {
        this.key = key;
        this.type = type;
    }

    private String getKey() {
        return TextUtils.isEmpty(key) ? "" : key;
    }

    private String getType() {
        return TextUtils.isEmpty(type) ? "" : type;
    }

    public boolean isForceKey() {
        return forceKey;
    }

    private JsonElement getHeader() {
        return header;
    }

    public UUID getUUID() {
        if (getType().contains("playready")) return C.PLAYREADY_UUID;
        if (getType().contains("widevine")) return C.WIDEVINE_UUID;
        if (getType().contains("clearkey")) return C.CLEARKEY_UUID;
        return C.UUID_NIL;
    }

    public MediaItem.DrmConfiguration get() {
        MediaItem.DrmConfiguration.Builder builder = new MediaItem.DrmConfiguration.Builder(getUUID());
        builder.setMultiSession(!C.CLEARKEY_UUID.equals(getUUID()));
        builder.setLicenseRequestHeaders(Json.toMap(getHeader()));
        builder.setForceDefaultLicenseUri(isForceKey());
        builder.setLicenseUri(getKey());
        return builder.build();
    }
}
