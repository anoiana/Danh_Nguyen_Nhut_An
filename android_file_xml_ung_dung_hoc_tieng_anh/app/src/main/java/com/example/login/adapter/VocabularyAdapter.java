package com.example.login.adapter;

import android.graphics.Color;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.example.login.R;
import com.example.login.fragment.FavouriteWordFragment;
import com.example.login.model.SharedViewModel;
import com.example.login.model.Word;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

public class VocabularyAdapter extends RecyclerView.Adapter<VocabularyAdapter.VocabularyViewHolder> {

    private List<Word> vocabularys;
    private FirebaseUser user;
    private SharedViewModel sharedViewModel;
    private String topicId;
    private TextToSpeech textToSpeech;
    private boolean isPublicTopic;
    private String ownerId;

    public VocabularyAdapter(List<Word> vocabularys, SharedViewModel sharedViewModel, String topicId, boolean isPublicTopic, String ownerId) {
        this.vocabularys = vocabularys;
        this.sharedViewModel = sharedViewModel;
        this.user = FirebaseAuth.getInstance().getCurrentUser();
        this.topicId = topicId;
        this.isPublicTopic = isPublicTopic; // Initialize the flag
        this.ownerId = ownerId;
    }

    public VocabularyAdapter(List<Word> vocabularys, SharedViewModel sharedViewModel, boolean isPublicTopic) {
        this(vocabularys, sharedViewModel, null, isPublicTopic, null);
    }

    @NonNull
    @Override
    public VocabularyAdapter.VocabularyViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_vocabulary, parent, false);

        textToSpeech = new TextToSpeech(parent.getContext(), new TextToSpeech.OnInitListener() {
            @Override
            public void onInit(int status) {
                if (status == TextToSpeech.SUCCESS) {
                    textToSpeech.setLanguage(Locale.ENGLISH);
                } else {
                    Log.e("TextToSpeech", "Initialization failed");
                }
            }
        });

        return new VocabularyAdapter.VocabularyViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull VocabularyAdapter.VocabularyViewHolder holder, int position) {
        Word word = vocabularys.get(position);
        holder.vocabularyName.setText(word.getEnglishWord());
        holder.vocabMeaning.setText(word.getVietnameseMeaning());

        int correctCount = word.getCorrectCount();
        if (correctCount == -1) {
            holder.vocabLevel.setVisibility(View.GONE);
        }
        if (correctCount < 5 && correctCount != 0) {
            holder.vocabLevel.setText("(Đang học)");
            holder.vocabLevel.setTextColor(Color.YELLOW);
        }
        else if (correctCount >= 5) {
            holder.vocabLevel.setText("(Đã thành thạo)");
            holder.vocabLevel.setTextColor(Color.GREEN);
        }

        String userId = user.getUid();

        // Hide the favorite button if the topic is public
        if (isPublicTopic && !userId.equals(ownerId)) {
            holder.favouriteWord.setVisibility(View.GONE);
        }
        else {
            holder.favouriteWord.setVisibility(View.VISIBLE); // Ensure visibility in non-public topics
            holder.favouriteWord.setImageResource(word.isStarred() ? R.drawable.baseline_star_24 : R.drawable.gray_star_24);
            holder.favouriteWord.setOnClickListener(view -> {
                int currentPosition = holder.getAdapterPosition();
                if (currentPosition != RecyclerView.NO_POSITION) {
                    Word currentWord = vocabularys.get(currentPosition);
                    boolean newStarredStatus = !currentWord.isStarred();
                    currentWord.setStarred(newStarredStatus);
                    holder.favouriteWord.setImageResource(newStarredStatus ? R.drawable.baseline_star_24 : R.drawable.gray_star_24);
                    notifyItemChanged(currentPosition);

                    FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
                    if (user == null) {
                        Log.e("FirebaseUpdateNew", "User is not authenticated.");
                        return;
                    }

                    if (userId != null) {
                        DatabaseReference userTopicsRef = FirebaseDatabase.getInstance()
                                .getReference("users")
                                .child(userId)
                                .child("topics");

                        userTopicsRef.addListenerForSingleValueEvent(new ValueEventListener() {
                            @Override
                            public void onDataChange(@NonNull DataSnapshot dataSnapshot) {
                                for (DataSnapshot topicSnapshot : dataSnapshot.getChildren()) {
                                    DataSnapshot wordsSnapshot = topicSnapshot.child("words");
                                    for (DataSnapshot wordSnapshot : wordsSnapshot.getChildren()) {
                                        if (wordSnapshot.getKey().equals(currentWord.getWordId())) {
                                            // Update the starred status
                                            wordSnapshot.getRef().child("starred").setValue(newStarredStatus)
                                                    .addOnSuccessListener(aVoid -> {
                                                        sharedViewModel.toggleFavorite(currentWord);
                                                        Log.d("FirebaseUpdate", "Successfully updated starred status for wordId: " + currentWord.getWordId());
                                                    })
                                                    .addOnFailureListener(e -> Log.e("FirebaseUpdate", "Failed to update starred status", e));
                                            return;
                                        }
                                    }
                                }
                                Log.d("FirebaseUpdate", "Word with wordId: " + currentWord.getWordId() + " not found in any topic.");
                            }

                            @Override
                            public void onCancelled(@NonNull DatabaseError databaseError) {
                                Log.e("FirebaseUpdate", "Failed to read topics", databaseError.toException());
                            }
                        });
                    } else {
                        Log.e("FirebaseUpdate", "User ID or Topic ID is null. Cannot update Firebase.");
                    }
                }
            });
        }


        holder.audioBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (textToSpeech != null && !textToSpeech.isSpeaking()) {
                    textToSpeech.speak(word.getEnglishWord(), TextToSpeech.QUEUE_FLUSH, null, null);
                } else {
                    Toast.makeText(view.getContext(), "Text-to-Speech is not ready or is currently speaking.", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }


    @Override
    public int getItemCount() {
        if (vocabularys != null)
            return vocabularys.size();
        return 0;
    }

    @Override
    public void onDetachedFromRecyclerView(@NonNull RecyclerView recyclerView) {
        super.onDetachedFromRecyclerView(recyclerView);
        if (textToSpeech != null) {
            textToSpeech.stop();
            textToSpeech.shutdown();
        }
    }

    public void updateWords(List<Word> newWords) {
        this.vocabularys.clear();
        this.vocabularys.addAll(newWords);
        notifyDataSetChanged();
    }

    public static class VocabularyViewHolder extends RecyclerView.ViewHolder {
        TextView vocabularyName, vocabMeaning, vocabLevel;
        ImageButton favouriteWord;
        ImageButton editBtn, deleteBtn, audioBtn;

        public VocabularyViewHolder(@NonNull View itemView) {
            super(itemView);
            vocabularyName = itemView.findViewById(R.id.vocabulary_name);
            favouriteWord = itemView.findViewById(R.id.favouriteBtnId);
            editBtn = itemView.findViewById(R.id.edit_btn);
            deleteBtn = itemView.findViewById(R.id.delete_btn);
            audioBtn = itemView.findViewById(R.id.audio_btn);
            vocabMeaning = itemView.findViewById(R.id.vocabulary_meaning);
            vocabLevel = itemView.findViewById(R.id.vocabulary_level);
        }
    }
}