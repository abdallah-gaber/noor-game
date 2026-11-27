#!/usr/bin/env python3
"""Project a small local authoring sample into an Android debug build define."""

import json
from pathlib import Path

from curriculum_handoff import ENHANCEMENT, challenge, read_json, verify_inputs

ROOT = Path(__file__).resolve().parents[1]
DRAFTS = ROOT / 'docs/curriculum/drafts'
OUTPUT = ROOT / '.dart_tool/noor-pilot/defines.json'
SELECTION = (
    ('noor-content-003/ibadah.json', 'W06'),
    ('noor-content-002/iman.json', 'I03'),
    ('noor-content-004/seerah.json', 'S11'),
    ('noor-content-005/exemplars.json', 'P01'),
)


def project_lesson(pack, lesson_id, additions):
    lesson, = (item for item in pack['lessons'] if item['id'] == lesson_id)
    knowledge = lesson['knowledgeUnits']
    knowledge_ids = {item['id'] for item in knowledge}
    if len(knowledge_ids) != len(knowledge):
        raise ValueError(f'Duplicate knowledge ID in {lesson_id}')
    sources = {source['id']: source for source in pack['sources']}
    base = {}
    for record in lesson['challenges']:
        base.setdefault(record['type'], record)
    # Use one core variant per mechanic and local CONTENT-007 additions. Cross-lesson
    # review activities require a broader knowledge selection and are left out.
    variants = [
        *base.values(),
        *(item for item in additions if item['lessonId'] == lesson_id
          and set(item['knowledgeIds']) <= knowledge_ids),
    ]
    if len({item['id'] for item in variants}) != len(variants):
        raise ValueError(f'Duplicate variant ID in {lesson_id}')
    if any(item['lessonId'] != lesson_id or item['worldId'] != pack['worldId']
           or not set(item['knowledgeIds']) <= knowledge_ids for item in variants):
        raise ValueError(f'Unresolved variant in {lesson_id}')
    refs = {ref for item in (*knowledge, *variants) for ref in item['sourceRefs']}
    return {
        'id': lesson_id, 'unitId': lesson['unitId'], 'worldId': pack['worldId'],
        'title': lesson['titleAr'],
        'knowledge': [{field: item[field] for field in ('id', 'textAr', 'sourceRefs')}
                      for item in knowledge],
        'variants': list(map(challenge, variants)),
        'sources': [sources[ref] for ref in sorted(refs)],
        **({'activity': lesson['parentActivityAr']} if 'parentActivityAr' in lesson else {}),
    }


def main():
    OUTPUT.unlink(missing_ok=True)
    verify_inputs(DRAFTS)
    enhancement = read_json(DRAFTS / ENHANCEMENT)
    lessons = [
        project_lesson(read_json(DRAFTS / path), lesson_id, enhancement['additions'])
        for path, lesson_id in SELECTION
    ]
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps({'NOOR_DRAFT_PILOT': json.dumps(
        {'schema': 1, 'lessons': lessons}, ensure_ascii=False, separators=(',', ':'),
    )}, ensure_ascii=False), encoding='utf-8')
    print('Prepared local debug payload:', OUTPUT.relative_to(ROOT))
    print('Selected:', ', '.join(f"{row['id']} ({len(row['variants'])})" for row in lessons))


if __name__ == '__main__':
    main()
