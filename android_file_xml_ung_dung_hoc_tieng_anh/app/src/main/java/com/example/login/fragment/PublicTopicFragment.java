package com.example.login.fragment;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.adapter.TopicAdapter;
import com.example.login.model.Account;
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

public class PublicTopicFragment extends Fragment {

    private RecyclerView recyclerView;
    private TopicAdapter topicAdapter;
    private List<Topic> publicTopicList;
    private DatabaseReference usersRef;
    private String currentUserId;

    public PublicTopicFragment() {
        // Required empty public constructor
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        currentUserId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        usersRef = FirebaseDatabase.getInstance().getReference("users");
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View mView = inflater.inflate(R.layout.fragment_public_topic, container, false);

        publicTopicList = new ArrayList<>();
        topicAdapter = new TopicAdapter(getActivity(), publicTopicList, true, true);

        recyclerView = mView.findViewById(R.id.folder_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(getActivity()));
        recyclerView.setAdapter(topicAdapter);

        loadPublicTopics();

        return mView;
    }

    private void loadPublicTopics() {
        usersRef.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot snapshot) {
                publicTopicList.clear();
                for (DataSnapshot userSnapshot : snapshot.getChildren()) {
                    String userId = userSnapshot.getKey();

                    // Exclude current user's topics
                    if (userId != null && !userId.equals(currentUserId)) {
                        DataSnapshot topicsSnapshot = userSnapshot.child("topics");
                        for (DataSnapshot topicSnapshot : topicsSnapshot.getChildren()) {
                            String topicId = topicSnapshot.getKey();
                            String topicName = topicSnapshot.child("topicName").getValue(String.class);
                            boolean isPublic = topicSnapshot.child("viewMode").getValue(Boolean.class) != null
                                    && topicSnapshot.child("viewMode").getValue(Boolean.class);

                            boolean forStudying = topicSnapshot.child("forStudying").getValue(Boolean.class) != null
                                    && topicSnapshot.child("forStudying").getValue(Boolean.class);

                            if (!forStudying) {
                                if (isPublic) {
                                    int wordCount = (int) topicSnapshot.child("words").getChildrenCount();
                                    String createdTime = topicSnapshot.child("createdTime").getValue(String.class);
                                    Integer userCount = topicSnapshot.child("userCount").getValue(Integer.class);

                                    Topic topic = new Topic(topicId, topicName, wordCount, true, createdTime);
                                    topic.setOwnerId(userId);

                                    if (userCount != null) {
                                        topic.setUserCount(userCount);
                                    }

                                    // Load words for this topic
                                    List<Word> wordList = new ArrayList<>();
                                    DataSnapshot dataSnapshot = topicSnapshot.child("words");
                                    for (DataSnapshot wordSnapshot : dataSnapshot.getChildren()) {
                                        Word word = wordSnapshot.getValue(Word.class);
                                        word.setCorrectCount(-1);
                                        if (word != null) {
                                            wordList.add(word);
                                        }
                                    }
                                    topic.setWords(wordList); // Assign the word list to the topic

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

                                    publicTopicList.add(topic);
                                }
                            }

                        }
                    }
                }
                topicAdapter.notifyDataSetChanged();
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
//                Toast.makeText(getActivity(), "Failed to load public topics", Toast.LENGTH_SHORT).show();
                Log.e("PublicTopicFragment", "Error loading public topics: " + error.getMessage());
            }
        });
    }

}
