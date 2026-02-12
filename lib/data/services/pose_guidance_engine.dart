import '../models/pose_guidance.dart';
import '../models/pose_tag.dart';

class PoseGuidanceEngine {
  static final PoseGuidanceEngine _instance =
      PoseGuidanceEngine._internal();
  factory PoseGuidanceEngine() => _instance;
  PoseGuidanceEngine._internal();

  final Map<String, PoseGuidance> _guidanceCache = {};

  PoseGuidance generateGuidance(PoseTag tags) {
    final cacheKey =
        '${tags.poseType}_${tags.angle}_${tags.expression}';
    if (_guidanceCache.containsKey(cacheKey)) {
      return _guidanceCache[cacheKey]!;
    }

    final guidance = _buildGuidance(tags.poseType, tags.angle,
        tags.expression, tags.shotSize, tags.difficulty);
    _guidanceCache[cacheKey] = guidance;
    return guidance;
  }

  PoseGuidance _buildGuidance(
    String poseType,
    String angle,
    String expression,
    String shotSize,
    String difficulty,
  ) {
    final poseCategory = _extractPoseCategory(poseType);
    final poseSubtype = _extractPoseSubtype(poseType);

    final title = _generateTitle(poseCategory, poseSubtype, expression);
    final sections = <GuidanceSection>[];
    final keywords = <String>[];

    sections.add(_buildFootLegSection(poseCategory, poseSubtype));
    sections.add(_buildWaistBodySection(poseCategory, poseSubtype));
    sections.add(_buildArmHandSection(poseCategory, poseSubtype, poseType));
    sections.add(_buildHeadDirectionSection(poseSubtype, angle));
    sections.add(_buildExpressionSection(expression));

    keywords.addAll(_extractKeywords(poseCategory, poseSubtype, expression));

    final cameraTip = _generateCameraTip(shotSize, angle);

    return PoseGuidance(
      title: title,
      sections: sections,
      cameraTip: cameraTip,
      keywords: keywords,
    );
  }

  String _extractPoseCategory(String poseType) {
    if (poseType.contains('站姿')) return 'standing';
    if (poseType.contains('坐姿')) return 'sitting';
    if (poseType.contains('蹲姿')) return 'squatting';
    if (poseType.contains('卧姿')) return 'lying';
    if (poseType.contains('动态')) return 'dynamic';
    if (poseType.contains('互动')) return 'interaction';
    return 'standing';
  }

  String _extractPoseSubtype(String poseType) {
    final parts = poseType.split('_');
    return parts.length > 1 ? parts[1] : '';
  }

  String _generateTitle(String category, String subtype, String expression) {
    final categoryNames = {
      'standing': '站姿',
      'sitting': '坐姿',
      'squatting': '蹲姿',
      'lying': '卧姿',
      'dynamic': '动态',
      'interaction': '互动',
    };

    final subtypeNames = {
      '正面站': '正面站姿',
      '侧面站': '侧面站姿',
      '背面站': '背面站姿',
      '倚靠站': '倚靠站姿',
      '单腿站': '单腿站立',
      '交叉站': '交叉站姿',
      'S型站': 'S型曲线站姿',
      '正坐': '端正坐姿',
      '侧坐': '侧面坐姿',
      '盘腿坐': '盘腿坐姿',
      '跪坐': '跪坐',
      '倚坐': '倚靠坐姿',
      '抱膝坐': '抱膝坐姿',
      '跷腿坐': '跷腿坐姿',
      '正蹲': '正面蹲姿',
      '侧蹲': '侧面蹲姿',
      '单膝跪': '单膝跪姿',
      '双膝跪': '双膝跪姿',
      '半蹲': '半蹲姿势',
      '仰卧': '仰卧姿势',
      '侧卧': '侧卧姿势',
      '俯卧': '俯卧姿势',
      '半躺': '半躺姿势',
      '倚躺': '倚靠躺姿',
      '行走': '行走姿态',
      '旋转': '旋转动态',
      '跳跃': '跳跃瞬间',
      '回眸': '回眸动作',
      '甩发': '甩发动态',
      '撩发': '撩发动作',
      '与道具互动': '道具互动',
      '与环境互动': '环境互动',
      '手部动作': '手部动作',
      '抚脸': '抚脸动作',
      '托腮': '托腮动作',
    };

    final title =
        subtypeNames[subtype] ?? '${categoryNames[category] ?? "姿势"}';
    final expressionPrefix = _getExpressionPrefix(expression);

    return '$title - $expression';
  }

