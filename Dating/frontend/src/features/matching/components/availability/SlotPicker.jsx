import React from 'react';

/**
 * Slot picker form: date/time inputs + add button.
 * Extracted from AvailabilityModal to follow Single Responsibility Principle.
 */
const SlotPicker = ({
    date, setDate,
    startTime, setStartTime,
    endTime, setEndTime,
    minDateStr, maxDateStr,
    onAdd,
}) => {
    return (
        <div className="space-y-6">
            <div className="bg-slate-50 p-6 rounded-3xl border border-slate-100">
                <p className="text-slate-500 font-bold text-sm leading-relaxed">
                    You and your partner need to select at least 3 availability slots in the next 3 weeks.
                    The system will automatically find the first overlap (min 1.5 hours).
                </p>
            </div>

            <div className="grid grid-cols-1 gap-4">
                <div className="flex flex-col gap-2">
                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-4">
                        Select Date
                    </label>
                    <input
                        type="date"
                        value={date}
                        min={minDateStr}
                        max={maxDateStr}
                        onChange={(e) => setDate(e.target.value)}
                        className="w-full p-5 bg-slate-50 rounded-2xl border-2 border-transparent focus:border-pink-500 transition-all font-bold text-slate-700 outline-none"
                    />
                </div>
                <div className="grid grid-cols-2 gap-4">
                    <div className="flex flex-col gap-2">
                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-4">From</label>
                        <input
                            type="time"
                            value={startTime}
                            onChange={(e) => setStartTime(e.target.value)}
                            className="w-full p-5 bg-slate-50 rounded-2xl border-2 border-transparent focus:border-pink-500 transition-all font-bold text-slate-700 outline-none"
                        />
                    </div>
                    <div className="flex flex-col gap-2">
                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-4">To</label>
                        <input
                            type="time"
                            value={endTime}
                            onChange={(e) => setEndTime(e.target.value)}
                            className="w-full p-5 bg-slate-50 rounded-2xl border-2 border-transparent focus:border-pink-500 transition-all font-bold text-slate-700 outline-none"
                        />
                    </div>
                </div>
                <button
                    onClick={onAdd}
                    className="w-full py-5 bg-white border-2 border-pink-500 text-pink-500 font-black text-xs uppercase tracking-[0.2em] rounded-2xl hover:bg-pink-500 hover:text-white transition-all shadow-lg shadow-pink-100 flex items-center justify-center gap-3"
                >
                    <span>➕</span> Add Available Slot
                </button>
            </div>
        </div>
    );
};

export default SlotPicker;
