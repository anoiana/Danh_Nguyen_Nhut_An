import { useState, useEffect } from 'react';
import { useNotification } from '../../../context/NotificationContext';
import { useLoading } from '../../../context/LoadingContext';
import { getDefaultAvatar } from '../../../lib/constants';

/**
 * Predefined interests list — extracted from inline constant to be reusable.
 */
export const PREDEFINED_INTERESTS = [
    { name: "Travel", icon: "✈️" },
    { name: "Coffee", icon: "☕" },
    { name: "Movies", icon: "🎬" },
    { name: "Music", icon: "🎵" },
    { name: "Reading", icon: "📚" },
    { name: "Cooking", icon: "🍳" },
    { name: "Photography", icon: "📸" },
    { name: "Sports", icon: "⚽" },
    { name: "Gaming", icon: "🎮" },
    { name: "Art", icon: "🎨" },
    { name: "Fashion", icon: "✨" },
    { name: "Tech", icon: "💻" },
    { name: "Fitness", icon: "💪" },
    { name: "Nature", icon: "🌿" },
];

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

/**
 * Custom hook encapsulating ProfileEditor business logic.
 * Extracted from ProfileEditor.jsx (391 lines).
 *
 * Responsibilities:
 * - Form state management (name, age, gender, bio, avatar, photos, interests)
 * - File upload logic with validation
 * - Form submission with error handling
 */
export const useProfileEditor = (currentUser, onUpdate, error) => {
    const { showNotification } = useNotification();
    const { showLoading, hideLoading } = useLoading();

    // --- Form State ---
    const [name, setName] = useState(currentUser.name || '');
    const [age, setAge] = useState(currentUser.age || '');
    const [gender, setGender] = useState(currentUser.gender || 'Male');
    const [bio, setBio] = useState(currentUser.bio || '');
    const [avatarUrl, setAvatarUrl] = useState(currentUser.avatarUrl || '');
    const [photos, setPhotos] = useState(
        currentUser.photos ? currentUser.photos.split(',').filter(p => p) : []
    );
    const [interests, setInterests] = useState(
        currentUser.interests ? currentUser.interests.split(',').filter(i => i) : []
    );
    const [uploading, setUploading] = useState(false);
    const [fieldErrors, setFieldErrors] = useState({});

    // --- Sync field errors from parent ---
    useEffect(() => {
        if (typeof error === 'object' && error !== null) {
            setFieldErrors(error);
        } else {
            setFieldErrors({});
        }
    }, [error]);

    // --- File Upload ---
    const handleFileChange = async (e, isAvatar = false) => {
        const files = Array.from(e.target.files);
        if (files.length === 0) return;

        const validFiles = files.filter(file => {
            if (file.size > MAX_FILE_SIZE) {
                showNotification(`"${file.name}" is too large! Max size is 10MB. 📸`, "error");
                return false;
            }
            return true;
        });

        if (validFiles.length === 0) {
            e.target.value = '';
            return;
        }

        setUploading(true);
        showLoading();

        try {
            const uploadPromises = validFiles.map(async (file) => {
                const formData = new FormData();
                formData.append('file', file);

                const response = await fetch('/api/users/upload', {
                    method: 'POST',
                    body: formData,
                    headers: {
                        'Authorization': `Bearer ${currentUser.token}`,
                    },
                });

                if (!response.ok) throw new Error('Upload failed');
                return await response.text();
            });

            const uploadedUrls = await Promise.all(uploadPromises);

            if (isAvatar) {
                setAvatarUrl(uploadedUrls[0]);
                showNotification("Profile avatar updated! 🌟", "success");
            } else {
                setPhotos(prev => [...prev, ...uploadedUrls]);
                showNotification(`Added ${uploadedUrls.length} photo(s) to your gallery! 📸`, "success");
            }
        } catch (err) {
            showNotification("Failed to upload image. Please try again.", "error");
        } finally {
            setUploading(false);
            hideLoading();
        }
    };

    // --- Photo Management ---
    const removePhoto = (indexToRemove) => {
        setPhotos(prev => prev.filter((_, index) => index !== indexToRemove));
        showNotification("Photo removed", "info");
    };

    // --- Interests ---
    const toggleInterest = (interestName) => {
        setInterests(prev =>
            prev.includes(interestName)
                ? prev.filter(i => i !== interestName)
                : [...prev, interestName]
        );
    };

    // --- Submit ---
    const handleSubmit = async (e) => {
        e.preventDefault();
        setFieldErrors({});
        showLoading();

        try {
            const updatedUser = await onUpdate({
                ...currentUser,
                name,
                age: parseInt(age),
                gender,
                bio,
                avatarUrl,
                photos: photos.join(','),
                interests: interests.join(','),
            });

            if (updatedUser) {
                showNotification("Profile updated successfully! ✨", "success");
            }
        } catch (err) {
            const serverErrors = err.response?.data;
            if (serverErrors && typeof serverErrors === 'object') {
                const errorMessages = Object.values(serverErrors).join('. ');
                showNotification(errorMessages || "Please check your information.", "error");
                setFieldErrors(serverErrors);
            } else {
                showNotification("Failed to update profile. Please check your connection.", "error");
            }
        } finally {
            hideLoading();
        }
    };

    return {
        // Form state
        name, setName,
        age, setAge,
        gender, setGender,
        bio, setBio,
        avatarUrl,
        photos,
        interests,
        uploading,
        fieldErrors,

        // Actions
        handleFileChange,
        removePhoto,
        toggleInterest,
        handleSubmit,
    };
};