  GuidanceSection _buildFootLegSection(String category, String subtype) {
    final footLegGuides = {
      'standing': {
        '正面站': '双脚分开与肩同宽，重心均匀分布在双脚上。膝盖微屈，不要僵硬。收腹挺胸，臀部微微收紧。双脚可平行或呈45度角站立。',
        '侧面站': '身体侧向（约45-90度角），重心放在后腿。前腿膝盖微曲，脚尖指向斜前方约45度。臀部微微翘起，形成自然曲线。',
        '背面站': '双脚交叉站立（约10点和2点方向），重心均匀分布。膝盖并拢或略微分开。臀部收紧，背部挺直。',
        '倚靠站': '身体侧向支撑物，一侧臀部轻靠。靠近支撑物的腿微屈，另一条腿向前方伸出。重心放在直立的腿上。',
        '单腿站': '一条腿直立站稳作为支撑腿，另一条腿向后抬起（或向侧方抬起）。直立腿膝盖微屈，臀部翘起。',
        '交叉站': '双脚一前一后交叉站立，重心放在后腿。前腿脚尖着地，后腿完全着地。膝盖微屈，臀部收紧。',
        'S型站': '重心放在后腿，前腿向前方伸出。身体形成C型或S型曲线。臀部翘起，腰部微微前挺。一只手可叉腰增加曲线。',
      },
      'sitting': {
        '正坐': '端正坐在凳子/台阶边缘，双腿并拢或一前一后。膝盖与脚尖方向一致。收腹挺胸，背部挺直但不僵硬。',
        '侧坐': '侧身坐在支撑物上，一条腿自然弯曲，另一条腿向侧面伸展。靠近镜头的腿可微曲或轻垂。膝盖方向与身体一致。',
        '盘腿坐': '盘腿坐在地面/垫子上，双腿交叉。双脚位于另一条腿下方。膝盖尽量下压靠近地面。收腹挺胸。',
        '跪坐': '双膝跪地，臀部坐在脚跟上。双脚脚趾着地，膝盖并拢或略微分开。背部挺直，肩膀打开。',
        '倚坐': '身体侧向支撑物，一只手肘撑住。双腿自然弯曲，一条腿向前方伸展。另一只手可托腮或放在膝盖上。',
        '抱膝坐': '双腿弯曲，双手环抱膝盖。双脚脚掌着地。头部可侧靠在膝盖上。整体呈现蜷缩姿态。',
        '跷腿坐': '一条腿跷起放在另一条腿膝盖上（4字形）。下方腿的膝盖方向与身体一致。收腹挺胸。',
      },
      'squatting': {
        '正蹲': '双脚分开与肩同宽，缓慢下蹲至大腿与地面平行或略高于地面。膝盖方向与脚尖一致。重心均匀分布。',
        '侧蹲': '身体侧向一侧下蹲。完全蹲下的腿膝盖靠近地面，另一条腿向侧方伸出。膝盖方向与身体一致。',
        '单膝跪': '一条腿完全跪地（膝盖着地），另一条腿向前方弯曲站立。跪地的腿膝盖方向与身体一致。',
        '双膝跪': '双膝跪地，臀部坐在脚跟上。双脚脚趾着地。膝盖并拢，间距与髋部同宽。',
        '半蹲': '双脚分开与肩同宽，膝盖微曲（下蹲约30-50%）。重心均匀分布在双脚上，不要过度前倾或后仰。',
      },
      'lying': {
        '仰卧': '平躺在地面上，双腿伸直或略微分开。双臂自然放在身体两侧或放在腹部。一侧膝盖微微抬起可增加变化。',
        '侧卧': '身体侧躺在地面上，下方的腿伸直或微屈。上方的腿可向前弯曲放在地面上。头部枕在手臂上。',
        '俯卧': '趴在地面上，双腿伸直或一前一后。双臂可支撑头部或放在身体两侧。脚尖着地，膝盖微屈。',
        '半躺': '上半身躺在支撑物上，双腿伸直或一前一后。一只手可支撑头部，另一只手放在身体一侧。',
        '倚躺': '身体侧躺在一侧，一只手支撑头部。双腿可伸直或弯曲。整体呈现慵懒随意的姿态。',
      },
      'dynamic': {
        '行走': '自然向前行走，步伐不要太大太快。一只脚着地时，另一只脚抬起。手臂自然摆动（与对侧腿同步）。',
        '旋转': '以一只脚为轴心，身体向内旋转。双臂自然张开保持平衡或举起。旋转时头部微微后仰，目光看向旋转方向。',
        '跳跃': '双脚轻轻跳起，膝盖微屈。双臂向上举起或自然张开。跳跃高度适中（约10-20cm）。核心收紧。',
        '回眸': '身体背向镜头站立，重心均匀分布。然后缓慢转头回望。在回眸瞬间抓拍，捕捉自然表情。',
        '甩发': '站立或走动中，头部快速向一侧甩动。双臂可轻轻拨动头发增加动感。发丝飘动时抓拍。',
        '撩发': '一只手轻轻将头发撩到耳后或抚过脸颊。头部微微歪向触碰的手一侧。目光可看镜头或看向别处。',
      },
      'interaction': {
        '与道具互动': '双手自然握住道具（扇子/花束等）。目光可看向道具或镜头。身体微微侧向道具方向。',
        '与环境互动': '身体自然靠近环境元素（栏杆/墙壁等）。手可搭在环境元素上。目光可看向环境或镜头。',
        '手部动作': '双手自然摆放，位置要有层次感。避免双手对称放置。一只手可触碰脸部、头发或身体其他部位。',
        '抚脸': '一只手轻轻抚摸脸颊或下巴，指尖朝上或朝外。头部微微歪向触碰的手一侧。目光平视或微微向上。',
        '托腮': '一只手肘支撑在支撑物上，另一只手轻轻托住下巴。头部微微倾斜。目光可看镜头或看向别处。',
      },
    };

    final guide = footLegGuides[category]?[subtype] ??
        '调整身体重心，双脚/双腿自然摆放。保持放松但有姿态感。';

    return GuidanceSection(
      icon: '🦵',
      title: '下半身',
      content: guide,
    );
  }

