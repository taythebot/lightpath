import Login from '@/views/Auth/Login';

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
  },
];

export default routes.map((route) => ({
  ...route,
  meta: { requiresAuth: false, onlyLoggedOut: true },
}));
