# vuqv.github.io

Personal academic website built with the [al-folio](https://github.com/alshedivat/al-folio) Jekyll theme.

## First-time setup

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)

### Steps

```bash
git clone https://github.com/vuqv/vuqv.github.io.git
cd vuqv.github.io
docker compose pull
docker compose up
```

Open [http://localhost:8080](http://localhost:8080) in your browser.

## Running after setup

```bash
docker compose up
```

The site will be available at [http://localhost:8080](http://localhost:8080) with live-reload on file changes.

To stop: `Ctrl+C` or `docker compose down`.

## Deploying to GitHub Pages

Deployment is automated via GitHub Actions. On every push to `main`/`master`, the [deploy workflow](.github/workflows/deploy.yml) will:

1. Build the Jekyll site
2. Purge unused CSS
3. Deploy to GitHub Pages

### Configuration

1. **Repository settings:** Go to *Settings → Pages → Source* and select **GitHub Actions**.
2. **Site URL:** Set the `url` field in [`_config.yml`](_config.yml) to your GitHub Pages URL:
   ```yaml
   url: https://vuqv.github.io
   baseurl:  # leave blank for user/org sites, or set to /repo-name for project sites
   ```
3. **Push to main** and the site will be live at your configured URL.

## Key files

| File / Directory | Purpose |
|---|---|
| `_config.yml` | Site-wide configuration |
| `_pages/` | Static pages (about, publications, projects, news, etc.) |
| `_news/` | News/announcement posts |
| `_posts/` | Blog posts |
| `_bibliography/papers.bib` | Publications (BibTeX) |
| `_data/` | CV, repositories, and other structured data |
| `assets/` | Images, CSS, JS, PDFs |

## Upstream

Based on [al-folio](https://github.com/alshedivat/al-folio) — a Jekyll theme for academics. See the upstream repo for full documentation on [customization](https://github.com/alshedivat/al-folio/blob/main/CUSTOMIZE.md) and [features](https://github.com/alshedivat/al-folio#features).

## License

[MIT](LICENSE)
