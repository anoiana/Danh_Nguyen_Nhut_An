package com.example.login.activity;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.adapter.AddVocaAdapter;
import com.example.login.model.Topic;
import com.example.login.model.Word;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;

import android.util.Log;
import android.view.View;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

public class AddTopicActivity extends AppCompatActivity implements AddVocaAdapter.OnImageChooserListener {

    ImageView bntSave, bntBack, btnUploadCSV;
    private AddVocaAdapter addVocaAdapter;
    private RecyclerView recyclerView;
    private static final int PICK_IMAGE_REQUEST = 1;
    private static final int PICK_CSV_FILE = 2;
    private int selectedPosition = -1;

    private FirebaseDatabase databaseTopic;
    private DatabaseReference userRef;
    private String userId;
    private List<Word> wordList = new ArrayList<>();
    CheckBox publicChbox;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_topic);

        userId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        userRef = FirebaseDatabase.getInstance().getReference("users").child(userId);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.addTopic), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        recyclerView = findViewById(R.id.recyclerView);
        addVocaAdapter = new AddVocaAdapter(this, this);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(addVocaAdapter);


        publicChbox = findViewById(R.id.chbox_public);

        FloatingActionButton fabAdd = findViewById(R.id.fab_add);
        fabAdd.setOnClickListener(view -> {
            addVocaAdapter.addNewTerm();
            recyclerView.scrollToPosition(addVocaAdapter.getItemCount() - 1);
        });

        addVocaAdapter.addNewTerm();
        recyclerView.scrollToPosition(addVocaAdapter.getItemCount() - 1);

        bntBack = findViewById(R.id.btn_back);
        bntBack.setOnClickListener(view -> {
            Intent intent = new Intent(AddTopicActivity.this, MainActivity.class);
            startActivity(intent);
            finish();
        });

        bntSave = findViewById(R.id.btn_complete);
        bntSave.setOnClickListener(view -> {
            EditText etTitle = findViewById(R.id.et_title);
            String title = etTitle.getText().toString().trim();

            if (title.isEmpty()) {
                Toast.makeText(AddTopicActivity.this, "Vui lòng nhập tên chủ đề", Toast.LENGTH_SHORT).show();
                return;
            }

            wordList = addVocaAdapter.getWordList();
            if (wordList.size() < 2) {
                Toast.makeText(AddTopicActivity.this, "Vui lòng thêm ít nhất 2 từ", Toast.LENGTH_SHORT).show();
                return;
            }

            for (Word word : wordList) {
                if (word.getEnglishWord().isEmpty() || word.getVietnameseMeaning().isEmpty()) {
                    Toast.makeText(AddTopicActivity.this, "Vui lòng điền tiếng Anh và nghĩa cho các từ", Toast.LENGTH_SHORT).show();
                    return;
                }
            }

            String createdTime = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(new Date());
            String topicId = userRef.child("topics").push().getKey();
            Topic newTopic = new Topic(topicId, title, wordList.size(), publicChbox.isChecked(), createdTime);
            newTopic.setOwnerId(userId);

            userRef.child("topics").child(topicId).setValue(newTopic)
                    .addOnSuccessListener(aVoid -> {
                        for (Word word : wordList) {
                            String wordId = word.getWordId();
                            if (wordId == null || wordId.isEmpty()) {
                                wordId = userRef.child("topics").child(topicId).child("words").push().getKey();
                                word.setWordId(wordId); // Set generated ID in Word object
                            }
                            userRef.child("topics").child(topicId).child("words").child(wordId).setValue(word);
                            Log.d("AddTopic", "Word: " + word.getEnglishWord());
                        }

                        Toast.makeText(AddTopicActivity.this, "Lưu topic thành công!", Toast.LENGTH_SHORT).show();
                        startActivity(new Intent(AddTopicActivity.this, MainActivity.class));
                        finish();
                    })
                    .addOnFailureListener(e -> Toast.makeText(AddTopicActivity.this, "Lưu topic thất bại: " + e.getMessage(), Toast.LENGTH_SHORT).show());
        });

        btnUploadCSV = findViewById(R.id.btn_upload_csv);
        btnUploadCSV.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                requestPermissionAndOpenFilePicker();
            }
        });


    }

    private void requestPermissionAndOpenFilePicker() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { // Android 13+
            selectFile(); // Permission not strictly required for file picker
        } else {
            if (checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(new String[]{Manifest.permission.READ_EXTERNAL_STORAGE}, 100);
            } else {
                selectFile(); // Permission already granted
            }
        }
    }


    // Handle the result of the permission request
    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == 100) { //
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "Đã cấp phép", Toast.LENGTH_SHORT).show();
                selectFile();
            } else {
                Toast.makeText(this, "Từ chối cấp phép", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void selectFile() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("text/csv");
        intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[]{"text/csv", "application/vnd.ms-excel", "text/*"});
        intent.addCategory(Intent.CATEGORY_OPENABLE); // Ensures only openable files are shown
        startActivityForResult(Intent.createChooser(intent, "Select CSV File"), PICK_CSV_FILE);
    }


    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            Uri imageUri = data.getData();
            uploadImageToFirebase(imageUri);
        }
        if (requestCode == PICK_CSV_FILE && resultCode == RESULT_OK && data != null) {
            Uri csvUri = data.getData();
            if (csvUri != null) {
                importCSV(csvUri); // Call your CSV processing method here
            }
        }
    }

    private void importCSV(Uri csvUri) {
        try {
            InputStream inputStream = getContentResolver().openInputStream(csvUri);
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));

            String line;
            List<Word> importedWords = new ArrayList<>();

            // Skip the header line (if any)
            boolean isFirstLine = true;
            while ((line = reader.readLine()) != null) {
                if (isFirstLine) {
                    isFirstLine = false;
                    continue; // Skip the header line
                }

                // Split the CSV line into values
                String[] values = line.split(",");
                if (values.length >= 3) { // Assuming the CSV has at least 3 columns: English, Vietnamese, Description
                    String englishWord = values[0].trim();
                    String vietnameseMeaning = values[1].trim();
                    String description = values[2].trim();

                    // Generate a unique ID for each word
                    String wordId = UUID.randomUUID().toString();

                    // Create a Word object (imageUri left empty)
                    Word word = new Word(wordId, englishWord, vietnameseMeaning, description, null);
                    word.setCorrectCount(0);
                    importedWords.add(word);
                }
            }
            reader.close();

            // Update the adapter with the imported words
            addVocaAdapter.updateWordList(importedWords);
            addVocaAdapter.notifyDataSetChanged();

            Toast.makeText(this, "Nhập file CSV thành công!", Toast.LENGTH_SHORT).show();

        } catch (Exception e) {
            e.printStackTrace();
            Toast.makeText(this, "Nhập file CSV thất bại!: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }


    private void uploadImageToFirebase(Uri imageUri) {
        if (imageUri != null) {
            StorageReference storageRef = FirebaseStorage.getInstance().getReference("vocImages")
                    .child(System.currentTimeMillis() + ".jpg");

            storageRef.putFile(imageUri)
                    .addOnSuccessListener(taskSnapshot -> storageRef.getDownloadUrl().addOnSuccessListener(uri -> {
                        String imageUrl = uri.toString();
                        if (selectedPosition != -1) {
                            addVocaAdapter.updateImageView(Uri.parse(imageUrl), selectedPosition);
                            selectedPosition = -1;
                        }
                    }))
                    .addOnFailureListener(e -> Toast.makeText(AddTopicActivity.this, "Tải ảnh lên thất bại: " + e.getMessage(), Toast.LENGTH_SHORT).show());
        }

    }

    @Override
    public void onImageChooserRequested(int position) {
        selectedPosition = position;
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(intent, PICK_IMAGE_REQUEST);
    }
}



