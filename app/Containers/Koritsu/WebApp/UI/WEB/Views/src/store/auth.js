import axios from 'axios';
import router from '../router/index'

export default {
    namespaced: true,
    state: {
        token: null,
        user: null,
        projects: null,
        report: null,
    },
    getters: {
        authenticated(state) {
            return state.token && state.user
        },
        user(state) {
            return state.user
        },
        projects(state) {
            return state.projects
        },
    },
    mutations: {
        SET_TOKEN(state, token) {
            state.token = token
        },
        SET_USER(state, user) {
            state.user = user
        },
        SET_PROJECTS(state, projects) {
            state.projects = projects
        }
    },
    actions: {
        async signIn({dispatch}, credentials) {

            let response = await axios.post("/oauth/token", {
                username: credentials.email,
                password: credentials.password,
                grant_type: "password",
                client_id: process.env.MIX_VUE_APP_CLIENT_ID,
                client_secret: process.env.MIX_VUE_APP_CLIENT_SECRET,
            })

            return dispatch('attempt', response.data)
        },

        async forgotPassword({}, data) {

            let response = await axios.post("/password/forgot", {
                email: data.email,
                reseturl: 'resetPassword',
                client_id: process.env.MIX_VUE_APP_CLIENT_ID,
                client_secret: process.env.MIX_VUE_APP_CLIENT_SECRET,
            })

            return response.data;
        },

        async resetPassword({}, data) {

            let response = await axios.post("/password/reset", {
                email: data.email,
                token: data.token,
                password: data.password,
                client_id: process.env.MIX_VUE_APP_CLIENT_ID,
                client_secret: process.env.MIX_VUE_APP_CLIENT_SECRET,
            })

            return response.data;
        },

        async changePassword({state}, data) {

            let response = await axios.patch("/users/" + state.user.id, {
                password: data.password,
                client_id: process.env.MIX_VUE_APP_CLIENT_ID,
                client_secret: process.env.MIX_VUE_APP_CLIENT_SECRET,
            }).catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            return response.data.data;
        },

        async signUp({dispatch}, credentials) {

            try {
                let response = await axios.post("/register", {
                    name: credentials.name,
                    email: credentials.email,
                    password: credentials.password
                })

              return response.data;
            } catch (error) {

                if (error.response) {
                    return error.response.data;
                } else if (error.request) {
                    console.log(error.request);
                } else {
                    console.log('Error', error.message);
                }

            }

        },


        async createProject({dispatch}, project) {

            try {
                let response = await axios.post("/projects/createWithAnalysis", project).catch((error) => {
                    if (error.response.status === 401) {
                        router.replace('/login')
                    }
                });

                if (response.data) {
                    return dispatch('getProjects')
                }
            } catch (error) {

                if (error.response) {
                    return error.response.data;
                } else if (error.request) {
                    console.log(error.request);
                } else {
                    console.log('Error', error.message);
                }

            }

        },

        async updateProject({dispatch}, project) {

            try {
                let response = await axios.put("/projects/" + project.id, project.data).catch((error) => {
                    if (error.response.status === 401) {
                        router.replace('/login')
                    }
                });

                if (response.data) {
                    return dispatch('getProjects')
                }
            } catch (error) {

                if (error.response) {
                    return error.response.data;
                } else if (error.request) {
                    console.log(error.request);
                } else {
                    console.log('Error', error.message);
                }

            }

        },

        async updateAlternativeAnalysisMeasures({dispatch}, alternative_analysis) {

            try {

                let response = await axios.put("/alternative_analyses/" + alternative_analysis.id + "/measures", alternative_analysis).catch((error) => {
                    if (error.response.status === 401) {
                        router.replace('/login')
                    }
                });

                if (response.data) {
                    return dispatch('getProjects')
                }
            } catch (error) {

                if (error.response) {
                    return error.response.data;
                } else if (error.request) {
                    console.log(error.request);
                } else {
                    console.log('Error', error.message);
                }

            }

        },

        async updateAlternativeAnalysisName({dispatch}, alternative_analysis) {

            try {

                let response = await axios.put("/alternative_analyses/" + alternative_analysis.id, alternative_analysis).catch((error) => {
                    if (error.response.status === 401) {
                        router.replace('/login')
                    }
                });

                if (response.data) {
                    return dispatch('getProjects')
                }
            } catch (error) {

                if (error.response) {
                    return error.response.data;
                } else if (error.request) {
                    console.log(error.request);
                } else {
                    console.log('Error', error.message);
                }

            }

        },

        async createAnalysisAlternatives({dispatch}, analysis) {

            try {

                let response = await axios.post("/analyses/" + analysis.id + "/alternatives/create", analysis.data).catch((error) => {
                    if (error.response.status === 401) {
                        router.replace('/login')
                    }
                });

                if (response.data) {
                    return dispatch('getProjects')
                }
            } catch (error) {

                if (error.response) {
                    return error.response.data;
                } else if (error.request) {
                    console.log(error.request);
                } else {
                    console.log('Error', error.message);
                }

            }

        },

        async copyAnalysisAlternatives({dispatch}, alternative_analysis) {

            try {

                let response = await axios.post("/alternative_analyses/" + alternative_analysis.id + "/copy").catch((error) => {
                    if (error.response.status === 401) {
                        router.replace('/login')
                    }
                });

                if (response.data) {
                    return dispatch('getProjects')
                }
            } catch (error) {

                if (error.response) {
                    return error.response.data;
                } else if (error.request) {
                    console.log(error.request);
                } else {
                    console.log('Error', error.message);
                }

            }

        },

        async attempt({commit, dispatch, state}, tokenJson) {

            if (tokenJson) {
                commit('SET_TOKEN', tokenJson)
            }

            if (!state.token) {
                return
            }

            try {
                let response = await axios.get("/user/profile")

                const hasEmailVerification = response.data.data.email_verified_at;
                if (hasEmailVerification) {
                    commit('SET_USER', response.data.data)
                } else {
                    dispatch('signOut')
                }

            } catch (e) {
                commit('SET_TOKEN', null)
                commit('SET_USER', null)
            }

        },

        async signOut({commit}) {
            return axios.delete("logout").then(() => {
                commit('SET_TOKEN', null)
                commit('SET_USER', null)
            })

        },

        async deleteProject({dispatch}, project_id) {
            let response = await axios.delete("projects/" + project_id).catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            if (response.status === 204) {
                return dispatch('getProjects')
            }
        },

        async deleteAlternativeAnalysis({dispatch}, alternative_analysis_id) {
            let response = await axios.delete("alternative_analyses/" + alternative_analysis_id).catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            if (response.status === 204) {
                return dispatch('getProjects')
            }
        },

        async deleteAlternativeAnalysisMeasure({dispatch}, alternative_analysis) {
            let response = await axios.delete("alternative_analyses/" + alternative_analysis.id + "/measures/" + alternative_analysis.name).catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            if (response.status === 204) {
                return dispatch('getProjects')
            }
        },

        async stopAnalysis({dispatch}, id) {
            let response = await axios.get("analyses/" + id + "/stop").catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            return response.data;
        },

        async runAlternativeAnalysis({dispatch}, id) {
            let response = await axios.get("alternative_analyses/" + id + "/run").catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            if (response.data) {
                return dispatch('getProjects')
            }

            return response.data;
        },
        async runAnalysisAction({dispatch}, id) {
            let response = await axios.get("analyses/" + id + "/run").catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            if (response.data) {
                return dispatch('getProjects')
            }

            return response.data;
        },

        async stopAlternativeAnalysis({dispatch}, id) {
            let response = await axios.get("alternative_analyses/" + id + "/stop").catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            return response.data;
        },

        async getMeasureInfo(__, data) {
            let response = await axios.get("/projects/" + data.id + '/measure_info/' + data.measure_name).catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            return response.data;
        },

        async getProject({dispatch}, project_id) {
            let response = await axios.get("projects/" + project_id).catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            dispatch('getProjects')
            return response.data.data
        },

        async getReport({dispatch}, analysis_id) {
            let response = await axios.get("analyses/" + analysis_id + "/report").catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            return response.data;
        },

        async getProjects({dispatch}) {
            let response = await axios.get("projects?include=analysis&limit=100").catch((error) => {
                if (error.response.status === 401) {
                    router.replace('/login')
                }
            });

            return dispatch('saveProjects', response.data.data)
        },

        async saveProjects({commit, dispatch}, projects) {

            // Sort Projects by Created date
            projects.sort((a, b) => a.created_at.localeCompare(b.created_at))

            let checkStatus = false;
            let timeout = 30000;
            let hasNewProject = false;
            let newProjectLists = [];
            for (const [key, value] of Object.entries(projects)) {
                const current_data = JSON.parse(value.data);
                projects[key].data = current_data;

                const date1Str = new Date(projects[key].created_at);
                const date2Str = new Date();
                const diffTime = Math.abs(date2Str - date1Str);
                const minutes = Math.floor((diffTime / 1000) / 60);

                let newProjectList = {
                    id: projects[key].id,
                    project_schema: current_data.project_schema ?? 'default_model',
                    weather_schema: current_data.weather_schema ?? 'weather_default',
                    created_at_minutes: minutes,
                    data: current_data,
                    analysis: {},
                    alternativeAnalysis: {}
                }

                if (typeof projects[key].analysis !== 'undefined') {
                    projects[key].analysis.data.data = JSON.parse(projects[key].analysis.data.data)
                    projects[key].analysis.data.results = JSON.parse(projects[key].analysis.data.results)
                    projects[key].analysis.data.status = JSON.parse(projects[key].analysis.data.status)

                    newProjectList.analysis.id = projects[key].analysis.data.id;

                    if( projects[key].analysis.data.alternativeAnalysis.data.length > 0 ) {
                        newProjectList.has_alternative = true;
                    }else{
                        newProjectList.has_alternative = false;
                    }

                    if (typeof projects[key].analysis.data.status !== 'undefined' && projects[key].analysis.data.status) {
                        if (typeof projects[key].analysis.data.status.analysis !== 'undefined') {
                            newProjectList.analysis.status = projects[key].analysis.data.status.analysis.status;
                            newProjectList.analysis.results = '';
                            newProjectList.analysis.openstudio_analysis_id = projects[key].analysis.data.openstudio_analysis_id;
                            newProjectList.analysis.host = projects[key].analysis.data.host;
                            newProjectList.analysis.ran_analysis = projects[key].analysis.data.ran_analysis;

                            if (typeof projects[key].analysis.data.status.analysis.data_points !== 'undefined') {
                                if (typeof projects[key].analysis.data.status.analysis.data_points[0] !== 'undefined') {
                                    newProjectList.analysis.data_point_id = projects[key].analysis.data.status.analysis.data_points[0].id
                                } else {
                                    newProjectList.analysis.data_point_id = ''
                                }
                            } else {
                                newProjectList.analysis.data_point_id = ''
                            }
                            if (projects[key].analysis.data.status.analysis.status !== 'completed') {
                                checkStatus = true;
                            } else {
                                newProjectList.analysis.results = projects[key].analysis.data.status.analysis.data_points[0].status_message;
                            }

                            newProjectList.alternativeAnalysis = [];
                            if (projects[key].analysis.data.alternativeAnalysis.data.length > 0) {

                                // Sort Alternative Analysis
                                projects[key].analysis.data.alternativeAnalysis.data.sort((a, b) => a.created_at.localeCompare(b.created_at));

                                for (const [key2] of Object.entries(projects[key].analysis.data.alternativeAnalysis.data)) {
                                    // TODO: Verify analysis exists / analyses will show if not found
                                    const status = JSON.parse(projects[key].analysis.data.alternativeAnalysis.data[key2].status);
                                    const alternative_data = projects[key].analysis.data.alternativeAnalysis.data[key2].data;
                                    const current_alternative_id = projects[key].analysis.data.alternativeAnalysis.data[key2].id;
                                    const current_alternative_name = projects[key].analysis.data.alternativeAnalysis.data[key2].name ?? '';
                                    const current_measures = alternative_data !== null ? (typeof alternative_data.measures !== 'undefined' ? alternative_data.measures : []) : [];
                                    const current_openstudio_analysis_id = projects[key].analysis.data.alternativeAnalysis.data[key2].openstudio_analysis_id ?? '';
                                    const current_host = projects[key].analysis.data.alternativeAnalysis.data[key2].host ?? '';
                                    const current_ran_analysis = projects[key].analysis.data.alternativeAnalysis.data[key2].ran_analysis;
                                    const altDate1Str = new Date(projects[key].analysis.data.alternativeAnalysis.data[key2].created_at);
                                    const altDate2Str = new Date();
                                    const altDiffTime = Math.abs(altDate2Str - altDate1Str);
                                    const altMinutes = Math.floor((altDiffTime / 1000) / 60);

                                    let current_results = '';
                                    let current_status = '';
                                    let current_data_point_id = '';
                                    if (status !== null) {
                                        if ('analysis' in status) {
                                            if (typeof status.analysis.data_points !== 'undefined') {
                                                if (typeof status.analysis.data_points[0] !== 'undefined') {
                                                    current_data_point_id = status.analysis.data_points[0].id;
                                                    current_results = status.analysis.data_points[0].status_message;
                                                }
                                            }
                                            current_status = status.analysis.status;
                                        }
                                    }

                                    for (let i = 0; i < current_measures.length; i++) {
                                        if (typeof current_measures[i].arguments === 'object' && current_measures[i].arguments === null) {
                                            current_measures[i].arguments = {};
                                        } else if (typeof current_measures[i].arguments.isArray && current_measures[i].arguments.length === 0) {
                                            current_measures[i].arguments = {};
                                        }
                                    }

                                    newProjectList.alternativeAnalysis.push({
                                        id: current_alternative_id,
                                        measures: current_measures,
                                        name: current_alternative_name,
                                        status: current_status,
                                        data_point_id: current_data_point_id,
                                        results: current_results,
                                        openstudio_analysis_id: current_openstudio_analysis_id,
                                        host: current_host,
                                        ran_analysis: current_ran_analysis,
                                        created_at_minutes: altMinutes
                                    })

                                    if (current_status !== 'completed' || altMinutes <= 1) {
                                        if (current_ran_analysis) {
                                            checkStatus = true;
                                        }
                                    }

                                }

                            }

                        }
                    }
                } else {
                    if (minutes <= 1) {
                        hasNewProject = true;
                        checkStatus = true;
                    }
                }

                newProjectLists.push(newProjectList)

            }

            if (checkStatus) {

                if (hasNewProject) {
                    timeout = 60000;
                }

                setTimeout(() => {
                    dispatch('getProjects', {root: true})
                }, timeout)
            }

            commit('SET_PROJECTS', newProjectLists)
        }

    }
}
