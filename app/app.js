require('dotenv').config({ path: '../.env' });
const express = require('express');
const session = require('express-session');
const axios = require('axios');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(session({
    secret: process.env.SESSION_SECRET || 'super-secret-study-server-key',
    resave: false,
    saveUninitialized: true,
    cookie: {
        domain: '.adriandrummond.com'
    }
}));

const COGNITO_DOMAIN = process.env.COGNITO_DOMAIN || 'login.adriandrummond.com';
const CLIENT_ID = process.env.COGNITO_CLIENT_ID;
const CLIENT_SECRET = process.env.COGNITO_CLIENT_SECRET;
const REDIRECT_URI = 'https://study.adriandrummond.com/callback';
const LOGOUT_URI = 'https://adriandrummond.wordpress.com';
const COGNITO_URL = `https://${COGNITO_DOMAIN}`;

function requireAuth(req, res, next) {
    if (req.session.user) {
        return next();
    }
    const targetUrl = req.protocol + '://' + req.hostname + req.originalUrl;
    const state = Buffer.from(targetUrl).toString('base64');
    const loginUrl = `${COGNITO_URL}/login?client_id=${CLIENT_ID}&response_type=code&scope=email+openid+profile&redirect_uri=${encodeURIComponent(REDIRECT_URI)}&state=${state}`;
    res.redirect(loginUrl);
}

app.get('/', requireAuth, (req, res, next) => {
    if (req.hostname === 'wiki.adriandrummond.com') return next();
    res.render('welcome', { user: req.session.user });
});

// Secure Proxy to OpenSearch Dashboards (Port 5601)
app.use('/opensearchdashboards', requireAuth, createProxyMiddleware({ 
    target: 'http://127.0.0.1:5601', 
    changeOrigin: true,
    onError: (err, req, res) => {
        console.error("Proxy error:", err);
        if (res.writeHead) res.writeHead(500, {"Content-Type": "text/plain"});
        if (res.end) res.end("Proxy Error");
    },
    pathRewrite: (path, req) => req.originalUrl,
    ws: true
}));

// Secure Proxy to OpenSearch DB (Port 9200)
app.use('/opensearch', requireAuth, createProxyMiddleware({ 
    target: 'http://127.0.0.1:9200', 
    changeOrigin: true,
    onError: (err, req, res) => {
        console.error("Proxy error:", err);
        if (res.writeHead) res.writeHead(500, {"Content-Type": "text/plain"});
        if (res.end) res.end("Proxy Error");
    },
    pathRewrite: { '^/opensearch': '' },
    ws: true
}));

// Unified Proxy for Wiki.js (Port 3001)
const wikiPublicPaths = ['/_assets', '/assets', '/favicon.ico', '/css', '/js', '/fonts', '/img', '/graphql', '/finalize'];

const wikiProxy = createProxyMiddleware({ 
    target: 'http://127.0.0.1:3001', 
    changeOrigin: true,
    pathRewrite: (path, req) => {
        // If accessed via the old /wiki path, strip the prefix
        if (req.hostname !== 'wiki.adriandrummond.com') {
             if (req.originalUrl === '/wiki' || req.originalUrl === '/wiki/') return '/';
             if (req.originalUrl.startsWith('/wiki/')) return req.originalUrl.substring(5);
        }
        return req.originalUrl;
    },
    onError: (err, req, res) => {
        console.error("Proxy error:", err);
        if (res.writeHead) res.writeHead(500, {"Content-Type": "text/plain"});
        if (res.end) res.end("Proxy Error");
    },
    ws: true
});

// 1. Intercept native traffic for wiki.adriandrummond.com
app.use((req, res, next) => {
    if (req.hostname === 'wiki.adriandrummond.com') {
        const isPublicPath = wikiPublicPaths.some(p => req.path === p || req.path.startsWith(p + '/'));
        if (isPublicPath) {
            return wikiProxy(req, res, next);
        }
        return requireAuth(req, res, () => {
            return wikiProxy(req, res, next);
        });
    }
    next();
});

// 2. Fallback for the old study.adriandrummond.com/wiki paths
const wikiPaths = ['/wiki', '/_next', '/a', '/e', '/p', '/t', '/u', '/w', '/i'];
app.use(wikiPublicPaths, wikiProxy); // Public assets on main domain
app.use(wikiPaths, requireAuth, wikiProxy); // Protected pages on main domain

// Callback route
app.get('/callback', async (req, res) => {
    const code = req.query.code;
    if (!code) { return res.send('No code provided'); }
    try {
        const tokenResponse = await axios.post(`${COGNITO_URL}/oauth2/token`, new URLSearchParams({
            grant_type: 'authorization_code',
            client_id: CLIENT_ID,
            client_secret: CLIENT_SECRET,
            code: code,
            redirect_uri: REDIRECT_URI
        }).toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
        
        const userInfoResponse = await axios.get(`${COGNITO_URL}/oauth2/userInfo`, {
            headers: { Authorization: `Bearer ${tokenResponse.data.access_token}` }
        });
        req.session.user = userInfoResponse.data;
        
        let returnUrl = '/';
        if (req.query.state) {
            try {
                returnUrl = Buffer.from(req.query.state, 'base64').toString('ascii');
            } catch (e) {}
        }
        res.redirect(returnUrl);
    } catch (error) {
        console.error('Error exchanging code:', error.response ? error.response.data : error.message);
        res.send('Error during authentication.');
    }
});

// Logout route
app.get('/logout', (req, res) => {
    req.session.destroy();
    res.redirect(`${COGNITO_URL}/logout?client_id=${CLIENT_ID}&logout_uri=${encodeURIComponent(LOGOUT_URI)}`);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Node app listening on port ${PORT}`));
