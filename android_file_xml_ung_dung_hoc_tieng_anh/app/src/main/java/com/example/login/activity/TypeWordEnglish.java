package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import android.text.Editable;
import android.text.TextWatcher;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

import com.example.login.R;
import com.example.login.model.Word;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.MutableData;
import com.google.firebase.database.Transaction;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

public class TypeWordEnglish extends AppCompatActivity {

    ImageView btnGoBack;
    String topicId, userId, ownerId;
    TextView question;
    EditText answer;
    Button completeBtn;
    public static int score = 0;
    int currentIndex = 0;
    TextView scoreTv;
    TextView currentState;
    View feedbackLayout;
    TextView correcWord;
    ImageView shuffleBtn;
    private Button hintBtn;
    private int hintCount = 0;
    private String currentWord = "";
    private String currentHint = "";
    private TextToSpeech textToSpeech;
    public static ArrayList<Word> CorrectWord = new ArrayList<Word>();
    public static ArrayList<Word> IncorrectWord = new ArrayList<Word>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_type_word_english);
        userId = Objects.requireNonNull(FirebaseAuth.getInstance().getCurrentUser()).getUid();
        ownerId = getIntent().getStringExtra("owner_id");
        topicId = getIntent().getStringExtra("topicId");
        btnGoBack = findViewById(R.id.goBackBtnId);
        hintBtn = findViewById(R.id.hintBtn);
        answer = findViewById(R.id.edt_answer);
        getVocabularies(topicId);

        answer.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.length() > 0 && s.length() <= currentHint.length()) {
                    StringBuilder newText = new StringBuilder(currentHint);
                    for (int i = 0; i < s.length(); i++) {
                        newText.setCharAt(i, s.charAt(i));
                    }
                    currentHint = newText.toString();
                    answer.removeTextChangedListener(this);
                    answer.setText(currentHint);
                    answer.setSelection(s.length());
                    answer.addTextChangedListener(this);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });

        hintBtn.setOnClickListener(view -> provideHint());

        score = 0;
        CorrectWord.clear();
        IncorrectWord.clear();

        textToSpeech = new TextToSpeech(this, status -> {
            if (status != TextToSpeech.SUCCESS) {
                showToast("Text-to-Speech initialization failed.");
            }
        });

        btnGoBack.setOnClickListener(view -> {
            score = 0;
            finish();
        });
    }

    private boolean Question(Word word) {
        question.setText(word.getVietnameseMeaning());
        String userAnswer = answer.getText().toString().trim();
        if (userAnswer.isEmpty()) {
            return false;
        }
        return userAnswer.equalsIgnoreCase(word.getEnglishWord().trim());
    }

    private void getVocabularies(String topicId) {
        DatabaseReference myRef = FirebaseDatabase.getInstance().getReference("users")
                .child(userId)
                .child("topics")
                .child(topicId)
                .child("words");

        myRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                ArrayList<Word> vocabularies = new ArrayList<>();
                for (DataSnapshot snapshot : dataSnapshot.getChildren()) {
                    Word vocabulary = snapshot.getValue(Word.class);
                    if (vocabulary != null) {
                        vocabulary.setWordId(snapshot.getKey());
                        vocabularies.add(vocabulary);
                    } else {
                        showToast("Vocabulary is null");
                    }
                }
                Log.d("testVocabularies", String.valueOf(vocabularies));
                if (vocabularies.isEmpty()) {
                    showToast("No vocabularies available.");
                    finish();
                    return;
                }

                shuffleBtn = findViewById(R.id.iv_shuffle);
                shuffleBtn.setOnClickListener(view -> {
                    if (currentIndex < vocabularies.size()) {
                        List<Word> remainingWords = vocabularies.subList(currentIndex, vocabularies.size());

                        Collections.shuffle(remainingWords);

                        for (int i = 0; i < remainingWords.size(); i++) {
                            vocabularies.set(currentIndex + i, remainingWords.get(i));
                        }

                        showToast("Shuffled remaining vocabularies");
                        answer.setText("");
                        updateUI(vocabularies);
                    } else {
                        showToast("No remaining words to shuffle");
                    }
                });

                if (currentIndex < vocabularies.size()) {
                    updateUI(vocabularies);
                    completeBtn.setOnClickListener(view -> handleAnswer(vocabularies));
                } else {
                    Intent intent = new Intent(TypeWordEnglish.this, TypeWordResult.class);
                    startActivity(intent);
                }
            }
            @Override
            public void onCancelled(DatabaseError databaseError) {
                showToast("Database error: " + databaseError.getMessage());
            }
        });
    }

    private void updateUI(ArrayList<Word> vocabularies) {
        question = findViewById(R.id.textViewWord);
        completeBtn = findViewById(R.id.CompleteAnswerBtnId);
        scoreTv = findViewById(R.id.score);
        answer = findViewById(R.id.edt_answer);
        currentState = findViewById(R.id.currentState);

        Word currenWordObj = vocabularies.get(currentIndex);
        currentWord = currenWordObj.getEnglishWord();
        hintCount = 0;

        question.setText(vocabularies.get(currentIndex).getVietnameseMeaning());
        scoreTv.setText("Score: " + score);
        currentState.setText((currentIndex + 1) + "/" + vocabularies.size());
    }

    private void provideHint() {
        if (hintCount < 3) {
            hintCount++;
            StringBuilder hint = new StringBuilder();
            for (int i = 0; i < currentWord.length(); i++) {
                if (i < hintCount) {
                    hint.append(currentWord.charAt(i));
                } else {
                    hint.append(" ");
                }
            }
            answer.setText(hint.toString().trim());
            answer.setSelection(hintCount);
        } else {
            showToast("No more hints available");
        }
    }
    private void handleAnswer(ArrayList<Word> vocabularies) {
        Word currentWord = vocabularies.get(currentIndex);

        if (Question(currentWord)) {
            Log.d("Feedback", "Showing correct feedback for: " + currentWord.getEnglishWord());
            CorrectWord.add(currentWord);
            score += 1;
            showFeedback(R.layout.feedback_correct_type_word, currentWord.getEnglishWord(), vocabularies);
            SpeechAutomatical(currentWord.getEnglishWord());
        } else {
            Log.d("Feedback", "Showing incorrect feedback for: " + currentWord.getEnglishWord());
            IncorrectWord.add(currentWord);
            showFeedback(R.layout.feedback_incorrect_type_word, currentWord.getEnglishWord(), vocabularies);
        }
    }

    private void showFeedback(int layoutId, String correctTerm, ArrayList<Word> vocabularies) {
        feedbackLayout = getLayoutInflater().inflate(layoutId, null);
        correcWord = feedbackLayout.findViewById(R.id.tv_correct_word);
        if (correcWord != null) {
            correcWord.setText(correctTerm);
        } else {
            Log.e("TypeWordEnglish", "TextView with ID tv_correct_word not found in layout.");
            return;
        }

        ViewGroup rootView = findViewById(android.R.id.content);
        rootView.addView(feedbackLayout);

        feedbackLayout.setVisibility(View.VISIBLE);

        new Handler().postDelayed(() -> {
            feedbackLayout.setVisibility(View.GONE);
            answer.setText("");
            currentIndex++;
            if (currentIndex < vocabularies.size()) {
                updateUI(vocabularies);
            } else {
                // Update correctCount in Firebase
                updateCorrectCountsInDatabase();
                Intent intent = new Intent(TypeWordEnglish.this, TypeWordResult.class);
                intent.putExtra("score", score);
                intent.putExtra("totalQuestions", vocabularies.size());
                startActivity(intent);
                finish();
            }
        }, 2000);
    }

    private void showToast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }

    public void SpeechAutomatical(String word) {
        textToSpeech = new TextToSpeech(this, new TextToSpeech.OnInitListener() {
            @Override
            public void onInit(int status) {
                if (status == TextToSpeech.SUCCESS) {
                    int langResult = textToSpeech.setLanguage(Locale.US);
                    if (langResult == TextToSpeech.LANG_MISSING_DATA || langResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                        Toast.makeText(TypeWordEnglish.this, "Text-to-Speech is not supported on your device.", Toast.LENGTH_SHORT).show();
                    } else {
                        speak(word);
                    }
                } else {
                    Toast.makeText(TypeWordEnglish.this, "Text-to-Speech initialization failed.", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    private void speak(String text) {
        if (textToSpeech != null) {
            textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, null, null);
        }
    }

    private void updateCorrectCountsInDatabase() {
        // Get the database reference
        DatabaseReference databaseReference = FirebaseDatabase.getInstance().getReference();

        // Loop through the CorrectWord list and update correctCount in the RTDB
        for (Word word : CorrectWord) {
            String wordId = word.getWordId(); // Get the word's ID

            // Path to the specific word in the RTDB (adjust the path according to your structure)
            DatabaseReference wordRef = databaseReference.child("users")
                    .child(userId) // Replace with the actual owner ID dynamically
                    .child("topics")
                    .child(topicId) // Replace with the actual topic ID dynamically
                    .child("words")
                    .child(wordId);

            // Increment correctCount atomically
            wordRef.child("correctCount").get().addOnCompleteListener(task -> {
                if (task.isSuccessful() && task.getResult().exists()) {
                    Integer currentCount = task.getResult().getValue(Integer.class);
                    if (currentCount != null) {
                        wordRef.child("correctCount").setValue(currentCount + 1);
                    }
                } else {
                    // Handle error (word doesn't exist or other issue)
                    Toast.makeText(this, "Failed to update correctCount for word: " + word.getEnglishWord(), Toast.LENGTH_SHORT).show();
                }
            });
        }

        DatabaseReference topicRef = databaseReference.child("users")
                .child(ownerId)
                .child("topics")
                .child(topicId)
                .child("learners")
                .child(userId);

        topicRef.child("learnerCorrectCount").get().addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                if (task.getResult().exists()) {
                    // Node exists, increment the value
                    Integer currentCount = task.getResult().getValue(Integer.class);
                    if (currentCount != null) {
                        topicRef.child("learnerCorrectCount").setValue(currentCount + CorrectWord.size());
                    }
                } else {
                    // Node does not exist, set initial value to 1
                    topicRef.child("learnerCorrectCount").setValue(1);
                }
            } else {
                // Handle error (e.g., network issue)
                Toast.makeText(this, "Failed to update", Toast.LENGTH_SHORT).show();
            }
        });
    }

}