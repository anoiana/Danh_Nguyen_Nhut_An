package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Patterns;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.example.login.R;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.auth.FirebaseAuth;

public class ForgotPasswordActivity extends AppCompatActivity {

    EditText email;
    Button btnGoBack, btnReset;
    private FirebaseAuth auth;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_forgor_password);

        email = findViewById(R.id.emailId);
        btnGoBack = findViewById(R.id.btnGoBackToLoginId);
        btnReset = findViewById(R.id.btnResetId);

        auth = FirebaseAuth.getInstance();

        btnReset.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String userEmail = email.getText().toString();

                if (userEmail.isEmpty() && !Patterns.EMAIL_ADDRESS.matcher(userEmail).matches()) {
                    Toast.makeText(ForgotPasswordActivity.this, "Vui lòng nhập email mà bạn đã đăng ký!", Toast.LENGTH_SHORT).show();
                    email.requestFocus();
                    return;
                }

                auth.sendPasswordResetEmail(userEmail).addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull Task<Void> task) {
                        if(task.isSuccessful()) {
                            Toast.makeText(ForgotPasswordActivity.this, "Đã gửi mail để bạn, vui lòng kiểm tra email của bạn!", Toast.LENGTH_SHORT).show();
                        }else{
                            Toast.makeText(ForgotPasswordActivity.this, "Không thể gửi mail đến bạn, vui lòng kiểm tra lại mail!", Toast.LENGTH_SHORT).show();
                        }
                    }
                });
            }
        });

        btnGoBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(ForgotPasswordActivity.this, LoginActivity.class);
                startActivity(i);
            }
        });

    }
}