  GuidanceSection _buildWaistBodySection(String category, String subtype) {
    String guide;

    if (category == 'standing') {
      guide = '收腹挺胸，肩膀打开向后向下沉。腰部微微前挺，臀部轻轻收紧。身体形成自然S型或C型曲线。避免僵硬直立。';
    } else if (category == 'sitting') {
      guide = '背部挺直但不僵硬，像有一根线从头顶向上拉。肩膀打开向后向下沉。收腹，核心微微收紧。';
    } else if (category == 'squatting') {
      guide = '下蹲时背部保持挺直，核心收紧。肩膀打开，不要前倾。腰部保持自然曲度，不要过度前弯。';
    } else if (category == 'lying') {
      guide = '身体舒展不要蜷缩。肩膀打开下沉，腰部贴合地面或支撑物。核心放松但保持身体线条。';
    } else if (category == 'dynamic') {
      guide = '身体保持轻盈感，不要僵硬。动态姿势中保持核心稳定。肩膀打开，姿态舒展。';
    } else {
      guide = '身体自然舒展，不要僵硬。肩膀打开下沉，收腹。根据道具或环境调整身体方向。';
    }

    return GuidanceSection(
      icon: '💪',
      title: '上半身',
      content: guide,
    );
  }

  GuidanceSection _buildArmHandSection(
      String category, String subtype, String poseType) {
    String guide;

    if (poseType.contains('叉腰')) {
      guide = '双手轻轻叉腰，一只手在上、一只手在下放置。肘部微微向前，不要夹紧腋下。手指自然弯曲，不要僵硬。';
    } else if (poseType.contains('举起') || poseType.contains('上举')) {
      guide = '双臂向上举起超过头顶，手肘微屈不要完全伸直。手指自然分开或轻轻握拳。腋下打开，不要夹紧。';
    } else if (poseType.contains('托腮')) {
      guide = '一只手轻轻托住下巴，手腕放松。另一只手可放在膝盖上或身体一侧。手指自然弯曲，不要用力。';
    } else if (poseType.contains('抚脸')) {
      guide = '一只手轻轻抚摸脸颊，指尖朝上或朝外。另一只手可叉腰或自然摆放。手腕放松，动作轻柔。';
    } else if (poseType.contains('撑') || poseType.contains('支撑')) {
      guide = '手肘稳稳支撑在支撑物上，手掌朝下或朝内。肩膀打开，不要耸肩。手臂力量均匀分布。';
    } else if (category == 'sitting') {
      guide = '双臂自然摆放，可一手放在膝盖上，另一只手放在身体一侧或托腮。避免双臂僵硬下垂或交叉抱胸。';
    } else if (category == 'standing') {
      guide = '双臂自然垂放于身体两侧，肘部微屈。双手可插兜（露出手指）、拿道具或轻轻叉腰。避免双臂紧贴身体。';
    } else if (category == 'dynamic') {
      guide = '双臂随动作自然摆动，不要僵硬。行走时手臂与对侧腿同步摆动。跳跃或旋转时双臂可张开保持平衡。';
    } else {
      guide = '双臂自然摆放，位置要有层次感。避免双手对称放置。可根据姿势需要放在身体不同位置。';
    }

    return GuidanceSection(
      icon: '💆',
      title: '双臂与手部',
      content: guide,
    );
  }

