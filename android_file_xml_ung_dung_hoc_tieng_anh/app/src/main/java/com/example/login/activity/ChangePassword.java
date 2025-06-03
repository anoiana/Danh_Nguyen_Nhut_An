package com.example.login.activity;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import com.example.login.R;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.android.material.textfield.TextInputEditText;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.EmailAuthProvider;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;

public class ChangePassword extends AppCompatActivity {

    ImageView goBackBtn ;
    TextInputEditText oldPassword, newPassword, confirmedPassword;
    Button changePasswordBtn;

    FirebaseUser user;
    AuthCredential authCredential;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_change_password);

        goBackBtn = findViewById(R.id.goBackBtn);
        oldPassword = findViewById(R.id.oldPasswordId);
        newPassword = findViewById(R.id.newPasswordId);
        confirmedPassword = findViewById(R.id.confirmedPasswordId);
        changePasswordBtn = findViewById(R.id.btnChangPasswordId);

        goBackBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(ChangePassword.this, MainActivity.class);
                startActivity(i);
            }
        });

        changePasswordBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String oldPasswordContent = oldPassword.getText().toString();
                String newPasswordContent = newPassword.getText().toString();
                String confirmedPasswordContent = confirmedPassword.getText().toString();

                if(oldPasswordContent.isEmpty()) {
                    showToast("Vui lòng nhập mật khẩu cũ của bạn!");
                    oldPassword.requestFocus();
                    return;
                }

                if(newPasswordContent.isEmpty()){
                    showToast("Vui lòng nhập mật khẩu mới của bạn!");
                    newPassword.requestFocus();
                    return;
                }

                if (newPasswordContent.length() < 6) {
                    showToast("Mật khẩu phải có ít nhất 6 ký tự!");
                    newPassword.requestFocus();
                    return;
                }

                if(confirmedPasswordContent.isEmpty()){
                    showToast("Vui lòng nhập mật khẩu xác nhận của bạn!");
                    confirmedPassword.requestFocus();
                    return;
                }

                if(!newPasswordContent.equals(confirmedPasswordContent)){
                    showToast("Mật khẩu xác nhận của bạn cần phải khớp với mật khẩu bạn đã nhập!");
                    confirmedPassword.requestFocus();
                    return;
                }

                updatePassword(oldPasswordContent, newPasswordContent);
            }
        });
    }

    private void updatePassword(String oldPasswordContent, String newPasswordContent){
        user = FirebaseAuth.getInstance().getCurrentUser();
        authCredential = EmailAuthProvider.getCredential(user.getEmail(), oldPasswordContent);

        user.reauthenticate(authCredential).addOnSuccessListener(new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(Void unused) {
                user.updatePassword(newPasswordContent).addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull Task<Void> task) {
                        showToast("Mật khẩu đã được cập nhật!");

                        FirebaseAuth.getInstance().signOut();

                        Intent intent = new Intent(ChangePassword.this, LoginActivity.class);
                        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                        startActivity(intent);
                        finish();
                    }
                }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        showToast(e.getMessage());
                    }
                });

            }
        }).addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
                showToast(e.getMessage());
            }
        });
    }

    private void showToast(String message) {
        Toast.makeText(ChangePassword.this, message, Toast.LENGTH_SHORT).show();
    }
}