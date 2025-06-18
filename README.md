# Seafile with Tailscale

Copy the `.env.sample` file to `.env` and change the values to suit.

Start the containers by running:

```
docker compose up -d
```

Follow the initial startup process by running:

```
docker compose logs -f
```

Once Tailscale prompts for a login and displays a URL, copy it into a browser,
authenticate and click connect. Alternatively, you can run the following in
another terminal:

```
docker compose exec tailscale tailscale up
```

Once Tailscale is connected, the other containers will start up. Once the stack
is fully up, run the following to complete the install:

```
docker compose exec seafile conf/post-install.sh
```
