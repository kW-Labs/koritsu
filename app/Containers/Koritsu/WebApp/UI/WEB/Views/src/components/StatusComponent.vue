<template>
  <div>
    <div class="row" v-if=" status === 'queued'">
      <div class=" mt-2">
        <i class="px-2">
          <font-awesome-icon icon="hourglass-end"/>
        </i>
        <span class="processing"> Queued </span>
      </div>
    </div>
    <div class="row" v-if=" status === 'started'">
      <div class=" mt-2">
        <i class="px-2">
          <font-awesome-icon icon="hourglass-end" spin/>
        </i>
        <span class="processing"> Processing </span>
        <div class="text-center mr-5">
          <a href="#" class="text-danger"
             @click="showStopMsgBox(id, name)">
            <font-awesome-icon icon="times-circle" size="2x"/>
          </a>
        </div>
      </div>
    </div>
    <div class="row" v-if=" status === 'completed' && results === 'completed normal'">
      <div class="text-success mt-2">
        <i class="px-2">
          <font-awesome-icon icon="check"/>
        </i>
        <span class="completed"> Completed </span>
      </div>
    </div>
    <div class="row" v-if=" status === 'completed' && results !== 'completed normal'">
      <div class="text-danger mt-2">
        <i class="px-2">
          <font-awesome-icon icon="check"/>
        </i>
        <span class="completed"> Failed </span>
      </div>
    </div>
    <div class="row" v-if=" status === 'completed'">

      <div class="col-6">
        <b-dropdown variant="primary">
          <template #button-content>
          <span v-if="!downloading">
            <font-awesome-icon :icon="['fas', 'cloud-download-alt']"/>
            Download
          </span>
            <span v-else>
              <font-awesome-icon icon="spinner" spin/>
            Downloading
          </span>
          </template>

          <b-dropdown-item-button @click="download('zip')" class="text-decoration-none">
            Zip
          </b-dropdown-item-button>

          <b-dropdown-item-button @click="download('openstudio_report')" class="text-decoration-none">
            Openstudio Report
          </b-dropdown-item-button>

        </b-dropdown>
      </div>

      <div class="col-6">
        <b-button class="ml-2" @click="download('openstudio_analysis_report',id)" v-if="!is_alternative">
          <font-awesome-icon :icon="['fas', 'chart-bar']"/>
          Report
        </b-button>
      </div>

    </div>
    <div class="row" v-if=" status === 'unknown'">
      <div class="text-danger mt-2" >
        <i class="px-2">
          <font-awesome-icon icon="times-circle"/>
        </i>
        <span class="completed"> Unknown Status </span>
      </div>
    </div>
    <div class="row" v-if="!status">
      <div class="text-danger mt-2" >
        <i class="px-2">
          <font-awesome-icon icon="times-circle"/>
        </i>
        <span class="completed"> No Status </span>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";
import {mapActions} from "vuex";

export default {
  data: () => ({
    downloading: false,
    type: "Zip"
  }),
  props: {
    status: String,
    results: String,
    is_alternative: Boolean,
    name: String,
    openstudio_analysis_id: String,
    id: String
  },
  methods: {
    ...mapActions({
      stopAnalysisAction: "auth/stopAnalysis",
      stopAlternativeAnalysisAction: "auth/stopAlternativeAnalysis"
    }),

    showStopMsgBox(id, project_name) {

      this.$bvModal.msgBoxConfirm('Please confirm that you want to stop the "' + project_name + '" analysis.', {
        title: 'Please Confirm',
        size: 'sm',
        buttonSize: 'sm',
        okVariant: 'danger',
        okTitle: 'Yes',
        cancelTitle: 'No',
        footerClass: 'p-2',
        hideHeaderClose: false,
      })
          .then(value => {
            if (value) {

              if (this.is_alternative) {
                this.stopAlternativeAnalysisAction(id).then(() => {
                  this.$toasted.show(`Stopped ${project_name}`, {
                    theme: "outline",
                    position: "top-right",
                    duration: 5000
                  });

                }).catch(err => {
                  console.log(err)
                })
              } else {
                this.stopAnalysisAction(id).then(() => {
                  this.$toasted.show(`Stopped ${project_name}`, {
                    theme: "outline",
                    position: "top-right",
                    duration: 5000
                  });

                }).catch(err => {
                  console.log(err)
                })
              }
            }
          })
          .catch(err => {
            // An error occurred
            console.log(err)
          })
    },

    download(type, id = null) {

      if (type === "openstudio_analysis_report") {
        this.$router.push({
          name: 'AnalysisReport',
          params: {id: id}
        });
      } else {
        let file_type = 'application/zip'
        if (type === "report") {
          this.type = "Openstudio Report"
          file_type = 'application/html'
        } else {
          this.type = "Zip"
        }

        this.downloading = true;
        const url = (this.is_alternative ? "/alternative_analyses/" : "/analyses/") + this.id + '/download/' + type;
        axios.get(url, {responseType: 'blob'}).then((response) => {

          this.downloading = false;

          const url = window.URL.createObjectURL(new Blob([response.data], {type: file_type}));
          const link = document.createElement('a');
          link.href = url;
          if (type === "openstudio_report") {
            link.setAttribute('download', this.id + '.html');
          } else {
            link.setAttribute('download', this.id + '.zip');
          }
          document.body.appendChild(link);
          link.click();
        })
      }

    }
  }
}
</script>
