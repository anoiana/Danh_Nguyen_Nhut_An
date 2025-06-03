package com.example.login.activity;

import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.example.login.R;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.android.material.textfield.TextInputEditText;
import com.google.firebase.auth.AuthResult;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthInvalidCredentialsException;
import com.google.firebase.auth.FirebaseAuthInvalidUserException;
import com.google.firebase.auth.FirebaseUser;

public class LoginActivity extends AppCompatActivity {
    Button btnSignup;
    EditText emailInput;
    TextInputEditText passwordInput;
    Button btnLogIn, btnForgotPassword;
    FirebaseAuth mAuth;
    ProgressBar progressBar;

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
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_login);

        progressBar = findViewById(R.id.progressBar);
        mAuth = FirebaseAuth.getInstance();
        btnSignup = findViewById(R.id.btnSignup);
        emailInput = findViewById(R.id.username);
        passwordInput = findViewById(R.id.password);
        btnLogIn = findViewById(R.id.btnLogin);
        btnForgotPassword =  findViewById(R.id.btnForgotPassword);

        btnLogIn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String email, password;
                email = emailInput.getText().toString();
                password = passwordInput.getText().toString();

                if (email.isEmpty()) {
                    Toast.makeText(LoginActivity.this, "Vui lòng nhập email", Toast.LENGTH_SHORT).show();
                    emailInput.requestFocus();
                    return;
                }

                if (password.isEmpty()) {
                    Toast.makeText(LoginActivity.this, "Vui lòng nhập mật khẩu", Toast.LENGTH_SHORT).show();
                    passwordInput.requestFocus();
                    return;
                }
                progressBar.setVisibility(View.VISIBLE);
                signIn(email, password);
            }
        });


        btnSignup.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(LoginActivity.this, SignupActivity.class);
                startActivity(i);
            }
        });


        btnForgotPassword.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AlertDialog.Builder alert = new AlertDialog.Builder(LoginActivity.this);
                alert.setTitle("Quên mật khẩu");
                alert.setMessage("Bạn có muốn reset lại mật khẩu không ?");
                alert.setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                        Intent i = new Intent(LoginActivity.this, ForgotPasswordActivity.class);
                        startActivity(i);
                        finish();
                    }
                });
                alert.setNegativeButton(android.R.string.no, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                        dialog.cancel();
                    }
                });
                alert.show();
            }
        });
    }

    private void signIn(String email, String password) {
        mAuth.signInWithEmailAndPassword(email, password)
                .addOnCompleteListener(this, new OnCompleteListener<AuthResult>() {
                    @Override
                    public void onComplete(@NonNull Task<AuthResult> task) {
                        progressBar.setVisibility(View.GONE);
                        if (task.isSuccessful()) {
                            // Sign in success, update UI with the signed-in user's information
                            FirebaseUser user = mAuth.getCurrentUser();

                            Toast.makeText(LoginActivity.this, "Đăng nhập thành công.",
                                    Toast.LENGTH_SHORT).show();

                            Intent intent = new Intent(getApplicationContext(), MainActivity.class);
                            startActivity(intent);
                            finish();
                        }
                        else if (task.getException() instanceof FirebaseAuthInvalidUserException) {
                            // Người dùng không tồn tại
                            Toast.makeText(LoginActivity.this,
                                    "Người dùng không tồn tại.",
                                    Toast.LENGTH_SHORT).show();
                        }
                        else if (task.getException() instanceof FirebaseAuthInvalidCredentialsException) {
                            // Sai mật khẩu
                            Toast.makeText(LoginActivity.this,
                                    "Sai mật khẩu, vui lòng thử lại.",
                                    Toast.LENGTH_SHORT).show();
                        }
                        else {
                            // Xử lý các lỗi khác
                            Toast.makeText(LoginActivity.this,
                                    "Đăng nhập thất bại, vui lòng thử lại sau.",
                                    Toast.LENGTH_SHORT).show();
                        }
                    }
                });
    }
}