  GuidanceSection _buildHeadDirectionSection(String subtype, String angle) {
    String headGuide;
    String eyeGuide;

    if (angle == '平视') {
      headGuide = '头部端正，下巴微微回收。耳朵与肩膀保持一定距离（不要夹紧）。后脑勺与背部形成一条线。';
      eyeGuide = '目光与镜头平齐，平视前方。眼神自然放松，不要瞪眼或咪眼。瞳孔大小自然。';
    } else if (angle == '俯拍') {
      headGuide = '头部微微低下，下巴朝向胸部方向。后颈部微微收紧，脸部朝向镜头方向。避免双下巴。';
      eyeGuide = '目光可微微向下看或平视镜头。眼神柔和，不要向下看太多导致眼白过多。';
    } else if (angle == '仰拍') {
      headGuide = '头部微微抬起，下巴线条露出。后颈部拉伸，脸部朝向镜头。下巴尖朝向镜头方向。';
      eyeGuide = '目光微微向上看或平视。眼神要有神韵，避免瞳孔上翻。头部后仰时注意颈部线条。';
    } else if (angle == '侧拍' || angle == '侧脸') {
      headGuide = '身体和头部同时侧向镜头方向（约45-90度）。下颚线清晰可见，颈部线条修长。耳朵不要被头发完全遮挡。';
      eyeGuide = '目光平视前方或微微看向侧面。可回眸看镜头或看向远方。眼神要有故事感。';
    } else if (angle == '45度角') {
      headGuide = '身体微微侧转（约45度），头部可保持正面或也侧向45度。下巴微微收窄，脸部呈立体感。';
      eyeGuide = '目光可看向侧面或微微回望镜头。眼神柔和自然。';
    } else if (angle == '背影') {
      headGuide = '背部挺直，肩膀打开。头部可微微歪向一侧。整体姿态舒展，不要驼背。';
      eyeGuide = '目光看向远方或侧方，不要看镜头。营造若有所思或享受当下的氛围。';
    } else {
      headGuide = '头部端正，耳朵与肩膀保持距离。下巴微微回收，后脑勺与背部形成直线。';
      eyeGuide = '目光自然放松，平视前方。眼神柔和有神。';
    }

    return GuidanceSection(
      icon: '💆',
      title: '头部与目光',
      content: '$headGuide\n\n$eyeGuide',
    );
  }

