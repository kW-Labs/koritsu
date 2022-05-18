<template>
  <div class="container">
    <h3> Hourly Heatmap</h3>

    <div class="row pb-4">
      <div class="col-6">
        <label class="typo__label">Fuel Type</label>
        <multiselect v-model="fuel_type" :multiple="false" :options="fuel_options" :searchable="true"
                     :close-on-select="true"
                     :show-labels="false" label="name" track-by="name" placeholder="Pick a fuel type"
                     @input="switchFuelType">
        </multiselect>
      </div>
      <div class="col-6">
        <label class="typo__label">Run</label>
        <multiselect v-model="runs" :multiple="false" :options="options" :searchable="true" :close-on-select="true"
                     :show-labels="false" label="name" track-by="name" placeholder="Pick a run" @input="switchRuns">
        </multiselect>
      </div>
    </div>

    <div id="heatmap" class="container">

      <div id="heatmap-chart" v-if="hasData"></div>
      <div v-else>
        <h3> No Heatmap Data Available</h3>
      </div>

      <div id="heatmap-tooltip" class="hidden">
        <p><strong id="heatmap-date"> </strong></p>
        <p id="heatmap-hour"></p>
        <p id="heatmap-value"></p>
      </div>
    </div>
  </div>
</template>


<script>

import * as d3 from "d3";

