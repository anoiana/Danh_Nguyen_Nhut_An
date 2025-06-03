package com.example.login.activity;

import android.app.ProgressDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.example.login.R;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.OnProgressListener;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.UploadTask;

import java.io.IOException;
import java.util.UUID;


public class UploadAvatarImage extends AppCompatActivity {

    final int PICK_IMAGE_REQUEST = 71;
    ImageView profileImageView, chooseImage;
    Button gobackBtn, saveBtn;
    Uri imageUrl;

    FirebaseStorage storage;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_upload_avatar_image);

        profileImageView = findViewById(R.id.profileImageId);
        gobackBtn = findViewById(R.id.goBackBtnId);
        saveBtn = findViewById(R.id.btnSaveId);
        chooseImage = findViewById(R.id.chooseImageId);

        storage = FirebaseStorage.getInstance();

        gobackBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(UploadAvatarImage.this, MainActivity.class);
                startActivity(i);
            }
        });

        chooseImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                chooseImage();
            }
        });

        saveBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                uploadProfileImage();
            }
        });

        Intent i = getIntent();
        String currentImageUrl = i.getStringExtra("currentImageUrl");
        if (currentImageUrl != null) {
            Glide.with(this).load(currentImageUrl).apply(RequestOptions.circleCropTransform()).into(profileImageView);
            Log.d("monmon", "duoc");
        }
    }

    private void chooseImage() {
        Intent intent = new Intent();
        intent.setType("image/*");
        intent.setAction(Intent.ACTION_GET_CONTENT);
        startActivityForResult(Intent.createChooser(intent, "Select Picture"), PICK_IMAGE_REQUEST);
    }

    private  void uploadProfileImage(){
            if (imageUrl != null) {
                final ProgressDialog progressDialog = new ProgressDialog(this);
                progressDialog.setTitle("Uploading...");
                progressDialog.show();

                StorageReference ref = storage.getReference().child("images/" + UUID.randomUUID().toString());

                ref.putFile(imageUrl)
                        .addOnSuccessListener(new OnSuccessListener<UploadTask.TaskSnapshot>() {
                            @Override
                            public void onSuccess(UploadTask.TaskSnapshot taskSnapshot) {
                                progressDialog.dismiss();
                                Toast.makeText(UploadAvatarImage.this, "Cập nhật thành công!", Toast.LENGTH_SHORT).show();

                                ref.getDownloadUrl().addOnSuccessListener(new OnSuccessListener<Uri>() {
                                    @Override
                                    public void onSuccess(Uri downloadUri) {
                                        Glide.with(UploadAvatarImage.this).load(downloadUri).into(profileImageView);

                                        // Set result to pass back to MainActivity
                                        Intent resultIntent = new Intent();
                                        resultIntent.putExtra("imageUrl", downloadUri.toString());
                                        setResult(RESULT_OK, resultIntent);
                                        finish(); // Close UploadAvatarImage to go back to MainActivity
                                    }
                                });
                            }
                        })
                        .addOnFailureListener(new OnFailureListener() {
                            @Override
                            public void onFailure(@NonNull Exception e) {
                                progressDialog.dismiss();
                                Toast.makeText(UploadAvatarImage.this, "Cập nhật thất bại: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                            }
                        })
                        .addOnProgressListener(new OnProgressListener<UploadTask.TaskSnapshot>() {
                            @Override
                            public void onProgress(UploadTask.TaskSnapshot taskSnapshot) {
                                double progress = (100.0 * taskSnapshot.getBytesTransferred() / taskSnapshot.getTotalByteCount());
                                progressDialog.setMessage("Uploaded " + (int) progress + "%");
                            }
                        });
            } else {
                Toast.makeText(this, "Không có ảnh nào được chọn!", Toast.LENGTH_SHORT).show();
            }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            imageUrl = data.getData(); // Get image URI from intent
            try {
                Bitmap bitmap = MediaStore.Images.Media.getBitmap(getContentResolver(), imageUrl);
                profileImageView.setImageBitmap(bitmap); // Display the chosen image
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}