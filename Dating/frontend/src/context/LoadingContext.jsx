import React, { createContext, useContext, useState } from 'react';

const LoadingContext = createContext();

export const LoadingProvider = ({ children }) => {
    const [isLoading, setIsLoading] = useState(false);

    const showLoading = () => setIsLoading(true);
    const hideLoading = () => setIsLoading(false);

    return (
        <LoadingContext.Provider value={{ isLoading, showLoading, hideLoading }}>
            <div className="relative">
                {isLoading && (
                    <div className="fixed inset-0 z-[9999] flex flex-col items-center justify-center bg-white/80 backdrop-blur-xl">
                        {/* Premium Loader Animation */}
                        <div className="relative w-40 h-40">
                            {/* Outer spinning ring */}
                            <div className="absolute inset-0 border-4 border-pink-100 rounded-full"></div>
                            <div className="absolute inset-0 border-4 border-t-pink-500 border-pink-500/0 rounded-full animate-spin"></div>

                            {/* Inner pulsing logo container */}
                            <div className="absolute inset-4 bg-gradient-to-br from-pink-500 to-purple-600 rounded-full flex items-center justify-center shadow-2xl animate-pulse-soft">
                                <span className="text-white text-5xl font-black italic">M</span>
                            </div>

                            {/* Decorative particles */}
                            <div className="absolute -top-4 -right-4 w-8 h-8 bg-purple-500/20 rounded-full blur-xl animate-float"></div>
                            <div className="absolute -bottom-4 -left-4 w-8 h-8 bg-pink-500/20 rounded-full blur-xl animate-float" style={{ animationDelay: '1s' }}></div>
                        </div>

                        {/* Loading text */}
                        <div className="mt-12 text-center">
                            <h2 className="text-3xl font-black text-slate-800 italic animate-text-shimmer">
                                Setting the mood...
                            </h2>
                            <p className="text-slate-400 font-bold uppercase tracking-[0.3em] text-[10px] mt-2">
                                Finding your perfect vibe
                            </p>
                        </div>
                    </div>
                )}
                {children}
            </div>
        </LoadingContext.Provider>
    );
};

export const useLoading = () => {
    const context = useContext(LoadingContext);
    if (!context) {
        throw new Error('useLoading must be used within a LoadingProvider');
    }
    return context;
};
