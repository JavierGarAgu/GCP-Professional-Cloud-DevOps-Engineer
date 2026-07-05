#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y curl ca-certificates

# Instalar Node.js 20 (incluye npm)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

mkdir -p /opt/app

cat >/opt/app/package.json <<'EOF'
{
  "name": "sre-lab",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

cat >/opt/app/index.js <<'EOF'
const express = require("express");

const app = express();

let incident = false;

app.get("/", (req, res) => {

    console.log(new Date().toISOString(), "GET /");

    if (incident) {
        console.log("Returning 500");
        return res.status(500).send("Internal Server Error");
    }

    res.send("Application healthy");

});

app.get("/start-incident", (req, res) => {

    incident = true;

    console.log("INCIDENT STARTED");

    res.send("Incident started");

});

app.get("/end-incident", (req, res) => {

    incident = false;

    console.log("INCIDENT RESOLVED");

    res.send("Incident resolved");

});

app.listen(80, "0.0.0.0", () => {

    console.log("Application listening on port 80");

});
EOF

cd /opt/app

npm install

cat >/etc/systemd/system/sre-app.service <<'EOF'
[Unit]
Description=SRE Lab Node Application
After=network.target

[Service]
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node /opt/app/index.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sre-app
systemctl start sre-app