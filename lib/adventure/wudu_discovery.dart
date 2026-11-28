import '../challenges/arrangement.dart';
import '../content/curriculum.dart';
import '../content/packs/catalog.dart';

enum WuduAction { drop, touch, wipe, closeTap }

enum WuduObject {
  palms('الكفّان'),
  mouth('الفم'),
  nose('الأنف'),
  face('الوجه'),
  rightArm('الذراع اليمنى'),
  leftArm('الذراع اليسرى'),
  head('الرأس'),
  rightFoot('القدم اليمنى'),
  leftFoot('القدم اليسرى'),
  tap('مقبض الصنبور');

  const WuduObject(this.label);
  final String label;
}

typedef WuduStop = ({
  WuduAction action,
  List<WuduObject> objects,
  String hint,
  String feedback,
});

class WuduDiscovery {
  WuduDiscovery._(this.title, Iterable<WuduStop> stops, this.rinseLabels)
    : stops = List.unmodifiable(stops);

  final String title;
  final List<WuduStop> stops;
  final Map<WuduObject, String> rinseLabels;

  static WuduDiscovery? fromApproved(
    IntegratedCatalog catalog,
    LearningLesson lesson,
  ) {
    // These digests bind the illustrated actions to the exact approved text.
    // A revision of their meaning requires checking the scene mapping again.
    const reviewed = {
      'W06.K1':
          'cc46bde9deb7dc12554d809ac5c637e4a81692498b91d526433d6c1a578c73e8',
      'W06.K2':
          '6a24e38cc07253c9f265cd475066fd613c6ede5548756591c75a035285adbcba',
      'W06.K3':
          'd6662a9d82dc382d31ec4aa9d1d45101cf2adc6e722d507c3ff2da74ef1f6c92',
      'W06.E01':
          '27feb1f3af3779cedbbeac8f6f923c2f0b9683e5802fee9089465c824535e57e',
    };
    if (lesson.id != 'W06' ||
        reviewed.entries.any(
          (entry) => catalog.records[entry.key]?.digest != entry.value,
        ) ||
        !lesson.knowledgeLabels.keys.toSet().containsAll(const [
          'W06.K1',
          'W06.K2',
          'W06.K3',
        ])) {
      return null;
    }
    final arrangement = lesson.challenges
        .whereType<Arrangement>()
        .where((variant) => variant.id == 'W06.E01')
        .firstOrNull;
    if (arrangement == null) return null;

    final labels = {for (final item in arrangement.items) item.id: item.label};
    final opening = labels['i1']!.split(' و');
    final water = catalog.records['W06.K3']!.text('text');
    final stops = <String, List<WuduStop>>{
      'i1': [
        (
          action: WuduAction.drop,
          objects: [WuduObject.palms],
          hint: 'اسحب القطرة أو المسها',
          feedback: opening.first,
        ),
        (
          action: WuduAction.touch,
          objects: [WuduObject.mouth, WuduObject.nose],
          hint: 'المس الفم والأنف',
          feedback: opening.skip(1).join(' و'),
        ),
      ],
      'i2': [
        (
          action: WuduAction.touch,
          objects: [WuduObject.face],
          hint: 'المس الوجه',
          feedback: labels['i2']!,
        ),
      ],
      'i3': [
        (
          action: WuduAction.touch,
          objects: [WuduObject.rightArm, WuduObject.leftArm],
          hint: 'المس الذراعين',
          feedback: labels['i3']!,
        ),
      ],
      'i4': [
        (
          action: WuduAction.wipe,
          objects: [WuduObject.head],
          hint: 'مرّر إصبعك أو المس الرأس',
          feedback: labels['i4']!,
        ),
      ],
      'i5': [
        (
          action: WuduAction.touch,
          objects: [WuduObject.rightFoot, WuduObject.leftFoot],
          hint: 'المس القدمين',
          feedback: "${labels['i5']} · ${water.split('،').first}",
        ),
      ],
    };
    return WuduDiscovery._(
      lesson.title,
      [
        for (final id in arrangement.correctOrder) ...stops[id]!,
        (
          action: WuduAction.closeTap,
          objects: [WuduObject.tap],
          hint: 'أغلق الصنبور',
          feedback: water.split('. ').last,
        ),
      ],
      Map.unmodifiable({
        WuduObject.mouth: opening[1],
        WuduObject.nose: opening[2],
      }),
    );
  }
}
