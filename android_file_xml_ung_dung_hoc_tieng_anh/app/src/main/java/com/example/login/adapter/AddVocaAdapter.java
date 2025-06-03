package com.example.login.adapter;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.activity.AddTopicActivity;
import com.example.login.model.Word;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class AddVocaAdapter extends RecyclerView.Adapter<AddVocaAdapter.TermViewHolder> {

    private final List<Word> wordList;
    private final Context context;

    private final OnImageChooserListener imageChooserListener;

    public AddVocaAdapter(Context context, OnImageChooserListener listener) {
        this.context = context;
        this.wordList = new ArrayList<>();
        this.imageChooserListener = listener;
    }

    public void updateWordList(List<Word> newWordList) {
        if (context instanceof AddTopicActivity) {
            wordList.clear(); // Clear the existing list

        }
        wordList.addAll(newWordList); // Add the new words
        notifyDataSetChanged(); // Notify RecyclerView about data change
    }


    @NonNull
    @Override
    public TermViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_add_voca, parent, false);
        return new TermViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull TermViewHolder holder, int position) {
        Word word = wordList.get(position);

        holder.etTerm.removeTextChangedListener(holder.termWatcher);
        holder.etDefinition.removeTextChangedListener(holder.definitionWatcher);
        holder.etDescription.removeTextChangedListener(holder.descriptionWatcher);

        holder.etTerm.setText(word.getEnglishWord());
        holder.etDefinition.setText(word.getVietnameseMeaning());
        holder.etDescription.setText(word.getDescription());

        holder.termWatcher = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) { }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                word.setEnglishWord(s.toString());
            }

            @Override
            public void afterTextChanged(Editable s) { }
        };
        holder.etTerm.addTextChangedListener(holder.termWatcher);

        holder.definitionWatcher = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) { }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                word.setVietnameseMeaning(s.toString());
            }

            @Override
            public void afterTextChanged(Editable s) { }
        };
        holder.etDefinition.addTextChangedListener(holder.definitionWatcher);

        holder.descriptionWatcher = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) { }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                word.setDescription(s.toString());
            }

            @Override
            public void afterTextChanged(Editable s) { }
        };
        holder.etDescription.addTextChangedListener(holder.descriptionWatcher);

        if (word.getImageUri() != null && !word.getImageUri().isEmpty()) {
            holder.ivImage.setImageURI(Uri.parse(word.getImageUri()));
        }

        holder.btnAddImage.setOnClickListener(v -> {
            if (imageChooserListener != null) {
                imageChooserListener.onImageChooserRequested(position);
            }
        });


        holder.btnDelete.setOnClickListener(view -> {
            int positionToRemove = holder.getAdapterPosition();
            if (positionToRemove != RecyclerView.NO_POSITION) {
                wordList.remove(positionToRemove); // Remove the word from the list
                notifyItemRemoved(positionToRemove); // Notify the adapter of item removal
            }
        });
    }

    @Override
    public int getItemCount() {
        return wordList.size();
    }

    public void addNewTerm() {
        String newWordId = UUID.randomUUID().toString();
        wordList.add(new Word(newWordId, "", "", "", "",false, 0)); // Set imageUri as an empty string initially
        notifyItemInserted(wordList.size() - 1);
    }


    public void updateImageView(Uri imageUri, int position) {
        wordList.get(position).setImageUri(imageUri != null ? imageUri.toString() : ""); // Convert Uri to String
        notifyItemChanged(position);
    }

    public List<Word> getWordList() {
        return wordList;
    }

    public void setWordList(List<Word> wordList) {
        this.wordList.clear();
        this.wordList.addAll(wordList);
        notifyDataSetChanged();
    }


    public static class TermViewHolder extends RecyclerView.ViewHolder {
        EditText etTerm, etDefinition, etDescription;
        Button btnAddImage, btnDelete;
        ImageView ivImage;
        TextWatcher termWatcher, definitionWatcher, descriptionWatcher;


        public TermViewHolder(@NonNull View itemView) {
            super(itemView);
            etTerm = itemView.findViewById(R.id.et_term);
            etDefinition = itemView.findViewById(R.id.et_definition);
            etDescription = itemView.findViewById(R.id.et_description);
            btnAddImage = itemView.findViewById(R.id.btn_add_image);
            ivImage = itemView.findViewById(R.id.iv_image);
            btnDelete = itemView.findViewById(R.id.btn_delete_word);
        }
    }

    public interface OnImageChooserListener {
        void onImageChooserRequested(int position);
    }

}
