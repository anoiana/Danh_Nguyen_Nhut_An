package com.example.login.activity;

import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;

import com.example.login.model.SharedViewModel;
import com.example.login.model.Word;
import com.google.android.material.bottomsheet.BottomSheetDialog;

import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.lifecycle.ViewModelProvider;
import androidx.viewpager2.widget.ViewPager2;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.example.login.R;
import com.example.login.adapter.ViewPagerAdapter;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.navigation.NavigationView;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity implements NavigationView.OnNavigationItemSelectedListener {
    FirebaseAuth auth;
    FirebaseUser user;
    DatabaseReference userRef;

    DrawerLayout drawerLayout;
    BottomNavigationView bottomNavigationView;
    NavigationView navigationView;
    ViewPager2 viewPager;
    ImageView avatarImg, changeImage;
    TextView editUsername, emailTextView, userName;

    FloatingActionButton fab;
    SharedViewModel sharedViewModel;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        sharedViewModel = new ViewModelProvider(this).get(SharedViewModel.class);
        // Khởi tạo DrawerLayout và Toolbar
        Toolbar toolbar = findViewById(R.id.toolbar);
        drawerLayout = findViewById(R.id.drawer_layout);
        setSupportActionBar(toolbar);

        // Khởi tạo ActionBarDrawerToggle
        ActionBarDrawerToggle toggle = new ActionBarDrawerToggle(this, drawerLayout,
                toolbar, R.string.open_nav, R.string.close_nav);

        // Thêm toggle làm listener cho DrawerLayout
        drawerLayout.addDrawerListener(toggle);

        // Liên kết NavigationView với listener để xử lý sự kiện chọn menu
        navigationView = findViewById(R.id.nav_view);
        navigationView.setNavigationItemSelectedListener(this);

        // Đồng bộ trạng thái của toggle
        toggle.syncState();

        View headerView = navigationView.getHeaderView(0);
        emailTextView = headerView.findViewById(R.id.email_user);
        userName = headerView.findViewById(R.id.name_user);
        changeImage = headerView.findViewById(R.id.changeImageId);
        avatarImg = headerView.findViewById(R.id.avatarImgId);
        editUsername = headerView.findViewById(R.id.editUsernameId);

        auth = FirebaseAuth.getInstance();
        user = auth.getCurrentUser();
        userRef = FirebaseDatabase.getInstance().getReference("users")
                .child(FirebaseAuth.getInstance().getCurrentUser().getUid());

        if (user == null) {
            Intent intent = new Intent(getApplicationContext(), LoginActivity.class);
            startActivity(intent);
            finish();
        } else {
            emailTextView.setText(user.getEmail());
        }

        // Lấy username từ Realtime Database khi Activity được tạo
        userRef.child("username").addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                if (dataSnapshot.exists()) {
                    String retrievedUsername = dataSnapshot.getValue(String.class);
                    userName.setText(retrievedUsername);
                } else {
                    String userNameString = emailTextView.getText().toString().split("@")[0];
                    userName.setText(userNameString);
                }
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
                Toast.makeText(MainActivity.this, "Tải tên người dùng thất bại!.", Toast.LENGTH_SHORT).show();
            }
        });

        editUsername.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                final EditText input = new EditText(MainActivity.this);
                input.setText(userName.getText().toString());

                new AlertDialog.Builder(MainActivity.this)
                        .setTitle("Đổi username")
                        .setMessage("Hãy nhập username mới:")
                        .setView(input)
                        .setPositiveButton("Lưu", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                String newUsername = input.getText().toString().trim();
                                if (newUsername.isEmpty()) {
                                    Toast.makeText(MainActivity.this, "Username không được để trống", Toast.LENGTH_SHORT).show();
                                } else {
                                    // Proceed with the update
                                    userName.setText(newUsername);

                                    userRef.child("username").setValue(newUsername)
                                            .addOnCompleteListener(task -> {
                                                if (task.isSuccessful()) {
                                                    Toast.makeText(MainActivity.this, "Cập nhật username thành công", Toast.LENGTH_SHORT).show();
                                                } else {
                                                    Toast.makeText(MainActivity.this, "Cập nhật username thất bại", Toast.LENGTH_SHORT).show();
                                                }
                                            });
                                    dialog.dismiss(); // Dismiss the dialog after a successful update
                                }
                            }
                        })
                        .setNegativeButton("Hủy", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                dialog.cancel();
                            }
                        })
                        .show();
            }
        });

        userRef.child("profileImageUrl").addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                String imageUrl = dataSnapshot.getValue(String.class);
                if (imageUrl != null) {
                    Glide.with(MainActivity.this).load(imageUrl).apply(RequestOptions.circleCropTransform()).into(avatarImg);
                    avatarImg.setTag(imageUrl);
                }
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
            }
        });

        changeImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(MainActivity.this, UploadAvatarImage.class);
                String currentImageUrl = (avatarImg.getTag() != null) ? avatarImg.getTag().toString() : null;
                i.putExtra("currentImageUrl", currentImageUrl);
                startActivityForResult(i, 1001);
            }
        });



        // Lấy username từ Realtime Database khi Activity được tạo
        userRef.child("username").addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                if (dataSnapshot.exists()) {
                    String retrievedUsername = dataSnapshot.getValue(String.class);
                    userName.setText(retrievedUsername);
                } else {
                    String userNameString = emailTextView.getText().toString().split("@")[0];
                    userName.setText(userNameString);
                }
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
                Toast.makeText(MainActivity.this, "Tải username thất bại.", Toast.LENGTH_SHORT).show();
            }
        });


        userRef.child("profileImageUrl").addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                String imageUrl = dataSnapshot.getValue(String.class);
                if (imageUrl != null) {
                    Glide.with(MainActivity.this).load(imageUrl).apply(RequestOptions.circleCropTransform()).into(avatarImg);
                    avatarImg.setTag(imageUrl);
                }
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
            }
        });

        changeImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(MainActivity.this, UploadAvatarImage.class);
                String currentImageUrl = (avatarImg.getTag() != null) ? avatarImg.getTag().toString() : null;
                i.putExtra("currentImageUrl", currentImageUrl);
                startActivityForResult(i, 1001);
            }
        });

        // Thiết lập BottomNavigation và xử lý sự kiện chuyển đổi Fragment
        viewPager = findViewById(R.id.viewPager);
        ViewPagerAdapter viewPagerAdapter = new ViewPagerAdapter(getSupportFragmentManager(), getLifecycle());
        viewPager.setAdapter(viewPagerAdapter);

        viewPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageSelected(int position) {
                super.onPageSelected(position);
                if (position == 0) {
                    bottomNavigationView.setSelectedItemId(R.id.cards);
                } else if (position == 1) {
                    bottomNavigationView.setSelectedItemId(R.id.words);
                } else if (position == 2) {
                    bottomNavigationView.setSelectedItemId(R.id.choices);
                } else if (position == 3) {
                    bottomNavigationView.setSelectedItemId(R.id.library);
                }
            }
        });

        bottomNavigationView = findViewById(R.id.bottomNavigationView);
        bottomNavigationView.setBackground(null);

        viewPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageSelected(int position) {
                super.onPageSelected(position);
            }
        });

        bottomNavigationView.setOnItemSelectedListener(item -> {
            if (item.getItemId() == R.id.cards) {
                viewPager.setCurrentItem(0);
            } else if (item.getItemId() == R.id.words) {
                viewPager.setCurrentItem(1);
            } else if (item.getItemId() == R.id.choices) {
                viewPager.setCurrentItem(2);
            } else if (item.getItemId() == R.id.library) {
                viewPager.setCurrentItem(3);
            }
            return true;
        });

        // Khởi tạo FloatingActionButton và thiết lập sự kiện mở menu
        fab = findViewById(R.id.fab);
        fab.setOnClickListener(view -> {
            BottomSheetDialog bottomSheetDialog = new BottomSheetDialog(MainActivity.this);
            bottomSheetDialog.setContentView(R.layout.bottom_sheet_layout);

            TextView item1 = bottomSheetDialog.findViewById(R.id.item1);
            TextView item2 = bottomSheetDialog.findViewById(R.id.item2);

            item1.setOnClickListener(v -> {
                Intent intent = new Intent(this, AddTopicActivity.class);
                startActivity(intent);
                finish();
                bottomSheetDialog.dismiss();
            });

            item2.setOnClickListener(v -> {
                showAddFolderDialog();
                bottomSheetDialog.dismiss();
            });

            bottomSheetDialog.show();
        });
    }

    public void showAddFolderDialog() {
        LayoutInflater dialogInflater = getLayoutInflater();
        View dialogView = dialogInflater.inflate(R.layout.dialog_add_folder, null);

        // Tạo AlertDialog
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setView(dialogView)
                .create();

        // Lấy các View từ layout dialog
        EditText editFolderName = dialogView.findViewById(R.id.edit_folder_name);
        Button btnCancel = dialogView.findViewById(R.id.btn_cancel);
        Button btnOk = dialogView.findViewById(R.id.btn_ok);

        // Xử lý sự kiện nút Hủy
        btnCancel.setOnClickListener(view -> dialog.dismiss());

        // Xử lý sự kiện nút OK
        btnOk.setOnClickListener(view -> {
            String folderName = editFolderName.getText().toString();
            if (!folderName.isEmpty()) {
                // Gửi dữ liệu đến ViewModel
                sharedViewModel.setFolderData(folderName);
                Toast.makeText(MainActivity.this, "Thêm folder thành công", Toast.LENGTH_SHORT).show();
                // Chuyển sang tab Library
                viewPager.setCurrentItem(3);
                dialog.dismiss();
            } else {
                editFolderName.requestFocus();
                editFolderName.setError("Tên thư mục không được để trống");
            }
        });

        // Hiển thị dialog
        dialog.show();
    }

    @Override
    public boolean onNavigationItemSelected(@NonNull MenuItem item) {
        int id = item.getItemId();
        if (id == R.id.nav_logout) {
            FirebaseAuth.getInstance().signOut();
            Intent intent = new Intent(MainActivity.this, LoginActivity.class);
            startActivity(intent);
            finish();
            return true;
        }
        if(id == R.id.nav_change_password){
            Intent i = new Intent(MainActivity.this, ChangePassword.class);
            startActivity(i);
        }
        if(id == R.id.nav_settings){
            Intent i = new Intent(MainActivity.this, SettingActivity.class);
            startActivity(i);
        }
        if (id == R.id.nav_about) {
            Intent i = new Intent(MainActivity.this, AboutActivity.class);
            startActivity(i);
        }
        drawerLayout.closeDrawer(GravityCompat.START);
        return true;
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 1001 && resultCode == RESULT_OK && data != null) {
            String imageUrl = data.getStringExtra("imageUrl");
            if (imageUrl != null) {
                Glide.with(this).load(imageUrl).apply(RequestOptions.circleCropTransform()).into(avatarImg);
                avatarImg.setTag(imageUrl);  // Save URL in ImageView's tag for persistence

                // Save URL to Firebase for persistence across sessions
                userRef.child("profileImageUrl").setValue(imageUrl);
            }
        }
    }


}
