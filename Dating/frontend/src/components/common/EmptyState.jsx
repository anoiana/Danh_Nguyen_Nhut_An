import React from 'react';

/**
 * Reusable empty state placeholder.
 * Replaces multiple identical "no data" displays across the app.
 *
 * @param {string} icon - Emoji icon to display. Default: '😴'
 * @param {string} title - Heading text
 * @param {string} description - Subtitle description
 */
const EmptyState = ({ icon = '😴', title = 'Nothing here yet!', description = '' }) => {
    return (
        <div className="glass-card rounded-[3rem] p-20 text-center space-y-6 border-dashed border-2 bg-white/30 backdrop-blur-xl">
            <div className="text-7xl opacity-30 animate-float">{icon}</div>
            <div className="space-y-2">
                <p className="text-2xl font-black text-gray-800">{title}</p>
                {description && (
                    <p className="text-gray-500 font-medium italic">{description}</p>
                )}
            </div>
        </div>
    );
};

export default EmptyState;
