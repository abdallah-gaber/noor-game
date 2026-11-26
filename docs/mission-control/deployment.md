# Mission Control deployment

Open `docs/mission-control/index.html` in a browser for the standalone dashboard. Regenerate with `python3 scripts/generate_dashboard.py`. When the authoring team updates the local canonical packs, run `python3 scripts/content_inventory.py` and review the public-safe inventory diff before regenerating. `python3 scripts/content_inventory.py --check` verifies the exported inventory against the inputs. Draft records and the source planning package stay in the local authoring workspace.

- [Stable dashboard](https://abdallah-gaber.github.io/noor-game/) reads the latest trusted `main` snapshot.
- [Season One review preview](https://abdallah-gaber.github.io/noor-game/previews/season-one/) reads `docs/season-one-mission-control`, including the published 003-01 checkpoint and Season One metadata.

The push workflow rebuilds both available snapshots in one serialized deployment, displays each source branch, full commit SHA and commit timestamp, and checks source tips shortly before deployment. The only deployment sources are `main` and `docs/season-one-mission-control` in the owner repository. The public bundle copies the explicit documentation and anonymized QA allowlist from Git archives. Update the allowlist only after reviewing new assets for publication. The workflow validates local links and uses write permission only in the Pages deploy job.

## Setup or recovery

1. Open repository **Settings → Pages → Build and deployment** and select **GitHub Actions** as the source.
2. Open **Settings → Environments → github-pages → Deployment branches and tags**, choose **Selected branches and tags**, and add exact branch rules for `main` and `docs/season-one-mission-control`.
3. Open **Actions → Mission Control Pages** and run the workflow on the trusted branch containing it, or push reviewed changes to that branch. Check the deployed commit in the dashboard header. Confirm the engineering, curriculum and QA navigation links open.

[GitHub Pages setup](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
