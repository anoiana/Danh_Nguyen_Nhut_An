package com.example.login.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.fragment.app.Fragment;
import com.example.login.R;
import com.example.login.widget.CustomViewPager;
import com.google.android.material.tabs.TabLayout;

public class LibrarysFragment extends Fragment {

    private View mView;
    private TabLayout tabLayout;
    private CustomViewPager viewPager;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mView = inflater.inflate(R.layout.fragment_library, container, false);

        tabLayout = mView.findViewById(R.id.tab_layout);
        viewPager = mView.findViewById(R.id.view_pager);

        ViewPagerAdapter2 viewPagerAdapter = new ViewPagerAdapter2(getChildFragmentManager());
        viewPager.setAdapter(viewPagerAdapter);
        viewPager.setPagingEnable(false);

        tabLayout.setupWithViewPager(viewPager); // Kết nối TabLayout với ViewPager

        return mView;
    }
}
