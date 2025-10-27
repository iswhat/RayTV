package com.github.catvod.bean;

import android.net.Uri;
import android.text.TextUtils;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.annotations.SerializedName;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.net.InetSocketAddress;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

public class Proxy {

    @SerializedName("name")
    private String name;
    @SerializedName("hosts")
    private List<String> hosts;
    @SerializedName("urls")
    private List<String> urls;

    private List<java.net.Proxy> proxies;

    public static List<Proxy> arrayFrom(JsonElement element) {
        try {
            Type listType = new TypeToken<List<Proxy>>() {}.getType();
            List<Proxy> items = new Gson().fromJson(element, listType);
            return items == null ? Collections.emptyList() : items;
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    public void init() {
        proxies = new ArrayList<>();
        for (String url : getUrls()) proxies.add(create(url));
        proxies.removeIf(Objects::isNull);
    }

    public String getName() {
        return TextUtils.isEmpty(name) ? "" : name;
    }

    public List<String> getHosts() {
        return hosts == null ? Collections.emptyList() : hosts;
    }

    public List<String> getUrls() {
        return urls == null ? Collections.emptyList() : urls;
    }

    public List<java.net.Proxy> getProxies() {
        return proxies == null ? Collections.emptyList() : proxies;
    }

    private java.net.Proxy create(String url) {
        Uri uri = Uri.parse(url);
        if (uri.getScheme() == null || uri.getHost() == null || uri.getPort() <= 0) return null;
        if (uri.getScheme().startsWith("http")) return new java.net.Proxy(java.net.Proxy.Type.HTTP, InetSocketAddress.createUnresolved(uri.getHost(), uri.getPort()));
        if (uri.getScheme().startsWith("socks")) return new java.net.Proxy(java.net.Proxy.Type.SOCKS, InetSocketAddress.createUnresolved(uri.getHost(), uri.getPort()));
        return null;
    }

    public static void sort(List<Proxy> items) {
        items.sort((o1, o2) -> {
            boolean g1 = o1.getHosts().stream().anyMatch(h -> h.contains("*"));
            boolean g2 = o2.getHosts().stream().anyMatch(h -> h.contains("*"));
            if (g1 == g2) return 0;
            return g1 ? 1 : -1;
        });
    }
}