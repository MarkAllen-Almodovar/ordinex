/**
 * Barangay Official registration.
 * - Role is hardcoded as 'official'
 * - Status is 'pending' â€” requires admin confirmation before login
 * - Account is signed out immediately after creation
 */

import { createUserWithEmailAndPassword, onAuthStateChanged, signOut } from 'firebase/auth';
import { doc, setDoc, addDoc, collection, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../shared/firebase.js';

// â”€â”€ DOM refs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const form          = document.getElementById('register-form');
const nameInput     = document.getElementById('name-input');
const emailInput    = document.getElementById('email-input');
const phoneInput    = document.getElementById('phone-input');
const barangayInput = document.getElementById('barangay-input');
const passwordInput = document.getElementById('password-input');
const confirmInput  = document.getElementById('confirm-input');
const registerBtn   = document.getElementById('register-btn');
const authError     = document.getElementById('auth-error');
const authSuccess   = document.getElementById('auth-success');
const nameError     = document.getElementById('name-error');
const emailError    = document.getElementById('email-error');
const phoneError    = document.getElementById('phone-error');
const barangayError = document.getElementById('barangay-error');
const passwordError = document.getElementById('password-error');
const confirmError  = document.getElementById('confirm-error');
const togglePwdBtn  = document.getElementById('toggle-password');
const eyeShow       = document.getElementById('eye-show');
const eyeHide       = document.getElementById('eye-hide');

// â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function showErr(el, msg) { if (!el) return; el.textContent = msg; el.hidden = false; }
function clearErr(el)     { if (!el) return; el.textContent = ''; el.hidden = true; }
function showAuthError(msg)   { if (authError)   { authError.textContent = msg;   authError.hidden = false; } }
function clearAuthError()     { if (authError)   { authError.textContent = '';    authError.hidden = true; } }
function showAuthSuccess(msg) { if (authSuccess) { authSuccess.textContent = msg; authSuccess.hidden = false; } }

function setLoading(on) {
  if (!registerBtn) return;
  registerBtn.disabled = on;
  registerBtn.textContent = on ? 'Creating accountâ€¦' : 'Create Account';
}

// â”€â”€ Password toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

togglePwdBtn?.addEventListener('click', () => {
  const visible = passwordInput.type === 'text';
  passwordInput.type = visible ? 'password' : 'text';
  eyeShow.style.display = visible ? '' : 'none';
  eyeHide.style.display = visible ? 'none' : '';
  togglePwdBtn.setAttribute('aria-label', visible ? 'Show password' : 'Hide password');
});

// â”€â”€ Validation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function validate() {
  let valid = true;

  const name = nameInput?.value.trim() ?? '';
  if (!name) { showErr(nameError, 'Full name is required.'); valid = false; }
  else clearErr(nameError);

  const email = emailInput?.value.trim() ?? '';
  if (!email) { showErr(emailError, 'Email address is required.'); valid = false; }
  else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { showErr(emailError, 'Enter a valid email address.'); valid = false; }
  else clearErr(emailError);

  const phone = phoneInput?.value.trim() ?? '';
  const digits = phone.replace(/\D/g, '');
  if (!phone) { showErr(phoneError, 'Mobile number is required.'); valid = false; }
  else if (!((digits.length === 11 && digits.startsWith('09')) || (digits.length === 10 && digits.startsWith('9')))) {
    showErr(phoneError, 'Enter a valid PH number (09XXXXXXXXX).'); valid = false;
  } else clearErr(phoneError);

  const barangay = barangayInput?.value ?? '';
  if (!barangay) { showErr(barangayError, 'Please select your barangay.'); valid = false; }
  else clearErr(barangayError);

  const password = passwordInput?.value ?? '';
  if (!password) { showErr(passwordError, 'Password is required.'); valid = false; }
  else if (password.length < 6) { showErr(passwordError, 'Password must be at least 6 characters.'); valid = false; }
  else clearErr(passwordError);

  const confirm = confirmInput?.value ?? '';
  if (!confirm) { showErr(confirmError, 'Please confirm your password.'); valid = false; }
  else if (confirm !== password) { showErr(confirmError, 'Passwords do not match.'); valid = false; }
  else clearErr(confirmError);

  return valid;
}

// â”€â”€ Title case helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function toTitleCase(str) {
  return str.split(' ').map(w => w ? w[0].toUpperCase() + w.slice(1).toLowerCase() : w).join(' ');
}

// â”€â”€ Register â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

async function handleRegister(e) {
  e.preventDefault();
  clearAuthError();
  if (!validate()) return;

  setLoading(true);

  try {
    const name     = toTitleCase(nameInput.value.trim());
    const email    = emailInput.value.trim();
    const phone    = phoneInput.value.trim();
    const barangay = barangayInput.value;    const password = passwordInput.value;

    // Create Firebase Auth account
    const credential = await createUserWithEmailAndPassword(auth, email, password);
    const uid = credential.user.uid;

    // Save profile â€” role: 'official', status: 'pending' (needs admin approval)
    await setDoc(doc(db, 'users', uid), {
      uid,
      fullName:    name,
      displayName: name,
      email,
      phoneNumber: phone,
      barangay,      role:        'official',
      status:      'pending',
      createdAt:   serverTimestamp(),
    });

    // Write admin notification
    await addDoc(collection(db, 'admin_notifications'), {
      type:  'new_signup',
      title: 'New Official Sign-Up: ' + name,
      body:  name + ' from Brgy. ' + barangay + ' has registered as a barangay official and is waiting for approval.',
      meta:  { userId: uid, residentName: name, barangay },
      read:  false,
      createdAt: serverTimestamp(),
    });

    // Sign out immediately â€” must wait for admin approval
    await signOut(auth);

    form.reset();
    showAuthSuccess('Account created! Your account is pending approval by the admin. You will be able to sign in once approved.');
    setLoading(false);

    setTimeout(() => { window.location.href = '/index.html'; }, 4000);
  } catch (err) {
    console.error('[register]', err);
    showAuthError(errorMessage(err.code));
    setLoading(false);
  }
}

// â”€â”€ Error messages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

function errorMessage(code) {
  const map = {
    'auth/email-already-in-use':   'An account with this email already exists.',
    'auth/invalid-email':          'Invalid email address format.',
    'auth/weak-password':          'Password is too weak. Use at least 6 characters.',
    'auth/network-request-failed': 'Network error. Check your connection.',
  };
  return map[code] ?? 'Registration failed. Please try again.';
}

// â”€â”€ Redirect if already signed in as admin â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

onAuthStateChanged(auth, async (user) => {
  if (user) {
    try {
      const { getDoc } = await import('firebase/firestore');
      const snap = await getDoc(doc(db, 'users', user.uid));
      const data = snap.data() ?? {};
      if (['admin', 'official'].includes(data.role) && data.status === 'approved') {
        window.location.href = '/admin.html';
      }
    } catch (_) {}
  }
});

// â”€â”€ Event listeners â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

form?.addEventListener('submit', handleRegister);
nameInput?.addEventListener('input',      () => clearErr(nameError));
emailInput?.addEventListener('input',     () => clearErr(emailError));
phoneInput?.addEventListener('input',     () => clearErr(phoneError));
barangayInput?.addEventListener('change', () => clearErr(barangayError));passwordInput?.addEventListener('input',  () => clearErr(passwordError));
confirmInput?.addEventListener('input',   () => clearErr(confirmError));
