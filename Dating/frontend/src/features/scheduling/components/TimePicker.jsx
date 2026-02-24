import React, { useState } from 'react';

const TimePicker = ({ slots, onAddSlot, onRemoveSlot, onSave, loading, error }) => {
    const [mode, setMode] = useState('single'); // 'single' or 'batch'
    const [start, setStart] = useState('');
    const [end, setEnd] = useState('');

    // Batch mode state
    const [batchFromDate, setBatchFromDate] = useState('');
    const [batchToDate, setBatchToDate] = useState('');
    const [batchStartTime, setBatchStartTime] = useState('09:00');
    const [batchEndTime, setBatchEndTime] = useState('17:00');

    const [localError, setLocalError] = useState('');

    const now = new Date();
    const threeWeeksFromNow = new Date();
    threeWeeksFromNow.setDate(now.getDate() + 21);

    const minDateSimple = now.toISOString().split('T')[0];
    const maxDateSimple = threeWeeksFromNow.toISOString().split('T')[0];
    const minDateTime = now.toISOString().slice(0, 16);
    const maxDateTime = threeWeeksFromNow.toISOString().slice(0, 16);

    const handleAddSingle = () => {
        setLocalError('');
        if (!start || !end) {
            setLocalError("Please select both start and end times.");
            return;
        }

        const startTime = new Date(start);
        const endTime = new Date(end);

        if (startTime < now) {
            setLocalError("Start time cannot be in the past!");
            return;
        }
        if (endTime <= startTime) {
            setLocalError("End time must be after start time.");
            return;
        }

        onAddSlot(start, end);
        setStart('');
        setEnd('');
    };

    const handleAddBatch = () => {
        setLocalError('');
        if (!batchFromDate || !batchToDate) {
            setLocalError("Please select both From and To dates.");
            return;
        }

        const from = new Date(batchFromDate);
        const to = new Date(batchToDate);

        if (to < from) {
            setLocalError("End date must be after start date.");
            return;
        }

        // Generate slots
        let current = new Date(from);
        const addedSlots = [];

        while (current <= to) {
            const dateStr = current.toISOString().split('T')[0];
            const startStr = `${dateStr}T${batchStartTime}:00`;
            const endStr = `${dateStr}T${batchEndTime}:00`;

            // Basic validation for each generated slot
            const s = new Date(startStr);
            const e = new Date(endStr);

            if (s >= now && e > s) {
                addedSlots.push({ start: startStr, end: endStr });
            }

            current.setDate(current.getDate() + 1);
        }

        if (addedSlots.length === 0) {
            setLocalError("No valid slots generated (check if times are in the past).");
            return;
        }

        addedSlots.forEach(s => onAddSlot(s.start, s.end));
        setBatchFromDate('');
        setBatchToDate('');
    };

    return (
        <div className="flex flex-col space-y-10 w-full animate-fade-in relative">
            {/* Guide Section */}
            <div className="relative overflow-hidden bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-500 p-8 rounded-[2.5rem] text-white shadow-2xl shadow-indigo-200">
                <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                    <div className="max-w-xl">
                        <div className="flex items-center gap-3 mb-4">
                            <div className="w-10 h-10 bg-white/20 backdrop-blur-md rounded-xl flex items-center justify-center text-xl">
                                💡
                            </div>
                            <h3 className="text-2xl font-black tracking-tight italic">How it works</h3>
                        </div>
                        <p className="text-white/80 font-medium leading-relaxed">
                            Share when you're free, and we'll automatically find the perfect moment for both of you.
                            The more slots you add, the better the magic works! ✨
                        </p>
                    </div>
                    <div className="hidden lg:block">
                        <div className="w-24 h-24 bg-white/10 backdrop-blur-3xl rounded-full flex items-center justify-center animate-pulse-soft">
                            <span className="text-5xl">🕒</span>
                        </div>
                    </div>
                </div>
                {/* Background circles */}
                <div className="absolute -top-10 -right-10 w-40 h-40 bg-white/10 rounded-full blur-3xl"></div>
                <div className="absolute -bottom-10 -left-10 w-40 h-40 bg-pink-400/20 rounded-full blur-3xl"></div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                {/* Left side: Input Area */}
                <div className="lg:col-span-12 xl:col-span-5">
                    <div className="glass-card rounded-[3rem] p-6 sm:p-8 md:p-10 space-y-8 border-white shadow-[0_20px_50px_-15px_rgba(0,0,0,0.05)] overflow-hidden">
                        <div className="flex flex-col gap-6 pb-6 border-b border-slate-50">
                            <div className="space-y-1">
                                <h4 className="text-2xl sm:text-3xl font-black text-slate-800 tracking-tighter italic whitespace-nowrap">Add Schedule</h4>
                                <p className="text-slate-400 text-[10px] font-black uppercase tracking-[0.2em]">Set your free time</p>
                            </div>
                            <div className="flex bg-slate-100/50 p-1.5 rounded-2xl w-full sm:w-fit">
                                <button
                                    onClick={() => { setMode('single'); setLocalError(''); }}
                                    className={`flex-1 sm:flex-none px-6 py-2.5 rounded-xl text-[10px] sm:text-xs font-black uppercase tracking-widest transition-all duration-300 ${mode === 'single' ? 'bg-white text-pink-500 shadow-md' : 'text-slate-400 hover:text-slate-600'}`}
                                >
                                    Single
                                </button>
                                <button
                                    onClick={() => { setMode('batch'); setLocalError(''); }}
                                    className={`flex-1 sm:flex-none px-6 py-2.5 rounded-xl text-[10px] sm:text-xs font-black uppercase tracking-widest transition-all duration-300 ${mode === 'batch' ? 'bg-white text-indigo-600 shadow-md' : 'text-slate-400 hover:text-slate-600'}`}
                                >
                                    Batch
                                </button>
                            </div>
                        </div>

                        {mode === 'single' ? (
                            <div className="space-y-6 animate-fade-in">
                                <div className="space-y-4">
                                    <div className="group">
                                        <label className="text-[11px] font-black text-slate-500 uppercase tracking-[0.2em] ml-2 mb-2 block flex items-center gap-2">
                                            <span className="w-1.5 h-1.5 rounded-full bg-pink-500"></span> Start Time
                                        </label>
                                        <input
                                            type="datetime-local"
                                            value={start}
                                            min={minDateTime}
                                            max={maxDateTime}
                                            onChange={(e) => setStart(e.target.value)}
                                            className="w-full bg-slate-50 border-2 border-transparent focus:border-pink-100 focus:bg-white rounded-[1.5rem] px-6 py-5 outline-none font-bold text-slate-700 transition-all shadow-sm text-sm appearance-none cursor-pointer hover:bg-slate-100/50"
                                        />
                                    </div>
                                    <div className="group">
                                        <label className="text-[11px] font-black text-slate-500 uppercase tracking-[0.2em] ml-2 mb-2 block flex items-center gap-2">
                                            <span className="w-1.5 h-1.5 rounded-full bg-purple-500"></span> End Time
                                        </label>
                                        <input
                                            type="datetime-local"
                                            value={end}
                                            min={minDateTime}
                                            max={maxDateTime}
                                            onChange={(e) => setEnd(e.target.value)}
                                            className="w-full bg-slate-50 border-2 border-transparent focus:border-purple-100 focus:bg-white rounded-[1.5rem] px-6 py-5 outline-none font-bold text-slate-700 transition-all shadow-sm text-sm appearance-none cursor-pointer hover:bg-slate-100/50"
                                        />
                                    </div>
                                </div>
                                <button
                                    onClick={handleAddSingle}
                                    className="w-full bg-slate-900 text-white font-black text-sm uppercase tracking-[0.3em] py-6 rounded-[1.8rem] shadow-2xl shadow-slate-200 hover:bg-slate-800 transition-all transform active:scale-95 flex items-center justify-center gap-4 group mt-4"
                                >
                                    <span>Add Slot</span>
                                    <div className="w-8 h-8 bg-white/10 rounded-xl flex items-center justify-center group-hover:bg-pink-500 transition-colors">
                                        <span className="text-xl group-hover:translate-x-1 transition-transform">➡️</span>
                                    </div>
                                </button>
                            </div>
                        ) : (
                            <div className="space-y-6 animate-fade-in">
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                    <div className="group">
                                        <label className="text-[11px] font-black text-slate-500 uppercase tracking-[0.2em] ml-2 mb-2 block">From Date</label>
                                        <input
                                            type="date"
                                            value={batchFromDate}
                                            min={minDateSimple}
                                            max={maxDateSimple}
                                            onChange={(e) => setBatchFromDate(e.target.value)}
                                            className="w-full bg-slate-50 border-2 border-transparent focus:border-indigo-100 focus:bg-white rounded-[1.5rem] px-5 py-5 outline-none font-bold text-slate-700 transition-all text-xs cursor-pointer"
                                        />
                                    </div>
                                    <div className="group">
                                        <label className="text-[11px] font-black text-slate-500 uppercase tracking-[0.2em] ml-2 mb-2 block">To Date</label>
                                        <input
                                            type="date"
                                            value={batchToDate}
                                            min={minDateSimple}
                                            max={maxDateSimple}
                                            onChange={(e) => setBatchToDate(e.target.value)}
                                            className="w-full bg-slate-50 border-2 border-transparent focus:border-indigo-100 focus:bg-white rounded-[1.5rem] px-5 py-5 outline-none font-bold text-slate-700 transition-all text-xs cursor-pointer"
                                        />
                                    </div>
                                </div>
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                    <div className="group">
                                        <label className="text-[11px] font-black text-slate-500 uppercase tracking-[0.2em] ml-2 mb-2 block">Daily Start</label>
                                        <input
                                            type="time"
                                            value={batchStartTime}
                                            onChange={(e) => setBatchStartTime(e.target.value)}
                                            className="w-full bg-slate-50 border-2 border-transparent focus:border-indigo-100 focus:bg-white rounded-[1.5rem] px-5 py-5 outline-none font-bold text-slate-700 transition-all text-xs cursor-pointer"
                                        />
                                    </div>
                                    <div className="group">
                                        <label className="text-[11px] font-black text-slate-500 uppercase tracking-[0.2em] ml-2 mb-2 block">Daily End</label>
                                        <input
                                            type="time"
                                            value={batchEndTime}
                                            onChange={(e) => setBatchEndTime(e.target.value)}
                                            className="w-full bg-slate-50 border-2 border-transparent focus:border-indigo-100 focus:bg-white rounded-[1.5rem] px-5 py-5 outline-none font-bold text-slate-700 transition-all text-xs cursor-pointer"
                                        />
                                    </div>
                                </div>
                                <button
                                    onClick={handleAddBatch}
                                    className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white font-black text-sm uppercase tracking-[0.3em] py-6 rounded-[1.8rem] shadow-xl shadow-indigo-100 hover:shadow-indigo-200 transition-all transform active:scale-95 flex items-center justify-center gap-4 group"
                                >
                                    <span>Generate Slots</span>
                                    <span className="text-2xl group-hover:scale-125 group-hover:rotate-12 transition-transform">⚡</span>
                                </button>
                            </div>
                        )}

                        {localError && (
                            <div className="bg-red-50 text-red-500 p-5 rounded-2xl text-xs font-black flex items-center gap-3 animate-bounce-soft border border-red-100">
                                <span className="text-lg">⚠️</span> {localError}
                            </div>
                        )}
                    </div>
                </div>

                {/* Right side: Staged Slots */}
                <div className="lg:col-span-12 xl:col-span-7 space-y-8 h-full">
                    <div className="bg-white/40 backdrop-blur-md rounded-[3rem] p-8 md:p-10 h-full border border-white/60 shadow-xl shadow-slate-200/50">
                        <div className="flex items-center justify-between mb-8">
                            <div className="flex items-center gap-4">
                                <div className="w-12 h-12 bg-green-500 text-white rounded-2xl flex items-center justify-center text-xl shadow-lg shadow-green-100">
                                    📋
                                </div>
                                <div>
                                    <h4 className="text-2xl font-black text-slate-800 tracking-tight italic">
                                        Staging Area
                                    </h4>
                                    <p className="text-slate-400 text-[10px] font-black uppercase tracking-[0.2em] mt-0.5">
                                        {slots.length} Ready to commit
                                    </p>
                                </div>
                            </div>
                            {slots.length > 0 && (
                                <button
                                    onClick={() => slots.forEach(s => onRemoveSlot(s.id))}
                                    className="text-[10px] font-black text-red-400 uppercase tracking-[0.25em] hover:text-red-600 transition-colors bg-red-50 px-4 py-2 rounded-full hover:bg-red-100"
                                >
                                    Clear All
                                </button>
                            )}
                        </div>

                        <div className="space-y-4">
                            {slots.length === 0 ? (
                                <div className="bg-slate-50/50 border-2 border-dashed border-slate-200/50 rounded-[2.5rem] p-20 text-center space-y-6">
                                    <div className="text-7xl opacity-10 animate-pulse">📅</div>
                                    <div>
                                        <p className="text-slate-500 font-black italic text-lg">Your list is empty</p>
                                        <p className="text-slate-400 text-xs mt-2 font-medium">Add some slots to get started!</p>
                                    </div>
                                </div>
                            ) : (
                                <>
                                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-1 gap-4 max-h-[450px] overflow-y-auto pr-2 custom-scrollbar p-1">
                                        {[...slots].sort((a, b) => new Date(a.startTime) - new Date(b.startTime)).map((slot) => (
                                            <div key={slot.id} className="bg-white p-5 rounded-[2rem] border border-slate-100 flex justify-between items-center shadow-md shadow-slate-200/40 animate-fade-in group hover:border-pink-200 hover:shadow-pink-100/30 transition-all transform hover:-translate-y-1">
                                                <div className="flex items-center space-x-5">
                                                    <div className="w-12 h-12 bg-gradient-to-br from-slate-50 to-slate-100 rounded-xl flex items-center justify-center text-xl shadow-inner group-hover:scale-110 transition-transform">
                                                        🗓️
                                                    </div>
                                                    <div>
                                                        <p className="font-black text-slate-800 text-base tracking-tight">
                                                            {new Date(slot.startTime).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
                                                        </p>
                                                        <div className="flex items-center gap-2 mt-0.5">
                                                            <span className="text-[9px] font-black text-slate-400 uppercase tracking-[0.1em] bg-slate-50 px-2 py-0.5 rounded-md">
                                                                {new Date(slot.startTime).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                                                            </span>
                                                            <span className="text-slate-200">—</span>
                                                            <span className="text-[9px] font-black text-slate-400 uppercase tracking-[0.1em] bg-slate-50 px-2 py-0.5 rounded-md">
                                                                {new Date(slot.endTime).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                                                            </span>
                                                        </div>
                                                    </div>
                                                </div>
                                                <button
                                                    onClick={() => onRemoveSlot(slot.id)}
                                                    className="w-10 h-10 rounded-xl bg-gray-50 text-gray-300 hover:bg-red-50 hover:text-red-500 transition-all flex items-center justify-center group/del shadow-sm hover:shadow-red-100"
                                                >
                                                    <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 transform group-hover/del:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                                    </svg>
                                                </button>
                                            </div>
                                        ))}
                                    </div>

                                    <div className="pt-8 mt-4 border-t border-slate-100/50">
                                        {error && <p className="text-red-500 text-xs font-black mb-4 text-center bg-red-50 py-3 rounded-xl border border-red-100">❌ {error}</p>}
                                        <button
                                            onClick={onSave}
                                            disabled={loading}
                                            className="w-full bg-gradient-to-r from-green-500 to-emerald-600 text-white font-black text-sm uppercase tracking-[0.4em] py-6 rounded-[2rem] shadow-2xl shadow-green-100 hover:shadow-green-200 hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 flex items-center justify-center gap-4 group relative overflow-hidden"
                                        >
                                            {loading ? (
                                                <div className="w-6 h-6 border-3 border-white/30 border-t-white rounded-full animate-spin"></div>
                                            ) : (
                                                <>
                                                    <span className="text-2xl group-hover:rotate-12 transition-transform">💾</span>
                                                    <span>Commit Availability</span>
                                                    <div className="absolute top-0 -inset-full h-full w-1/2 z-5 block transform -skew-x-12 bg-gradient-to-r from-transparent to-white opacity-20 group-hover:animate-shine" />
                                                </>
                                            )}
                                        </button>
                                    </div>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default TimePicker;
