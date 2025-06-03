package com.example.login.activity;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.Switch;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AppCompatDelegate;

import com.example.login.R;

public class SettingActivity extends AppCompatActivity {

    private Switch switchDarkMode;
    private ImageView imgBack;
    private TextView tvDarkMode;
    private SharedPreferences sharedPreferences;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Lấy trạng thái từ SharedPreferences
        sharedPreferences = getSharedPreferences("AppSettings", MODE_PRIVATE);
        boolean isDarkMode = sharedPreferences.getBoolean("isDarkMode", false);

        // Thiết lập giao diện
        setContentView(R.layout.activity_setting);

        // Ánh xạ View
        switchDarkMode = findViewById(R.id.switchDarkMode);
        imgBack = findViewById(R.id.imgBack);
        tvDarkMode = findViewById(R.id.tvDarkMode);

        // Đặt trạng thái cho Switch và TextView
        switchDarkMode.setChecked(isDarkMode);
        updateTextView(isDarkMode);

        // Xử lý sự kiện bật/tắt chế độ tối
        switchDarkMode.setOnCheckedChangeListener((buttonView, isChecked) -> {
            // Áp dụng chế độ mới
            if (isChecked) {
                AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES);
            } else {
                AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO);
            }

            // Lưu trạng thái vào SharedPreferences
            sharedPreferences.edit().putBoolean("isDarkMode", isChecked).apply();

            // Cập nhật giao diện TextView
            updateTextView(isChecked);
        });

        // Xử lý sự kiện nút Back
        imgBack.setOnClickListener(v -> finish());
    }

    // Phương thức cập nhật nội dung TextView
    private void updateTextView(boolean isDarkMode) {
        if (isDarkMode) {
            tvDarkMode.setText("Dark Mode");
            tvDarkMode.setTextColor(getResources().getColor(android.R.color.white, getTheme()));
        } else {
            tvDarkMode.setText("Light Mode");
            tvDarkMode.setTextColor(getResources().getColor(android.R.color.black, getTheme()));
        }
    }
}
