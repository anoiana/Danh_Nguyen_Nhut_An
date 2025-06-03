package com.example.login.fragment;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.adapter.FolderAdapter;
import com.example.login.model.Folder;
import com.example.login.model.SharedViewModel;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.List;

public class FolderFragment extends Fragment implements FolderAdapter.OnFolderDeletedListener {
    private RecyclerView recyclerView;
    private FolderAdapter folderAdapter;
    private List<Folder> folderList;
    private DatabaseReference databaseFolders;
    private String userId;
    private SharedViewModel sharedViewModel;


    // Thêm biến để lưu trữ dữ liệu nhận được từ BroadcastReceiver
    private String newFolderName;
    private String newFolderDescription;

    @Override
    public void onFolderDeleted() {
        loadFolders();
    }

    public FolderFragment() {
        // Required empty public constructor
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        userId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        databaseFolders = FirebaseDatabase.getInstance().getReference("users").child(userId).child("folders");

        // Khởi tạo ViewModel
        sharedViewModel = new ViewModelProvider(requireActivity()).get(SharedViewModel.class);

        // Lắng nghe thay đổi dữ liệu từ ViewModel
        sharedViewModel.getFolderName().observe(this, folderName -> {
            if (folderName != null) {
                addFolder(folderName);
            }
        });
    }

    // Phương thức hiển thị hộp thoại xác nhận
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View mView = inflater.inflate(R.layout.fragment_folder, container, false);

        folderList = new ArrayList<>();
        folderAdapter = new FolderAdapter(getActivity(), folderList, this);

        recyclerView = mView.findViewById(R.id.folder_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(getActivity()));
        recyclerView.setAdapter(folderAdapter);

        loadFolders(); // Tải danh sách thư mục

        return mView;
    }

    // Thêm folder mới vào Firebase
    private void addFolder(String folderName) {
        String folderId = databaseFolders.push().getKey(); // Tạo ID duy nhất cho thư mục
        Folder newFolder = new Folder(folderId, folderName, userId, null); // null cho topicList

        // Thêm thư mục mới vào Firebase
        databaseFolders.child(folderId).setValue(newFolder).addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                loadFolders(); // Cập nhật danh sách thư mục
            } else {
                Toast.makeText(getActivity(), "Có lỗi khi thêm folder", Toast.LENGTH_SHORT).show();
            }
        });
    }

    // Tải danh sách folder từ Firebase
    private void loadFolders() {
        databaseFolders.addValueEventListener(new ValueEventListener() {
            @SuppressLint("NotifyDataSetChanged")
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                folderList.clear(); // Clear list để tránh lặp
                for (DataSnapshot snapshot : dataSnapshot.getChildren()) {
                    Folder folder = snapshot.getValue(Folder.class);
                    folderList.add(folder);
                }
                folderAdapter.notifyDataSetChanged();
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
//                Toast.makeText(getActivity(), "Không đọc được folder", Toast.LENGTH_SHORT).show();
                Log.e("FolderFragment", "Error loading public topics: " + error.getMessage());
            }
        });
    }
}
