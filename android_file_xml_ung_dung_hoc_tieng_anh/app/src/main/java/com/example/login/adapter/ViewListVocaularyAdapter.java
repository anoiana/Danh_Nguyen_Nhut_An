package com.example.login.adapter;

import android.content.Context;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.login.R;
import com.example.login.model.Word;

import java.util.ArrayList;
import java.util.Locale;

public class ViewListVocaularyAdapter extends ArrayAdapter<Word> {
    private ArrayList<Word> items;
    private Context context;
    private TextToSpeech textToSpeech;
    private boolean isTtsInitialized = false;

    public ViewListVocaularyAdapter(@NonNull Context context, ArrayList<Word> items) {
        super(context, 0, items);
        this.items = items;
        this.context = context;
        initializeTextToSpeech();
    }

    private void initializeTextToSpeech() {
        textToSpeech = new TextToSpeech(context, status -> {
            if (status == TextToSpeech.SUCCESS) {
                int langResult = textToSpeech.setLanguage(Locale.US);
                if (langResult != TextToSpeech.LANG_MISSING_DATA && langResult != TextToSpeech.LANG_NOT_SUPPORTED) {
                    isTtsInitialized = true;
                    Log.d("monmonhehe", "nhan duoc");
                }
            }
        });
    }

    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        if (convertView == null) {
            convertView = LayoutInflater.from(context).inflate(R.layout.item_for_vocabulary, parent, false);
        }
        TextView tv_term = convertView.findViewById(R.id.tv_term);
        TextView tv_defination = convertView.findViewById(R.id.tv_defination);
        ImageView iv_audio = convertView.findViewById(R.id.iv_audio);
        tv_term.setText(items.get(position).getEnglishWord());
        tv_defination.setText(items.get(position).getVietnameseMeaning());

        iv_audio.setOnClickListener(view -> {
            Log.d("AudioClick", "Audio button clicked");
            if (isTtsInitialized) {
                String termToSpeak = getItem(position).getEnglishWord();
                speak(termToSpeak);
            } else {
                Toast.makeText(context, "Text-to-Speech not initialized", Toast.LENGTH_SHORT).show();
            }
        });
        return convertView;
    }

    private void speak(String text) {
        if (textToSpeech != null) {
            textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, null, null);
        }
    }

    @Override
    protected void finalize() throws Throwable {
        if (textToSpeech != null) {
            textToSpeech.stop();
            textToSpeech.shutdown();
        }
        super.finalize();
    }
}