  GuidanceSection _buildExpressionSection(String expression) {
    final expressionGuides = {
      '微笑': {
        'guide': '自然放松，露出淡淡的微笑。嘴角上扬约15-30度，露出6-8颗牙齿也可以。自然张开嘴笑，不要勉强。',
        'tips': '想象看到喜欢的人或事物时的开心感受',
      },
      '大笑': {
        'guide': '开心大笑，露出大部分牙齿。苹果肌上扬，眼睛微眯。表情夸张但真诚。声音不需要发出来，但表情要做到位。',
        'tips': '想到最开心的事情，比如收到礼物、中大奖',
      },
      '冷艳': {
        'guide': '表情冷淡，眼神犀利或慵懒。嘴角平直或微微下撇。眉毛可微微皱起或保持平直。整体酷酷的感觉。',
        'tips': '想象自己是国际超模，气场全开',
      },
      '甜美': {
        'guide': '温柔微笑，表情柔和温暖。眼睛要有光，苹果肌上扬。给人亲切可爱的感觉。',
        'tips': '想到可爱的小动物或美好的回忆',
      },
      '自然': {
        'guide': '放松表情，像平时一样。嘴角微微上扬，不要刻意。不要皱眉或紧绷面部肌肉。',
        'tips': '深呼吸，放空大脑，进入发呆状态',
      },
      '忧郁': {
        'guide': '表情沉思或轻微哀伤。嘴角微微下撇，眼神看向远方或微微向下。眉毛可微微皱起呈八字形。',
        'tips': '听一首抒情歌，感受歌词中的情绪',
      },
      '俏皮': {
        'guide': '调皮的表情，可吐舌、做wink或歪嘴笑。眼神要有灵动感。整体活泼可爱。',
        'tips': '想到恶作剧成功的得意感',
      },
      '妩媚': {
        'guide': '性感迷人的表情，眼神微微放电。嘴角微微上扬，露出自信的笑容。眼神要有勾魂的感觉。',
        'tips': '想象自己是最有魅力的人',
      },
      '清纯': {
        'guide': '干净清爽的表情，眼神清澈。嘴角淡淡微笑，不要夸张。给人清新脱俗的感觉。',
        'tips': '想象自己是最美好的18岁',
      },
      '酷飒': {
        'guide': '帅气冷酷的表情，眼神坚定锐利。嘴角可平直或微微下撇。眉头可微微皱起。整体气场强大。',
        'tips': '想象自己是电影女主角',
      },
    };

    final expressionData = expressionGuides[expression] ?? {
      'guide': '保持自然放松的表情',
      'tips': '深呼吸，放轻松',
    };

    return GuidanceSection(
      icon: '😊',
      title: '表情引导',
      content: '${expressionData['guide']}\n\n💡 小技巧：${expressionData['tips']}',
    );
  }

  String _generateCameraTip(String shotSize, String angle) {
    final tips = <String, String>{};

    tips['特写'] = '大光圈f/1.4-f/2.8，虚化背景。焦点在眼睛。对焦准确后轻按快门。';
    tips['近景'] = '光圈f/2.0-f/2.8，虚化背景但保留部分环境信息。胸部以上入画。';
    tips['中景'] = '光圈f/2.8-f/4，可保留更多背景。大腿以上或腰部以上入画。';
    tips['全景'] = '光圈f/5.6-f/8，保留完整背景信息。全身入画，注意环境构图。';
    tips['远景'] = '光圈f/8-f/11，背景清晰可见。人物在画面中较小，注重环境氛围。';

    tips['俯拍'] =
        '相机从上方45-90度角拍摄。可用梯子或高举手臂。俯拍显瘦，适合拍脸型。';
    tips['仰拍'] =
        '相机从下方仰拍，显腿长。角度约15-45度。注意天空过曝，可补光。';
    tips['侧拍'] =
        '相机在人物侧方45-90度。突出身体侧面轮廓和S型曲线。营造立体感。';
    tips['平视'] =
        '相机与人物眼睛同高。最自然的视角，真实感强。适合大多数场景。';
    tips['45度角'] =
        '相机在人物斜前方45度。显瘦又立体，是最常用的拍摄角度。';
    tips['背影'] =
        '相机在人物背面。营造神秘感或氛围感。注意人物头部位置与背景的关系。';

    final shotTip = tips[shotSize] ?? '根据场景调整光圈和构图';
    final angleTip = tips[angle] ?? '';

    return '$shotTip $angleTip';
  }

  List<String> _extractKeywords(
      String category, String subtype, String expression) {
    final keywords = <String>[];

    keywords.add(category);
    keywords.add(subtype);
    keywords.add(expression);

    return keywords;
  }

  String _getExpressionPrefix(String expression) {
    final prefixes = {
      '微笑': '微笑',
      '大笑': '大笑',
      '冷艳': '冷艳',
      '甜美': '甜美',
      '自然': '自然',
      '忧郁': '忧郁',
      '俏皮': '俏皮',
      '妩媚': '妩媚',
      '清纯': '清纯',
      '酷飒': '酷飒',
    };

    return prefixes[expression] ?? expression;
  }
}
