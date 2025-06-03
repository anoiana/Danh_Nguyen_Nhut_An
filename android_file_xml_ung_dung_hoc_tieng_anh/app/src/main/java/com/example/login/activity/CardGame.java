package com.example.login.activity;

import android.app.AlertDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ViewFlipper;

import androidx.appcompat.app.AppCompatActivity;

import com.bumptech.glide.Glide;
import com.example.login.R;
import com.example.login.model.Word;
import com.google.firebase.database.FirebaseDatabase;

import java.util.List;
import java.util.Locale;

public class CardGame extends AppCompatActivity {

    private ViewFlipper viewFlipper;
    private SeekBar seekBar;
    private TextView progressText;
    private Button meaningButton;
    private ImageButton playButton, soundButton, settingsButton, backButton;
    private int currentIndex = 0;
    private boolean isPlaying = false;
    private boolean isLooping = false;
    private Handler handler = new Handler();
    private List<Word> wordList;
    private String[] flashCards;
    private String[] meanings;
    private Button nextButton;
    private TextToSpeech textToSpeech;
    private boolean isShowingEnglish = true;
    private ImageView vocabularyImg;

    private int autoPlayDelay = 1000;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_card_game);

        textToSpeech = new TextToSpeech(this, new TextToSpeech.OnInitListener() {
            @Override
            public void onInit(int i) {
                if (i == TextToSpeech.SUCCESS) {
                    textToSpeech.setLanguage(Locale.ENGLISH);
                }
            }
        });
        SharedPreferences preferences = getSharedPreferences("SettingsPrefs", MODE_PRIVATE);

        vocabularyImg = findViewById(R.id.vocabularyImgId);
