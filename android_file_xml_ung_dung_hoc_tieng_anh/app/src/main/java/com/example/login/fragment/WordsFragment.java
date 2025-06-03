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

/**
 * A simple {@link Fragment} subclass.
 * Use the {@link WordsFragment#newInstance} factory method to
 * create an instance of this fragment.
 */
public class WordsFragment extends Fragment {

    private RecyclerView recyclerView;
    private TopicAdapter topicAdapter;
    private List<Topic> topicList;
    private DatabaseReference userTopicsRef;
    private String userId;
    // TODO: Rename parameter arguments, choose names that match
    // the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
    private static final String ARG_PARAM1 = "param1";
    private static final String ARG_PARAM2 = "param2";

    // TODO: Rename and change types of parameters
    private String mParam1;
    private String mParam2;

    public WordsFragment() {
        // Required empty public constructor
    }

    /**
     * Use this factory method to create a new instance of
     * this fragment using the provided parameters.
     *
     * @param param1 Parameter 1.
     * @param param2 Parameter 2.
     * @return A new instance of fragment SubscriptionsFragment.
     */
    // TODO: Rename and change types and number of parameters
    public static WordsFragment newInstance(String param1, String param2) {
        WordsFragment fragment = new WordsFragment();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        args.putString(ARG_PARAM2, param2);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mParam1 = getArguments().getString(ARG_PARAM1);
            mParam2 = getArguments().getString(ARG_PARAM2);
        }
        userId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        userTopicsRef = FirebaseDatabase.getInstance().getReference("users").child(userId).child("topics");
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View view = inflater.inflate(R.layout.fragment_words, container, false);

        topicList = new ArrayList<>();
        topicAdapter = new TopicAdapter(getActivity(), topicList, false, false);

        recyclerView = view.findViewById(R.id.folder_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(getActivity()));
        recyclerView.setAdapter(topicAdapter);

        loadTopics();
        return view;
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
                    DataSnapshot wordsSnapshot = topicSnapshot.child("words");
                    for (DataSnapshot wordSnapshot : wordsSnapshot.getChildren()) {
                        Word word = wordSnapshot.getValue(Word.class);
                        if (word != null) {
                            wordList.add(word);
                        }
                    }
                    topic.setWords(wordList); // Gắn danh sách từ vựng vào topic

                    topicList.add(topic);
                }
                topicAdapter.notifyDataSetChanged(); // Cập nhật RecyclerView
            }

            @Override
            public void onCancelled(@NonNull DatabaseError error) {
//                Toast.makeText(getActivity(), "Failed to load topics", Toast.LENGTH_SHORT).show();
                Log.e("WordsFragment", "Error loading public topics: " + error.getMessage());
            }
        });
    }
}