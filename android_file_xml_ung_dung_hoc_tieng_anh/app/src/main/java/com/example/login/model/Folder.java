package com.example.login.model;

import java.util.List;

public class Folder {
    private String folderId;
    private String folderName;
    // description ?
    private String ownerId; // mã người dùng
    private List<Topic> topicList = null;

    public Folder() {}

    public Folder(String folderId, String folderName, String ownerId, List<Topic> topicList) {
        this.folderId = folderId;
        this.folderName = folderName;
        this.ownerId = ownerId;
        this.topicList = topicList;
    }

    public String getFolderId() {
        return folderId;
    }

    public void setFolderId(String folderId) {
        this.folderId = folderId;
    }

    public String getFolderName() {
        return folderName;
    }

    public void setFolderName(String folderName) {
        this.folderName = folderName;
    }

    public String getOwnerId() {
        return ownerId;
    }

    public void setOwnerId(String ownerId) {
        this.ownerId = ownerId;
    }

    public List<Topic> getTopicList() {
        return topicList;
    }

    public void setTopicList(List<Topic> topicList) {
        this.topicList = topicList;
    }
}
