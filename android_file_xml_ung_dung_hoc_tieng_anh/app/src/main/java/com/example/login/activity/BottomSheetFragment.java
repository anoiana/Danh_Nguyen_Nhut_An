package com.example.login.activity;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.adapter.FolderAdapter;
import com.example.login.model.Folder;
import com.google.android.material.bottomsheet.BottomSheetDialogFragment;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.List;

public class BottomSheetFragment extends BottomSheetDialogFragment {

    private FolderAdapter folderAdapter;
    private String userId;
    private List<Folder> folderList;
    private DatabaseReference databaseFolders;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        // Inflate the Bottom Sheet layout
        View view = inflater.inflate(R.layout.bottom_sheet_with_list_folder, container, false);

        // Lấy userId của người dùng hiện tại
        FirebaseAuth firebaseAuth = FirebaseAuth.getInstance();
        if (firebaseAuth.getCurrentUser() != null) {
            userId = firebaseAuth.getCurrentUser().getUid();
            databaseFolders = FirebaseDatabase.getInstance().getReference("users").child(userId).child("folders");
        } else {
            Toast.makeText(requireContext(), "Người dùng chưa đăng nhập", Toast.LENGTH_SHORT).show();
            dismiss(); // Đóng BottomSheet nếu không có người dùng
            return view;
        }

        folderList = new ArrayList<>();
        folderAdapter = new FolderAdapter(requireContext(), folderList, null);

        // Setup RecyclerView
        RecyclerView recyclerView = view.findViewById(R.id.folder_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(requireContext()));
        recyclerView.setAdapter(folderAdapter);

        // Load dữ liệu từ Firebase
        loadFolders();

        return view;
    }

    private void loadFolders() {
        if (databaseFolders != null) {
            databaseFolders.addValueEventListener(new ValueEventListener() {
                @SuppressLint("NotifyDataSetChanged")
                @Override
                public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                    folderList.clear(); // Xóa danh sách cũ
                    for (DataSnapshot snapshot : dataSnapshot.getChildren()) {
                        Folder folder = snapshot.getValue(Folder.class);
                        if (folder != null) {
                            folderList.add(folder);
                        }
                    }
                    folderAdapter.notifyDataSetChanged(); // Cập nhật RecyclerView
                }

                @Override
                public void onCancelled(@NonNull DatabaseError error) {
                    Toast.makeText(requireContext(), "Không thể tải dữ liệu: " + error.getMessage(), Toast.LENGTH_SHORT).show();
                }
            });
        } else {
            Toast.makeText(requireContext(), "Database không khả dụng", Toast.LENGTH_SHORT).show();
        }
    }
}
