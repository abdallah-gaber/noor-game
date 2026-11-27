# Curriculum workflow
1. Draft Arabic fact, explanation, distractors and source locators. 2. Verify source text and authenticity/context; mark differences clearly. 3. Human reviewer checks religious accuracy and child comprehension. 4. Approve specific content hash. 5. Validate and publish only approved items. Do not let an AI agent self-approve.
Suggested source starting points (not verified citations for any lesson): Quran, Sahih al-Bukhari, Sahih Muslim, reliable fiqh and seerah references. Historical claims need appropriate sourcing; disputed dates should not be treated as uniquely correct answers.
Content record fields: id, worldId, lessonId, type, promptAr, explanationAr, options, correctOptionIds, sourceRefs, reviewStatus, approvalHash, reviewer, reviewedAt. Sources: id, title, locator, URL if available, notes. No actual content authored or approved in this bootstrap.

## Season One authoring

Use the [curriculum roadmap](roadmap.md) and [season plan](season-one.json) for scope. The initial 12-lesson outline is provisionally accepted for authoring. Final hash review is per record. Keep draft payloads in the authoring track and export structure-only public inventory for Mission Control.

A knowledge unit holds one teachable idea, child-facing Arabic, verified source locators and optional parent notes. Variants independently reference knowledge units, carry a mechanic and difficulty, and include reviewed answers and explanations. Reordering the same options does not produce another variant. Keep memorization aids and optional knowledge treasures as individually reviewed and rights-cleared records. The authoring track supplies established material, authentic Qur'an and Hadith content, alongside reviewed Arabic narration.

[Offline pack schema and synthetic examples](pack-schema.md) describe versioning, graph validation, trusted record approvals and progress migration.
