import { createRouter, createWebHistory } from 'vue-router';
import store from '@/store';

// Routes
import auth from './routes/auth';
import zones from './routes/zones';

const router = createRouter({
  history: createWebHistory(),
  routes: [{ path: '/', redirect: '/zones' }, ...auth, ...zones],
});

// Auth middleware
router.beforeEach(async (to, from, next) => {
  const requiresAuth = to.meta?.requiresAuth;
  const onlyLoggedOut = to.meta?.onlyLoggedOut;
  let isAuthenticated = store.getters['users/isAuthenticated'];

  // Fetch user
  if (!isAuthenticated) {
    const user = await store.dispatch('users/GET');
    if (user) isAuthenticated = true;
  }

  console.log(requiresAuth);
  console.log(isAuthenticated);

  // Enforce authentication
  if (requiresAuth && !isAuthenticated && to.name !== 'Login') {
    next({ name: 'Login' });
  } else if (isAuthenticated && onlyLoggedOut) {
    next('/');
  }

  next();
});

export default router;
