package com.example.login.model;


import androidx.annotation.NonNull;

import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;
import com.google.firebase.firestore.auth.User;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

public class Topic {
    private String topicId;
    private String topicName;
    private int wordCount;
    private boolean viewMode;
    private String createdTime;  // Changed to String
    private String ownerId;
    private List<Word> words;
    private int userCount;
    private List<Account> learners;
    private boolean forStudying = false;

    public boolean isForStudying() {
        return forStudying;
    }

    public void setForStudying(boolean forStudying) {
        this.forStudying = forStudying;
    }

    public List<Account> getLearners() {
        return learners;
    }

    public void setLearners(List<Account> learners) {
        this.learners = learners;
    }

    public int getUserCount() {
        return userCount;
    }

    public void setUserCount(int userCount) {
        this.userCount = userCount;
    }

    // Default constructor for Firebase
    public Topic() {}

    // Constructor with parameters
    public Topic(String topicId, String topicName, int wordCount, boolean viewMode,
                 String createdTime, List<Word> words) {
        this.topicId = topicId;
        this.topicName = topicName;
        this.wordCount = wordCount;
        this.viewMode = viewMode;
        this.createdTime = createdTime;
        this.words = words;
    }

    public Topic(String topicId, String topicName, int wordCount, boolean viewMode,
                 String createdTime) {
        this.topicId = topicId;
        this.topicName = topicName;
        this.wordCount = wordCount;
        this.viewMode = viewMode;
        this.createdTime = createdTime;
    }

    // Getters and Setters
    public List<Word> getWords() {
        return words;
    }

    public void setWords(List<Word> words) {
        this.words = words;
    }

    public String getTopicId() {
        return topicId;
    }

    public void setTopicId(String topicId) {
        this.topicId = topicId;
    }

    public String getTopicName() {
        return topicName;
    }

    public void setTopicName(String topicName) {
        this.topicName = topicName;
    }

    public boolean isViewMode() {
        return viewMode;
    }

    public void setViewMode(boolean viewMode) {
        this.viewMode = viewMode;
    }

    public int getWordCount() {
        return wordCount;
    }

    public void setWordCount(int wordCount) {
        this.wordCount = wordCount;
    }

    public String getCreatedTime() {
        return createdTime;
    }

    public void setCreatedTime(String createdTime) {
        this.createdTime = createdTime;
    }

    // Helper method to set the current date/time as a string
    public void setCreatedTimeAsCurrent() {
        this.createdTime = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                .format(new Date());  // Sets current time in ISO 8601 format
    }

    public String getOwnerId() {
        return ownerId;
    }

    public void setOwnerId(String ownerId) {
        this.ownerId = ownerId;
    }

    // Method to retrieve the owner's username from Firebase
    public void fetchOwnerUsername(Callback<String> callback) {
        DatabaseReference userRef = FirebaseDatabase.getInstance().getReference("users").child(getOwnerId()).child("username");
        userRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot snapshot) {
                if (snapshot.exists()) {
                    String username = snapshot.getValue(String.class);
                    callback.onSuccess(username);
                } else {
                    callback.onFailure("Username not found");
                }
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
                callback.onFailure(error.getMessage());
            }
        });
    }

    // Method to retrieve the owner's profile image URL from Firebase
    public void fetchOwnerProfileImageUrl(Callback<String> callback) {
        DatabaseReference userRef = FirebaseDatabase.getInstance().getReference("users").child(getOwnerId()).child("profileImageUrl");
        userRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot snapshot) {
                if (snapshot.exists()) {
                    String profileImageUrl = snapshot.getValue(String.class);
                    callback.onSuccess(profileImageUrl);
                } else {
                    callback.onFailure("Profile image URL not found");
                }
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
                callback.onFailure(error.getMessage());
            }
        });
    }

    // Callback interface for async data retrieval
    public interface Callback<T> {
        void onSuccess(T result);
        void onFailure(String errorMessage);
    }
}
