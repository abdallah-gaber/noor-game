# Offline curriculum pack contract v1

This contract is implemented by `PackDocument`, `CatalogIngestor` and the signed-bundle loader. The complete [geometry](examples/geometry.pack.json) and [cross-world follow-up](examples/follow-up.pack.json) JSON examples are synthetic and deliberately scoped as fixtures. A [sample empty approval ledger](examples/approvals.example.json) and [local illustration bytes](examples/circle.svg) accompany them.

## Pack and record identities

A pack has integer `schema: 1`, stable `packId`, independent `version` in numeric `major.minor.patch` form, `channel` of `draft`, `fixture`, or `production`, and a nonempty `records` array. Each record has a globally unique `id`, a `kind` and `reviewStatus` of `draft` or `sourceVerified`. IDs use a leading ASCII letter or digit followed by letters, digits, periods, underscores or hyphens. A variant ID remains stable across option orders. Preserve knowledge IDs across copies and pack versions.

| Kind | Required record fields beyond identity and review |
|---|---|
| `source` | `title`, precise `locator`, and `category` of `quran`, `hadith`, `scholarship`, or `other`. Hadith also requires `authenticity`. Optional `url` is HTTPS metadata. |
| `asset` | `path` below `assets/curriculum/media/`, `media` of `illustration` or `narration`, lowercase `sha256` of bytes, and `rights`. |
| `unit` | `title` and `worldId` of `iman`, `ibadah`, `seerah`, or `exemplars`. |
| `knowledge` | `title`, `text`, stable `revision`, and nonempty `sourceRefs`. |
| `variant` | `revision`, `difficulty` of `recognition`, `recall`, or `application`, nonempty `knowledgeIds` and `sourceRefs`, and a mechanic `definition`. |
| `lesson` | `title`, `unitId`, `revision`, `prerequisiteIds`, nonempty ordered `knowledgeIds`, and ordered `variantIds`. Variant knowledge must be taught by the lesson. |
| `memorization` | `title`, `text`, `sourceRefs`, and `rights`. |
| `treasure` | `title`, `text`, `sourceRefs`, and nonempty `knowledgeIds`. |
| `path` | `title`, `priority` of `prayerReadiness` or `standard`, and ordered `lessonIds`. A path includes its prerequisites earlier in that sequence. |
| `release` | `title`, `whatsNew` and UTC `releasedAt`. The record belongs to its pack version. |

A rights object contains `basis` of `publicDomain`, `licensed`, `permission`, or `original`, plus an `evidence` locator. Learning text and variant records may reference a correctly typed local `illustrationRef` or `audioRef`. Narration is reviewed speech and the app remains music-free. Rights locators and source quality are human-reviewed inputs.

A variant's `definition` contains `type` and the fields below. Its identity and knowledge links come from the enclosing record.

| Mechanic | Definition fields |
|---|---|
| `multipleChoice` | `prompt`, `explanation`, 2–4 `options`, and `correctOptionId` |
| `trueFalse` | `prompt`, `explanation` and `correctOptionId` of `true` or `false` |
| `flashcard` | `prompt` and `answer` |
| `matching` | `prompt`, `explanation`, and 2–4 `pairs` of `left` and `right` options |
| `ordering` | `prompt`, `explanation`, 2–5 `items`, and a `correctOrder` containing each item ID once |

An option has `id`, `label` and optional `illustration` pointing to an illustration asset record. Validation rejects duplicate ID or normalized visible labels in an answer group, unresolved or wrong-type references, cyclic lesson dependencies, and ambiguous answers. Cross-world prerequisites apply to both visible path states and direct lesson routing. Prayer-readiness paths sort first. Their reviewed lesson and source content belongs to the authoring track.

## Approval and activation

Draft and source-verified states describe the authoring record. Structural validation, final human approval and integration are separate results. Validation alone makes a pack inspectable by tooling. Child mode receives only a fully integrated catalog.

The platform trust boundary is the signed app bundle. When a future approved release registers `assets/curriculum/index.json`, it contains `{"schema":1,"packIds":[...]}`. The loader reads the fixed `assets/curriculum/packs/<packId>.json` paths and the separate trusted `assets/curriculum/approvals.json`. The ledger uses schema 1 and an `approvals` array. Each approval records `packId`, `recordId`, `digest`, `reviewer`, and UTC `reviewedAt`. The human-reviewed release supplies this ledger through its trusted build process. Importing a record cannot create its own trusted approval.

A record digest is SHA-256 of UTF-8 compact JSON for `{"packId": <pack ID>, "record": <full record object>}`. Object keys are recursively sorted. Arrays retain their given order. The loader checks exact per-record approvals, source-verified review status, production channel and the SHA-256 of each referenced local asset. A missing or invalid bundle leaves child mode on the public world shells. This task registers zero production assets. The developer fixtures remain separate.

## Migration and compatibility

- Keep SQLite schema 4 unchanged. Existing approved and preview rows stay in their respective scopes. Catalog installation performs no progress or attempt writes. A failed candidate leaves the previously integrated snapshot usable.
- A pack update may replace one pack while keeping the other installed versions. Compare numeric versions and reject downgrades or differing content at the same version. Validate the complete resulting graph and approvals before returning an active snapshot. Retired record IDs must never be reused.
- Preserve lesson and knowledge IDs for editorial edits. Keep their revisions when their objectives, order and answer semantics are compatible. Reading resumes by stable lesson ID and effective revision. In-flight challenges also retain saved option order and feedback across compatible edits. Changed grading with an unchanged variant revision is rejected during a known-catalog update. A new effective revision starts a new resumable round and retains historical attempts and earned completion. Use a new lesson ID when an incompatible replacement requires a distinct completion gate.
- Bring the four authoring drafts forward through a reviewed adapter. Carry forward lesson, knowledge and variant IDs. Map legacy world, source, difficulty and mechanic fields explicitly and document any source ID aliases. Enrich prerequisites, rights and media only from authoritative authoring inputs. Source-verify and obtain exact record approvals before constructing a production bundle. The provisional acceptance and the separate CONTENT-006 and CONTENT-007 work do not confer final approvals.
