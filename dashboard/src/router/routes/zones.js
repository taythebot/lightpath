import ZonesOverview from '../../views/Zones/Overview';
import ZonesNew from '../../views/Zones/New';

// Zones subviews
import ZonesRoot from '../../views/Zones/Root';
import ZonesAnalytics from '../../views/Zones/Analytics';
import ZonesSSL from '../../views/Zones/SSL';
import ZonesCache from '../../views/Zones/Cache';
import ZonesSecurity from '../../views/Zones/Security';

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
      {
        path: 'ssl',
        name: 'ZonesSSL',
        component: ZonesSSL,
      },
      {
        path: 'cache',
        name: 'ZonesCache',
        component: ZonesCache,
      },
      {
        path: 'security',
        name: 'ZonesSecurity',
        component: ZonesSecurity,
      },
    ],
  },
];

export default routes.map((route) => ({
  ...route,
  meta: { requiresAuth: true },
}));
