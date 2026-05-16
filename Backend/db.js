const sql = require('mssql');
require('dotenv').config();

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

const poolPromise = new sql.ConnectionPool(config)
    .connect()
    .then(pool => {
        console.log('SQL Server Bağlantısı Başarılı!');
        return pool;
    })
    .catch(err => console.log('Veritabanı Bağlantı Hatası: ', err));

module.exports = { sql, poolPromise };