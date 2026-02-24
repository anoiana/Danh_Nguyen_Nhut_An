import React from 'react';

const Footer = () => {
    return (
        <footer className="mt-auto px-8 py-12 bg-white border-t border-gray-100">
            <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-start gap-12">
                {/* Branding Section */}
                <div className="space-y-4 max-w-xs">
                    <div className="flex items-center space-x-3">
                        <div className="w-8 h-8 bg-gradient-to-br from-pink-500 to-purple-600 rounded-xl flex items-center justify-center shadow-md">
                            <span className="text-white text-sm font-bold">M</span>
                        </div>
                        <h2 className="text-xl font-black text-gray-800 tracking-tight">MiniDating</h2>
                    </div>
                    <p className="text-gray-400 text-sm font-medium leading-relaxed">
                        The modern web application for meaningful connections. Find your perfect match through shared interests and schedules.
                    </p>
                    <div className="flex gap-4">
                        {['Twitter', 'Instagram', 'Facebook'].map(social => (
                            <div key={social} className="w-10 h-10 rounded-xl bg-gray-50 flex items-center justify-center text-gray-400 hover:bg-pink-50 hover:text-pink-500 cursor-pointer transition-all">
                                <span className="text-xs font-bold font-monospaced leading-none">{social[0]}</span>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Links Sections */}
                <div className="grid grid-cols-2 md:grid-cols-3 gap-12">
                    <div className="space-y-4">
                        <h4 className="text-xs font-black text-gray-900 uppercase tracking-widest">Platform</h4>
                        <ul className="space-y-2">
                            {['Explore', 'Matches', 'Events', 'Safety'].map(link => (
                                <li key={link} className="text-sm font-bold text-gray-400 hover:text-pink-500 cursor-pointer transition-colors">{link}</li>
                            ))}
                        </ul>
                    </div>
                    <div className="space-y-4">
                        <h4 className="text-xs font-black text-gray-900 uppercase tracking-widest">Company</h4>
                        <ul className="space-y-2">
                            {['About', 'Careers', 'Blog', 'Contact'].map(link => (
                                <li key={link} className="text-sm font-bold text-gray-400 hover:text-pink-500 cursor-pointer transition-colors">{link}</li>
                            ))}
                        </ul>
                    </div>
                    <div className="space-y-4">
                        <h4 className="text-xs font-black text-gray-900 uppercase tracking-widest">Legal</h4>
                        <ul className="space-y-2">
                            {['Privacy', 'Terms', 'Cookie Policy'].map(link => (
                                <li key={link} className="text-sm font-bold text-gray-400 hover:text-pink-500 cursor-pointer transition-colors">{link}</li>
                            ))}
                        </ul>
                    </div>
                </div>
            </div>

            <div className="max-w-7xl mx-auto mt-16 pt-8 border-t border-gray-50 flex flex-col md:flex-row justify-between items-center gap-4">
                <p className="text-xs font-bold text-gray-300 uppercase tracking-[0.2em]">
                    © 2026 MiniDating Inc. All rights reserved.
                </p>
                <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-green-400"></span>
                    <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest">Systems Operational</p>
                </div>
            </div>
        </footer>
    );
};

export default Footer;
