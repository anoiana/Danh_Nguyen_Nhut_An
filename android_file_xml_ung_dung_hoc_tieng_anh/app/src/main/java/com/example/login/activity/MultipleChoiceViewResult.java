package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.login.R;
import com.example.login.model.Word;

import java.util.List;

public class MultipleChoiceViewResult extends AppCompatActivity {
    private TextView scoreLabel;
    private Button restartBtn, quizDetailBtn;
    private ImageView goBackBtn;
    private String topicId, ownerId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_multiple_choice_view_result); // Use the same layout

        // Get the score and total questions from intent
        topicId = getIntent().getStringExtra("topic_id");
        ownerId = getIntent().getStringExtra("owner_id");
        int score = getIntent().getIntExtra("score", 0);
        List<Word> wordList = (List<Word>) getIntent().getSerializableExtra("word_list");

        // Bind views
        scoreLabel = findViewById(R.id.scoreLable);
        restartBtn = findViewById(R.id.restartQuiz);
        quizDetailBtn = findViewById(R.id.quizDetail);
        goBackBtn = findViewById(R.id.goBackBtn);
        scoreLabel.setText("Điểm của bạn: " + score + "/" + wordList.size()); // Score label

        restartBtn.setOnClickListener(v -> {
            Intent intent = new Intent(MultipleChoiceViewResult.this, MultipleChoiceActivity.class);
            intent.putExtra("topic_id", topicId);
            intent.putExtra("owner_id", ownerId);
            intent.putExtra("word_list", (java.io.Serializable) wordList);
            startActivity(intent);
            finish();
        });

        goBackBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                finish();
            }
        });

        quizDetailBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MultipleChoiceViewResult.this, MultipleChoiceResultDetailActivity.class);
                startActivity(intent);
            }
        });
    }
}