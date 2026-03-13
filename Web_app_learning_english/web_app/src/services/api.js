const BASE_URL = 'https://danh-nguyen-nhut-an.onrender.com/api';

// Helper for API calls
async function request(url, options = {}) {
    const res = await fetch(`${BASE_URL}${url}`, {
        headers: { 'Content-Type': 'application/json', ...options.headers },
        ...options,
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(text || `HTTP ${res.status}`);
    }
    const contentType = res.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
        return res.json();
    }
    return res.text();
}

// Auth
export const authAPI = {
    login: (username, password) =>
        request('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ username, password }),
        }),
    register: (username, password) =>
        request('/auth/register', {
            method: 'POST',
            body: JSON.stringify({ username, password }),
        }),
};

// Folders
export const folderAPI = {
    getByUser: (userId, page = 0, size = 15, search = '') =>
        request(`/folders/user/${userId}?page=${page}&size=${size}&search=${search}`),
    create: (name, userId) =>
        request('/folders', {
            method: 'POST',
            body: JSON.stringify({ name, userId }),
        }),
    update: (folderId, name) =>
        request(`/folders/${folderId}`, {
            method: 'PUT',
            body: JSON.stringify({ name }),
        }),
    delete: (folderId) =>
        request(`/folders/${folderId}`, { method: 'DELETE' }),
};

// Vocabularies
export const vocabAPI = {
    getByFolder: (folderId, page = 0, size = 15, search = '') =>
        request(`/vocabularies/folder/${folderId}?page=${page}&size=${size}&search=${search}`),
    create: (dto) =>
        request('/vocabularies', {
            method: 'POST',
            body: JSON.stringify(dto),
        }),
    update: (vocabId, dto) =>
        request(`/vocabularies/${vocabId}`, {
            method: 'PUT',
            body: JSON.stringify(dto),
        }),
    delete: (vocabId) =>
        request(`/vocabularies/${vocabId}`, { method: 'DELETE' }),
    batchDelete: (vocabularyIds) =>
        request('/vocabularies/batch-delete', {
            method: 'POST',
            body: JSON.stringify({ vocabularyIds }),
        }),
};

// Translation
export const translateAPI = {
    translate: (word) => request(`/translate/${encodeURIComponent(word)}`),
};

// Game
export const gameAPI = {
    startGame: (dto) =>
        request('/game/start', {
            method: 'POST',
            body: JSON.stringify(dto),
        }),
    retryWrong: (dto) =>
        request('/game/retry-wrong', {
            method: 'POST',
            body: JSON.stringify(dto),
        }),
    generateListening: (dto) =>
        request('/game/generate-listening', {
            method: 'POST',
            body: JSON.stringify(dto),
        }),
    generateReading: (dto) =>
        request('/game/generate-reading', {
            method: 'POST',
            body: JSON.stringify(dto),
        }),
    checkSentence: (dto) =>
        request('/game/check-sentence', {
            method: 'POST',
            body: JSON.stringify(dto),
        }),
};

// Game Results
export const gameResultAPI = {
    update: (id, dto) =>
        request(`/game-results/${id}`, {
            method: 'PUT',
            body: JSON.stringify(dto),
        }),
    getWrong: (userId) => request(`/game-results/wrong/${userId}`),
};
