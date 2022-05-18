import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import Login from '../views/Login.vue'
import ForgotPassword from '../views/ForgotPassword.vue'
import ResetPassword from '../views/ResetPassword.vue'
import ChangePassword from '../views/ChangePassword.vue'
import VerifiedEmail from '../views/VerifiedEmail.vue'
import Register from '../views/Register.vue'
import Projects from '../views/Projects.vue'
import ProjectCreate from '../views/ProjectCreate.vue'
import ProjectEdit from '../views/ProjectEdit.vue'
import AnalysisReport from '../views/AnalysisReport.vue'
import store from '../store'

Vue.use(VueRouter)

const before = (next) =>{
    if (!store.getters['auth/authenticated']) {
        return next({
            name: 'Login'
        })
    }
    next();
}

const routes = [
    {
        path: '/',
        name: 'Home',
        component: Home,
    },
    {
        path: '/login',
        name: 'Login',
        component: Login
    },
    {
        path: '/forgotPassword',
        name: 'ForgotPassword',
        component: ForgotPassword
    },
    {
        path: '/resetPassword',
        name: 'ResetPassword',
        component: ResetPassword
    },
    {
        path: '/changePassword',
        name: 'ChangePassword',
        component: ChangePassword
    },
    {
        path: '/verifiedEmail',
        name: 'verifiedEmail',
        component: VerifiedEmail
    },
    {
        path: '/register',
        name: 'Register',
        component: Register
    },
    {
        path: '/projects',
        name: 'Projects',
        component: Projects,
        beforeEnter: (to, from, next) => {before(next);}
    },
    {
        path: '/projects/create',
        name: 'Projects',
        component: Projects,
        beforeEnter: (to, from, next) => {before(next);}
    },
    {
        path: '/projects/create/:type/:weather',
        name: 'ProjectCreate',
        component: ProjectCreate,
        beforeEnter: (to, from, next) => {before(next);}
    },
    {
        path: '/projects/:id/:type/:weather',
        name: 'ProjectEdit',
        component: ProjectEdit,
        beforeEnter: (to, from, next) => {before(next);}
    },
    {
        path: '/analyses/:id/report',
        name: 'AnalysisReport',
        component: AnalysisReport,
        beforeEnter: (to, from, next) => {before(next);}
    },
    {path: "*", component: Login}
]

const router = new VueRouter({
    mode: 'history',
    base: process.env.MIX_BASE_URL,
    routes
})

export default router
