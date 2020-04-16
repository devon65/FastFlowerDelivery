<template>
  <div>
    <h2>Driver</h2>
    <input type="text" v-model="driverEci" /> Driver ECI<br />
    <input type="text" v-model="username" /> Driver username
    <h3>Current Orders</h3>
    <div v-for="(item, index) in this.currentOrders" :key="index">
      <div
        style="background-color: green; padding: 8px; border-radius: 6px; color: white;" class="driver-order"
        v-if="item.status === 'open'"
      >
        <div>
          <b>Item: </b>{{ item.itemID }} <b>Status: </b
          >{{ item["status"] }} <br /><b>Flower Shop: </b>
          {{ item["flowerShopAddress"] }}<br />
          <b>Customer Address: </b>{{ item.address }}
        </div>
        <button
          style="font-size: 24px; margin-top: 8px; background-color: #2892d0; color: white; border-radius: 4px;"
          v-on:click="acceptOrder(item['orderID'])"
        >
          Accept Order
        </button>
      </div>
      <div
        style="background-color: red; color: white; padding: 8px; border-radius: 6px;" class="driver-order"
        v-else
      >
        <b>Item: </b>{{ item.itemID }} <b>Status: </b>{{ item["status"]
        }}<br />
        <b>Flower Shop: </b> {{ item.store.address }}<br />
        <b>Customer Address: </b>{{ item.customerAddress }}
      </div>
      <br />
    </div>
    <h3>Your orders</h3>
    <div v-for="(item, index) in this.currentOrders" :key="'my-' + index">
      <div class="driver-order" v-if="item.driver && item.driver.username === username">
        <div
          v-if="item.status === 'enroute'"
          style="background-color: yellow; padding: 8px; border-radius: 6px;"
        >
          <div>
            <b>Item: </b>{{ item.itemID }} <b>Status: </b
            >{{ item["status"] }} <br /><b>Flower Shop: </b>
            {{ item.store.address }} <br /><b>Customer Address: </b
            >{{ item.address }}
          </div>
          <button
            style="font-size: 24px; margin-top: 8px; background-color: #2892d0; color: white; border-radius: 4px;"
            v-on:click="markDelivered(item['orderID'])"
          >
            Mark Delivered
          </button>
        </div>
        <div
          v-else
          style="background-color: blue; padding: 8px; border-radius: 6px; color: white;"
        >
          <div>
            <b>Item: </b>{{ item.itemID }} <b>Status: </b
            >{{ item["status"] }} <br /><b>Flower Shop: </b>
            {{ item.store.address }} <br /><b>Customer Address: </b
            >{{ item.address }}
          </div>
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
      driverEci: "QUHHcSVGJJQ9HHcsj6UVG2",
      loop: null,
      currentOrders: {},
      username: ""
    };
  },
  mounted() {
    this.getDriverOrders();
    this.loop = window.setInterval(this.getDriverOrders, 5000)
  },
  beforeDestroy() {
    window.clearInterval(this.loop);
  },
  methods: {
    getDriverOrders() {
      let requestUrl = `http://localhost:8080/sky/cloud/${this.driverEci}/driver_base/orders`
      // this.currentOrders = {
      //   "123abc": {
      //     orderID: "123abc",
      //     itemID: "Roses",
      //     status: "open",
      //     customerAddress: "121+N+State+St+Orem+UT+84057",
      //     flowerShopAddress: "669+E+800+N+Provo+UT+84606",
      //     driver: {
      //       name: "john",
      //       username: "john",
      //       notify_number: "12345678901"
      //     }
      //   },
      //   "123abc2": {
      //     orderID: "123abc2",
      //     itemID: "Roses",
      //     status: "enroute",
      //     customerAddress: "121+N+State+St%2C+Orem%2C+UT+84057",
      //     flowerShopAddress: "669+E+800+N%2C+Provo%2C+UT%2C+84606",
      //     driver: {
      //       name: "Jeff",
      //       username: "jeff",
      //       notify_number: "12345678901"
      //     }
      //   }
      // };
      axios
          .get(requestUrl)
          .then(response => this.currentOrders = response.data)
    },

    acceptOrder(orderID) {
      const requestUrl = `http://localhost:8080/sky/event/${this.driverEci}/pico/driver/order_accepted?orderID=${orderID}`;
      axios
        .get(requestUrl)
        .then(() => {
          alert("Order accepted");
          this.getDriverOrders();
        })
        .catch(() => alert("Error accepting order"));
    },
    markDelivered(orderID) {
      console.log(orderID);
      const requestUrl = `http://localhost:8080/sky/event/${this.driverEci}/pico/driver/order_delivered?orderID=${orderID}`;
      axios
        .post(requestUrl)
        .then(() => {
          alert("Marked as Delivered");
          this.getDriverOrders();
        })
        .catch(() => alert("Error marking as delivered"));
    }
  }
};
</script>
<style>
.driver-order {
  width: 60vw;
  margin: auto;
}
button:hover {
  cursor: pointer;
}
</style>