package com.example.login.adapter;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.recyclerview.widget.RecyclerView;

import com.example.login.R;
import com.example.login.activity.TopicActivity;
import com.example.login.model.Folder;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

import java.util.List;

public class FolderAdapter extends RecyclerView.Adapter<FolderAdapter.FolderViewHolder> {

    private List<Folder> folderList; // Danh sách dữ liệu
    private Context context; // Thêm biến context
    private OnFolderDeletedListener listener;

    public interface OnFolderDeletedListener {
        void onFolderDeleted();
    }

    public FolderAdapter(Context context, List<Folder> folderList, OnFolderDeletedListener listener) {
        this.context = context;
        this.folderList = folderList;
        this.listener = listener;
    }

    @NonNull
    @Override
    public FolderViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        // Inflate layout cho mỗi item trong danh sách
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_folder, parent, false);
        return new FolderViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull FolderViewHolder holder, int position) {
        // Gán dữ liệu cho từng item trong danh sách
        Folder folder = folderList.get(position);
        holder.topicName.setText(folder.getFolderName());

        // Xử lý sự kiện click
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Chuyển sang Activity mới
                Intent intent = new Intent(context, TopicActivity.class);
                // Gửi dữ liệu qua Intent nếu cần
                intent.putExtra("folder_id", folder.getFolderId());
                intent.putExtra("folder_name", folder.getFolderName());
                context.startActivity(intent);
            }
        });


        // Sửa folder
        holder.editButton.setOnClickListener(v -> showEditDialog(folder, position));

        // Xóa folder
        holder.deleteButton.setOnClickListener(v -> {
            new AlertDialog.Builder(context)
                    .setTitle("Xóa folder")
                    .setMessage("Bạn có muốn xóa folder?")
                    .setPositiveButton("Có", (dialog, which) -> deleteFolder(folder.getFolderId(), position))
                    .setNegativeButton("Không", null)
                    .show();
        });

    }

    @Override
    public int getItemCount() {
        return folderList.size();
    }

    // ViewHolder cho mỗi item
    public static class FolderViewHolder extends RecyclerView.ViewHolder {
        TextView topicName;
        ImageButton editButton, deleteButton;

        public FolderViewHolder(@NonNull View itemView) {
            super(itemView);
            topicName = itemView.findViewById(R.id.topic_name);
            editButton = itemView.findViewById(R.id.folder_edit_btn);
            deleteButton = itemView.findViewById(R.id.folder_delete_btn);
        }
    }

    private void deleteFolder(String folderId, int position) {
        DatabaseReference folderRef = FirebaseDatabase.getInstance().getReference("users")
                .child(FirebaseAuth.getInstance().getCurrentUser().getUid())
                .child("folders").child(folderId);

        folderRef.removeValue().addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                // Safely remove item and update adapter
                if (position >= 0 && position < folderList.size()) {
                    folderList.remove(position);
                    notifyDataSetChanged();
                    if (listener != null) {
                        listener.onFolderDeleted(); // Refresh lại data
                    }
                }
                Toast.makeText(context, "Xóa folder thành công", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(context, "Có lỗi khi xóa folder", Toast.LENGTH_SHORT).show();
            }
        });
    }


    private void updateFolder(String folderId, String newFolderName, int position) {
        DatabaseReference folderRef = FirebaseDatabase.getInstance().getReference("users")
                .child(FirebaseAuth.getInstance().getCurrentUser().getUid())
                .child("folders").child(folderId);

        folderRef.child("folderName").setValue(newFolderName).addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                // Cập nhật danh sách
                folderList.get(position).setFolderName(newFolderName);
                notifyItemChanged(position);
                Toast.makeText(context, "Cập nhật thành công", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(context, "Có lỗi khi cập nhật", Toast.LENGTH_SHORT).show();
            }
        });
    }


    private void showEditDialog(Folder folder, int position) {
        // Inflate the edit dialog layout
        LayoutInflater inflater = LayoutInflater.from(context);
        View dialogView = inflater.inflate(R.layout.dialog_add_folder, null);

        // Set up AlertDialog
        AlertDialog dialog = new AlertDialog.Builder(context)
                .setView(dialogView)
                .setTitle("Chỉnh sửa thư mục")
                .create();

        // Get dialog views
        EditText editFolderName = dialogView.findViewById(R.id.edit_folder_name);
        Button btnCancel = dialogView.findViewById(R.id.btn_cancel);
        Button btnOk = dialogView.findViewById(R.id.btn_ok);

        // Lấy data
        editFolderName.setText(folder.getFolderName());

        // Cancel button
        btnCancel.setOnClickListener(v -> dialog.dismiss());

        // OK button
        btnOk.setOnClickListener(v -> {
            String newFolderName = editFolderName.getText().toString();
            if (!newFolderName.isEmpty()) {
                updateFolder(folder.getFolderId(), newFolderName, position);
                dialog.dismiss();
            } else {
                editFolderName.setError("Tên thư mục không được để trống");
                editFolderName.requestFocus();
            }
        });

        dialog.show();
    }


}
