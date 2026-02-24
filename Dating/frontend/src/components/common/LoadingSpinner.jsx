import React from 'react';

/**
 * Reusable loading spinner with consistent styling.
 * Replaces 6+ identical spinner implementations across the app.
 *
 * @param {string} size - 'sm' | 'md' | 'lg'. Default: 'md'
 * @param {string} message - Optional text below the spinner
 */
const LoadingSpinner = ({ size = 'md', message = '' }) => {
    const sizeClasses = {
        sm: 'w-8 h-8 border-[3px]',
        md: 'w-12 h-12 border-4',
        lg: 'w-16 h-16 border-4',
    };

    return (
        <div className="flex flex-col items-center justify-center p-20 space-y-4">
            <div
                className={`${sizeClasses[size]} border-pink-500 border-t-transparent rounded-full animate-spin`}
            />
            {message && (
                <p className="text-gray-400 font-black uppercase tracking-widest text-sm animate-pulse">
                    {message}
                </p>
            )}
        </div>
    );
};

export default LoadingSpinner;
