package com.example.login.fragment;

import android.content.Context;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import com.example.login.R;
import com.example.login.adapter.TopicToAddAdapter;
import com.example.login.model.Topic;
import com.google.android.material.bottomsheet.BottomSheetDialogFragment;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class TopicBottomSheetFragment extends BottomSheetDialogFragment {

    private RecyclerView recyclerView;
    private TopicToAddAdapter adapter;
    private final List<Topic> topicList = new ArrayList<>();
    private String folderId;
    private OnTopicsUpdatedListener listener;
    private static HashSet<String> m_currentTopicIds;

    public interface OnTopicsUpdatedListener {
        void onTopicsUpdated();
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        if (context instanceof OnTopicsUpdatedListener) {
            listener = (OnTopicsUpdatedListener) context;
        } else {
            throw new RuntimeException(context.toString() + " must implement OnTopicsUpdatedListener");
        }
    }

    public static TopicBottomSheetFragment newInstance(String folderId, HashSet<String> currentTopicIds) {
        TopicBottomSheetFragment fragment = new TopicBottomSheetFragment();
        Bundle args = new Bundle();
        args.putString("folderId", folderId);
        fragment.setArguments(args);
        m_currentTopicIds = currentTopicIds; // Clone for safety
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            folderId = getArguments().getString("folderId");
        }
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_topic_bottom_sheet, container, false);

        recyclerView = view.findViewById(R.id.topic_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        adapter = new TopicToAddAdapter(getContext(), topicList, m_currentTopicIds);
        recyclerView.setAdapter(adapter);

        view.findViewById(R.id.confirm_button).setOnClickListener(v -> confirmSelection());

        loadTopicsFromFirebase();

        return view;
    }

    private void loadTopicsFromFirebase() {
        String userId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        DatabaseReference topicRef = FirebaseDatabase.getInstance()
                .getReference("users")
                .child(userId)
                .child("topics");

        topicRef.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot snapshot) {
                topicList.clear();
                for (DataSnapshot topicSnapshot : snapshot.getChildren()) {
                    String topicId = topicSnapshot.getKey();
                    String topicName = topicSnapshot.child("topicName").getValue(String.class);

                    Topic topic = new Topic();
                    topic.setTopicId(topicId);
                    topic.setTopicName(topicName);

                    topicList.add(topic);
                }
                adapter.notifyDataSetChanged();
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
//                Toast.makeText(getContext(), "Failed to load topics: " + error.getMessage(), Toast.LENGTH_SHORT).show();
                Log.e("BottomSheetFragment", "Error loading public topics: " + error.getMessage());
            }
        });
    }

    private void confirmSelection() {
        HashSet<String> selectedTopicIds = adapter.getSelectedTopics();
        String userId = FirebaseAuth.getInstance().getCurrentUser().getUid();

        DatabaseReference folderRef = FirebaseDatabase.getInstance()
                .getReference("users")
                .child(userId)
                .child("folders")
                .child(folderId)
                .child("topics");

        folderRef.setValue(new ArrayList<>(selectedTopicIds)).addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                Toast.makeText(getContext(), "Topics updated successfully", Toast.LENGTH_SHORT).show();
                if (listener != null) {
                    listener.onTopicsUpdated(); // Notify parent activity
                }
                dismiss();
            } else {
                Toast.makeText(getContext(), "Failed to update topics", Toast.LENGTH_SHORT).show();
            }
        });
    }

}
