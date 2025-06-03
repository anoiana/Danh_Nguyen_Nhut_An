package com.example.login.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.login.R;
import com.example.login.model.Account;

import java.util.List;

public class LeaderBoardAdapter extends RecyclerView.Adapter<LeaderBoardAdapter.ViewHolder> {
    private final List<Account> learners;

    public LeaderBoardAdapter(List<Account> learners) {
        this.learners = learners;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_leaderboard, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Account currentLearner = learners.get(position);

        // Calculate rank dynamically
        int rank;
        if (position > 0 && learners.get(position).getLearnerCorrectCount().equals(learners.get(position - 1).getLearnerCorrectCount())) {
            rank = holder.getAdapterPosition(); // Same rank as the previous learner
        } else {
            rank = position + 1;
        }

        // Bind data to views
        holder.rankTextView.setText(String.valueOf(rank));
        holder.nameTextView.setText(currentLearner.getName());
        holder.correctCountTextView.setText("Tổng số câu đúng: " + String.valueOf(currentLearner.getLearnerCorrectCount()));

        // Load avatar image
        Glide.with(holder.avatarImageView.getContext())
                .load(currentLearner.getAvatarPath())
                .placeholder(R.drawable.aklogo) // Replace with your default avatar drawable
                .into(holder.avatarImageView);
    }


    @Override
    public int getItemCount() {
        return learners.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView rankTextView, nameTextView, correctCountTextView;
        ImageView avatarImageView;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            rankTextView = itemView.findViewById(R.id.rank_text_view);
            nameTextView = itemView.findViewById(R.id.name_text_view);
            correctCountTextView = itemView.findViewById(R.id.correct_count_text_view);
            avatarImageView = itemView.findViewById(R.id.avatar_image_view);
            avatarImageView.setClipToOutline(true);

        }
    }
}

