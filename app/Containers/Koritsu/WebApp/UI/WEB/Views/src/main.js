import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import axios from 'axios';
import {
  ValidationObserver,
  ValidationProvider,
  extend,
  localize
} from "vee-validate";
import en from "./components/en.json";
import * as rules from "vee-validate/dist/rules";

// Bootstrap
import { BootstrapVue, IconsPlugin, PopoverPlugin } from 'bootstrap-vue'

// Import Bootstrap an BootstrapVue CSS files (order is important)
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import "bootstrap";

// Make BootstrapVue available throughout your project
Vue.use(BootstrapVue)
// Optionally install the BootstrapVue icon components plugin
Vue.use(IconsPlugin)
Vue.use(PopoverPlugin)

// register the plugin on vue
import Toasted from 'vue-toasted';
Vue.use(Toasted)

// Font Awesome
import { library } from '@fortawesome/fontawesome-svg-core'
import { faPlus, faPencilAlt, faCheck, faCaretRight, faChartBar, faSignOutAlt, faAsterisk, faChevronUp, faTimesCircle, faPlay, faChevronDown, faBuilding, faCloudDownloadAlt, faUserCircle, faCopy, faHome, faSpinner, faInfoCircle, faHourglassEnd, faTrash } from '@fortawesome/free-solid-svg-icons'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
library.add(faPlus, faPencilAlt, faSignOutAlt, faAsterisk, faCheck, faCaretRight, faChartBar, faChevronUp, faTimesCircle, faPlay, faChevronDown, faBuilding, faCloudDownloadAlt, faUserCircle, faCopy, faHome, faSpinner, faInfoCircle, faHourglassEnd,faTrash)
Vue.component('font-awesome-icon', FontAwesomeIcon)

//  Storage and API calls
require('./store/subscriber')
axios.defaults.baseURL = process.env.MIX_VUE_APP_URL

Vue.config.productionTip = false
import "./assets/css/custom.css"

// Install VeeValidate rules and localization
Object.keys(rules).forEach(rule => {
  extend(rule, rules[rule]);
});

localize({
  en: {
    messages: en.messages,
    names: {
      password: "Password"
    },
    fields: {
      password: {
        regex: "Your password must be 8-20 characters long, contain letters and numbers, and one Uppercase letter"
      }
    }
  }
})


Vue.component('validation-observer', ValidationObserver);
Vue.component('validation-provider', ValidationProvider);

Vue.filter('deCamelCase', function (str) {
  if (typeof str !== 'undefined') {
    const toUppercase = str => str.toUpperCase();
    return str.replace(/[A-Z]/g, ' $&').replace(/^./, toUppercase);
  } else {
    return '';
  }
});

// Echarts
import ECharts from 'vue-echarts'
import { use } from 'echarts/core'

// import ECharts modules manually to reduce bundle size
import {
    CanvasRenderer
} from 'echarts/renderers'
import {
    BarChart
} from 'echarts/charts'
import {
    GridComponent,
    TooltipComponent
} from 'echarts/components'

use([
    CanvasRenderer,
    BarChart,
    GridComponent,
    TooltipComponent
]);

// register globally (or you can do it locally)
Vue.component('v-chart', ECharts)

// Multi Select
import Multiselect from 'vue-multiselect'
import "./assets/scss/vue-multiselect.scss"
Vue.component('multiselect', Multiselect)


// Get Token from Local Storage
store.dispatch('auth/attempt', JSON.parse(localStorage.getItem('token'))).then(() => {

  new Vue({
    router,
    store,
    ECharts,
    created() {
      this.$root.$emit('bv::enable::tooltip');
    },
    render: h => h(App)
  }).$mount('#app')


})
