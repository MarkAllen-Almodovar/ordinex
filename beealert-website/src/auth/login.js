/**
 * src/auth/login.js
 *
 * Handles two separate login tabs:
 *  - Admin tab     → only allows role === 'admin'
 *  - B. Official tab → only allows role === 'official'
 */

import { signInWithEmailAndPassword, onAuthStateChanged, signOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../shared/firebase.js';

// ---------------------------------------------------------------------------
// Tab switching
// ---------------------------------------------------------------------------

let activeRole = 'admin'; // 'admin' | 'official'

document.querySelectorAll('.login-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        // Update tab active state
        document.querySelectorAll('.login-tab').forEach(t => {
            t.classList.remove('is-active');
            t.setAttribute('aria-selected', 'false');
        });
        tab.classList.add('is-active');
        tab.setAttribute('aria-selected', 'true');

        // Show/hide panels
        const panelId = tab.getAttribute('aria-controls');
        document.querySelectorAll('[role="tabpanel"]').forEach(p => {
            p.hidden = p.id !== panelId;
        });

        activeRole = tab.dataset.role;
        clearAuthError();
    });
});

// ---------------------------------------------------------------------------
// DOM references — Admin panel
// ---------------------------------------------------------------------------

const adminForm      = document.getElementById('login-form-admin');
const adminEmail     = document.getElementById('email-admin');
const adminPassword  = document.getElementById('password-admin');
const adminBtn       = document.getElementById('login-btn-admin');
const adminEmailErr  = document.getElementById('email-admin-error');
const adminPwdErr    = document.getElementById('password-admin-error');
const toggleAdminPwd = document.getElementById('toggle-password-admin');
const eyeShowAdmin   = document.getElementById('eye-show-admin');
const eyeHideAdmin   = document.getElementById('eye-hide-admin');

// ---------------------------------------------------------------------------
// DOM references — B. Official panel
// ---------------------------------------------------------------------------

const officialForm      = document.getElementById('login-form-official');
const officialEmail     = document.getElementById('email-official');
const officialPassword  = document.getElementById('password-official');
const officialBtn       = document.getElementById('login-btn-official');
const officialEmailErr  = document.getElementById('email-official-error');
const officialPwdErr    = document.getElementById('password-official-error');
const toggleOfficialPwd = document.getElementById('toggle-password-official');
const eyeShowOfficial   = document.getElementById('eye-show-official');
const eyeHideOfficial   = document.getElementById('eye-hide-official');

// ---------------------------------------------------------------------------
// Shared error banner
// ---------------------------------------------------------------------------

const authError = document.getElementById('auth-error');

function showAuthError(msg) {
    if (!authError) return;
    authError.textContent = msg;
    authError.hidden = false;
}
function clearAuthError() {
    if (!authError) return;
    authError.textContent = '';
    authError.hidden = true;
}

// ---------------------------------------------------------------------------
// Field-level helpers
// ---------------------------------------------------------------------------

function showError(el, msg) { if (!el) return; el.textContent = msg; el.hidden = false; }
function clearError(el)     { if (!el) return; el.textContent = ''; el.hidden = true; }

// ---------------------------------------------------------------------------
// Password toggle — Admin
// ---------------------------------------------------------------------------

toggleAdminPwd?.addEventListener('click', () => {
    const visible = adminPassword.type === 'text';
    adminPassword.type = visible ? 'password' : 'text';
    toggleAdminPwd.setAttribute('aria-label', visible ? 'Show password' : 'Hide password');
    eyeShowAdmin.style.display = visible ? '' : 'none';
    eyeHideAdmin.style.display = visible ? 'none' : '';
});

// ---------------------------------------------------------------------------
// Password toggle — B. Official
// ---------------------------------------------------------------------------

toggleOfficialPwd?.addEventListener('click', () => {
    const visible = officialPassword.type === 'text';
    officialPassword.type = visible ? 'password' : 'text';
    toggleOfficialPwd.setAttribute('aria-label', visible ? 'Show password' : 'Hide password');
    eyeShowOfficial.style.display = visible ? '' : 'none';
    eyeHideOfficial.style.display = visible ? 'none' : '';
});

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

function validateForm(emailEl, emailErrEl, passwordEl, passwordErrEl) {
    let valid = true;

    const email = emailEl?.value?.trim() ?? '';
    if (!email) {
        showError(emailErrEl, 'Please enter your email address.');
        emailEl?.focus();
        valid = false;
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        showError(emailErrEl, 'Please enter a valid email address.');
        emailEl?.focus();
        valid = false;
    } else {
        clearError(emailErrEl);
    }

    const password = passwordEl?.value ?? '';
    if (!password) {
        showError(passwordErrEl, 'Please enter your password.');
        if (valid) passwordEl?.focus();
        valid = false;
    } else {
        clearError(passwordErrEl);
    }

    return valid;
}

