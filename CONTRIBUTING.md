# Contributing

1. Open an issue describing the user-visible or protocol impact.
2. Use a branch named `feat/...`, `fix/...`, `docs/...`, or `chore/...`.
3. Use Conventional Commits and update `CHANGELOG.md` for notable changes.
4. Run `./tools/check-release-contract.sh` plus the affected SDK/firmware tests.
5. Never commit credentials, transcripts, device serials, customer data, or
   unsanitized physical-test reports.

Protocol and compatibility changes require an explicit versioning review under
[`VERSIONING.md`](VERSIONING.md).

