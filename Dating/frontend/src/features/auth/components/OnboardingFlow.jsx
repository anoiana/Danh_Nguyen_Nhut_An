import React, { useState } from 'react';
import { client } from '../../../lib/axios';
import { useNotification } from '../../../context/NotificationContext';
import { useLoading } from '../../../context/LoadingContext';

const INTEREST_OPTIONS = [
    { id: '1', name: 'Travel', icon: '✈️' },
    { id: '2', name: 'Music', icon: '🎵' },
    { id: '3', name: 'Movies', icon: '🎬' },
    { id: '4', name: 'Cooking', icon: '🍳' },
    { id: '5', name: 'Sports', icon: '⚽' },
    { id: '6', name: 'Reading', icon: '📚' },
    { id: '7', name: 'Coffee', icon: '☕' },
    { id: '8', name: 'Photography', icon: '📸' },
    { id: '9', name: 'Gaming', icon: '🎮' },
    { id: '10', name: 'Pets', icon: '🐶' },
    { id: '11', name: 'Art', icon: '🎨' },
    { id: '12', name: 'Fashion', icon: '✨' },
];

const OnboardingFlow = ({ currentUser, onUpdate, onComplete }) => {
    const [step, setStep] = useState(1);
    const [formData, setFormData] = useState({
        name: currentUser.name || '',
        age: currentUser.age || 18,
        gender: currentUser.gender || 'Other',
        bio: currentUser.bio || '',
        email: currentUser.email || '',
        interests: currentUser.interests ? currentUser.interests.split(',') : [],
        photos: currentUser.photos ? currentUser.photos.split(',') : [],
    });
    const [uploading, setUploading] = useState(false);
    const { showNotification } = useNotification();
    const { showLoading, hideLoading } = useLoading();

    const handleUpdateField = (field, value) => {
        setFormData(prev => ({ ...prev, [field]: value }));
    };

    const toggleInterest = (interestName) => {
        setFormData(prev => {
            const current = prev.interests;
            if (current.includes(interestName)) {
                return { ...prev, interests: current.filter(i => i !== interestName) };
            } else {
                return { ...prev, interests: [...current, interestName] };
            }
        });
    };

    const handleFileUpload = async (e, startIndex) => {
        const files = Array.from(e.target.files);
        if (files.length === 0) return;

        // Total slots available are 6
        const availableSlots = 6 - startIndex;
        const filesToUpload = files.slice(0, availableSlots);

        const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
        const oversizedFiles = filesToUpload.filter(f => f.size > MAX_FILE_SIZE);

        if (oversizedFiles.length > 0) {
            showNotification(`${oversizedFiles.length} images are too large! Max 10MB per image. 📸`, 'error');
            e.target.value = '';
            return;
        }

        setUploading(true);
        showLoading();

        try {
            const uploadPromises = filesToUpload.map(async (file, i) => {
                const data = new FormData();
                data.append('file', file);
                const response = await client.post('/users/upload', data);
                return { index: startIndex + i, url: response.data };
            });

            const results = await Promise.all(uploadPromises);

            setFormData(prev => {
                const newPhotos = [...prev.photos];
                while (newPhotos.length < 6) newPhotos.push(null);

                results.forEach(res => {
                    newPhotos[res.index] = res.url;
                });
                return { ...prev, photos: newPhotos };
            });

            showNotification(`Successfully uploaded ${results.length} photo(s)! ✨`, 'success');
        } catch (error) {
            console.error(error);
            showNotification('Some uploads failed. Please try again.', 'error');
        } finally {
            setUploading(false);
            hideLoading();
            e.target.value = '';
        }
    };

    const handleFinish = async () => {
        if (formData.photos.filter(p => p).length < 2) {
            return showNotification('Hi! Please upload at least 2 photos to continue.', 'error');
        }

        showLoading();
        try {
            // Request GPS coordinates (fallback to central HCMC if denied)
            let latitude = 10.7769;
            let longitude = 106.7009;
            try {
                const pos = await new Promise((resolve, reject) =>
                    navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 5000 })
                );
                latitude = pos.coords.latitude;
                longitude = pos.coords.longitude;
            } catch {
                showNotification('Location not available — using default HCMC.', 'info');
            }

            await onUpdate({
                ...formData,
                interests: formData.interests.join(','),
                photos: formData.photos.filter(p => p).join(','),
                avatarUrl: formData.photos[0],
                latitude,
                longitude
            });
            showNotification('Awesome! Your profile is ready.', 'success');
            onComplete();
        } catch (error) {
            const serverErrors = error.response?.data;
            if (serverErrors && typeof serverErrors === 'object') {
                const errorMessages = Object.values(serverErrors).join('. ');
                showNotification(errorMessages, 'error');
            } else {
                showNotification('Error saving profile. Please check your data.', 'error');
            }
        } finally {
            hideLoading();
        }
    };

    return (
        <div className="fixed inset-0 z-[200] bg-white flex flex-col items-center p-6 sm:p-12 overflow-y-auto">
            {/* Background elements */}
            <div className="fixed -top-10 -left-10 w-64 h-64 bg-pink-100 rounded-full blur-3xl opacity-50 -z-10"></div>
            <div className="fixed -bottom-10 -right-10 w-64 h-64 bg-purple-100 rounded-full blur-3xl opacity-50 -z-10"></div>

            <div className="w-full max-w-2xl space-y-12 animate-fade-in py-12">
                {/* Progress Bar */}
                <div className="flex justify-between items-center mb-12 gap-4">
                    {[1, 2, 3, 4].map(s => (
                        <div
                            key={s}
                            className={`h-2.5 flex-1 rounded-full transition-all duration-500 ${step >= s ? 'bg-gradient-to-r from-pink-500 to-purple-600' : 'bg-gray-100'}`}
                        ></div>
                    ))}
                </div>

                {/* Step 1: Identity */}
                {step === 1 && (
                    <div className="space-y-10 animate-slide-up">
                        <div className="text-center space-y-4">
                            <h2 className="text-6xl font-black text-gray-900 tracking-tight italic px-2">What's your name?</h2>
                            <p className="text-gray-500 font-bold text-lg">This is how you'll appear on MiniDating.</p>
                        </div>
                        <div className="space-y-8">
                            <input
                                type="text"
                                placeholder="Enter your name..."
                                value={formData.name}
                                onChange={(e) => handleUpdateField('name', e.target.value)}
                                className="w-full text-4xl font-black bg-transparent border-b-4 border-gray-100 focus:border-pink-500 outline-none pb-4 transition-all"
                            />

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                <div className="space-y-3">
                                    <label className="text-xs font-bold text-gray-400 uppercase tracking-widest pl-1">How old are you?</label>
                                    <input
                                        type="number"
                                        value={formData.age}
                                        onChange={(e) => handleUpdateField('age', e.target.value)}
                                        className="w-full bg-gray-50 rounded-2xl p-5 text-xl font-bold outline-none focus:ring-2 focus:ring-pink-500 border border-gray-100"
                                    />
                                </div>
                                <div className="space-y-3">
                                    <label className="text-xs font-bold text-gray-400 uppercase tracking-widest pl-1">Your Gender</label>
                                    <div className="flex gap-2">
                                        {['Male', 'Female', 'Other'].map(g => (
                                            <button
                                                key={g}
                                                onClick={() => handleUpdateField('gender', g)}
                                                className={`flex-1 p-5 rounded-2xl font-bold transition-all border ${formData.gender === g ? 'bg-gray-900 text-white border-gray-900 shadow-xl scale-105' : 'bg-gray-50 text-gray-400 border-gray-100 hover:bg-gray-100'}`}
                                            >
                                                {g === 'Male' ? 'Male' : g === 'Female' ? 'Female' : 'Other'}
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        </div>
                        <button
                            onClick={() => formData.name && setStep(2)}
                            disabled={!formData.name}
                            className="w-full py-6 bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black text-2xl rounded-3xl shadow-lg hover:shadow-pink-200 transition-all transform hover:scale-[1.02] disabled:opacity-50"
                        >
                            Next 🚀
                        </button>
                    </div>
                )}

                {/* Step 2: About & Interests */}
                {step === 2 && (
                    <div className="space-y-10 animate-slide-up">
                        <div className="text-center space-y-4">
                            <h2 className="text-6xl font-black text-gray-900 tracking-tight italic px-2">Your Interests?</h2>
                            <p className="text-gray-500 font-bold text-lg">Pick what you love to find someone with the same vibe.</p>
                        </div>

                        <div className="space-y-4">
                            <label className="text-xs font-bold text-gray-400 uppercase tracking-widest pl-1">Short Bio</label>
                            <textarea
                                placeholder="Share a bit about your personality or special hobbies..."
                                value={formData.bio}
                                onChange={(e) => handleUpdateField('bio', e.target.value)}
                                className="w-full h-40 bg-gray-50 rounded-[2rem] p-8 text-xl font-medium outline-none focus:ring-2 focus:ring-pink-500 resize-none border border-gray-100"
                            />
                        </div>

                        <div className="flex flex-wrap gap-3 justify-center">
                            {INTEREST_OPTIONS.map(opt => (
                                <button
                                    key={opt.id}
                                    onClick={() => toggleInterest(opt.name)}
                                    className={`px-8 py-4 rounded-full font-bold text-base flex items-center gap-3 transition-all ${formData.interests.includes(opt.name) ? 'bg-pink-500 text-white shadow-lg scale-110' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'}`}
                                >
                                    <span className="text-xl">{opt.icon}</span>
                                    {opt.name}
                                </button>
                            ))}
                        </div>

                        <div className="flex gap-4">
                            <button onClick={() => setStep(1)} className="flex-1 py-6 bg-gray-100 text-gray-500 font-black text-xl rounded-3xl hover:bg-gray-200 transition-all">Back</button>
                            <button
                                onClick={() => setStep(3)}
                                className="flex-[2] py-6 bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black text-xl rounded-3xl shadow-lg hover:shadow-pink-200 transition-all transform hover:scale-[1.02]"
                            >
                                Continue ✨
                            </button>
                        </div>
                    </div>
                )}

                {/* Step 3: Photos */}
                {step === 3 && (
                    <div className="space-y-10 animate-slide-up">
                        <div className="text-center space-y-4">
                            <h2 className="text-6xl font-black text-gray-900 tracking-tight italic px-2">Add Photos?</h2>
                            <p className="text-gray-500 font-bold text-lg">Good looking profiles get more matches! Add at least 2 photos ✨</p>
                        </div>

                        <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
                            {[0, 1, 2, 3, 4, 5].map(idx => (
                                <div key={idx} className="aspect-[3/4] relative group">
                                    {formData.photos[idx] ? (
                                        <div className="w-full h-full rounded-3xl overflow-hidden shadow-xl ring-4 ring-white">
                                            <img src={formData.photos[idx]} alt="User" className="w-full h-full object-cover" />
                                            <button
                                                onClick={() => {
                                                    const newPhotos = [...formData.photos];
                                                    newPhotos[idx] = null;
                                                    setFormData(prev => ({ ...prev, photos: newPhotos }));
                                                }}
                                                className="absolute top-3 right-3 w-10 h-10 bg-black/50 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-500"
                                            >
                                                ✕
                                            </button>
                                        </div>
                                    ) : (
                                        <label className={`w-full h-full border-4 border-dashed rounded-[2rem] flex flex-col items-center justify-center cursor-pointer transition-all ${uploading ? 'opacity-50 bg-gray-50' : 'hover:bg-pink-50 hover:border-pink-300 bg-gray-50 border-gray-200'}`}>
                                            <span className="text-4xl text-gray-300 font-light mb-2">+</span>
                                            <span className="text-[12px] font-black uppercase text-gray-400 tracking-widest text-center px-4">
                                                {uploading ? 'Uploading...' : 'Add Photos'}
                                            </span>
                                            <input
                                                type="file"
                                                accept="image/*"
                                                multiple
                                                className="hidden"
                                                disabled={uploading}
                                                onChange={(e) => handleFileUpload(e, idx)}
                                            />
                                        </label>
                                    )}
                                </div>
                            ))}
                        </div>

                        <div className="flex gap-4">
                            <button onClick={() => setStep(2)} className="flex-1 py-6 bg-gray-100 text-gray-500 font-black text-xl rounded-3xl hover:bg-gray-200 transition-all">Back</button>
                            <button
                                onClick={handleFinish}
                                disabled={formData.photos.filter(p => p).length < 2 || uploading}
                                className="flex-[2] py-6 bg-gray-900 text-white font-black text-xl rounded-3xl shadow-lg hover:shadow-gray-200 transition-all transform hover:scale-[1.02] disabled:opacity-50"
                            >
                                {uploading ? 'Processing...' : 'Complete 🎉'}
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default OnboardingFlow;
