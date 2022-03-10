const fs = require('fs');

const { Pool } = require('pg');
const pool = new Pool(
    {
        ssl: {
            rejectUnauthorized : false,
            ca   : fs.readFileSync("./ca/dbaas.ca").toString()
        }
    }
);

// Try connecting
pool
  .query('SELECT NOW()')
  .then(res => console.log('DB Connection works'))
  .catch(err =>
    setImmediate(() => {
        console.log('Error while connecting to DB.');
        throw err
    })
  );

module.exports = {
    orderDrink,
    getOrders
};

const now = new Date();

async function orderDrink(drinkid, userid, username) {
    const result = await pool.query(`INSERT INTO public."order"(
        userid, drinkid, nickname, time)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (userid) DO UPDATE SET drinkid = $2, nickname = $3, time = $4`, [userid, drinkid, username, now]);
    
    return result;
}

async function getOrders() {
    const result = await pool.query(`SELECT userid, nickname, drinkid, time FROM public."order"`);
    
    return result.rows;
}

pool.on('error', (err, client) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
  })