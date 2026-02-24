import React, { Component } from 'react';

class ErrorBoundary extends Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false, error: null };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true, error };
    }

    componentDidCatch(error, errorInfo) {
        console.error("Uncaught error:", error, errorInfo);
    }

    render() {
        if (this.state.hasError) {
            return (
                <div className="min-h-screen flex flex-col items-center justify-center bg-white p-6 text-center">
                    <div className="w-24 h-24 bg-red-100 rounded-3xl flex items-center justify-center mb-8 animate-bounce-in">
                        <span className="text-5xl">⚠️</span>
                    </div>
                    <h1 className="text-4xl font-black text-slate-800 italic mb-4 tracking-tighter">
                        Oops! Something went wrong
                    </h1>
                    <p className="text-slate-500 max-w-md mx-auto mb-10 font-medium">
                        Our matchmaking engine hit a little snag. Don't worry, your data is safe!
                        Try refreshing the page or come back in a moment.
                    </p>
                    <button
                        onClick={() => window.location.reload()}
                        className="px-10 py-4 bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black rounded-2xl shadow-xl shadow-pink-200 hover:scale-105 transition-all text-sm uppercase tracking-widest"
                    >
                        Refresh Page ✨
                    </button>

                    {process.env.NODE_ENV === 'development' && (
                        <div className="mt-12 p-6 bg-gray-50 rounded-2xl text-left max-w-2xl w-full border border-gray-100 overflow-auto">
                            <p className="text-red-500 font-bold text-xs uppercase tracking-widest mb-2">Debug Info</p>
                            <pre className="text-slate-600 text-sm font-mono whitespace-pre-wrap">
                                {this.state.error && this.state.error.toString()}
                            </pre>
                        </div>
                    )}
                </div>
            );
        }

        return this.props.children;
    }
}

export default ErrorBoundary;
