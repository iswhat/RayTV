package com.fongmi.android.tv.bean;

import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.Index;
import androidx.room.PrimaryKey;

import com.fongmi.android.tv.db.AppDatabase;

import java.util.Collections;
import java.util.List;

@Entity(indices = @Index(value = {"key", "type"}, unique = true))
public class Track {

    @PrimaryKey(autoGenerate = true)
    private int id;
    private int type;
    private int group;
    private int track;
    private String key;
    private String name;
    private boolean selected;

    public Track(int type, String name) {
        this.type = type;
        this.name = name;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public int getGroup() {
        return group;
    }

    public void setGroup(int group) {
        this.group = group;
    }

    public int getTrack() {
        return track;
    }

    public void setTrack(int track) {
        this.track = track;
    }

    public String getKey() {
        return key;
    }

    public void setKey(@NonNull String key) {
        this.key = key;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public boolean isSelected() {
        return selected;
    }

    public void setSelected(boolean selected) {
        this.selected = selected;
    }

    public Track key(String key) {
        setKey(key);
        return this;
    }

    public Track toggle() {
        setSelected(!isSelected());
        return this;
    }

    public Track save() {
        if (TextUtils.isEmpty(getKey())) return this;
        AppDatabase.get().getTrackDao().insert(this);
        return this;
    }

    public static List<Track> find(String key) {
        return TextUtils.isEmpty(key) ? Collections.emptyList() : AppDatabase.get().getTrackDao().find(key);
    }

    public static void delete(String key) {
        if (TextUtils.isEmpty(key)) return;
        AppDatabase.get().getTrackDao().delete(key);
    }
}
