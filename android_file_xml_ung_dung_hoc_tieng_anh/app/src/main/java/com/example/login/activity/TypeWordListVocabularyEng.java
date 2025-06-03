package com.example.login.activity;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.ListView;
import com.example.login.R;
import com.example.login.adapter.ViewListVocaularyAdapter;

public class TypeWordListVocabularyEng extends AppCompatActivity {

    private ViewListVocaularyAdapter correctAdapter;
    private ViewListVocaularyAdapter incorrectAdapter;
    private ListView listView;
    private CardView cvCorrect;
    private CardView cvIncorrect;
    private ImageView ivBack;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.multiple_choice_list_vocabulary);

        initializeViews();
        setupAdapters();
        setupListeners();
    }

    private void initializeViews() {
        listView = findViewById(R.id.list);
        cvCorrect = findViewById(R.id.cv_corect);
        cvIncorrect = findViewById(R.id.cv_incorect);
        ivBack = findViewById(R.id.iv_back);
    }

    private void setupAdapters() {
        correctAdapter = new ViewListVocaularyAdapter(this, TypeWordEnglish.CorrectWord);
        incorrectAdapter = new ViewListVocaularyAdapter(this, TypeWordEnglish.IncorrectWord);
        listView.setAdapter(incorrectAdapter); // Set default adapter
    }

    private void setupListeners() {
        cvCorrect.setOnClickListener(view -> {
            listView.setAdapter(correctAdapter);
            cvCorrect.setCardBackgroundColor(Color.parseColor("#EAF6FA"));
            cvIncorrect.setCardBackgroundColor(Color.parseColor("#FFFFFF"));
        });

        cvIncorrect.setOnClickListener(view -> {
            listView.setAdapter(incorrectAdapter);
            cvIncorrect.setCardBackgroundColor(Color.parseColor("#EAF6FA"));
            cvCorrect.setCardBackgroundColor(Color.parseColor("#FFFFFF"));
        });

        ivBack.setOnClickListener(view -> {
            TypeWordEnglish.CorrectWord.clear();
            TypeWordEnglish.IncorrectWord.clear();
            Intent intent = new Intent(TypeWordListVocabularyEng.this, MainActivity.class);
            startActivity(intent);
        });
    }
}