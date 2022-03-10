const express = require("express");
const app = express();
const cors = require('cors');
const http = require('http');
const server = http.createServer(app);
const { Server } = require("socket.io");
const validator = require("validator");

const orderservice = require('./order.js');

// Socket IO server
const io = new Server(server, { cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }});

io.on('connection', (socket) => {
    console.log('Socket user connected');
  });

var corsOptions = {
    origin: '*',
    optionsSuccessStatus: 200
  }

app.use(cors(corsOptions));

// parse requests of content-type - application/json
//app.use(express.json());
// parse requests of content-type - application/x-www-form-urlencoded
//app.use(express.urlencoded({ extended: true }));

// simple route
app.get("/", (req, res) => {
  res.json({ message: "Welcome" });
});

app.get('/drink/:drinkid', async (req, res) => {
    try {
        var drinkid = req.params.drinkid;

        var userid = req.query.userid;
        var nickname = req.query.nickname;

        if (!validator.isUUID(userid)) {
            res.sendStatus(400);
            return;
        }

        if (!validator.isNumeric(drinkid, { min: 0, max: 50 })) {
            res.sendStatus(400);
            return;
        }

        if (nickname.length > 32) {
            res.sendStatus(400);
            return;
        }

        console.log('Drink:' + req.params.drinkid);

        console.log('Userid: ' + req.query.userid);

        orderservice.orderDrink(drinkid, userid, nickname).then(function() {
            res.sendStatus(200);
            io.emit("ordernotification", {drinkid: drinkid, nickname: nickname});
        });


    } catch (error) {
        console.log(error);
        res.sendStatus(500);
    }
});

app.get('/orders', async (req, res) => {
    try {
        orderservice.getOrders().then(function(rows) {
            res.send(rows)
        });


    } catch (error) {
        console.log(error);
        res.sendStatus(500);
    }
});

// set port, listen for requests
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}.`);
});
