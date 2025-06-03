package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.login.R;

public class TypeWordResultViet extends AppCompatActivity {

    ImageView btnGoBack;
    TextView scoreTv;
    Button watchDetailBtn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_type_word_result_viet);

        scoreTv = findViewById(R.id.scoreId);
        watchDetailBtn = findViewById(R.id.watchDetailBtn);
        btnGoBack = findViewById(R.id.goBackBtn);
        int score = getIntent().getIntExtra("score", 0);
        int totalQuestions = getIntent().getIntExtra("totalQuestions", 0);
        scoreTv.setText(" " + score + "/" + totalQuestions);

        watchDetailBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(TypeWordResultViet.this, TypeWordListVocabularyViet.class);
                startActivity(intent);
            }
        });

        btnGoBack.setOnClickListener(view -> {
            finish();
        });
    }

}