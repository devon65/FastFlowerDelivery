<template>
  <div>
    <h2>Driver</h2>
    <input type="text" v-model="driverEci" /> Driver ECI<br />
    <input type="text" v-model="username" /> Driver username
    <h3>Current Orders</h3>
    <div v-for="(item, index) in this.currentOrders" :key="index">
      <div
        style="background-color: green; padding: 8px; border-radius: 6px; color: white;"
        v-if="item[1].status === 'open'"
      >
        <div>
          <b>Item: </b>{{ item[1].itemID }} <b>Status: </b
          >{{ item[1]["status"] }} <br /><b>Flower Shop: </b>
          {{ item[1]["flowerShopAddress"] }}<br />
          <b>Customer Address: </b>{{ item[1].customerAddress }}
        </div>
        <button
          style="font-size: 24px; margin-top: 8px; background-color: #2892d0; color: white; border-radius: 4px;"
          v-on:click="acceptOrder(item[1]['orderID'])"
        >
          Accept Order
        </button>
      </div>
      <div
        style="background-color: red; color: white; padding: 8px; border-radius: 6px;"
        v-else
      >
        <b>Item: </b>{{ item[1].itemID }} <b>Status: </b>{{ item[1]["status"]
        }}<br />
        <b>Flower Shop: </b> {{ item[1]["flowerShopAddress"] }}<br />
        <b>Customer Address: </b>{{ item[1].customerAddress }}
      </div>
      <br /><br />
    </div>
    <h3>Your orders</h3>
    <div v-for="(item, index) in this.currentOrders" :key="'my-' + index">
      <div v-if="item[1].driver.username === username">
        <div
          v-if="item[1].status === 'enroute'"
          style="background-color: yellow; padding: 8px; border-radius: 6px;"
        >
          <div>
            <b>Item: </b>{{ item[1].itemID }} <b>Status: </b
            >{{ item[1]["status"] }} <br /><b>Flower Shop: </b>
            {{ item[1]["flowerShopAddress"] }} <br /><b>Customer Address: </b
            >{{ item[1].customerAddress }}
          </div>
          <button
            style="font-size: 24px; margin-top: 8px; background-color: #2892d0; color: white; border-radius: 4px;"
            v-on:click="markDelivered(item[1]['orderID'])"
          >
            Mark Delivered
          </button>
        </div>
        <div
          v-else
          style="background-color: blue; padding: 8px; border-radius: 6px; color: white;"
        >
          <div>
            <b>Item: </b>{{ item[1].itemID }} <b>Status: </b
            >{{ item[1]["status"] }} <br /><b>Flower Shop: </b>
            {{ item[1]["flowerShopAddress"] }} <br /><b>Customer Address: </b
            >{{ item[1].customerAddress }}
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
      driverEci: "12093",
      loop: null,
      currentOrders: {},
      username: ""
    };
  },
  mounted() {
    this.getDriverOrders();
    // this.loop = window.setInterval(this.getDriverOrders, 5000)
  },
  beforeDestroy() {
    window.clearInterval(this.loop);
  },
  methods: {
    getDriverOrders() {
      // let requestUrl = `http://localhost:8080/sky/event/${this.driverEci}/driver_base/available_orders`
      this.currentOrders = {
        "123abc": {
          orderID: "123abc",
          itemID: "Roses",
          status: "open",
          customerAddress: "121+N+State+St+Orem+UT+84057",
          flowerShopAddress: "669+E+800+N+Provo+UT+84606",
          driver: {
            name: "Jeff",
            username: "jeff",
            notify_number: "12345678901"
          }
        },
        "123abc2": {
          orderID: "123abc2",
          itemID: "Roses",
          status: "enroute",
          customerAddress: "121+N+State+St%2C+Orem%2C+UT+84057",
          flowerShopAddress: "669+E+800+N%2C+Provo%2C+UT%2C+84606",
          driver: {
            name: "Jeff",
            username: "jeff",
            notify_number: "12345678901"
          }
        }
      };
      // axios
      //     .get(requestUrl)
      //     .then(response => this.currentOrders = response)
      this.currentOrders = Object.entries(this.currentOrders);
    },

    acceptOrder(orderID) {
      const requestUrl = `http://localhost:8080/sky/event/${this.driverEci}/driver/order_accepted?orderID=${orderID}`;
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
      const requestUrl = `http://localhost:8080/sky/event/${this.driverEci}/driver/order_delivered`;
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
