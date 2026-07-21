// Fake Palworld REST API for local development: npm run mock
// Serves /v1/api/* on port 8212 with canned data and simulated player churn.
import { createServer } from "node:http";

const startedAt = Date.now();

const pool = [
  { name: "GlitchApotamus", accountName: "glitch", level: 57 },
  { name: "swanky", accountName: "swanky", level: 9 },
  { name: "TrustfullAlarm", accountName: "trust", level: 13 },
  { name: "FuackKingThicc", accountName: "fuack", level: 57 },
  { name: "小龙猫", accountName: "xiaolong", level: 42 },
];

function currentPlayers() {
  // Deterministic churn: the set of online players changes every ~2 minutes
  const online = pool.filter((_, i) => Math.floor(Date.now() / 120_000 + i) % 3 !== 0);
  return online.map((p, i) => ({
    name: p.name,
    accountName: p.accountName,
    playerId: `pid_${p.accountName}`,
    userId: `steam_7656119${i}`,
    ip: "127.0.0.1",
    ping: 20 + Math.round(Math.random() * 80),
    location_x: 0,
    location_y: 0,
    level: p.level,
    building_count: 12 * (i + 1),
  }));
}

const server = createServer((req, res) => {
  const url = req.url ?? "";
  const respond = (body: unknown) => {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(body));
  };

  if (url.endsWith("/info")) {
    respond({ version: "v0.6.4", servername: "GlitchHaven Command Center", description: "Mock server" });
  } else if (url.endsWith("/metrics")) {
    const players = currentPlayers();
    respond({
      serverfps: 120 + Math.round(Math.random() * 19),
      currentplayernum: players.length,
      serverframetime: 8.3,
      maxplayernum: 128,
      uptime: Math.floor((Date.now() - startedAt) / 1000) + 3600 * 37,
      basecampnum: 23,
      days: 87,
    });
  } else if (url.endsWith("/players")) {
    respond({ players: currentPlayers() });
  } else if (req.method === "POST") {
    console.log(`mock: POST ${url}`);
    respond({});
  } else {
    respond({});
  }
});

server.listen(8212, "127.0.0.1", () => console.log("mock palworld REST API listening on http://127.0.0.1:8212"));
