package com.example.login.activity;

import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.login.R;
import com.example.login.model.Account;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.android.material.textfield.TextInputEditText;
import com.google.firebase.Firebase;
import com.google.firebase.auth.AuthResult;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

public class SignupActivity extends AppCompatActivity {
    EditText userNameInput, emailInput;
    TextInputEditText passwordInput, confPasswordInput;
    Button btnSignUp;
    FirebaseAuth mAuth;
    ProgressBar progressBar;
    DatabaseReference databaseReference;

    @Override
    public void onStart() {
        super.onStart();
        // Check if user is signed in (non-null) and update UI accordingly.
        FirebaseUser currentUser = mAuth.getCurrentUser();
        if(currentUser != null){
            Intent intent = new Intent(getApplicationContext(), MainActivity.class);
            startActivity(intent);
            finish();
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_signup);

        mAuth = FirebaseAuth.getInstance();
        userNameInput = findViewById(R.id.usernameId);
        emailInput = findViewById(R.id.emailId);
        passwordInput = findViewById(R.id.passwordId);
        confPasswordInput = findViewById(R.id.passwordConfirmId);
        btnSignUp = findViewById(R.id.btnSignup);
        progressBar = findViewById(R.id.progressbar_signup);

        databaseReference = FirebaseDatabase.getInstance().getReference("users");

        btnSignUp.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String email, password, confPassword;
                email = emailInput.getText().toString();
                password = passwordInput.getText().toString();
                confPassword = confPasswordInput.getText().toString();

                if (email.isEmpty()) {
                    Toast.makeText(SignupActivity.this, "Vui lòng nhập email", Toast.LENGTH_SHORT).show();
                    emailInput.requestFocus();
                    return;
                }

                if (password.isEmpty()) {
                    Toast.makeText(SignupActivity.this, "Vui lòng nhập mật khẩu", Toast.LENGTH_SHORT).show();
                    passwordInput.requestFocus();
                    return;
                }

                if (password.length() < 6) {
                    Toast.makeText(SignupActivity.this, "Mật khẩu phải ít nhất 6 ký tự", Toast.LENGTH_SHORT).show();
                    passwordInput.requestFocus();
                    return;
                }

                if (confPassword.isEmpty()) {
                    Toast.makeText(SignupActivity.this, "Vui lòng nhập lại mật khẩu", Toast.LENGTH_SHORT).show();
                    confPasswordInput.requestFocus();
                    return;
                }

                // Mật khẩu không khớp trong 2 lần nhập
                if (!password.equals(confPassword)) {
                    Toast.makeText(SignupActivity.this, "Mật khẩu nhập lại không khớp", Toast.LENGTH_SHORT).show();
                    return;
                }

                createUser(email, password);

                // Hiện thanh xoay
                progressBar.setVisibility(View.VISIBLE);

            }
        });
    }

    private void createUser(String email, String password) {
        mAuth.createUserWithEmailAndPassword(email, password)
                .addOnCompleteListener(this, new OnCompleteListener<AuthResult>() {
                    @Override
                    public void onComplete(@NonNull Task<AuthResult> task) {
                        progressBar.setVisibility(View.GONE);
                        if (task.isSuccessful()) {
                            // Sign in success, update UI with the signed-in user's information
                            FirebaseUser user = mAuth.getCurrentUser();
                            String userId = user.getUid();
                            String username = userNameInput.getText().toString();

                            // Save the username to Firebase Realtime Database
                            saveUsernameToDatabase(userId, username);

                            Toast.makeText(SignupActivity.this, "Tạo tài khoản thành công.",
                                    Toast.LENGTH_SHORT).show();

                            AlertDialog.Builder alert = new AlertDialog.Builder(SignupActivity.this);
                            alert.setTitle("Đăng ký tài khoản thành công");
                            alert.setMessage("Bạn muốn quay lại màn hình đăng nhập ?");
                            alert.setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                                public void onClick(DialogInterface dialog, int which) {
                                    Intent intent = new Intent(getApplicationContext(), LoginActivity.class);
                                    startActivity(intent);
                                    finish();
                                }
                            });
                            alert.setNegativeButton(android.R.string.no, new DialogInterface.OnClickListener() {
                                public void onClick(DialogInterface dialog, int which) {
                                    dialog.cancel();
                                }
                            });
                            alert.show();
                        } else {
                            // If sign in fails, display a message to the user.
                            Toast.makeText(SignupActivity.this, "Tạo tài khoản thất bại.",
                                    Toast.LENGTH_SHORT).show();
                        }
                    }
                });
    }

    private void saveUsernameToDatabase(String userId, String username) {
        // Save only the username under the user's UID
        databaseReference.child(userId).child("username").setValue(username)
                .addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull Task<Void> task) {
                        if (task.isSuccessful()) {
                            Log.d("SignupActivity", "Username added to database successfully");
                        } else {
                            Log.e("SignupActivity", "Failed to add username to database", task.getException());
                        }
                    }
                });
    }
}