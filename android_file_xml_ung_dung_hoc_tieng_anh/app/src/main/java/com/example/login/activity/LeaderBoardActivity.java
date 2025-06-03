package com.example.login.activity;

import android.os.Bundle;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.adapter.LeaderBoardAdapter;
import com.example.login.model.Account;

import java.util.ArrayList;
import java.util.List;

public class LeaderBoardActivity extends AppCompatActivity {
    private List<Account> learners;
    private RecyclerView recyclerView;
    private LeaderBoardAdapter adapter;
    private ImageView backImg; // Change to ImageView

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_leader_board);

        // Retrieve the list of learners from Intent
        learners = (List<Account>) getIntent().getSerializableExtra("learners");
        if (learners == null) {
            learners = new ArrayList<>();
        }

        // Sort learners by learnerCorrectCount in descending order
        learners.sort((a, b) -> Integer.compare(b.getLearnerCorrectCount(), a.getLearnerCorrectCount()));

        // Set up RecyclerView
        backImg = findViewById(R.id.backBnt); // Ensure R.id.backBnt matches your XML
        recyclerView = findViewById(R.id.recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new LeaderBoardAdapter(learners);
        recyclerView.setAdapter(adapter);

        // Handle back button click
        backImg.setOnClickListener(v -> onBackPressed());
    }
}
