const express = require("express");

const app = express();

app.use(express.json());

app.get("/", (req, res) => {
    res.send("Webhook receiver is running.");
});

app.post("/", (req, res) => {

    console.log("========================================");
    console.log("Cloud Build notification received");
    console.log("========================================");

    console.log(JSON.stringify(req.body, null, 2));

    res.status(200).send("OK");
});

const port = process.env.PORT || 8080;

app.listen(port, () => {
    console.log(`Webhook listening on port ${port}`);
});