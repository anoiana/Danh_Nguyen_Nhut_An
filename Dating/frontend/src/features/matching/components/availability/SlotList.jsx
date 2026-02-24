import React from 'react';
import { formatTime } from '../../../../lib/constants';

/**
 * Displays the list of user's saved availability slots with delete capability.
 * Extracted from AvailabilityModal.
 */
const SlotList = ({ availabilities, onDelete }) => {
    if (availabilities.length === 0) return null;

    return (
        <div className="space-y-4">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-4">
                Your Schedule ({availabilities.length}/3+)
            </label>
            <div className="max-h-48 overflow-y-auto pr-2 space-y-3 scrollbar-premium">
                {availabilities.map((avail) => (
                    <div
                        key={avail.id}
                        className="flex items-center justify-between p-5 bg-white border-2 border-slate-100 rounded-2xl group hover:border-pink-200 transition-all"
                    >
                        <div className="flex flex-col gap-1">
                            <p className="text-slate-800 font-black text-sm">
                                {new Date(avail.startTime).toLocaleDateString('en-US', {
                                    weekday: 'short', day: 'numeric', month: 'numeric',
                                })}
                            </p>
                            <p className="text-[11px] font-black text-slate-400 uppercase tracking-widest leading-none">
                                {formatTime(avail.startTime)} - {formatTime(avail.endTime)}
                            </p>
                        </div>
                        <button
                            onClick={() => onDelete(avail.id)}
                            className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center text-slate-400 hover:bg-red-50 hover:text-red-500 transition-all opacity-0 group-hover:opacity-100"
                        >
                            <span className="text-[10px]">✕</span>
                        </button>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default SlotList;
