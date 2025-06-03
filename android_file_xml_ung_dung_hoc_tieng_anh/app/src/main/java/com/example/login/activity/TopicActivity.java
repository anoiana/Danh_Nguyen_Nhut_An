package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.adapter.TopicAdapter;
import com.example.login.adapter.TopicInFolderAdapter;
import com.example.login.fragment.TopicBottomSheetFragment;
import com.example.login.model.Topic;
import com.example.login.model.Word;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

public class TopicActivity extends BaseActivity implements TopicBottomSheetFragment.OnTopicsUpdatedListener {

    private RecyclerView recyclerView;
    private TopicInFolderAdapter adapter;
    private List<Topic> topicList;
    private ImageView addTopicToFolderBtn;
    private DatabaseReference userFoldersRef, topicsRef, databaseReference;
    private String userId;
    HashSet<String> currentTopicIds = new HashSet<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_topic);
        addTopicToFolderBtn = findViewById(R.id.add_bnt);
        userId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        databaseReference = FirebaseDatabase.getInstance().getReference("users").child(userId);


        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });


        // Get database references
        userFoldersRef = FirebaseDatabase.getInstance().getReference("users").child(userId).child("folders");
        topicsRef = FirebaseDatabase.getInstance().getReference("users").child(userId).child("topics");

        recyclerView = findViewById(R.id.topic_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        Intent intent = getIntent();
        String folderId = intent.getStringExtra("folder_id");

        // Fetch and display topic details
        if (folderId != null) {
            fetchTopicIds(folderId);
            fetchAndDisplayTopics(folderId);
        }

        topicList = new ArrayList<>();
        adapter = new TopicInFolderAdapter(this, topicList, topicId -> {
            currentTopicIds.remove(topicId);
        });
        recyclerView.setAdapter(adapter);

        String folderName = intent.getStringExtra("folder_name");
        TextView textView = findViewById(R.id.app_title_text_view);
        if (folderName != null) {
            textView.setText(folderName);
        }

        ImageView backBtn = findViewById(R.id.back_bnt);
        backBtn.setOnClickListener(v -> finish());

        addTopicToFolderBtn.setOnClickListener(view -> {
            TopicBottomSheetFragment fragment = TopicBottomSheetFragment.newInstance(folderId, currentTopicIds);
            fragment.show(getSupportFragmentManager(), "TopicBottomSheetFragment");
        });


    }

    private void fetchTopicIds(String folderId) {
        databaseReference.child("folders").child(folderId).child("topics")
                .addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(DataSnapshot dataSnapshot) {
                        if (dataSnapshot.exists()) {
                            for (DataSnapshot topicSnapshot : dataSnapshot.getChildren()) {
                                String topicId = topicSnapshot.getValue(String.class);
                                if (topicId != null) {
                                    currentTopicIds.add(topicId);
                                }
                            }
                        } else {

                        }
                    }

                    @Override
                    public void onCancelled(DatabaseError databaseError) {
                        Toast.makeText(TopicActivity.this, "Không thể lấy danh sách chủ đề: " + databaseError.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void fetchAndDisplayTopics(String folderId) {
        // Fetch topic IDs from the folder
        userFoldersRef.child(folderId).child("topics")
                .addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(DataSnapshot dataSnapshot) {
                        if (dataSnapshot.exists()) {
                            topicList.clear(); // Clear the current list
                            for (DataSnapshot topicIdSnapshot : dataSnapshot.getChildren()) {
                                String currTopicId = topicIdSnapshot.getValue(String.class);
                                if (currTopicId != null) {
                                    // Fetch details of the topic from the global "topics" node
                                    loadTopics(currTopicId);
                                }
                            }
                        }
                    }

                    @Override
                    public void onCancelled(DatabaseError databaseError) {
                        Toast.makeText(TopicActivity.this, "Không thể lấy danh sách topic: " + databaseError.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                });
    }


    private void loadTopics(String currTopicId) {
        topicsRef.child(currTopicId).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot snapshot) {
                // Check if the snapshot exists
                if (snapshot.exists()) {
                    // Extract topic details
                    String topicId = snapshot.getKey();
                    String title = snapshot.child("topicName").getValue(String.class);
                    int wordCount = (int) snapshot.child("words").getChildrenCount();
                    String createdTime = snapshot.child("createdTime").getValue(String.class);
                    String ownerId = snapshot.child("ownerId").getValue(String.class);
                    boolean isActive = snapshot.child("viewMode").getValue(Boolean.class) != null
                            ? snapshot.child("viewMode").getValue(Boolean.class) : true;

                    Topic topic = new Topic(topicId, title, wordCount, isActive, createdTime);
                    topic.setOwnerId(ownerId);

                    // Load words for this topic
                    List<Word> wordList = new ArrayList<>();
                    DataSnapshot wordsSnapshot = snapshot.child("words");
                    for (DataSnapshot wordSnapshot : wordsSnapshot.getChildren()) {
                        Word word = wordSnapshot.getValue(Word.class);
                        if (word != null) {
                            wordList.add(word);
                        }
                    }
                    topic.setWords(wordList); // Assign the word list to the topic

                    topicList.add(topic);
                    adapter.notifyDataSetChanged(); // Notify the adapter of changes
                } else {
                    Toast.makeText(TopicActivity.this, "Topic không tìm thấy: " + currTopicId, Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
                Toast.makeText(TopicActivity.this, "Không thể lấy chi tiết danh sách topic: " + error.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onTopicsUpdated() {
        if (currentTopicIds.isEmpty()) {
            topicList.clear(); // Clear the list if no topics remain
            adapter.notifyDataSetChanged(); // Notify adapter of the change
            return;
        }

        // Otherwise, fetch and reload the topics
        topicList.clear(); // Clear the existing list
        for (String topicId : currentTopicIds) {
            loadTopics(topicId); // Re-fetch topic details from Firebase
        }
        adapter.notifyItemRangeRemoved(0, topicList.size());

    }


}