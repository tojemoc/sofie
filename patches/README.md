# Patches

## `sofie-demo-assets-pr1.patch`

Applies PR1 assets work (Caspar deploy layout, Sofie field mapping, SPRÁVY stubs) onto
`tojemoc/sofie-demo-assets` **main**.

```bash
cd /path/to/sofie-demo-assets
git checkout main
git pull origin main
git checkout -b cursor/feat-caspar-deploy-spravy-stubs
git am /path/to/sofie/patches/sofie-demo-assets-pr1.patch
git push -u origin cursor/feat-caspar-deploy-spravy-stubs
```

Open PR: https://github.com/tojemoc/sofie-demo-assets/compare/main...cursor/feat-caspar-deploy-spravy-stubs?expand=1

If `git am` fails, try `git am --3way` or `patch -p1 < sofie-demo-assets-pr1.patch` then commit manually.

Source commit: `26a7de7` on branch `cursor/feat-caspar-deploy-spravy-stubs` (cloud workspace).