export default {

  props: {
    chart_data: Array,
    options: Array,
    fuel_options: Array,
  },
  data() {
    return {
      fuel_type: {},
      runs: {},
      index: 0,
      is_first_fuel_type: false,
      hasData: true,
    }
  },
  created() {

    setTimeout(() => {
      if (!this.is_first_fuel_type) {
        this.fuel_type = this.fuel_options[0];
        this.runs = this.options[0];
        this.index = this.chart_data.findIndex(x => x.index === 0 && x.key === 0);
      }
      this.plot()
    }, 100)
  },
  methods: {
    plot() {
      // 1. Access data
      const width = 875;

      let dimensions = {
        width: width,
        height: width * 0.5,
        margin: {
          top: 0,
          right: 0,
          bottom: 100,
          left: 75
        },
        buckets: 10,
        colors: [
          "#0F08FF",
          "#3208B9",
          "#50088C",
          "#73036E",
          "#8C0B55",
          "#BE1232",
          "#FA3C1E",
          "#FA5A1E",
          "#FFC328",
          "#FFFF2E"
        ],
        months: ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."],
        hours: [
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23
        ]
      };

      dimensions.boundedWidth =
          dimensions.width - dimensions.margin.left - dimensions.margin.right;
      dimensions.boundedHeight =
          dimensions.height - dimensions.margin.top - dimensions.margin.bottom;

      // 2. Draw Canvas
      const svg = d3
          .select("#heatmap-chart")
          .append("svg")
          .attr("id", "heatmap-chart-svg")
          .attr(
              "width",
              dimensions.width + dimensions.margin.left + dimensions.margin.right
          )
          .attr(
              "height",
              dimensions.height + dimensions.margin.top + dimensions.margin.bottom
          )
          .append("g")
          .attr(
              "transform",
              "translate(" + dimensions.margin.left + "," + dimensions.margin.top + ")"
          );

      svg
          .append("g")
          .style(
              "transform",
              `translate(${dimensions.margin.left}px, ${dimensions.margin.top}px)`
          );

      // 3. Create scales
      let Tdata = this.chart_data[this.index].heatmap_data;

      const formatTime = d3.timeFormat("%j");

      let data = Tdata.map(function (d) {

        const myTime = d.date.split(" ");
        const myDay = parseInt(formatTime(new Date(myTime[0])), 0);
        const myHour = myTime[1].split(":");

        d.day = myTime[0];
        d.days = (myDay === 366 ? 1 : myDay + 1);
        d.hour = parseInt(myHour[0], 0);

        return d;
      });

      let dates = data.map(function (d) {
        return d.days;
      });

      dates = dates.filter(function (v, i) {
        return dates.indexOf(v) === i;
      });

      const Vdata = Tdata.map(function (d) {
        return d.value;
      });

      const minValue = d3.min(Vdata);
      const maxValue = d3.max(Vdata);

      const W = dimensions.width / (dates.length + 10);
      const H = dimensions.height / dimensions.hours.length;

      const getColor = d3
          .scaleQuantile()
          .domain([minValue, maxValue])
          .range(dimensions.colors);

      const yLabels = svg
          .selectAll(".monthLabel")
          .data(dimensions.hours)
          .enter()
          .append("text")
          .text(function (d) {
            return d;
          })
          .attr("x", 0)
          .attr("y", function (d, i) {
            return i * H;
          })
          .style("text-anchor", "end")
          .attr("transform", "translate(5,30)")
          .attr("class", "mono axis-month");

      const xScale = d3
          .scaleBand()
          .domain(dimensions.months)
          .range([0, dimensions.width]);

      const xAxisH = d3.axisBottom(xScale).ticks(12);

      const xLabel = svg
          .append("g")
          .attr("class", "axis mono axis-date")
          .attr("transform", "translate(10,-5)")
          .call(xAxisH);

      const yLabelTitle = svg
          .append("g")
          .attr("transform", "translate(" + -45 + ", " + dimensions.height / 2 + ")")
          .append("text")
          .attr("text-anchor", "middle")
          .attr("transform", "rotate(-90)")
          .attr("class", "mono axis-label")
          .text("Hours");

      const t = svg
          .selectAll(".dates")
          .data(data, function (d) {
            return d.days + ":" + d.hour;
          })
          .enter()
          .append("rect")
          .attr("transform", "translate(15,15)")
          .attr("x", function (d) {
            return d.days * W;
          })
          .attr("y", function (d) {
            return (d.hour - 1) * H + 20;
          })
          .attr("rx", 0)
          .attr("ry", 0)
          .attr("width", W)
          .attr("height", H)
          .style("fill", function (d) {
            return getColor(d.value);
          }).on("mouseover", function (event, d) {
            const xPosition = parseFloat(d3.select(this).attr("x")) + 50;
            const yPosition = parseFloat(d3.select(this).attr("y")) - dimensions.height - 55;

            d3.select("#heatmap-tooltip")
                .style("left", xPosition + "px")
                .style("top", yPosition + "px")
                .select("#heatmap-date")
                .text(d.day);

            d3.select("#heatmap-hour")
                .text("Hour: " + d.hour);

            d3.select("#heatmap-value")
                .text("Value: " + d.value);

            d3.select("#heatmap-tooltip").classed("hidden", false);
          }).on("mouseout", function () {
            d3.select("#heatmap-tooltip").classed("hidden", true);
          });


      // Legend
      const linearGradient = svg
          .append("linearGradient")
          .attr("id", "linear-gradient");

      // Horizontal gradient
      linearGradient
          .attr("x1", "0%")
          .attr("y1", "0%")
          .attr("x2", "100%")
          .attr("y2", "0%");

      // Append multiple color stops by using D3's data/enter step
      linearGradient
          .selectAll("stop")
          .data([
            {offset: "0%", color: dimensions.colors[0]},
            {offset: "20%", color: dimensions.colors[1]},
            {offset: "30%", color: dimensions.colors[2]},
            {offset: "40%", color: dimensions.colors[3]},
            {offset: "50%", color: dimensions.colors[4]},
            {offset: "60%", color: dimensions.colors[5]},
            {offset: "70%", color: dimensions.colors[6]},
            {offset: "80%", color: dimensions.colors[7]},
            {offset: "90%", color: dimensions.colors[8]},
            {offset: "100%", color: dimensions.colors[9]}
          ])
          .enter()
          .append("stop")
          .attr("offset", function (d) {
            return d.offset;
          })
          .attr("stop-color", function (d) {
            return d.color;
          });

      const minLegend = d3.min(data, (d) => d.value);
      const maxLegend = d3.max(data, (d) => d.value);
      const sumMinMaxLegend =
          d3.max(data, (d) => d.value) + d3.min(data, (d) => d.value);
      const legendWidth = width * 0.3,
          legendHeight = 18;

      // Color Legend container
      const legendsvg = svg
          .append("g")
          .attr("id", "legend")
          .attr(
              "transform",
              "translate(" +
              (dimensions.margin.left + legendWidth + 100) +
              "," +
              (dimensions.height + 50) +
              ")"
          );

      // Draw the Rectangle
      legendsvg
          .append("rect")
          .attr("class", "legendRect")
          .attr("x", -legendWidth / 2 + 0.5)
          .attr("y", 10)
          .attr("width", legendWidth)
          .attr("height", legendHeight)
          .style("fill", "url(#linear-gradient)")
          .style("stroke", "black")
          .style("stroke-width", "1px");

      // Append title
      legendsvg
          .append("text")
          .attr("class", "legendTitle")
          .attr("x", 0)
          .attr("y", 2)
          .text(this.chart_data[this.index].units);

      // Set scale for x-axis
      const xScaleLegend = d3
          .scaleLinear()
          .range([0, legendWidth])
          .domain([d3.min(data, (d) => d.value), d3.max(data, (d) => d.value)]);

      const xAxisLegend = legendsvg
          .append("g")
          .call(
              d3
                  .axisBottom(xScaleLegend)
                  .tickValues([
                    minLegend,
                    (sumMinMaxLegend / 2 + minLegend) / 2,
                    sumMinMaxLegend / 2,
                    (sumMinMaxLegend / 2 + maxLegend) / 2,
                    maxLegend
                  ])
                  .tickFormat((x) => Math.round(parseFloat(x)))
          )
          .attr("class", "legendAxis")
          .attr("id", "legendAxis")
          .attr(
              "transform",
              "translate(" + -legendWidth / 2 + "," + (10 + legendHeight) + ")"
          );

    },
    switchFuelType(fuelType) {
      const fuel_type_index = this.fuel_options.findIndex(x => x.name === fuelType.value);
      const runs_index = this.options.findIndex(x => x.name === this.runs.name);
      this.index = this.chart_data.findIndex(x => x.index === runs_index && x.key === fuel_type_index);
      this.checkIfData()
    },
    switchRuns(runs) {
      const fuel_type_index = this.fuel_options.findIndex(x => x.name === this.fuel_type.name);
      const runs_index = this.options.findIndex(x => x.name === runs.name);
      this.index = this.chart_data.findIndex(x => x.index === runs_index && x.key === fuel_type_index);
      this.checkIfData()
    },

    checkIfData() {

      // chart data will not have missing data records
      if (this.index === -1) {
        this.hasData = false;
      } else {
        this.hasData = true;
        d3.select("#heatmap-chart-svg").remove();
        setTimeout(() => {
          this.plot();
        }, 100)
      }
    }
  }
}
</script>

<style>

#heatmap {
  position: relative;
  background-color: white;
  padding: 0;
  height: 550px;
}

rect.bordered {
  stroke: #E6E6E6;
  stroke-width: 2px;
}

text.mono, .axis text, .axis-month {
  font-size: 9pt;
  font-family: Consolas, courier, serif;
  fill: #aaa;
}

text.axis-date, text.axis-month {
  fill: #aaa;
}

text.axis-label {
  font-size: 15pt;
}

.axis path, .axis line {
  fill: none;
  stroke: #000;
  shape-rendering: crispEdges;
}

#heatmap-tooltip {
  position: relative;
  width: 140px;
  height: auto;
  padding: 10px;
  background-color: black;
  border-radius: 12px;
  box-shadow: 5px 5px 12px rgba(0, 0, 0, 0.6);
  pointer-events: none;
  top: 400px;
  left: 650px;
  opacity: 0.80;
  color: white;

}

#heatmap-tooltip.hidden {
  display: none;
}

#heatmap-tooltip p {
  margin: 0;
  font-family: sans-serif;
  font-size: 16px;
  line-height: 20px;
}
</style>
