package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.login.R;

public class TypeWord extends AppCompatActivity {

    Button typeWordEngBtn, typeWordVietBtn;
    ImageView goBackBtn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_type_word);

        typeWordEngBtn = findViewById(R.id.typeWordEngBtnId);
        typeWordVietBtn = findViewById(R.id.typeWordVietBtnId);
        goBackBtn = findViewById(R.id.goBackBtnId);
        String topicId = getIntent().getStringExtra("topicId");
        String ownerId = getIntent().getStringExtra("owner_id");

        typeWordEngBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(TypeWord.this, TypeWordEnglish.class);
                i.putExtra("owner_id", ownerId);
                i.putExtra("topicId", topicId);
                startActivity(i);
            }
        });

        typeWordVietBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(TypeWord.this, TypeWordViet.class);
                i.putExtra("owner_id", ownerId);
                i.putExtra("topicId", topicId);
                startActivity(i);
            }
        });

        goBackBtn.setOnClickListener(view -> finish());

    }
}