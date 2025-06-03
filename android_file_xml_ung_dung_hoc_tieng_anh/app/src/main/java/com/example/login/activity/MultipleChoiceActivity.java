package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.example.login.R;
import com.example.login.model.Word;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

public class MultipleChoiceActivity extends AppCompatActivity {

    private List<Word> wordList;
    private int currentIndex = 0;
    private String questionLanguage, topicId, userId, ownerId;
    private int score = 0;
    private TextView questionText, scoreText;
    private CardView card1, card2, card3, card4;
    private TextView choice1, choice2, choice3, choice4;
    private ImageView goBackButton;
    public static ArrayList<Word> CorrectWord = new ArrayList<Word>();
    public static ArrayList<Word> IncorrectWord = new ArrayList<Word>();
    private TextToSpeech textToSpeech;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_multiple_choice);
        CorrectWord.clear();
        IncorrectWord.clear();
        // Retrieve data from intent
        topicId = getIntent().getStringExtra("topic_id");
        ownerId = getIntent().getStringExtra("owner_id");
        wordList = (List<Word>) getIntent().getSerializableExtra("word_list");
        questionLanguage = getIntent().getStringExtra("question_language");
        userId = Objects.requireNonNull(FirebaseAuth.getInstance().getCurrentUser()).getUid();

        textToSpeech = new TextToSpeech(this, status -> {
            if (status != TextToSpeech.SUCCESS) {
                Toast.makeText(this, "Khởi tạo chuyển đổi văn bản thành giọng nói thất bại!", Toast.LENGTH_SHORT).show();
            }
        });

        // Shuffle word list once
        Collections.shuffle(wordList);

        // Bind views
        questionText = findViewById(R.id.text_question);
        scoreText = findViewById(R.id.score);
        goBackButton = findViewById(R.id.goBackBtn);

        goBackButton.setOnClickListener(view -> {
            // Add dialog to ask if user want to exist here
            new AlertDialog.Builder(this)
                    .setTitle("Thoát khỏi làm trắc nghiệm")
                    .setMessage("Bạn có chắc là muốn thoát? Quá trình làm bài sẽ bị mất.")
                    .setPositiveButton("Có", (dialog, which) -> finish())
                    .setNegativeButton("Không", null)
                    .show();
        });


        card1 = findViewById(R.id.card1);
        card2 = findViewById(R.id.card2);
        card3 = findViewById(R.id.card3);
        card4 = findViewById(R.id.card4);

        choice1 = (TextView) card1.findViewById(R.id.text1);
        choice2 = (TextView) card2.findViewById(R.id.text2);
        choice3 = (TextView) card3.findViewById(R.id.text3);
        choice4 = (TextView) card4.findViewById(R.id.text4);

        // Start the first question
        loadNewQuestion();
    }

    private void loadNewQuestion() {
        if (currentIndex >= wordList.size()) {
            // Update correct counts in the database
            updateCorrectCountsInDatabase();

            // Navigate to the result screen
            Intent intent = new Intent(MultipleChoiceActivity.this, MultipleChoiceViewResult.class);
            intent.putExtra("topic_id", topicId);
            intent.putExtra("owner_id", ownerId);
            intent.putExtra("score", score);
            intent.putExtra("word_list", (java.io.Serializable) wordList);
            startActivity(intent);
            finish();

            return;
        }


        // Get the current question
        Word currentQuestion = wordList.get(currentIndex);

        // Generate four choices
        List<String> choices = new ArrayList<>();
        if ("ENGLISH".equals(questionLanguage)) {
            questionText.setText(currentQuestion.getEnglishWord());
            choices.add(currentQuestion.getVietnameseMeaning()); // Add correct answer

            // Add three random incorrect answers
            for (Word word : wordList) {
                if (!word.getVietnameseMeaning().equals(currentQuestion.getVietnameseMeaning())
                        && choices.size() < 4) {
                    choices.add(word.getVietnameseMeaning());
                }
            }
        } else {
            questionText.setText(currentQuestion.getVietnameseMeaning());
            choices.add(currentQuestion.getEnglishWord()); // Add correct answer

            // Add three random incorrect answers
            for (Word word : wordList) {
                if (!word.getEnglishWord().equals(currentQuestion.getEnglishWord())
                        && choices.size() < 4) {
                    choices.add(word.getEnglishWord());
                }
            }
        }

        // Shuffle choices and display
        Collections.shuffle(choices);
        choice1.setText(choices.get(0));
        choice2.setText(choices.get(1));
        choice3.setText(choices.get(2));
        choice4.setText(choices.get(3));

        // Set click listeners
        setChoiceListeners(choices, currentQuestion);
        currentIndex++; // Move to the next question
    }

    private void setChoiceListeners(List<String> choices, Word currentQuestion) {
        View.OnClickListener listener = view -> {
            TextView selectedChoice = (TextView) ((CardView) view).getChildAt(0);
            String selectedText = selectedChoice.getText().toString();

            if (("ENGLISH".equals(questionLanguage) && selectedText.equals(currentQuestion.getVietnameseMeaning()))
                    || ("VIETNAMESE".equals(questionLanguage) && selectedText.equals(currentQuestion.getEnglishWord()))) {
                // Correct answer
                CorrectWord.add(currentQuestion);
                score++;
                SpeechAutomatical(currentQuestion.getEnglishWord());
                Toast.makeText(this, "Correct!", Toast.LENGTH_SHORT).show();
            } else {
                // Incorrect answer
                IncorrectWord.add(currentQuestion);
                Toast.makeText(this, "Wrong!", Toast.LENGTH_SHORT).show();
            }

            // Update score and load a new question
            scoreText.setText("Score: " + score);
            loadNewQuestion();
        };

        card1.setOnClickListener(listener);
        card2.setOnClickListener(listener);
        card3.setOnClickListener(listener);
        card4.setOnClickListener(listener);
    }

    public void SpeechAutomatical(String word) {
        textToSpeech = new TextToSpeech(this, new TextToSpeech.OnInitListener() {
            @Override
            public void onInit(int status) {
                if (status == TextToSpeech.SUCCESS) {
                    int langResult = textToSpeech.setLanguage(Locale.US);
                    if (langResult == TextToSpeech.LANG_MISSING_DATA || langResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                        Toast.makeText(MultipleChoiceActivity.this, "Giọng đọc văn bản không được hỗ trợ ", Toast.LENGTH_SHORT).show();
                    } else {
                        speak(word);
                    }
                } else {
                    Toast.makeText(MultipleChoiceActivity.this, "Khởi tạo chuyển đổi văn bản thành giọng nói thất bại!", Toast.LENGTH_SHORT).show();
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
                    Toast.makeText(this, "\n" + "Không thể cập nhật số lần đúng cho từ: " + word.getEnglishWord(), Toast.LENGTH_SHORT).show();
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
                Toast.makeText(this, "Cập nhật thất bại!", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

