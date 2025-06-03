package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.ImageView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

import com.example.login.R;
import com.example.login.model.Word;

import java.io.Serializable;
import java.util.List;


// This activity allow users to decide question type (question in English and 4 choices in Vietnamese and vice versa)
public class MultipleChoiceStartActivity extends AppCompatActivity {
    private Button englishButton, vietButton;
    private List<Word> wordList;
    private ImageView goBackButton;
    private String topicId, ownerId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_multiple_choice_start);

        englishButton = findViewById(R.id.answerInEnglishBtnId);
        vietButton = findViewById(R.id.answerInVietnameseBtnId);
        goBackButton = findViewById(R.id.goBackBtn);

        topicId = getIntent().getStringExtra("topic_id");
        ownerId = getIntent().getStringExtra("owner_id");
        wordList = (List<Word>) getIntent().getSerializableExtra("word_list");

        // Start activity with English as question
        englishButton.setOnClickListener(v -> {
            Intent intent = new Intent(MultipleChoiceStartActivity.this, MultipleChoiceActivity.class);
            intent.putExtra("owner_id", ownerId);
            intent.putExtra("topic_id", topicId);
            intent.putExtra("word_list", (Serializable) wordList);
            intent.putExtra("question_language", "ENGLISH");
            startActivity(intent);
        });

        // Start activity with Vietnamese as question
        vietButton.setOnClickListener(v -> {
            Intent intent = new Intent(MultipleChoiceStartActivity.this, MultipleChoiceActivity.class);
            intent.putExtra("owner_id", ownerId);
            intent.putExtra("topic_id", topicId);
            intent.putExtra("word_list", (Serializable) wordList);
            intent.putExtra("question_language", "VIETNAMESE");
            startActivity(intent);
        });

        goBackButton.setOnClickListener(view -> {
            finish();
        });
    }

}