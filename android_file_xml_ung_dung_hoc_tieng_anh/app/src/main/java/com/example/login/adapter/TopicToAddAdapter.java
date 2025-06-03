package com.example.login.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.model.Topic;

import java.util.HashSet;
import java.util.List;

public class TopicToAddAdapter extends RecyclerView.Adapter<TopicToAddAdapter.TopicToAddViewHolder> {

    private final Context context;
    private final List<Topic> topics;
    private final HashSet<String> selectedTopicIds;

    public TopicToAddAdapter(Context context, List<Topic> topics, HashSet<String> currentTopicIds) {
        this.context = context;
        this.topics = topics;
        this.selectedTopicIds = currentTopicIds;
    }

    public HashSet<String> getSelectedTopics() {
        return selectedTopicIds;
    }

    @NonNull
    @Override
    public TopicToAddViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_topic_to_add, parent, false);
        return new TopicToAddViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull TopicToAddViewHolder holder, int position) {
        Topic topic = topics.get(position);
        holder.topicName.setText(topic.getTopicName());

        // Set the checkbox state based on whether the topic ID is selected
        holder.topicCheckbox.setOnCheckedChangeListener(null); // Remove previous listeners
        holder.topicCheckbox.setChecked(selectedTopicIds.contains(topic.getTopicId()));

        holder.topicCheckbox.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                selectedTopicIds.add(topic.getTopicId());
            } else {
                selectedTopicIds.remove(topic.getTopicId());
            }
        });
    }

    @Override
    public int getItemCount() {
        return topics.size();
    }

    public static class TopicToAddViewHolder extends RecyclerView.ViewHolder {
        TextView topicName;
        CheckBox topicCheckbox;

        public TopicToAddViewHolder(@NonNull View itemView) {
            super(itemView);
            topicName = itemView.findViewById(R.id.topic_name_text_view);
            topicCheckbox = itemView.findViewById(R.id.topic_checkbox);
        }
    }
}
