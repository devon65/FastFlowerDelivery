<template>
    <div>
        Create Order
        <div>
            <br><br>
            Select a shop location
            <select v-model="shopLocation">
                <option>Provo</option>
                <option>Lehi</option>
                <option>Salt Lake City</option>
            </select>
            <br><br>
            Customer Name
            <input type="text" placeholder="Customer Name" v-model="customerName"/>
            <br><br>
            Location <input type="text" placeholder="address" v-model="address"><input type="text" placeholder="City" v-model="city"><input type="text" placeholder="State" v-model="state"/><input placeholder="Zip Code" type="number" v-model="zip"/><br><br>
            Flowers <br>
            <input type="checkbox" v-model="roses"> Roses
            <input type="checkbox" v-model="hydrangeas"> Hydrangeas
            <input type="checkbox" v-model="lilies"> Lilies
            <input type="checkbox" v-model="tulips"> Tulips
            <br><br>
            <input type="text" v-model="eci"> App ECI <br><br>
            <button v-on:click="submitOrder" style="color: white; background-color: green; font-size: 20px;">Submit Order</button>
        </div>
    </div>
</template>

<script>
import axios from 'axios';
export default {
    data() {
        return {
            customerName: "",
            address:"",
            city:"",
            state:"",
            zip:"",
            roses: false,
            hydrangeas: false,
            lilies: false,
            tulips: false,
            eci: "",
            shopLocation: "Provo"
        }
    },
    methods: {
        submitOrder() {
            let flowers = []
            if (this.roses) { flowers.push("Roses")}
            if (this.hydrangeas) { flowers.push("Hydrangeas")}
            if (this.lilies) { flowers.push("Lilies")}
            if (this.tulips) { flowers.push("Tulips")}
            console.log(this.shopLocation)
            this.address = this.address.replace(/\s+/g, '+')
            this.city = this.city.replace(/\s+/g, '+')
            this.state = this.state.replace(/\s+/g, '+')
            let location = `${this.address},${this.city},${this.state},${this.zip}`
            console.log(location)
            axios
                .get('https://api.coindesk.com/v1/bpi/currentprice.json')
                .then(response => (console.log(response)))
        }
    }
    
}
</script>