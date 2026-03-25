const sql = require('mssql');

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: true
    }
};

async function getProductos() {

    await sql.connect(config);

    const result = await sql.query(
        "SELECT * FROM Productos"
    );

    return result.recordset;
}

module.exports = { getProductos };