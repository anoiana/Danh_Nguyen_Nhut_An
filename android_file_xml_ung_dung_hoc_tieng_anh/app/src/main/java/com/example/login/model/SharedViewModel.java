package com.example.login.model;
import android.util.Log;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;
import java.util.ArrayList;
import java.util.List;

public class SharedViewModel extends ViewModel {
    private final MutableLiveData<List<Word>> favoriteWords = new MutableLiveData<>(new ArrayList<>());
    private final MutableLiveData<String> folderName = new MutableLiveData<>();
    private final MutableLiveData<String> folderDescription = new MutableLiveData<>();

    public void setFolderData(String name) {
        folderName.setValue(name);
    }

    public void clearFolderData() {
        folderName.setValue(null);
        folderDescription.setValue(null);
    }


    public LiveData<String> getFolderName() {
        return folderName;
    }

    public LiveData<String> getFolderDescription() {
        return folderDescription;
    }

    public LiveData<List<Word>> getFavoriteWords() {
        return favoriteWords;
    }

    public void toggleFavorite(Word word) {
        List<Word> currentFavorites = favoriteWords.getValue();
        if (currentFavorites != null) {
            if (word.isStarred()) {
                if (!currentFavorites.contains(word)) {
                    currentFavorites.add(word);
                }
            } else {
                currentFavorites.remove(word);
            }
            favoriteWords.setValue(new ArrayList<>(currentFavorites));
        }
        Log.d("SharedViewModelToggle", "Favorite words updated: " +  currentFavorites.toString());
    }



    public void initializeFavoriteWords(List<Word> allWords) {
        List<Word> favorites = new ArrayList<>();
        for (Word word : allWords) {
            if (word.isStarred()) {
                favorites.add(word);
            }
        }
        favoriteWords.setValue(favorites);
        Log.d("SharedViewModelIniiii", "Initialized favorite words: " + favorites);
    }
}