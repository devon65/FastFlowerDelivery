<template>
  <div class="home">
    <!-- <img alt="Vue logo" src="../assets/logo.png" />
    <HelloWorld msg="Welcome to Your Vue.js App" /> -->
    <create-order></create-order>
  </div>
</template>

<script>
// @ is an alias to /src
// import HelloWorld from "@/components/HelloWorld.vue";
import CreateOrder from "@/components/CreateOrder.vue";
export default {
  name: "Home",
  components: {
    CreateOrder
  }
};
</script>