// ---------------------------------------------------------------------------
// Role check
// ---------------------------------------------------------------------------

async function checkRole(uid, expectedRole) {
    try {
        const snap = await getDoc(doc(db, 'users', uid));
        if (!snap.exists()) return { ok: false, reason: 'not_found' };
        const data   = snap.data() ?? {};
        const role   = data.role   ?? '';
        const status = data.status ?? 'approved';

        if (role !== expectedRole)    return { ok: false, reason: 'wrong_role' };
        if (status === 'pending')     return { ok: false, reason: 'pending' };
        if (status === 'rejected')    return { ok: false, reason: 'rejected' };
        return { ok: true };
    } catch {
        return { ok: false, reason: 'error' };
    }
}

function roleErrorMessage(reason, role) {
    if (reason === 'pending')    return 'Your account is pending approval. Please wait for confirmation.';
    if (reason === 'rejected')   return 'Your account registration was rejected. Contact the administrator.';
    if (reason === 'wrong_role') {
        return role === 'admin'
            ? 'This account is not an Admin account. Try the B. Official tab.'
            : 'This account is not a B. Official account. Try the Admin tab.';
    }
    return 'Access denied. This portal is for authorized officials only.';
}

// ---------------------------------------------------------------------------
// Sign-in handler (shared)
// ---------------------------------------------------------------------------

function setLoading(btn, loading, defaultLabel) {
    if (!btn) return;
    btn.disabled    = loading;
    btn.textContent = loading ? 'Signing in...' : defaultLabel;
}

async function handleLogin(emailEl, passwordEl, btn, btnLabel, emailErrEl, passwordErrEl, role) {
    clearAuthError();

    if (!validateForm(emailEl, emailErrEl, passwordEl, passwordErrEl)) return;

    setLoading(btn, true, btnLabel);

    try {
        const credential = await signInWithEmailAndPassword(
            auth,
            emailEl.value.trim(),
            passwordEl.value,
        );

        const { ok, reason } = await checkRole(credential.user.uid, role);

        if (!ok) {
            await signOut(auth);
            showAuthError(roleErrorMessage(reason, role));
            setLoading(btn, false, btnLabel);
            return;
        }

        // Auth state change listener will redirect to admin.html
    } catch (err) {
        console.error('[login] error:', err);
        showAuthError(errorMessage(err.code));
        setLoading(btn, false, btnLabel);
    }
}

// ---------------------------------------------------------------------------
// Form submit listeners
// ---------------------------------------------------------------------------

adminForm?.addEventListener('submit', (e) => {
    e.preventDefault();
    handleLogin(adminEmail, adminPassword, adminBtn, 'Sign In as Admin', adminEmailErr, adminPwdErr, 'admin');
});

officialForm?.addEventListener('submit', (e) => {
    e.preventDefault();
    handleLogin(officialEmail, officialPassword, officialBtn, 'Sign In as B. Official', officialEmailErr, officialPwdErr, 'official');
});

// Clear errors on input
adminEmail?.addEventListener('input',    () => { clearError(adminEmailErr);   clearAuthError(); });
adminPassword?.addEventListener('input', () => { clearError(adminPwdErr);     clearAuthError(); });
officialEmail?.addEventListener('input',    () => { clearError(officialEmailErr);   clearAuthError(); });
officialPassword?.addEventListener('input', () => { clearError(officialPwdErr);     clearAuthError(); });

// ---------------------------------------------------------------------------
// Auth state — redirect if already signed in
// ---------------------------------------------------------------------------

onAuthStateChanged(auth, async (user) => {
    if (!user) return;

    // Check if the user has any valid admin role
    try {
        const snap = await getDoc(doc(db, 'users', user.uid));
        if (!snap.exists()) { await signOut(auth); return; }
        const data   = snap.data() ?? {};
        const role   = data.role   ?? '';
        const status = data.status ?? 'approved';

        if ((role === 'admin' || role === 'official') && status !== 'pending' && status !== 'rejected') {
            window.location.href = '/admin.html';
        } else {
            await signOut(auth);
        }
    } catch {
        await signOut(auth);
    }
});

// ---------------------------------------------------------------------------
// Firebase error messages
// ---------------------------------------------------------------------------

function errorMessage(code) {
    const map = {
        'auth/invalid-email':          'Invalid email address format.',
        'auth/user-not-found':         'No account found with this email.',
        'auth/wrong-password':         'Incorrect password. Please try again.',
        'auth/invalid-credential':     'Incorrect email or password. Please try again.',
        'auth/too-many-requests':      'Too many failed attempts. Please wait and try again.',
        'auth/user-disabled':          'This account has been disabled.',
        'auth/network-request-failed': 'Network error. Check your connection.',
    };
    return map[code] ?? 'Sign in failed. Please check your credentials.';
}
