package com.fongmi.android.tv.ui.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import androidx.viewbinding.ViewBinding;

import com.fongmi.android.tv.Product;
import com.fongmi.android.tv.api.config.VodConfig;
import com.fongmi.android.tv.bean.Result;
import com.fongmi.android.tv.bean.Site;
import com.fongmi.android.tv.bean.Style;
import com.fongmi.android.tv.bean.Value;
import com.fongmi.android.tv.bean.Vod;
import com.fongmi.android.tv.databinding.FragmentTypeBinding;
import com.fongmi.android.tv.model.SiteViewModel;
import com.fongmi.android.tv.ui.activity.SearchActivity;
import com.fongmi.android.tv.ui.activity.VideoActivity;
import com.fongmi.android.tv.ui.adapter.VodAdapter;
import com.fongmi.android.tv.ui.base.BaseFragment;
import com.fongmi.android.tv.ui.custom.CustomScroller;
import com.fongmi.android.tv.utils.Notify;
import com.fongmi.android.tv.utils.ResUtil;

import java.util.HashMap;

public class TypeFragment extends BaseFragment implements CustomScroller.Callback, VodAdapter.OnClickListener, SwipeRefreshLayout.OnRefreshListener {

    private HashMap<String, String> mExtends;
    private FragmentTypeBinding mBinding;
    private CustomScroller mScroller;
    private SiteViewModel mViewModel;
    private VodAdapter mAdapter;

    public static TypeFragment newInstance(String key, String typeId, Style style, HashMap<String, String> extend, boolean folder, int y) {
        Bundle args = new Bundle();
        args.putInt("y", y);
        args.putString("key", key);
        args.putString("typeId", typeId);
        args.putBoolean("folder", folder);
        args.putParcelable("style", style);
        args.putSerializable("extend", extend);
        TypeFragment fragment = new TypeFragment();
        fragment.setArguments(args);
        return fragment;
    }

    private String getKey() {
        return getArguments().getString("key");
    }

    private String getTypeId() {
        return getArguments().getString("typeId");
    }

    private Style getStyle() {
        return isFolder() ? Style.list() : getSite().getStyle(getArguments().getParcelable("style"));
    }

    private HashMap<String, String> getExtend() {
        return (HashMap<String, String>) getArguments().getSerializable("extend");
    }

    private int getY() {
        return getArguments().getInt("y");
    }

    private boolean isFolder() {
        return getArguments().getBoolean("folder");
    }

    private boolean isHome() {
        return "home".equals(getTypeId());
    }

    private Site getSite() {
        return VodConfig.get().getSite(getKey());
    }

    private FolderFragment getParent() {
        return (FolderFragment) getParentFragment();
    }

    @Override
    protected ViewBinding getBinding(@NonNull LayoutInflater inflater, @Nullable ViewGroup container) {
        return mBinding = FragmentTypeBinding.inflate(inflater, container, false);
    }

    @Override
    protected void initView() {
        mScroller = new CustomScroller(this);
        mExtends = getExtend();
        setRecyclerView();
        setViewModel();
    }

    @Override
    protected void initEvent() {
        mBinding.swipeLayout.setOnRefreshListener(this);
        mBinding.recycler.addOnScrollListener(mScroller = new CustomScroller(this));
    }

    @Override
    protected void initData() {
        mBinding.progressLayout.showProgress();
        getVideo();
    }

    private void setRecyclerView() {
        mBinding.recycler.setTranslationY(-ResUtil.dp2px(getY()));
        mBinding.recycler.setHasFixedSize(true);
        setStyle(getStyle());
    }

    private void setStyle(Style style) {
        mBinding.recycler.setAdapter(mAdapter = new VodAdapter(this, style, Product.getSpec(requireActivity(), style)));
        mBinding.recycler.setLayoutManager(style.isList() ? new LinearLayoutManager(requireActivity()) : new GridLayoutManager(getContext(), Product.getColumn(requireActivity(), style)));
    }

    private void setViewModel() {
        mViewModel = new ViewModelProvider(this).get(SiteViewModel.class);
        mViewModel.result.observe(getViewLifecycleOwner(), this::setAdapter);
        mViewModel.action.observe(getViewLifecycleOwner(), result -> Notify.show(result.getMsg()));
    }

    private void getHome() {
        mViewModel.homeContent();
        mAdapter.clear();
    }

    private void getVideo() {
        mScroller.reset();
        getVideo(getTypeId(), "1");
    }

    private void getVideo(String typeId, String page) {
        if ("1".equals(page)) mAdapter.clear();
        if ("1".equals(page) && !mBinding.swipeLayout.isRefreshing()) mBinding.progressLayout.showProgress();
        if (isHome() && "1".equals(page)) setAdapter(getParent().getResult());
        else mViewModel.categoryContent(getKey(), typeId, page, true, mExtends);
    }

    private void setAdapter(Result result) {
        boolean first = mScroller.first();
        int size = result.getList().size();
        mBinding.progressLayout.showContent(first, size);
        mBinding.swipeLayout.setRefreshing(false);
        if (size > 0) addVideo(result);
        mScroller.endLoading(result);
        checkMore(size);
    }

    private void addVideo(Result result) {
        Style style = result.getList().get(0).getStyle(getStyle());
        if (!style.equals(mAdapter.getStyle())) setStyle(style);
        mAdapter.addAll(result.getList());
    }

    private void checkMore(int count) {
        if (mScroller.isDisable() || count == 0 || mBinding.recycler.canScrollVertically(1) || mBinding.recycler.getScrollState() > 0 || isHome()) return;
        getVideo(getTypeId(), String.valueOf(mScroller.addPage()));
    }

    public void scrollToTop() {
        mBinding.recycler.smoothScrollToPosition(0);
    }

    public void setFilter(String key, Value value) {
        if (value.isActivated()) mExtends.put(key, value.getV());
        else mExtends.remove(key);
        onRefresh();
    }

    @Override
    public void onRefresh() {
        if (isHome()) getHome();
        else getVideo();
    }

    @Override
    public void onLoadMore(String page) {
        if (isHome()) return;
        mScroller.setLoading(true);
        getVideo(getTypeId(), page);
    }

    @Override
    public void onItemClick(Vod item) {
        if (item.isAction()) {
            mViewModel.action(getKey(), item.getAction());
        } else if (item.isFolder()) {
            getParent().openFolder(item.getVodId(), mExtends);
        } else {
            if (getSite().isIndex()) SearchActivity.start(requireActivity(), item.getVodName());
            else VideoActivity.start(requireActivity(), getKey(), item.getVodId(), item.getVodName(), item.getVodPic(), isFolder() ? item.getVodName() : null);
        }
    }

    @Override
    public boolean onLongClick(Vod item) {
        SearchActivity.start(requireActivity(), item.getVodName());
        return true;
    }
}
