package com.fongmi.android.tv.impl;

import android.graphics.drawable.Drawable;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.request.transition.Transition;

public class CustomTarget<T> extends com.bumptech.glide.request.target.CustomTarget<T> {

    public CustomTarget() {
        super();
    }

    public CustomTarget(int width, int height) {
        super(width, height);
    }

    @Override
    public void onResourceReady(@NonNull T resource, @Nullable Transition<? super T> transition) {
    }

    @Override
    public void onLoadCleared(@Nullable Drawable placeholder) {
    }
}
