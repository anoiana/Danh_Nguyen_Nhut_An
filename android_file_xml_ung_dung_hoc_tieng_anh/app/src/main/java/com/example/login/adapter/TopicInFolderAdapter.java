package com.example.login.adapter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
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
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

import java.util.ArrayList;
import java.util.List;

public class TopicInFolderAdapter extends RecyclerView.Adapter<TopicAdapter.TopicViewHolder> {
    private List<Topic> topics;
    private Context context;
    private OnTopicRemovedListener topicRemovedListener;

    public TopicInFolderAdapter(Context context, List<Topic> topics, OnTopicRemovedListener listener) {
        this.context = context;
        this.topics = topics;
        this.topicRemovedListener = listener;
    }

    @NonNull
    @Override
    public TopicAdapter.TopicViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_topic_in_folder, parent, false);
        return new TopicAdapter.TopicViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull TopicAdapter.TopicViewHolder holder, @SuppressLint("RecyclerView") int position) {
        Topic topic = topics.get(position);
        holder.topicName.setText(topic.getTopicName());
        holder.wordCount.setText(String.valueOf(topic.getWordCount()) + " từ vựng");

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

        // Set the click listener to open VocabularyActivity with the topic's words
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(context, VocabularyActivity.class);
                intent.putExtra("word_list", new ArrayList<>(topic.getWords()));
                intent.putExtra("vocabulary_name", topic.getTopicName());
                context.startActivity(intent);
            }
        });

        holder.btnEdit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!topic.isViewMode()) {
                    Intent intent = new Intent(context, UpdateTopicActivity.class);
                    intent.putExtra("word_list", new ArrayList<>(topic.getWords()));
                    intent.putExtra("vocabulary_name", topic.getTopicName());
                    intent.putExtra("topic_id", topic.getTopicId());
                    context.startActivity(intent);
                }
                else {
                    Toast.makeText(context, "Không thể chỉnh sửa topic đã được công khai", Toast.LENGTH_SHORT).show();
                }
            }
        });

        holder.btnDelete.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String topicId = topic.getTopicId();
                String userId = FirebaseAuth.getInstance().getCurrentUser().getUid();

                if (topicId == null || topicId.isEmpty()) {
                    return; // Safeguard against invalid topic IDs
                }

                // Show confirmation dialog
                new AlertDialog.Builder(context)
                        .setTitle("Delete Topic Reference")
                        .setMessage("Are you sure you want to remove this topic from the folder?")
                        .setPositiveButton("Yes", (dialog, which) -> {
                            DatabaseReference userRef = FirebaseDatabase.getInstance()
                                    .getReference("users")
                                    .child(userId)
                                    .child("folders");

                            // Find the folder containing this topic ID
                            userRef.get().addOnCompleteListener(task -> {
                                if (task.isSuccessful() && task.getResult() != null) {
                                    boolean topicFound = false;
                                    for (DataSnapshot folderSnapshot : task.getResult().getChildren()) {
                                        if (folderSnapshot.hasChild("topics")) {
                                            for (DataSnapshot topicSnapshot : folderSnapshot.child("topics").getChildren()) {
                                                if (topicSnapshot.getValue(String.class).equals(topicId)) {
                                                    // Remove topic reference from this folder
                                                    folderSnapshot.child("topics").child(topicSnapshot.getKey()).getRef().removeValue()
                                                            .addOnSuccessListener(aVoid -> {
                                                                Toast.makeText(context, "Topic reference removed from folder successfully", Toast.LENGTH_SHORT).show();
                                                                int adapterPosition = holder.getAdapterPosition();
                                                                if (adapterPosition != RecyclerView.NO_POSITION) {
                                                                    topics.remove(adapterPosition);
                                                                    notifyItemRemoved(adapterPosition);
                                                                }
                                                            })
                                                            .addOnFailureListener(e -> {
                                                                Toast.makeText(context, "Failed to remove topic reference: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                                                            });
                                                    topicFound = true;
                                                    break;
                                                }
                                            }
                                        }
                                        if (topicFound) break;
                                    }

                                    if (!topicFound) {
                                        Toast.makeText(context, "Topic reference not found in any folder", Toast.LENGTH_SHORT).show();
                                    }
                                } else {
                                    Toast.makeText(context, "Failed to retrieve folders: " + task.getException().getMessage(), Toast.LENGTH_SHORT).show();
                                }
                            });
                        })
                        .setNegativeButton("No", (dialog, which) -> {
                            // Dismiss the dialog
                            dialog.dismiss();
                        })
                        .create()
                        .show();
                if (topicRemovedListener != null) {
                    topicRemovedListener.onTopicRemoved(topicId);
                }
            }
        });
    }

    public interface OnTopicRemovedListener {
        void onTopicRemoved(String topicId);
    }

    @Override
    public int getItemCount() {
        return topics.size();
    }


}