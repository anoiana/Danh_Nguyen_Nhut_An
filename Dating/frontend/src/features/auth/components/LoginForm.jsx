import React from 'react';
import { GoogleLogin } from '@react-oauth/google';

const LoginForm = ({ onGoogleLogin, loading, error }) => {
    return (
        <div className="flex items-center justify-center min-h-[90vh] p-4 bg-gradient-to-br from-pink-50 via-white to-purple-50">
            <div className="glass-card p-12 rounded-[3.5rem] w-full max-w-lg transform transition-all shadow-[0_40px_100px_-20px_rgba(236,72,153,0.3)] border-white/80 bg-white/40 backdrop-blur-2xl">
                <div className="text-center mb-12">
                    <div className="inline-block p-5 bg-gradient-to-br from-pink-100 to-purple-100 rounded-[2rem] mb-6 animate-float shadow-inner">
                        <span className="text-5xl">💝</span>
                    </div>
                    <h1 className="text-5xl font-black text-gray-900 tracking-tight leading-tight mb-4 italic">
                        MiniDating
                    </h1>
                    <p className="text-slate-500 font-medium text-lg px-4">
                        Find your soulmate using your Google account. It's fast, secure, and magical. ✨
                    </p>
                </div>

                <div className="space-y-8">
                    {error && (
                        <div className="bg-red-50 border border-red-100 p-5 rounded-3xl flex items-center space-x-4 animate-bounce-soft">
                            <span className="text-2xl">⚠️</span>
                            <p className="text-red-600 text-sm font-black uppercase tracking-tight">{error}</p>
                        </div>
                    )}

                    <div className="flex flex-col items-center gap-8 py-4">
                        <div className="relative group flex justify-center scale-125 hover:scale-[1.3] transition-all duration-500">
                            <div className="absolute -inset-1 bg-gradient-to-r from-pink-500 to-purple-600 rounded-full blur opacity-25 group-hover:opacity-75 transition duration-1000 group-hover:duration-200"></div>
                            <GoogleLogin
                                onSuccess={credentialResponse => {
                                    onGoogleLogin(credentialResponse.credential);
                                }}
                                onError={() => {
                                    console.log('Login Failed');
                                }}
                                theme="filled_blue"
                                shape="pill"
                                text="continue_with"
                                width="340"
                            />
                        </div>

                        {loading && (
                            <div className="flex flex-col items-center gap-3 animate-pulse">
                                <div className="w-8 h-8 border-4 border-pink-500 border-t-transparent rounded-full animate-spin"></div>
                                <p className="text-[10px] font-black text-pink-500 uppercase tracking-[0.3em]">Connecting to destiny...</p>
                            </div>
                        )}
                    </div>

                    <div className="pt-8 border-t border-slate-100 italic text-center">
                        <p className="text-slate-400 text-xs font-medium">
                            By joining, you agree to our <span className="underline cursor-pointer hover:text-pink-500 transition-colors">Terms</span> & <span className="underline cursor-pointer hover:text-pink-500 transition-colors">Privacy Policy</span>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default LoginForm;
