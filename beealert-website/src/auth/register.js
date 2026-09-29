/**
 * Admin registration — creates a new admin/official Firebase account
 * and saves the user profile to Firestore with the selected role.
 */

import { createUserWithEmailAndPassword, onAuthStateChanged, signOut } from 'firebase/auth';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../shared/firebase.js';

// ── DOM refs ─────────────────────────────────────────────────────────────────

const form          = document.getElementById('register-form');
const nameInput     = document.getElementById('name-input');
const emailInput    = document.getElementById('email-input');
const roleInput     = document.getElementById('role-input');
const passwordInput = document.getElementById('password-input');
const confirmInput  = document.getElementById('confirm-input');
const registerBtn   = document.getElementById('register-btn');
const authError     = document.getElementById('auth-error');
const authSuccess   = document.getElementById('auth-success');
const nameError     = document.getElementById('name-error');
const emailError    = document.getElementById('email-error');
const roleError     = document.getElementById('role-error');
const passwordError = document.getElementById('password-error');
const confirmError  = document.getElementById('confirm-error');
const togglePwdBtn  = document.getElementById('toggle-password');
const eyeShow       = document.getElementById('eye-show');
const eyeHide       = document.getElementById('eye-hide');

// ── Helpers ───────────────────────────────────────────────────────────────────

function showErr(el, msg) { if (!el) return; el.textContent = msg; el.hidden = false; }
function clearErr(el)     { if (!el) return; el.textContent = ''; el.hidden = true; }
function showAuthError(msg) { if (authError) { authError.textContent = msg; authError.hidden = false; } }
function clearAuthError()   { if (authError) { authError.textContent = ''; authError.hidden = true; } }
function showAuthSuccess(msg) { if (authSuccess) { authSuccess.textContent = msg; authSuccess.hidden = false; } }

function setLoading(on) {
  if (!registerBtn) return;
  registerBtn.disabled = on;
  registerBtn.textContent = on ? 'Creating account…' : 'Create Account';
}

// ── Password toggle ───────────────────────────────────────────────────────────

togglePwdBtn?.addEventListener('click', () => {
  const visible = passwordInput.type === 'text';
  passwordInput.type = visible ? 'password' : 'text';
  eyeShow.style.display = visible ? '' : 'none';
  eyeHide.style.display = visible ? 'none' : '';
  togglePwdBtn.setAttribute('aria-label', visible ? 'Show password' : 'Hide password');
});

// ── Validation ────────────────────────────────────────────────────────────────

function validate() {
  let valid = true;

  const name = nameInput?.value.trim() ?? '';
  if (!name) {
    showErr(nameError, 'Please enter your full name.');
    valid = false;
  } else { clearErr(nameError); }

  const email = emailInput?.value.trim() ?? '';
  if (!email) {
    showErr(emailError, 'Please enter your email address.');
    valid = false;
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    showErr(emailError, 'Please enter a valid email address.');
    valid = false;
  } else { clearErr(emailError); }

  const role = roleInput?.value ?? '';
  if (!role) {
    showErr(roleError, 'Please select a role.');
    valid = false;
  } else { clearErr(roleError); }

  const password = passwordInput?.value ?? '';
  if (!password) {
    showErr(passwordError, 'Please enter a password.');
    valid = false;
  } else if (password.length < 8) {
    showErr(passwordError, 'Password must be at least 8 characters.');
    valid = false;
  } else { clearErr(passwordError); }

  const confirm = confirmInput?.value ?? '';
  if (!confirm) {
    showErr(confirmError, 'Please confirm your password.');
    valid = false;
  } else if (confirm !== password) {
    showErr(confirmError, 'Passwords do not match.');
    valid = false;
  } else { clearErr(confirmError); }

  return valid;
}

// ── Register ──────────────────────────────────────────────────────────────────

async function handleRegister(e) {
  e.preventDefault();
  clearAuthError();

  if (!validate()) return;

  setLoading(true);

  try {
    const email    = emailInput.value.trim();
    const password = passwordInput.value;
    const name     = nameInput.value.trim();
    const role     = roleInput.value;

    // Create Firebase Auth account
    const credential = await createUserWithEmailAndPassword(auth, email, password);
    const uid = credential.user.uid;

    // Save profile to Firestore
    await setDoc(doc(db, 'users', uid), {
      uid,
      fullName:    name,
      displayName: name,
      email,
      role,
      phone:       '',
      createdAt:   serverTimestamp(),
    });

    // Sign out immediately — admin must log in manually
    await signOut(auth);

    // Show success and redirect after 2 seconds
    form.reset();
    showAuthSuccess(
      `Account created for ${name}. Redirecting to sign in…`
    );
    setTimeout(() => { window.location.href = '/index.html'; }, 2000);
  } catch (err) {
    console.error('[register]', err);
    showAuthError(errorMessage(err.code));
    setLoading(false);
  }
}

// ── Error messages ────────────────────────────────────────────────────────────

function errorMessage(code) {
  const map = {
    'auth/email-already-in-use': 'An account with this email already exists.',
    'auth/invalid-email':        'Invalid email address format.',
    'auth/weak-password':        'Password is too weak. Use at least 8 characters.',
    'auth/network-request-failed': 'Network error. Check your connection.',
  };
  return map[code] ?? 'Registration failed. Please try again.';
}

// ── If already signed in as admin, redirect to dashboard ─────────────────────

onAuthStateChanged(auth, async (user) => {
  if (user) {
    try {
      const { getDoc } = await import('firebase/firestore');
      const snap = await getDoc(doc(db, 'users', user.uid));
      const role = snap.data()?.role ?? '';
      if (['admin', 'official'].includes(role)) {
        window.location.href = '/admin.html';
      }
    } catch (_) {}
  }
});

// ── Event listeners ───────────────────────────────────────────────────────────

form?.addEventListener('submit', handleRegister);
nameInput?.addEventListener('input',     () => clearErr(nameError));
emailInput?.addEventListener('input',    () => clearErr(emailError));
roleInput?.addEventListener('change',    () => clearErr(roleError));
passwordInput?.addEventListener('input', () => clearErr(passwordError));
confirmInput?.addEventListener('input',  () => clearErr(confirmError));
