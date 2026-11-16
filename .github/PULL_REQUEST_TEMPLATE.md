## Summary

<!-- What changed and why (1–3 bullets). -->

-

## Type of change

- [ ] Feature (`feature/*` → `develop`)
- [ ] Bug fix
- [ ] Hotfix (`hotfix/*` → `main`)
- [ ] Release prep (`release/*`)
- [ ] Documentation only
- [ ] Chore / tooling

## Git Flow checklist

- [ ] Branched from the correct base (`develop` for features, `main` for hotfixes)
- [ ] PR targets the correct branch (`develop` or `main` per flow)
- [ ] CHANGELOG.md updated for user-visible changes (or N/A)

## Test plan

- [ ] PowerShell script parses without errors
- [ ] Bat launcher still elevates / starts the script (if touched)
- [ ] README / docs updated if behavior changed
- [ ] Manual run notes (menu options exercised):

## Risk / safety

- [ ] No forced reboot added
- [ ] Destructive steps still warn the user
- [ ] No secrets or machine-specific paths committed
