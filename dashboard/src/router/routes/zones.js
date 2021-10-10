import ZonesOverview from '../../views/Zones/Overview';
import ZonesNew from '../../views/Zones/New';

// Zones subviews
import ZonesRoot from '../../views/Zones/Root';
import ZonesAnalytics from '../../views/Zones/Analytics';

const routes = [
  {
    path: '/zones',
    name: 'ZonesOverview',
    component: ZonesOverview,
  },
  {
    path: '/zones/new',
    name: 'ZonesNew',
    component: ZonesNew,
  },
  {
    path: '/zones/:id',
    name: 'Zones',
    component: ZonesRoot,
    children: [
      {
        path: 'analytics',
        alias: '',
        name: 'ZonesAnalytics',
        component: ZonesAnalytics,
      },
    ],
  },
];

export default routes.map((route) => ({
  ...route,
  meta: { requiresAuth: true },
}));
