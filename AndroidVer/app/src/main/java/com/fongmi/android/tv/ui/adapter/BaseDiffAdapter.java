package com.fongmi.android.tv.ui.adapter;

import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.AsyncListDiffer;
import androidx.recyclerview.widget.RecyclerView;

import com.fongmi.android.tv.impl.Diffable;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public abstract class BaseDiffAdapter<T extends Diffable<T>, VH extends RecyclerView.ViewHolder> extends RecyclerView.Adapter<VH> {

    protected final AsyncListDiffer<T> differ;

    public BaseDiffAdapter() {
        this.differ = new AsyncListDiffer<>(this, new BaseItemCallback<T>());
    }

    public T getItem(int position) {
        return differ.getCurrentList().get(position);
    }

    public List<T> getItems() {
        return differ.getCurrentList();
    }

    public void setItems(List<T> items, Runnable commitCallback) {
        differ.submitList(items, commitCallback);
    }

    public void setItems(List<T> items) {
        setItems(items, null);
    }

    public void addItem(T item) {
        List<T> current = new ArrayList<>(getItems());
        current.add(item);
        setItems(current);
    }

    public void addItems(List<T> items) {
        List<T> current = new ArrayList<>(getItems());
        current.addAll(items);
        setItems(current);
    }

    public void sort(Comparator<T> comparator) {
        List<T> current = new ArrayList<>(getItems());
        if (current.size() < 2) return;
        current.sort(comparator);
        setItems(current);
    }

    public void remove(T item) {
        List<T> current = new ArrayList<>(getItems());
        if (current.remove(item)) setItems(current);
    }

    public void clear() {
        setItems(new ArrayList<>());
    }

    @Override
    public int getItemCount() {
        return differ.getCurrentList().size();
    }

    @NonNull
    @Override
    public abstract VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType);

    @Override
    public abstract void onBindViewHolder(@NonNull VH holder, int position);
}
