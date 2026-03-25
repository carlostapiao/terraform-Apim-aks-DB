const express = require('express');
const { getProductos } = require('./db');

const app = express();

app.get('/productos', async (req, res) => {

    try {

        const data = await getProductos();

        res.json(data);

    } catch (err) {

        res.status(500).send(err.message);

    }

});

app.listen(80, () => {

    console.log("API running");

});