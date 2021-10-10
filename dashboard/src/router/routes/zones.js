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
    name: 'ZoneNew',
    component: ZonesNew,
  },
  {
    path: '/zones/:id',
    name: 'Zone',
    component: ZonesRoot,
    children: [
      {
        path: 'analytics',
        alias: '',
        name: 'ZoneAnalytics',
        component: ZonesAnalytics,
      },
    ],
  },
];

export default routes.map((route) => ({
  ...route,
  meta: { requiresAuth: true },
}));
