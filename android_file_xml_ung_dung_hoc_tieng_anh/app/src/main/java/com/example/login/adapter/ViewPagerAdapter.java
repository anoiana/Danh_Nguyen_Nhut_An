package com.example.login.adapter;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.Lifecycle;
import androidx.viewpager2.adapter.FragmentStateAdapter;

import com.example.login.fragment.ChoicesFragment;
import com.example.login.fragment.LibrarysFragment;
import com.example.login.fragment.FragmentCards;
import com.example.login.fragment.WordsFragment;

public class ViewPagerAdapter extends FragmentStateAdapter {

    public ViewPagerAdapter(@NonNull FragmentManager fragmentManager, @NonNull Lifecycle lifecycle) {
        super(fragmentManager, lifecycle);
    }


    @NonNull
    @Override
    public Fragment createFragment(int position) {
        switch (position){
            case 0:
                return new FragmentCards();
            case 1:
                return new WordsFragment();
            case 2:
                return new ChoicesFragment();
            case 3:
                return new LibrarysFragment();
            default:
                return new FragmentCards();
        }
    }

    @Override
    public int getItemCount() {
        return 4;
    }
}

