package com.example.login.activity;


import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.drawerlayout.widget.DrawerLayout;
import com.example.login.R;
import com.google.android.material.bottomnavigation.BottomNavigationView;
public class BaseActivity extends AppCompatActivity {
    protected DrawerLayout drawerLayout;
    protected BottomNavigationView bottomNavigationView;

    protected void setupToolbarAndDrawer() {
        drawerLayout = findViewById(R.id.drawer_layout);
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        ActionBarDrawerToggle toggle = new ActionBarDrawerToggle(this, drawerLayout, toolbar, R.string.open_nav, R.string.close_nav);
        toggle.syncState();
    }

    protected void setupBottomNavigation(BottomNavigationView.OnItemSelectedListener listener) {
        bottomNavigationView = findViewById(R.id.bottomNavigationView);
        bottomNavigationView.setBackground(null);
        bottomNavigationView.setOnItemSelectedListener(listener);
    }

}
