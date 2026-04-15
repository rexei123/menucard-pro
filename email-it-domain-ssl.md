# E-Mail an externe IT – Domain & SSL für MenuCard Pro

**Betreff:** Subdomain menu.hotel-sonnblick.at – DNS-Eintrag + SSL-Zertifikat einrichten

---

Guten Tag,

wir haben eine neue digitale Menükarten-Plattform (MenuCard Pro) für unser Hotel entwickelt, die bereits auf unserem Server läuft. Damit unsere Gäste die Karten über eine saubere URL aufrufen können, benötigen wir folgende Einrichtung:

## 1. Aufgabe: DNS-Eintrag

Bitte erstellen Sie folgenden DNS-Eintrag für die Domain hotel-sonnblick.at:

- **Typ:** A-Record
- **Name / Subdomain:** menu
- **Ziel / IP-Adresse:** 178.104.138.177
- **TTL:** 300 (oder Standard)

Ergebnis: menu.hotel-sonnblick.at → 178.104.138.177

## 2. Aufgabe: SSL-Zertifikat (Let's Encrypt)

Sobald der DNS-Eintrag aktiv ist, wird das SSL-Zertifikat serverseitig von uns eingerichtet (per Certbot/Nginx auf unserem Server). Wir benötigen dafür nur den aktiven DNS-Eintrag.

Falls Sie das SSL-Zertifikat ebenfalls einrichten möchten, hier die Details:
- **Server:** Ubuntu 24.04, Nginx als Reverse Proxy
- **Certbot-Befehl:** `certbot --nginx -d menu.hotel-sonnblick.at`
- **App läuft auf:** localhost:3000 (wird von Nginx weitergeleitet)

## 3. Nginx-Konfiguration (zur Information)

Die Nginx-Konfiguration auf dem Server wird nach SSL-Einrichtung so aussehen:

```
server {
    listen 443 ssl;
    server_name menu.hotel-sonnblick.at;

    ssl_certificate /etc/letsencrypt/live/menu.hotel-sonnblick.at/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/menu.hotel-sonnblick.at/privkey.pem;

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

server {
    listen 80;
    server_name menu.hotel-sonnblick.at;
    return 301 https://$host$request_uri;
}
```

## 4. Prüfschritte nach Einrichtung

Nach der DNS-Einrichtung bitte kurz prüfen:
- `nslookup menu.hotel-sonnblick.at` → sollte 178.104.138.177 zurückgeben
- `ping menu.hotel-sonnblick.at` → sollte antworten

Die SSL-Einrichtung und den Funktionstest der Webseite übernehmen wir dann selbst.

## 5. Zeitrahmen

Wir würden die Domain gerne so bald wie möglich aktiv haben. Könnten Sie uns bitte eine Rückmeldung geben, bis wann der DNS-Eintrag eingerichtet werden kann?

Falls es Fragen gibt oder etwas unklar ist, stehe ich gerne zur Verfügung.

Mit freundlichen Grüßen
Hotel Sonnblick
