require('dotenv').config({ path: '../.env' });
const express = require('express');
const session = require('express-session');
const axios = require('axios');
const path = require('path');

const app = express();
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(session({
    secret: process.env.SESSION_SECRET || 'super-secret-study-server-key',
    resave: false,
    saveUninitialized: true
}));

const COGNITO_DOMAIN = process.env.COGNITO_DOMAIN || 'login.adriandrummond.com';
const CLIENT_ID = process.env.COGNITO_CLIENT_ID;
const CLIENT_SECRET = process.env.COGNITO_CLIENT_SECRET;
const REDIRECT_URI = 'https://study.adriandrummond.com/callback';
const LOGOUT_URI = 'https://adriandrummond.wordpress.com';
const COGNITO_URL = `https://${COGNITO_DOMAIN}`;

// Middleware to check authentication
function requireAuth(req, res, next) {
    if (req.session.user) {
        return next();
    }
    const loginUrl = `${COGNITO_URL}/login?client_id=${CLIENT_ID}&response_type=code&scope=email+openid+profile&redirect_uri=${encodeURIComponent(REDIRECT_URI)}`;
    res.redirect(loginUrl);
}

const { createProxyMiddleware } = require('http-proxy-middleware');

// Welcome page
app.get('/', requireAuth, (req, res) => {
    res.render('welcome', { user: req.session.user });
});

// Secure Proxy to Wiki.js (Port 3001)
app.use('/wiki', requireAuth, createProxyMiddleware({ 
    target: 'http://127.0.0.1:3001', 
    changeOrigin: true,
    ws: true // Enable WebSocket proxying for Wiki.js real-time features
}));

// Secure Proxy to OpenSearch Dashboards (Port 5601)
app.use('/opensearchdashboards', requireAuth, createProxyMiddleware({ 
    target: 'http://127.0.0.1:5601', 
    changeOrigin: true,
    ws: true
}));

// Secure Proxy to OpenSearch DB (Port 9200)
app.use('/opensearch', requireAuth, createProxyMiddleware({ 
    target: 'http://127.0.0.1:9200', 
    changeOrigin: true,
    pathRewrite: { '^/opensearch': '' },
    ws: true
}));

// Callback route
app.get('/callback', async (req, res) => {
    const code = req.query.code;
    if (!code) {
        return res.send('No code provided');
    }

    try {
        const tokenResponse = await axios.post(`${COGNITO_URL}/oauth2/token`, new URLSearchParams({
            grant_type: 'authorization_code',
            client_id: CLIENT_ID,
            client_secret: CLIENT_SECRET,
            code: code,
            redirect_uri: REDIRECT_URI
        }).toString(), {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
        });

        const accessToken = tokenResponse.data.access_token;
        
        // Fetch user info
        const userInfoResponse = await axios.get(`${COGNITO_URL}/oauth2/userInfo`, {
            headers: { Authorization: `Bearer ${accessToken}` }
        });

        req.session.user = userInfoResponse.data;
        res.redirect('/');
    } catch (error) {
        console.error('Error exchanging code:', error.response ? error.response.data : error.message);
        res.send('Error during authentication.');
    }
});

// Logout route
app.get('/logout', (req, res) => {
    req.session.destroy();
    const logoutUrl = `${COGNITO_URL}/logout?client_id=${CLIENT_ID}&logout_uri=${encodeURIComponent(LOGOUT_URI)}`;
    res.redirect(logoutUrl);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Node app listening on port ${PORT}`);
});
