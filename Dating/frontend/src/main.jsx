import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

import { GoogleOAuthProvider } from '@react-oauth/google';

ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
        <GoogleOAuthProvider clientId="1035305573096-ikgrdeoqt0d1t8hl1up861evqgbbl48l.apps.googleusercontent.com">
            <App />
        </GoogleOAuthProvider>
    </React.StrictMode>,
)