//        databaseReference = FirebaseDatabase.getInstance().getReference();
        backButton = findViewById(R.id.backButton);
        viewFlipper = findViewById(R.id.viewFlipper);
        seekBar = findViewById(R.id.seekBar);
        progressText = findViewById(R.id.progressText);
        meaningButton = findViewById(R.id.meaningButton);
        playButton = findViewById(R.id.playButton);
        soundButton = findViewById(R.id.soundButton);
        settingsButton = findViewById(R.id.settingsButton);
        nextButton = findViewById(R.id.nextButton);

        wordList = (List<Word>) getIntent().getSerializableExtra("word_list");
        if (wordList != null && !wordList.isEmpty()) {
            flashCards = new String[wordList.size()];
            meanings = new String[wordList.size()];

            for (int i = 0; i < wordList.size(); i++) {
                flashCards[i] = wordList.get(i).getEnglishWord();
                meanings[i] = wordList.get(i).getVietnameseMeaning();
            }

            seekBar.setMax(flashCards.length - 1);
            updateFlashCard();
        } else {
            Toast.makeText(this, "Từ không có sẵn!", Toast.LENGTH_SHORT).show();
        }

        nextButton.setOnClickListener(v -> goToNextFlashCard());
        playButton.setOnClickListener(v -> toggleAutoPlay());
        meaningButton.setOnClickListener(v -> toggleMeaning());
        soundButton.setOnClickListener(v -> playPronunciation());
        settingsButton.setOnClickListener(v -> showSettingsDialog());

        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                new AlertDialog.Builder(CardGame.this)
                        .setTitle("Thoát khỏi học thẻ ghi nhớ")
                        .setMessage("Bạn có chắc là muốn thoát?")
                        .setPositiveButton("Có", (dialog, which) -> finish())
                        .setNegativeButton("Không", null)
                        .show();
            }
        });

        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser) {
                    currentIndex = progress;
                    updateFlashCard();
                }
            }
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) { }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) { }
        });
    }

    private void updateFlashCard() {
        LinearLayout currentView = (LinearLayout) viewFlipper.getCurrentView();
        TextView wordText = currentView.findViewById(R.id.wordText);
        TextView description = currentView.findViewById(R.id.descriptionId);
        wordText.setText(flashCards[currentIndex]);

        if (isShowingEnglish) {
            description.setText(null);  // Hide description when showing English word
        } else {
            description.setText(wordList.get(currentIndex).getDescription());  // Show description when displaying Vietnamese meaning
        }

        for (Word word : wordList) {
            Log.d("DEBUG", "Word: " + word.getEnglishWord() + ", ImageUri: " + word.getImageUri());
        }

        // Cập nhật hình ảnh cho mỗi flashcard
        String imageUri = wordList.get(currentIndex).getImageUri();


        if (imageUri != null && !imageUri.isEmpty()) {
            Log.d("monmonhehe", imageUri);
            Glide.with(this)
                    .load(imageUri)
                    .into(vocabularyImg);
        } else {
            vocabularyImg.setImageResource(R.drawable.avatar_image);  // Hình ảnh mặc định nếu không có imageUri
        }

        progressText.setText((currentIndex + 1) + " / " + flashCards.length);
        seekBar.setProgress(currentIndex);
    }


    private void toggleMeaning() {
        LinearLayout currentView = (LinearLayout) viewFlipper.getCurrentView();
        TextView wordText = currentView.findViewById(R.id.wordText);
        TextView description = currentView.findViewById(R.id.descriptionId);

        if (isShowingEnglish) {
            wordText.setText(meanings[currentIndex]);
            description.setText(wordList.get(currentIndex).getDescription());
            isShowingEnglish = false;
        } else {
            wordText.setText(flashCards[currentIndex]);
            description.setText(null);
            isShowingEnglish = true;
        }
    }

    private void goToNextFlashCard() {
        if (currentIndex < flashCards.length - 1) {
            currentIndex++;
        } else {
            currentIndex = 0;
        }
        isShowingEnglish = true;
        updateFlashCard();
    }

    private void playPronunciation() {
        if (textToSpeech == null || textToSpeech.isSpeaking()) {
            Toast.makeText(this, "Text-to-Speech chưa sẵn sàng hoặc đang phát âm.", Toast.LENGTH_SHORT).show();
            return;
        }
        String wordToPronounce = isShowingEnglish ? flashCards[currentIndex] : meanings[currentIndex];
        Locale language = isShowingEnglish ? Locale.ENGLISH : new Locale("vi");

        textToSpeech.setLanguage(language);
        textToSpeech.speak(wordToPronounce, TextToSpeech.QUEUE_FLUSH, null, null);
    }

    private void toggleAutoPlay() {
        if (isPlaying) {
            handler.removeCallbacks(autoPlayRunnable);
            playButton.setImageResource(R.drawable.baseline_play_arrow_24);
        } else {
            handler.postDelayed(autoPlayRunnable, autoPlayDelay);
            playButton.setImageResource(R.drawable.baseline_pause_24);
        }
        isPlaying = !isPlaying;
    }

    private Runnable autoPlayRunnable = new Runnable() {
        @Override
        public void run() {
            if (currentIndex < flashCards.length - 1) {
                currentIndex++;
            } else if (isLooping) {
                currentIndex = 0;
            } else {
                isPlaying = false;
                playButton.setImageResource(R.drawable.baseline_play_arrow_24);
                return;
            }
            updateFlashCard();  // Cập nhật thẻ ghi nhớ với từ mới
            playPronunciation();  // Gọi phương thức phát âm từ mới
            handler.postDelayed(this, autoPlayDelay);  // Tiếp tục tự động chuyển qua các thẻ ghi nhớ
        }
    };

    private void showSettingsDialog() {
        String[] options = {"Tự động lặp lại"};
        boolean[] checkedItems = {isLooping, false};
        String[] timeOptions = {"2 giây", "5 giây", "8 giây", "10 giây"};
        final String[] selectedTime = new String[1];

        // Lấy thời gian đã chọn từ SharedPreferences (nếu có)
        SharedPreferences preferences = getSharedPreferences("SettingsPrefs", MODE_PRIVATE);
        selectedTime[0] = preferences.getString("selectedTime", timeOptions[0]); // mặc định là "2 giây"

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Setting")
                .setMultiChoiceItems(options, checkedItems, (dialog, which, isChecked) -> {
                    if (which == 0) {
                        isLooping = isChecked;
                    }
                })
                .setPositiveButton("OK", (dialog, which) -> {
                    StringBuilder selectedOptions = new StringBuilder("Đã chọn: ");
                    for (int i = 0; i < options.length; i++) {
                        if (checkedItems[i]) {
                            selectedOptions.append(options[i]).append(", ");
                        }
                    }
                    Toast.makeText(this, selectedOptions.toString(), Toast.LENGTH_SHORT).show();
                })
                .setNegativeButton("Cancel", (dialog, which) -> dialog.dismiss());

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 20, 50, 20);

        LinearLayout timeLayout = new LinearLayout(this);
        timeLayout.setOrientation(LinearLayout.HORIZONTAL);
        timeLayout.setGravity(Gravity.CENTER_VERTICAL);
        timeLayout.setPadding(0, 20, 0, 20);

        TextView timeSelection = new TextView(this);
        timeSelection.setText(selectedTime[0]);
        timeSelection.setTextSize(16);
        timeSelection.setTextColor(Color.BLUE);
        timeSelection.setPadding(0, 0, 20, 0);
        timeSelection.setOnClickListener(v -> showTimeSelectionDialog(timeSelection, timeOptions, selectedTime));

        TextView instructionText = new TextView(this);
        instructionText.setText("Thời gian chờ trước khi chuyển sang từ kế tiếp");
        instructionText.setTextSize(16);
        instructionText.setLayoutParams(new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

        timeLayout.addView(timeSelection);
        timeLayout.addView(instructionText);
        layout.addView(timeLayout);
        builder.setView(layout);

        builder.create().show();
    }

    private void showTimeSelectionDialog(TextView timeSelection, String[] timeOptions, String[] selectedTime) {
        AlertDialog.Builder timeDialogBuilder = new AlertDialog.Builder(this);
        timeDialogBuilder.setTitle("Chọn thời gian chuyển");

        // Lấy giá trị từ SharedPreferences nếu có
        SharedPreferences preferences = getSharedPreferences("SettingsPrefs", MODE_PRIVATE);
        String savedTime = preferences.getString("selectedTime", "2 giây"); // mặc định là "2 giây"
        int savedDelay = preferences.getInt("autoPlayDelay", 2000); // mặc định là 2000ms

        int defaultSelectionIndex = 0;
        for (int i = 0; i < timeOptions.length; i++) {
            if (timeOptions[i].equals(savedTime)) {
                defaultSelectionIndex = i;
                break;
            }
        }

        timeDialogBuilder.setSingleChoiceItems(timeOptions, defaultSelectionIndex, (dialog, which) -> {
            selectedTime[0] = timeOptions[which];
            switch (which) {
                case 0:
                    autoPlayDelay = 2000;
                    break;
                case 1:
                    autoPlayDelay = 5000;
                    break;
                case 2:
                    autoPlayDelay = 8000;
                    break;
                case 3:
                    autoPlayDelay = 10000;
                    break;
            }
            timeSelection.setText(selectedTime[0]);
        });

        timeDialogBuilder.setPositiveButton("OK", (dialog, which) -> {
            // Lưu giá trị vào SharedPreferences
            SharedPreferences.Editor editor = preferences.edit();
            editor.putString("selectedTime", selectedTime[0]);
            editor.putInt("autoPlayDelay", autoPlayDelay);
            editor.apply();

            Toast.makeText(this, "Thời gian chọn: " + selectedTime[0], Toast.LENGTH_SHORT).show();
            dialog.dismiss();
        });

        timeDialogBuilder.setNegativeButton("Cancel", (dialog, which) -> dialog.dismiss());

        timeDialogBuilder.create().show();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        handler.removeCallbacks(autoPlayRunnable);
        if (textToSpeech != null) {
            textToSpeech.stop();
            textToSpeech.shutdown();
        }
        handler.removeCallbacks(autoPlayRunnable);
    }
}
