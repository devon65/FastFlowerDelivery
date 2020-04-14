import Vue from "vue";
import VueRouter from "vue-router";
import Home from "../views/Home.vue";
// import axios from 'axios'
// import VueAxios from 'vue-axios'
import Driver from "../components/Driver.vue";

Vue.use(VueRouter);

const routes = [
  {
    path: "/",
    name: "Home",
    component: Home
  },
  {
    path: "/driver",
    name: "Driver",
    component: Driver
  }
];

const router = new VueRouter({
  routes
});

export default router;
