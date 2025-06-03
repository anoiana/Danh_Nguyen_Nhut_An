package com.example.login.model;

import java.io.Serializable;

public class Account implements Serializable {
    private String email;
    private String name;
    private String password;
    private String avatarPath;
    private Integer learnerCorrectCount;

    public Integer getLearnerCorrectCount() {
        return learnerCorrectCount;
    }

    public void setLearnerCorrectCount(Integer userCorrectCount) {
        this.learnerCorrectCount = userCorrectCount;
    }

    public Account() {}

    public Account(String email, String name, String password, String avatarPath) {
        this.email = email;
        this.name = name;
        this.password = password;
        this.avatarPath = avatarPath;
    }

    public Account(String name, String avatarPath) {
        this.name = name;
        this.avatarPath = avatarPath;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getAvatarPath() {
        return avatarPath;
    }

    public void setAvatarPath(String avatarPath) {
        this.avatarPath = avatarPath;
    }

}
