package com.example.login.fragment;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.PopupMenu;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.Toast;

import com.example.login.R;
import com.example.login.activity.BottomSheetFragment;
import com.example.login.adapter.FolderAdapter;
import com.example.login.adapter.TopicAdapter;
import com.example.login.model.Account;
import com.example.login.model.Folder;
import com.example.login.model.SharedViewModel;
import com.example.login.model.Topic;
import com.example.login.model.Word;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.List;

public class TopicFragment extends Fragment {
    private RecyclerView recyclerView;
    private TopicAdapter topicAdapter;
    private List<Topic> topicList;
    private DatabaseReference userTopicsRef;
    private String userId;

    public TopicFragment() {
        // Required empty public constructor
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        userId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        userTopicsRef = FirebaseDatabase.getInstance().getReference("users").child(userId).child("topics");
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View mView = inflater.inflate(R.layout.fragment_topic, container, false);
        ImageView menuIcon = mView.findViewById(R.id.menu_icon);

        topicList = new ArrayList<>();
        topicAdapter = new TopicAdapter(getActivity(), topicList, false, false);

        recyclerView = mView.findViewById(R.id.folder_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(getActivity()));
        recyclerView.setAdapter(topicAdapter);

        loadTopics();

        // Đặt sự kiện nhấn cho menuIcon
        menuIcon.setOnClickListener(v -> {
            // Hiển thị một menu dạng PopupMenu
            PopupMenu popupMenu = new PopupMenu(requireContext(), menuIcon);
            popupMenu.getMenuInflater().inflate(R.menu.menu_folder_options, popupMenu.getMenu());
            popupMenu.setOnMenuItemClickListener(item -> {
                if (item.getItemId() == R.id.action_add_folder) {
                    // Hiển thị BottomSheetFragment khi chọn "Thêm thư mục"
                    BottomSheetFragment bottomSheetFragment = new BottomSheetFragment();
                    bottomSheetFragment.show(getParentFragmentManager(), "BottomSheetFragment");
                    return true;
                } else if (item.getItemId() == R.id.action_copy_topic) {
                    Toast.makeText(getContext(), "Sao chép chủ đề được chọn", Toast.LENGTH_SHORT).show();
                    return true;
                } else {
                    return false;
                }
            });
            popupMenu.show();
        });


        return mView;
    }

    private void loadTopics() {
        userTopicsRef.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot snapshot) {
                topicList.clear(); // Xoá danh sách hiện tại để tải lại
                for (DataSnapshot topicSnapshot : snapshot.getChildren()) {
                    String topicId = topicSnapshot.getKey();
                    String title = topicSnapshot.child("topicName").getValue(String.class);
                    int wordCount = (int) topicSnapshot.child("words").getChildrenCount();
                    String createdTime = topicSnapshot.child("createdTime").getValue(String.class);
                    String ownerId = topicSnapshot.child("ownerId").getValue(String.class);
                    boolean isActive = topicSnapshot.child("viewMode").getValue(Boolean.class) != null
                            ? topicSnapshot.child("viewMode").getValue(Boolean.class) : true;

                    Topic topic = new Topic(topicId, title, wordCount, isActive, createdTime);
                    topic.setOwnerId(ownerId);

                    // Load từ vựng cho topic
                    List<Word> wordList = new ArrayList<>();
                    DataSnapshot dataSnapshot = topicSnapshot.child("words");
                    for (DataSnapshot wordSnapshot : dataSnapshot.getChildren()) {
                        Word word = wordSnapshot.getValue(Word.class);
                        if (word != null) {
                            wordList.add(word);
                        }
                    }
                    topic.setWords(wordList); // Gắn danh sách từ vựng vào topic

                    List<Account> learners = new ArrayList<>();
                    dataSnapshot = topicSnapshot.child("learners");
                    for (DataSnapshot snapshot1 : dataSnapshot.getChildren()) {
                        Account account = new Account();
                        account.setLearnerCorrectCount(snapshot1.child("learnerCorrectCount").getValue(Integer.class));
                        account.setName(snapshot1.child("name").getValue(String.class));
                        account.setAvatarPath(snapshot1.child("avatarPath").getValue(String.class));
                        learners.add(account);
                    }

                    topic.setLearners(learners);

                    topicList.add(topic);
                }
                topicAdapter.notifyDataSetChanged(); // Cập nhật RecyclerView
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
//                Toast.makeText(getActivity(), "Failed to load topics", Toast.LENGTH_SHORT).show();
                Log.e("TopicFragment", "Error loading public topics: " + error.getMessage());
            }
        });
    }



}