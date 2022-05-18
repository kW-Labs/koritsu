// @ts-ignore
import store from '../store'
import axios from 'axios';

store.subscribe((mutation) => {

    switch (mutation.type){
        case 'auth/SET_TOKEN':
            /**
             * @param mutation.payload.access_token
             */
            if(mutation.payload){
                axios.defaults.headers.common['Authorization'] = `Bearer ${mutation.payload.access_token}`
                localStorage.setItem('token', JSON.stringify(mutation.payload))
            }else{
                axios.defaults.headers.common['Authorization'] =  null
                localStorage.removeItem('token')
            }
            break;
    }
})
