# Curriculum workflow
1. Draft Arabic fact, explanation, distractors and source locators. 2. Verify source text and authenticity/context; mark differences clearly. 3. Human reviewer checks religious accuracy and child comprehension. 4. Approve specific content hash. 5. Validate and publish only approved items. Do not let an AI agent self-approve.
Suggested source starting points (not verified citations for any lesson): Quran, Sahih al-Bukhari, Sahih Muslim, reliable fiqh and seerah references. Historical claims need appropriate sourcing; disputed dates should not be treated as uniquely correct answers.
Content record fields: id, worldId, lessonId, type, promptAr, explanationAr, options, correctOptionIds, sourceRefs, reviewStatus, approvalHash, reviewer, reviewedAt. Sources: id, title, locator, URL if available, notes. No actual content authored or approved in this bootstrap.

## Season One authoring

Use the [curriculum roadmap](roadmap.md) and [season plan](season-one.json) for scope. The initial 12-lesson outline is provisionally accepted for authoring. Final hash review is per record. Keep draft payloads in the authoring track and export structure-only public inventory for Mission Control.

A knowledge unit holds one teachable idea, child-facing Arabic, verified source locators and optional parent notes. Variants independently reference knowledge units, carry a mechanic and difficulty, and include reviewed answers and explanations. Reordering the same options does not produce another variant. Keep memorization aids and optional knowledge treasures as individually reviewed and rights-cleared records. The authoring track supplies established material, authentic Qur'an and Hadith content, alongside reviewed Arabic narration.

[Offline pack schema and synthetic examples](pack-schema.md) describe versioning, graph validation, trusted record approvals and progress migration.

## Consolidated owner review

Run `python3 scripts/generate_curriculum_review.py` from the checkout with CONTENT-001–007 under the local planning and draft directories. Open `.dart_tool/noor-curriculum-review/index.html`. The command produces the private HTML, the versioned review bundle and the correction queue, then refreshes the public-safe inventory and Mission Control. GitHub Actions uses the checked-in aggregate snapshot.

Start with Prayer readiness and the Correction queue. The dashboard links findings to affected variants and source locators. Use the Record ID field to jump to individual lessons, knowledge units, variants or extras. Carry decisions back to the canonical authoring files. Apply any approved correction to its linked questions and explanations before producing a new review snapshot. A new source edit requires a corresponding CONTENT-007 audit update from the authoring track.

The private review schema preserves the original versioned documents and IDs, adds normalized game definitions and records lesson requirements for cross-lesson variants. Source identifiers stay scoped to their owning pack. It records structural checks separately from human verification, rights and final hash approval. The review bundle has no production channel or approval ledger. Records enter production through the existing [pack contract](pack-schema.md) after the consolidated human review.

### CONTENT-008 corrected draft review

With the local CONTENT-008 package installed, the same generation command verifies the original review-bundle SHA-256, all eight authoring input digests and every guarded before-value. It materializes corrected source files under `.dart_tool/noor-curriculum-review/corrected-drafts/`. The original inputs remain available for replay and audit. The corrected review bundle includes changed-record digests, supplied evidence, open dispositions and the repeated-prompt backlog. Review digests are separate from trusted production approval hashes.

Use the consolidated Correction queue for outstanding scientific, historical edition and reuse-rights work. Entries that carry partial evidence or draft edits remain open where further verification is required. The local source view identifies original locators retained for provenance. See the [corrected-draft QA](../qa/spec-004/004-03-corrected-draft.md).

With CONTENT-009 present, the generator verifies the exact CONTENT-008 bundle, applies the follow-up to private copies and records its dispositions. The prayer-readiness path introduces preparation for prayer. Complete practical instruction remains future content.

### Starter approval candidate

Run `python3 scripts/starter_candidate.py` with CONTENT-010 present. It writes four private v1 draft packs and `approval-request.json` to `.dart_tool/noor-starter-candidate/`. The request includes the exact draft digests and conditional digests for the case where humans verify the same record and only its review status changes. Any change to a locator, authenticity note or other record field requires a new digest and review. The request has no trusted approval entries.

Run `python3 scripts/generate_curriculum_review.py` for the consolidated private view and public aggregate inventory. Only integrated, actually approved catalogs enable the learning tools in production. The remaining lessons and optional extras are still in private authoring.
