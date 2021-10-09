import { createRouter, createWebHistory } from "vue-router";

// Auth views
import Login from "../views/Auth/Login";

// Zone views
import ZoneNew from "../views/Zone/New";
import ZoneRoot from "../views/Zone/Root";
import ZoneAnalytics from "../views/Zone/Analytics";

const routes = [
  {
    path: "/login",
    name: "Login",
    component: Login,
  },
  {
    path: "/zone/new",
    name: "ZoneNew",
    component: ZoneNew,
  },
  {
    path: "/zone/:id",
    name: "Zone",
    component: ZoneRoot,
    children: [
      {
        path: "analytics",
        alias: "",
        name: "ZoneAnalytics",
        component: ZoneAnalytics,
      },
    ],
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
