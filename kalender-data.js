(function () {
  'use strict';
  let client;
  function storageKey() { return 'filips-calendar-session-' + window.FILIPS_KALENDER.url; }
  function ready() {
    const c = window.FILIPS_KALENDER;
    return Boolean(c && /^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/i.test(c.url) && /^sb_publishable_[A-Za-z0-9_-]+$/.test(c.publishableKey));
  }
  function sdk() {
    if (!ready()) throw new Error('Kalenderen er endnu ikke sat op.');
    if (!window.supabase) throw new Error('Kalenderen kunne ikke indlæses. Genindlæs siden.');
    if (!client) client = window.supabase.createClient(window.FILIPS_KALENDER.url.replace(/\/$/, ''), window.FILIPS_KALENDER.publishableKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false, storageKey: storageKey() },
    });
    return client;
  }
  function checked(result) {
    if (result.error) {
      const error = new Error(result.error.message || 'Kalenderen kunne ikke kontaktes. Prøv igen.');
      error.code = result.error.status || result.error.code;
      throw error;
    }
    return result.data;
  }
  async function isAdmin() {
    const session = checked(await sdk().auth.getSession());
    if (!session.session) return false;
    return checked(await sdk().rpc('filips_is_admin')) === true;
  }
  async function login(password) {
    try {
      checked(await sdk().auth.signInWithPassword({ email: window.FILIPS_KALENDER.email, password }));
    } catch (error) {
      if (error.code === 400 || error.code === 'invalid_credentials') throw new Error('Forkert adgangskode.');
      throw error;
    }
    if (!await isAdmin()) {
      await sdk().auth.signOut({ scope: 'local' });
      throw new Error('Denne konto har ikke adgang til Filips kalender.');
    }
  }
  async function listJobs() {
    if (!await isAdmin()) { const e = new Error('Log ind igen.'); e.code = 401; throw e; }
    const jobs = [];
    for (let offset = 0; ; offset += 200) {
      const rows = checked(await sdk().from('filips_jobs').select('id,created_at,requested_date,scheduled_date,status,service,customer_name,address,email,phone,message,extras,price').order('scheduled_date').order('created_at').order('id').range(offset, offset + 199));
      jobs.push(...rows);
      if (rows.length < 200) return jobs;
    }
  }
  async function updateJob(id, status, date) {
    if (!['new', 'accepted'].includes(status) || !/^20\d{2}-\d{2}-\d{2}$/.test(date)) throw new Error('Vælg en gyldig status og dato.');
    const rows = checked(await sdk().from('filips_jobs').update({ status, scheduled_date: date }).eq('id', id).select('id'));
    if (!rows.length) throw new Error('Opgaven kunne ikke ændres. Kontrollér login.');
  }
  async function logout() {
    const active = sdk();
    // Clear this browser even if the authentication service cannot be reached.
    try { await active.auth.signOut({ scope: 'local' }); } catch {}
    await active.auth.stopAutoRefresh();
    try { window.localStorage.removeItem(storageKey()); } catch {}
    client = undefined;
  }
  window.FilipCloud = {
    ready, isAdmin, login, listJobs, updateJob, logout,
    async submitInquiry(payload) { return checked(await sdk().rpc('filips_submit_inquiry', { payload })); },
    async changePassword(oldPassword, newPassword) {
      if (newPassword.length < 12 || newPassword.length > 128) throw new Error('Vælg en adgangskode på 12–128 tegn.');
      checked(await sdk().auth.updateUser({ password: newPassword, current_password: oldPassword }));
      try { await sdk().auth.signOut({ scope: 'global' }); } finally { await logout(); }
    },
  };
})();
