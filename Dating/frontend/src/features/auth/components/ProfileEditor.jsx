import React from 'react';
import { useProfileEditor } from '../hooks/useProfileEditor';

// Sub-components (each < 80 lines, single responsibility)
import AvatarSection from './profile/AvatarSection';
import InfoFields from './profile/InfoFields';
import PhotoGallery from './profile/PhotoGallery';
import InterestsPicker from './profile/InterestsPicker';
import LivePreview from './profile/LivePreview';

/**
 * ProfileEditor — Thin orchestrator component.
 *
 * BEFORE refactor: 391 lines (logic + UI all mixed together)
 * AFTER refactor:  ~85 lines (pure rendering, delegates to hook + sub-components)
 *
 * Architecture:
 *   useProfileEditor (hook)  → Form state, uploads, submission
 *   AvatarSection             → Avatar + cover photo
 *   InfoFields                → Name, Age, Gender, Bio inputs
 *   PhotoGallery              → Photo grid with upload/delete
 *   InterestsPicker           → Interest tags grid
 *   LivePreview               → Sticky preview card
 */
const ProfileEditor = ({ currentUser, onUpdate, error }) => {
    const {
        name, setName,
        age, setAge,
        gender, setGender,
        bio, setBio,
        avatarUrl,
        photos,
        interests,
        fieldErrors,
        handleFileChange,
        removePhoto,
        toggleInterest,
        handleSubmit,
    } = useProfileEditor(currentUser, onUpdate, error);

    return (
        <div className="max-w-7xl mx-auto animate-fade-in pb-20">
            {/* Header Section */}
            <div className="mb-12 px-4 md:px-0">
                <div className="flex flex-col md:flex-row items-end justify-between gap-6">
                    <div className="space-y-4">
                        <div className="inline-flex items-center gap-2 bg-pink-50 px-4 py-1.5 rounded-full border border-pink-100">
                            <span className="text-pink-500 text-xs animate-pulse">●</span>
                            <span className="text-[10px] font-black text-pink-600 uppercase tracking-widest">Profile Editor</span>
                        </div>
                        <h2 className="text-5xl md:text-7xl font-black text-slate-800 tracking-tight italic leading-[1.1] px-2">
                            Refine Your <span className="bg-clip-text text-transparent bg-gradient-to-r from-pink-500 to-purple-600 pr-2">Identity</span>
                        </h2>
                        <p className="text-slate-400 font-medium max-w-md leading-relaxed">
                            Your profile is your digital aura. Make it shine and attract the right spark! ✨
                        </p>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
                {/* Left Side: Editor Form */}
                <div className="lg:col-span-8 space-y-10">
                    <form onSubmit={handleSubmit} className="space-y-10">
                        {/* Avatar & Cover */}
                        <AvatarSection
                            avatarUrl={avatarUrl}
                            currentUser={currentUser}
                            name={name}
                            onFileChange={handleFileChange}
                        />

                        {/* Info Fields (nested inside the avatar card visually, but separate component) */}
                        <InfoFields
                            name={name} setName={setName}
                            age={age} setAge={setAge}
                            gender={gender} setGender={setGender}
                            bio={bio} setBio={setBio}
                            fieldErrors={fieldErrors}
                        />

                        {/* Gallery */}
                        <PhotoGallery
                            photos={photos}
                            onFileChange={handleFileChange}
                            onRemovePhoto={removePhoto}
                        />

                        {/* Interests */}
                        <InterestsPicker
                            interests={interests}
                            onToggle={toggleInterest}
                        />

                        {/* Save Button */}
                        <button
                            type="submit"
                            className="w-full bg-slate-900 text-white font-black text-xs uppercase tracking-[0.5em] py-10 rounded-[3rem] shadow-2xl shadow-slate-300 hover:bg-slate-800 transition-all transform hover:-translate-y-1 active:scale-95 flex items-center justify-center gap-6 group relative overflow-hidden"
                        >
                            <span className="text-3xl group-hover:rotate-12 transition-transform">✨</span>
                            <span>Seal My Identity</span>
                            <div className="absolute top-0 -inset-full h-full w-1/2 z-5 block transform -skew-x-12 bg-gradient-to-r from-transparent to-white opacity-10 group-hover:animate-shine" />
                        </button>
                    </form>
                </div>

                {/* Right Side: Live Preview (Sticky) */}
                <div className="lg:col-span-4 hidden lg:block sticky top-32 h-fit">
                    <LivePreview
                        name={name}
                        age={age}
                        gender={gender}
                        bio={bio}
                        avatarUrl={avatarUrl}
                        photos={photos}
                        interests={interests}
                        currentUser={currentUser}
                    />
                </div>
            </div>
        </div>
    );
};

export default ProfileEditor;
