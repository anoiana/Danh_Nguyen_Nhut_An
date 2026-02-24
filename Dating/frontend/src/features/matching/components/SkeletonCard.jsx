import React from 'react';

const SkeletonCard = () => {
    return (
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col space-y-4 animate-pulse">
            <div className="w-full h-48 bg-gray-200 rounded-xl"></div>
            <div className="space-y-3">
                <div className="h-6 bg-gray-200 rounded w-3/4"></div>
                <div className="h-4 bg-gray-200 rounded w-full"></div>
                <div className="h-4 bg-gray-200 rounded w-5/6"></div>
            </div>
            <div className="pt-4 flex justify-between items-center">
                <div className="h-10 bg-gray-200 rounded-full w-24"></div>
                <div className="h-10 bg-gray-200 rounded-full w-10"></div>
            </div>
        </div>
    );
};

export default SkeletonCard;
