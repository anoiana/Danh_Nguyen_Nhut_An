package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.login.R;
import com.example.login.model.Word;

import java.util.List;

public class StartCardActivity extends AppCompatActivity {

    Button buttonStart;
    ImageView imageBack;
    List<Word> wordList;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_start_play_card);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        wordList = (List<Word>) getIntent().getSerializableExtra("word_list");
        if (wordList == null || wordList.isEmpty()) {
            Toast.makeText(this , "Không có từ", Toast.LENGTH_SHORT).show();
        }

        imageBack = findViewById(R.id.exitButton);
        buttonStart = findViewById(R.id.btnStart);
        buttonStart.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(StartCardActivity.this, CardGame.class); // Thay CurrentActivity và NewActivity bằng tên của các Activity của bạn
                intent.putExtra("word_list", (java.io.Serializable) wordList);
                startActivity(intent); // Bắt đầu Activity mới
                finish();
            }
        });


        imageBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                finish();
            }
        });
    }
}