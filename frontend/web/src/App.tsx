import { useState } from 'react';

export const App = () => {
    const [welcomeMessage] = useState<string>('Welcome to Anony');

    return (
        <main className="min-h-screen bg-slate-900 text-slate-100 flex flex-col items-center justify-center p-6">
            <div className="max-w-md w-full bg-slate-800 rounded-xl shadow-lg p-8 border border-slate-700 text-center">
                <div className="w-16 h-16 bg-indigo-600 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl font-bold shadow-md">
                    A
                </div>
                <h1 className="text-3xl font-extrabold tracking-tight text-white mb-2">
                    {welcomeMessage}
                </h1>
                <p className="text-slate-400 text-sm mb-6">
                    Anonymous Mental Health & Professional Coaching Platform
                </p>
                <div className="bg-slate-900/60 rounded-lg p-4 border border-slate-700/50 text-left mb-6">
                    <p className="text-xs font-mono text-emerald-400 flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                        Status: Backend Connected
                    </p>
                    <p className="text-xs font-mono text-slate-400 mt-1">
                        Zero-PII Anonymous Identity Engine Active
                    </p>
                </div>
                <button
                    type="button"
                    className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-2.5 px-4 rounded-lg transition-colors duration-200 shadow-sm"
                >
                    Get Started
                </button>
            </div>
        </main>
    );
};

export default App;
