<template>
  <div>
    <h3>Create Order</h3>
    <div>
      <br />
      Select a shop location
      <select v-model="shopLocation">
        <option>Provo</option>
        <option>Lehi</option>
        <option>Salt Lake City</option>
      </select>
      <br /><br />
      Customer Name
      <input type="text" placeholder="Customer Name" v-model="customerName" />
      <!-- <br /><br />
      Price
      <input type="text" placeholder="Price" v-model="price" /> -->
      <br /><br />
      Location
      <input type="text" placeholder="address" v-model="address" /><input
        type="text"
        placeholder="City"
        v-model="city"
      /><input type="text" placeholder="State" v-model="state" /><input
        placeholder="Zip Code"
        type="number"
        v-model="zip"
      /><br /><br />
      Flowers <br />
      <select v-model="itemID">
        <option>Roses</option>
        <option>Hydrangeas</option>
        <option>Lilies</option>
        <option>Tulips</option>
      </select>
      <br /><br />
      <input type="text" v-model="provoEci" /> Provo ECI <br /><br />
      <input type="text" v-model="lehiEci" /> Lehi ECI <br /><br />
      <input type="text" v-model="slcEci" /> SLC ECI <br /><br />
      <button
        v-on:click="submitOrder"
        style="color: white; background-color: green; font-size: 20px;"
      >
        Submit Order
      </button>
      <br /><br />
      <h3>Current Orders</h3>
      <div v-for="(item, index) in this.currentOrders" :key="index">
        <div
          class="order"
          :class="{
            intransit: item.status === 'delivered',
            delivered: item.status === 'delivered'
          }"
        >
          <b>Item:</b> {{ item["itemID"] }} <b>Status:</b> {{ item["status"] }}
          <b>Address:</b> {{ item["address"] }} <b>Driver:</b>
          {{ item["driver"] || "Not assigned yet" }}
        </div>
        <br />
      </div>
    </div>
    <div style="height: 300px;"></div>
  </div>
</template>

<script>
import axios from "axios";
export default {
  data() {
    return {
      customerName: "",
      address: "",
      city: "",
      state: "",
      zip: "",
      provoEci: "2gG9gzGGnuk2Ed5ZfSMPSh",
      lehiEci: "DktQsvscABRzMz6Ck6vRgT",
      slcEci: "DktQsvscABRzMz6Ck6vRgT",
      shopLocation: "Provo",
      baseUrl: "http://localhost:8080/sky/",
      eventUrl: "/Pico/create/order",
      currentOrders: [],
      itemID: "Roses",
      loop: null
    };
  },
  mounted() {
    this.getOrders();
    this.loop = window.setInterval(this.getOrders, 5000);
  },
  beforeDestroy() {
    window.clearInterval(this.loop);
  },
  methods: {
    submitOrder() {
      this.address = this.address.replace(/\s+/g, "+");
      this.city = this.city.replace(/\s+/g, "+");
      this.state = this.state.replace(/\s+/g, "+");
      this.shopLocation = this.shopLocation.replace(/\s+/g, "+");
      let eci = this.provoEci;
      if (this.shopLocation === "Lehi") {
        eci = this.lehiEci;
      } else if (this.shopLocation === "Salt Lake City") {
        eci = this.slcEci;
      }
      let location = `${this.address},${this.city},${this.state},${this.zip}`;
      let requestUrl = `${this.baseUrl}event/${eci}${this.eventUrl}?address=${location}&buyer=${this.customerName}&itemID=${this.itemID}`;
      console.log(requestUrl);
      axios.get(requestUrl).then(response => console.log(response.data));
    },

    getOrders() {
      let eci = this.provoEci;
      if (this.shopLocation === "Lehi") {
        eci = this.lehiEci;
      } else if (this.shopLocation === "Salt Lake City") {
        eci = this.slcEci;
      }

      const requestUrl = `${this.baseUrl}cloud/${eci}/flower_shop/orders`;
      // console.log(requestUrl);
      // this.currentOrders = [
      //   {
      //     orderID: "ck8wj8ab40kjqbakz3wn47gxp",
      //     itemID: "101",
      //     status: "OnMyWay",
      //     driver: "Pedro"
      //   },
      //   {
      //     orderID: "ck8wkvfc80nhvbakz2w38g0i3",
      //     itemID: "Another",
      //     status: "WorkingOnIt",
      //     driver: "Pedro"
      //   },
      //   {
      //     orderID: "ck8wlxw1l0qtzbakzhrpt09pi",
      //     itemID: "Yo",
      //     status: "open",
      //     driver: ""
      //   }
      // ];
      axios.get(requestUrl).then(response => {
        this.currentOrders = response.data;
      }).catch(() => {
        this.currentOrders = []
      })
    }
  }
};
</script>
<style>
.order {
  background-color: green;
  color: white;
  padding: 8px;
  border-radius: 6px;
  width: 60vw;
  margin: auto;
}
.intransit {
  color: black;
  background-color: yellow;
}
.delivered {
  background-color: red;
}
</style>
