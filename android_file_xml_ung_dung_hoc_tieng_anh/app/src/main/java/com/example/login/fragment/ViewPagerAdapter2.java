package com.example.login.fragment;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;

import androidx.fragment.app.FragmentPagerAdapter;

public class ViewPagerAdapter2 extends FragmentPagerAdapter {

    public ViewPagerAdapter2(@NonNull FragmentManager fm) {
        super(fm, BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT);
    }

    @NonNull
    @Override
    public Fragment getItem(int position) {
        switch (position) {
            case 0:
                return new FolderFragment();
            case 1:
                return new TopicFragment();
            case 2:
                return new FavouriteWordFragment();
            case 3:
                return new PublicTopicFragment();
            default:
                return new FolderFragment();
        }
    }

    @Override
    public int getCount() {
        return 4; // Số lượng tab
    }


    @Nullable
    @Override
    public CharSequence getPageTitle(int position) {
        switch (position) {
            case 0:
                return "List Folder";
            case 1:
                return "List Topic";
            case 2:
                return "Favorite Words";
            case 3:
                return "Public Topic";
            default:
                return "List Folder";
        }
    }
}
