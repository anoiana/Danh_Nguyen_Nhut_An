package com.example.login.fragment;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.login.R;
import com.example.login.adapter.VocabularyAdapter;
import com.example.login.model.SharedViewModel;
import com.example.login.model.Word;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.List;

public class FavouriteWordFragment extends Fragment {

    private RecyclerView recyclerView;
    private SharedViewModel sharedViewModel;
    private VocabularyAdapter adapter;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        sharedViewModel = new ViewModelProvider(requireActivity()).get(SharedViewModel.class);
        fetchAllWords();
    }

    @Override
    public void onResume() {
        super.onResume();
        fetchAllWords();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {

        View view = inflater.inflate(R.layout.fragment_favourite_word, container, false);
        recyclerView = view.findViewById(R.id.favouriteWordRecyclerViewId);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        adapter = new VocabularyAdapter(new ArrayList<>(), sharedViewModel, false);
        recyclerView.setAdapter(adapter);

        sharedViewModel.getFavoriteWords().observe(getViewLifecycleOwner(), favoriteWords -> {
            if (favoriteWords != null) {
                Log.d("FavouriteWordFragment", "Updating adapter with favorite words: " + favoriteWords);
                adapter.updateWords(favoriteWords);

            } else {
                Log.d("FavouriteWordFragment", "No favorite words to display.");
            }
        });
        return view;
    }

    private void fetchAllWords() {
        String userId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        DatabaseReference userTopicsRef = FirebaseDatabase.getInstance()
                .getReference("users")
                .child(userId)
                .child("topics");

        userTopicsRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                List<Word> allWords = new ArrayList<>();
                for (DataSnapshot topicSnapshot : dataSnapshot.getChildren()) {
                    DataSnapshot wordsSnapshot = topicSnapshot.child("words");
                    for (DataSnapshot wordSnapshot : wordsSnapshot.getChildren()) {
                        Word word = wordSnapshot.getValue(Word.class);
                        if (word != null) {
                            allWords.add(word);
                        }
                    }
                }
                Log.d("ALLWORDS", "All words for user: " + allWords);
                sharedViewModel.initializeFavoriteWords(allWords);
            }

            @Override
            public void onCancelled(@NonNull DatabaseError databaseError) {
                Log.e("ALLWORDS", "Failed to load words for user", databaseError.toException());
            }
        });
    }

}