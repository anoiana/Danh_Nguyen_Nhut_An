package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.example.login.R;
import com.example.login.adapter.VocabularyAdapter;
import com.example.login.model.Account;
import com.example.login.model.SharedViewModel;
import com.example.login.model.Topic;
import com.example.login.model.Word;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.MutableData;
import com.google.firebase.database.Transaction;
import com.google.firebase.database.ValueEventListener;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;

public class VocabularyActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private VocabularyAdapter adapter;
    private Button cardButton, choiceButton, wordBtn;
    private List<Word> wordList;
    private List<Account> learners;
    private String currentUserId, userName, avatarPath;
    private ImageView backBtn, exportBtn, leaderBoardBtn;
    private DatabaseReference userRef, originalTopicRef;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_vocabulary);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });


        recyclerView = findViewById(R.id.vocabulary_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        SharedViewModel sharedViewModel = new ViewModelProvider(this).get(SharedViewModel.class);

        exportBtn = findViewById(R.id.export_csv_btn);
        leaderBoardBtn = findViewById(R.id.leader_board_btn);
        backBtn = findViewById(R.id.back_bnt);
        cardButton = findViewById(R.id.cards_button);
        choiceButton = findViewById(R.id.choices_button);
        wordBtn = findViewById(R.id.words_button);

        learners = (List<Account>) getIntent().getSerializableExtra("learners");
        wordList = (List<Word>) getIntent().getSerializableExtra("word_list");
        String topicId = getIntent().getStringExtra("topicId");
        boolean topicViewMode = getIntent().getBooleanExtra("topicMode", false);
        String ownerId = getIntent().getStringExtra("ownerId");
        String topicName = getIntent().getStringExtra("vocabulary_name");
        currentUserId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        boolean showLeader = getIntent().getBooleanExtra("showLeader", false);

        if (!showLeader) {
            leaderBoardBtn.setVisibility(View.GONE);
        }
        

        backBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Quay trở lại trang trước đó
                finish();
            }
        });

        exportBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                // Replace with your topicName
                File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
                File csvFile = new File(downloadsDir, topicName + ".csv");

                try (FileWriter writer = new FileWriter(csvFile)) {
                    // Write the header
                    writer.append("english,vietnamese,description\n");

                    // Write each word's data
                    for (Word word : wordList) {
                        writer.append(word.getEnglishWord()).append(",")
                                .append(word.getVietnameseMeaning()).append(",")
                                .append(word.getDescription() != null ? word.getDescription() : "").append("\n");
                    }

                    // Notify user
                    Toast.makeText(VocabularyActivity.this,
                            "Xuất file đến: " + csvFile.getAbsolutePath(),
                            Toast.LENGTH_LONG).show();

                } catch (IOException e) {
                    e.printStackTrace();
                    Toast.makeText(VocabularyActivity.this,
                            "Lỗi xuất file CSV: " + e.getMessage(),
                            Toast.LENGTH_LONG).show();
                }
            }
        });

        leaderBoardBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(VocabularyActivity.this, LeaderBoardActivity.class);
                intent.putExtra("learners", (java.io.Serializable) learners);
                startActivity(intent);
            }
        });


        cardButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                userRef = FirebaseDatabase.getInstance().getReference("users").child(currentUserId).child("topics").child(topicId);
                originalTopicRef = FirebaseDatabase.getInstance().getReference("users").child(ownerId).child("topics").child(topicId);

                userRef.addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(@NonNull DataSnapshot snapshot) {
                        if (snapshot.exists() || currentUserId.equals(ownerId)) {
                            DatabaseReference accountRef = FirebaseDatabase.getInstance().getReference("users").child(currentUserId);
                            // Fetch username and avatarPath together
                            accountRef.addListenerForSingleValueEvent(new ValueEventListener() {
                                @Override
                                public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                                    String userName = dataSnapshot.child("username").getValue(String.class);
                                    String avatarPath = dataSnapshot.child("profileImageUrl").getValue(String.class);

                                    if (userName == null) {
                                        userName = FirebaseAuth.getInstance().getCurrentUser().getEmail().split("@")[0];
                                    }

                                    // Create learner object and add to the learners list
                                    Account learner = new Account(userName, avatarPath);
                                    learner.setLearnerCorrectCount(0);
                                    originalTopicRef.child("learners").child(currentUserId).setValue(learner)
                                            .addOnSuccessListener(aVoid -> {
                                                // Allow learning if the topic is already added to the user's workspace
                                                Intent intent = new Intent(VocabularyActivity.this, StartCardActivity.class);
                                                intent.putExtra("word_list", (java.io.Serializable) wordList);
                                                startActivity(intent);
                                                finish();
                                            })
                                            .addOnFailureListener(e -> Log.e("AddLearner", "Failed to add user to learners list: " + e.getMessage()));
                                }

                                @Override
                                public void onCancelled(@NonNull DatabaseError databaseError) {
                                    Toast.makeText(VocabularyActivity.this, "Tải chi tiết user thất bại!", Toast.LENGTH_SHORT).show();
                                }
                            });
                        }
                        else {
                            // Prompt the user to add the topic and increment the user counter
                            new AlertDialog.Builder(VocabularyActivity.this)
                                    .setTitle("Học topic")
                                    .setMessage("Bạn có muốn học topic này?")
                                    .setPositiveButton("Yes", (dialog, which) -> {
                                        // Add the topic to the user's workspace
                                        Topic newTopic = new Topic(topicId, topicName, wordList.size(), topicViewMode, "");
                                        newTopic.setOwnerId(ownerId);
                                        newTopic.setForStudying(true);
                                        userRef.setValue(newTopic)
                                                .addOnSuccessListener(aVoid -> {
                                                    for (Word word : wordList) {
                                                        String wordId = word.getWordId();
                                                        if (wordId == null || wordId.isEmpty()) {
                                                            wordId = userRef.child("words").push().getKey();
                                                            word.setWordId(wordId); // Set generated ID in Word object
                                                        }
                                                        word.setCorrectCount(0);
                                                        userRef.child("words").child(wordId).setValue(word);
                                                    }

                                                    originalTopicRef.child("userCount").runTransaction(new Transaction.Handler() {
                                                        @NonNull
                                                        @Override
                                                        public Transaction.Result doTransaction(@NonNull MutableData currentData) {
                                                            Long currentCount = currentData.getValue(Long.class);
                                                            if (currentCount == null) {
                                                                currentData.setValue(1); // Initialize to 1 if it doesn't exist
                                                            } else {
                                                                currentData.setValue(currentCount + 1); // Increment by 1
                                                            }
                                                            return Transaction.success(currentData);
                                                        }

                                                        @Override
                                                        public void onComplete(DatabaseError error, boolean committed, DataSnapshot currentData) {
                                                            if (error == null && committed) {
                                                                Log.d("IncrementUserCount", "User count updated successfully: " + currentData.getValue());

                                                                // Add current user to the topic's learner list
                                                                String currentUserId = FirebaseAuth.getInstance().getCurrentUser().getUid();
                                                                addLearnerToTopic(currentUserId);
                                                            } else {
                                                                Log.e("IncrementUserCount", "Failed to update user count: " + (error != null ? error.getMessage() : "Unknown error"));
                                                            }
                                                        }
                                                    });
                                                })
                                                .addOnFailureListener(e ->
                                                        Toast.makeText(VocabularyActivity.this, "Failed to save topic: " + e.getMessage(), Toast.LENGTH_SHORT).show()
                                                );
                                    })
                                    .setNegativeButton("No", (dialog, which) -> dialog.dismiss())
                                    .show();

                        }
                    }

                    @Override
                    public void onCancelled(@NonNull DatabaseError error) {
                        Toast.makeText(VocabularyActivity.this, "Failed to check topic: " + error.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });

        choiceButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                userRef = FirebaseDatabase.getInstance().getReference("users").child(currentUserId).child("topics").child(topicId);
                originalTopicRef = FirebaseDatabase.getInstance().getReference("users").child(ownerId).child("topics").child(topicId);

                userRef.addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(@NonNull DataSnapshot snapshot) {
                        if (snapshot.exists() || currentUserId.equals(ownerId)) {
                            // Allow learning if the topic is already added to the user's workspace
                            if (wordList.size() < 4) {
                                Toast.makeText(VocabularyActivity.this, "Topic này không đủ từ vựng để học trắc nghiệm", Toast.LENGTH_SHORT).show();
                                return;
                            }
                            DatabaseReference accountRef = FirebaseDatabase.getInstance().getReference("users").child(currentUserId);
                            // Fetch username and avatarPath together
                            accountRef.addListenerForSingleValueEvent(new ValueEventListener() {
                                @Override
                                public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                                    String userName = dataSnapshot.child("username").getValue(String.class);
                                    String avatarPath = dataSnapshot.child("profileImageUrl").getValue(String.class);

                                    if (userName == null) {
                                        userName = FirebaseAuth.getInstance().getCurrentUser().getEmail().split("@")[0];
                                    }

                                    // Create learner object and add to the learners list
                                    Account learner = new Account(userName, avatarPath);
                                    learner.setLearnerCorrectCount(0);
                                    originalTopicRef.child("learners").child(currentUserId).setValue(learner)
                                            .addOnSuccessListener(aVoid -> {
                                                Intent intent = new Intent(VocabularyActivity.this, MultipleChoiceStartActivity.class);
                                                intent.putExtra("owner_id", ownerId);
                                                intent.putExtra("topic_id", topicId);
                                                intent.putExtra("word_list", (java.io.Serializable) wordList);
                                                startActivity(intent);
                                                finish();
                                            })
                                            .addOnFailureListener(e -> Log.e("AddLearner", "Failed to add user to learners list: " + e.getMessage()));
                                }

                                @Override
                                public void onCancelled(@NonNull DatabaseError databaseError) {
                                    Toast.makeText(VocabularyActivity.this, "Failed to load user details.", Toast.LENGTH_SHORT).show();
                                }
                            });
                        }
                        else {
                            // Prompt the user to add the topic and increment the user counter
                            new AlertDialog.Builder(VocabularyActivity.this)
                                    .setTitle("Học topic")
                                    .setMessage("Bạn có muốn học topic này?")
                                    .setPositiveButton("Yes", (dialog, which) -> {
                                        // Add the topic to the user's workspace
                                        Topic newTopic = new Topic(topicId, topicName, wordList.size(), topicViewMode, "");
                                        newTopic.setOwnerId(ownerId);
                                        newTopic.setForStudying(true);
                                        userRef.setValue(newTopic)
                                                .addOnSuccessListener(aVoid -> {
                                                    for (Word word : wordList) {
                                                        String wordId = word.getWordId();
                                                        if (wordId == null || wordId.isEmpty()) {
                                                            wordId = userRef.child("words").push().getKey();
                                                            word.setWordId(wordId); // Set generated ID in Word object
                                                        }
                                                        word.setCorrectCount(0);
                                                        userRef.child("words").child(wordId).setValue(word);
                                                    }

                                                    originalTopicRef.child("userCount").runTransaction(new Transaction.Handler() {
                                                        @NonNull
                                                        @Override
                                                        public Transaction.Result doTransaction(@NonNull MutableData currentData) {
                                                            Long currentCount = currentData.getValue(Long.class);
                                                            if (currentCount == null) {
                                                                currentData.setValue(1); // Initialize to 1 if it doesn't exist
                                                            } else {
                                                                currentData.setValue(currentCount + 1); // Increment by 1
                                                            }
                                                            return Transaction.success(currentData);
                                                        }

                                                        @Override
                                                        public void onComplete(DatabaseError error, boolean committed, DataSnapshot currentData) {
                                                            if (error == null && committed) {
                                                                Log.d("IncrementUserCount", "User count updated successfully: " + currentData.getValue());

                                                                // Add current user to the topic's learner list
                                                                String currentUserId = FirebaseAuth.getInstance().getCurrentUser().getUid();
                                                                addLearnerToTopic(currentUserId);
                                                            } else {
                                                                Log.e("IncrementUserCount", "Failed to update user count: " + (error != null ? error.getMessage() : "Unknown error"));
                                                            }
                                                        }
                                                    });
                                                })
                                                .addOnFailureListener(e ->
                                                        Toast.makeText(VocabularyActivity.this, "Failed to save topic: " + e.getMessage(), Toast.LENGTH_SHORT).show()
                                                );
                                    })
                                    .setNegativeButton("No", (dialog, which) -> dialog.dismiss())
                                    .show();
                        }
                    }

                    @Override
                    public void onCancelled(@NonNull DatabaseError error) {
                        Toast.makeText(VocabularyActivity.this, "Kiểm tra topic thất bại!: " + error.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });

        wordBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                userRef = FirebaseDatabase.getInstance().getReference("users").child(currentUserId).child("topics").child(topicId);
                originalTopicRef = FirebaseDatabase.getInstance().getReference("users").child(ownerId).child("topics").child(topicId);

                userRef.addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(@NonNull DataSnapshot snapshot) {
                        if (snapshot.exists() || currentUserId.equals(ownerId)) {
                            DatabaseReference accountRef = FirebaseDatabase.getInstance().getReference("users").child(currentUserId);
                            // Fetch username and avatarPath together
                            accountRef.addListenerForSingleValueEvent(new ValueEventListener() {
                                @Override
                                public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                                    String userName = dataSnapshot.child("username").getValue(String.class);
                                    String avatarPath = dataSnapshot.child("profileImageUrl").getValue(String.class);

                                    if (userName == null) {
                                        userName = FirebaseAuth.getInstance().getCurrentUser().getEmail().split("@")[0];
                                    }

                                    // Create learner object and add to the learners list
                                    Account learner = new Account(userName, avatarPath);
                                    learner.setLearnerCorrectCount(0);
                                    originalTopicRef.child("learners").child(currentUserId).setValue(learner)
                                            .addOnSuccessListener(aVoid -> {
                                                // Allow learning if the topic is already added to the user's workspace
                                                Intent intent = new Intent(VocabularyActivity.this, TypeWord.class);
                                                intent.putExtra("owner_id", ownerId);
                                                intent.putExtra("topicId", topicId);
                                                startActivity(intent);
                                                finish();
                                            })
                                            .addOnFailureListener(e -> Log.e("AddLearner", "Failed to add user to learners list: " + e.getMessage()));
                                }

                                @Override
                                public void onCancelled(@NonNull DatabaseError databaseError) {
                                    Toast.makeText(VocabularyActivity.this, "Tải user thất bại!", Toast.LENGTH_SHORT).show();
                                }
                            });
                        }
                        else {
                            // Prompt the user to add the topic and increment the user counter
                            new AlertDialog.Builder(VocabularyActivity.this)
                                    .setTitle("Học topic")
                                    .setMessage("Bạn có muốn học topic này?")
                                    .setPositiveButton("Yes", (dialog, which) -> {
                                        // Add the topic to the user's workspace
                                        Topic newTopic = new Topic(topicId, topicName, wordList.size(), topicViewMode, "");
                                        newTopic.setOwnerId(ownerId);
                                        newTopic.setForStudying(true);
                                        userRef.setValue(newTopic)
                                                .addOnSuccessListener(aVoid -> {
                                                    for (Word word : wordList) {
                                                        String wordId = word.getWordId();
                                                        if (wordId == null || wordId.isEmpty()) {
                                                            wordId = userRef.child("words").push().getKey();
                                                            word.setWordId(wordId); // Set generated ID in Word object
                                                        }
                                                        word.setCorrectCount(0);
                                                        userRef.child("words").child(wordId).setValue(word);
                                                    }

                                                    originalTopicRef.child("userCount").runTransaction(new Transaction.Handler() {
                                                        @NonNull
                                                        @Override
                                                        public Transaction.Result doTransaction(@NonNull MutableData currentData) {
                                                            Long currentCount = currentData.getValue(Long.class);
                                                            if (currentCount == null) {
                                                                currentData.setValue(1); // Initialize to 1 if it doesn't exist
                                                            } else {
                                                                currentData.setValue(currentCount + 1); // Increment by 1
                                                            }
                                                            return Transaction.success(currentData);
                                                        }

                                                        @Override
                                                        public void onComplete(DatabaseError error, boolean committed, DataSnapshot currentData) {
                                                            if (error == null && committed) {
                                                                Log.d("IncrementUserCount", "User count updated successfully: " + currentData.getValue());

                                                                // Add current user to the topic's learner list
                                                                String currentUserId = FirebaseAuth.getInstance().getCurrentUser().getUid();
                                                                addLearnerToTopic(currentUserId);
                                                            } else {
                                                                Log.e("IncrementUserCount", "Failed to update user count: " + (error != null ? error.getMessage() : "Unknown error"));
                                                            }
                                                        }
                                                    });
                                                })
                                                .addOnFailureListener(e ->
                                                        Toast.makeText(VocabularyActivity.this, "Lưu topic thất bại: " + e.getMessage(), Toast.LENGTH_SHORT).show()
                                                );
                                    })
                                    .setNegativeButton("No", (dialog, which) -> dialog.dismiss())
                                    .show();
                        }
                    }

                    @Override
                    public void onCancelled(@NonNull DatabaseError error) {
                        Toast.makeText(VocabularyActivity.this, "Kiểm tra topic thất bại: " + error.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });

        recyclerView = findViewById(R.id.vocabulary_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new VocabularyAdapter(wordList , sharedViewModel, topicId, topicViewMode, ownerId);
        recyclerView.setAdapter(adapter);

        String vocabularyName = getIntent().getStringExtra("vocabulary_name");
        TextView textView = findViewById(R.id.app_title_text_view);

        if (vocabularyName != null) {
            textView.setText(vocabularyName);
        }

        // Khởi tạo adapter và gán cho RecyclerView
        recyclerView.setAdapter(adapter);
    }

    private void addLearnerToTopic(String userId) {
        DatabaseReference accountRef = FirebaseDatabase.getInstance().getReference("users").child(userId);

        // Fetch username and avatarPath together
        accountRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                String userName = dataSnapshot.child("username").getValue(String.class);
                String avatarPath = dataSnapshot.child("profileImageUrl").getValue(String.class);

                if (userName == null) {
                    userName = FirebaseAuth.getInstance().getCurrentUser().getEmail().split("@")[0];
                }

                // Create learner object and add to the learners list
                Account learner = new Account(userName, avatarPath);
                learner.setLearnerCorrectCount(0);
                originalTopicRef.child("learners").child(userId).setValue(learner)
                        .addOnSuccessListener(aVoid -> {
                            Log.d("AddLearner", "User added to learners list");
                            Toast.makeText(VocabularyActivity.this, "Topic đã được thêm không gian làm việc của bạn!", Toast.LENGTH_SHORT).show();
                            startActivity(new Intent(VocabularyActivity.this, MainActivity.class));
                            finish();
                        })
                        .addOnFailureListener(e -> Log.e("AddLearner", "Failed to add user to learners list: " + e.getMessage()));
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
                Toast.makeText(VocabularyActivity.this, "Tải chi tiết user thất bại!", Toast.LENGTH_SHORT).show();
            }
        });
    }


}
