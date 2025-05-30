# Seafile Tailscale Stack

Bring the stack up with:

```
docker compose up -d
```

Follow the initial startup with:

```
docker compose logs -f
```

Once Tailscale prompts for login and suggests a URL, copy it into a browser, authenticate
and click connect as usual. Alternatively, you can run:

```
docker compose exec tailscale tailscale up
```

Once the stack is fully up, run the following:

```
sudo sed -i -e '$a CSRF_TRUSTED_ORIGINS = ["https://files.your-tailnet.ts.net"]' conf/seahub_settings.py
docker compose restart seafile
```
