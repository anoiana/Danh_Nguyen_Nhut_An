package com.example.login.adapter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.login.R;
import com.example.login.activity.UpdateTopicActivity;
import com.example.login.activity.VocabularyActivity;
import com.example.login.model.Topic;
import com.example.login.model.Word;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

import java.util.ArrayList;
import java.util.List;

public class TopicAdapter extends RecyclerView.Adapter<TopicAdapter.TopicViewHolder> {
    private List<Topic> topics;
    private Context context;
    private boolean isPublicView, showLeaderBoard;

    public TopicAdapter(Context context, List<Topic> topics, boolean isPublicView, boolean showLeaderBoard) {
        this.context = context;
        this.topics = topics;
        this.isPublicView = isPublicView;
        this.showLeaderBoard = showLeaderBoard;
    }


    @NonNull
    @Override
    public TopicAdapter.TopicViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_topic, parent, false);
        return new TopicAdapter.TopicViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull TopicAdapter.TopicViewHolder holder, @SuppressLint("RecyclerView") int position) {
        Topic topic = topics.get(position);
        holder.topicName.setText(topic.getTopicName());
        holder.wordCount.setText(String.valueOf(topic.getWordCount()) + " từ vựng");
        holder.userCount.setText(String.valueOf(topic.getUserCount()) + " người đang học");


        // Fetch and display the owner's username
        topic.fetchOwnerUsername(new Topic.Callback<String>() {
            @Override
            public void onSuccess(String username) {
                holder.userName.setText("Tác giả: " + username);
            }

            @Override
            public void onFailure(String errorMessage) {
                holder.userName.setText("Tác giả: Unknown");
            }
        });

        // Fetch and display the owner's profile image using Glide
        topic.fetchOwnerProfileImageUrl(new Topic.Callback<String>() {
            @Override
            public void onSuccess(String profileImageUrl) {
                Glide.with(context)
                        .load(profileImageUrl)
                        .placeholder(R.drawable.aklogo)
                        .into(holder.avatarImage);
            }

            @Override
            public void onFailure(String errorMessage) {
                holder.avatarImage.setImageResource(R.drawable.aklogo);
            }
        });

        // Hide edit and delete buttons if in public view
        if (isPublicView) {
            holder.btnEdit.setVisibility(View.GONE);
            holder.btnDelete.setVisibility(View.GONE);
            holder.userCount.setVisibility(View.VISIBLE);
        }

        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(context, VocabularyActivity.class);
                intent.putExtra("word_list", new ArrayList<>(topic.getWords() != null ? topic.getWords() : new ArrayList<>()));
                intent.putExtra("vocabulary_name", topic.getTopicName());
                intent.putExtra("topicId", topic.getTopicId());
                intent.putExtra("topicMode", topic.isViewMode());
                intent.putExtra("ownerId", topic.getOwnerId());
                intent.putExtra("learners", new ArrayList<>(topic.getLearners() != null ? topic.getLearners() : new ArrayList<>()));
                intent.putExtra("showLeader", showLeaderBoard);
                context.startActivity(intent);
            }
        });

        holder.btnEdit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!topic.isViewMode()) {
                    Intent intent = new Intent(context, UpdateTopicActivity.class);
                    intent.putExtra("word_list", new ArrayList<>(topic.getWords() != null ? topic.getWords() : new ArrayList<>()));
                    intent.putExtra("vocabulary_name", topic.getTopicName());
                    intent.putExtra("topic_id", topic.getTopicId());
                    context.startActivity(intent);
                } else {
                    Toast.makeText(context, "Không thể chỉnh sửa topic đã được công khai", Toast.LENGTH_SHORT).show();
                }
            }
        });

        holder.btnDelete.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String topicId = topic.getTopicId();
                if (topicId == null || topicId.isEmpty()) {
                    return; // Safeguard against invalid topic IDs
                }

                // Hiển thị dialog xác nhận xóa
                new AlertDialog.Builder(context)
                        .setTitle("Delete Topic")
                        .setMessage("Are you sure you want to delete this topic?")
                        .setPositiveButton("Yes", (dialog, which) -> {
                            // Reference to the topic in Firebase
                            DatabaseReference topicRef = FirebaseDatabase.getInstance()
                                    .getReference("users")
                                    .child(FirebaseAuth.getInstance().getCurrentUser().getUid())
                                    .child("topics")
                                    .child(topicId);

                            // Delete the topic
                            topicRef.removeValue()
                                    .addOnSuccessListener(aVoid ->
                                            Toast.makeText(context, "Topic deleted successfully", Toast.LENGTH_SHORT).show())
                                    .addOnFailureListener(e ->
                                            Toast.makeText(context, "Failed to delete topic: " + e.getMessage(), Toast.LENGTH_SHORT).show());
                        })
                        .setNegativeButton("No", (dialog, which) -> {
                            // Đóng dialog
                            dialog.dismiss();
                        })
                        .create()
                        .show();
            }
        });


    }

    @Override
    public int getItemCount() {
        return topics.size();
    }

    public static class TopicViewHolder extends RecyclerView.ViewHolder {
        TextView topicName, wordCount, userName, userCount;
        ImageView avatarImage, btnEdit, btnDelete;

        public TopicViewHolder(@NonNull View itemView) {
            super(itemView);
            topicName = itemView.findViewById(R.id.topic_name);
            wordCount = itemView.findViewById(R.id.word_count);
            userName = itemView.findViewById(R.id.user_name_text);
            avatarImage = itemView.findViewById(R.id.topic_avatar_image);
            avatarImage.setClipToOutline(true);
            btnEdit = itemView.findViewById(R.id.edit_btn);
            btnDelete = itemView.findViewById(R.id.delete_btn);
            userCount = itemView.findViewById(R.id.user_count);
        }
    }
}
