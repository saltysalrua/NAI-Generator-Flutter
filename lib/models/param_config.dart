import 'dart:math';

const defaultSizes = [
  '832 x 1216',
  '1024 x 1024',
  '1216 x 832',
  '1024 x 1536',
  '1472 x 1472',
  '1536 x 1024',
];
const samplers = [
  'k_euler',
  'k_euler_ancestral',
  'k_dpmpp_2s_ancestral',
  'k_dpmpp_2m_sde',
  'k_dpmpp_sde',
  'k_dpmpp_2m',
  'ddim_v3'
];
const noiseSchedules = ['native', 'karras', 'exponential', 'polyexponential'];
const defaultUC =
    'lowres, {bad}, error, fewer, extra, missing, worst quality, jpeg artifacts, bad quality, watermark, unfinished, displeasing, chromatic aberration, signature, extra digits, artistic error, username, scan, [abstract], bad anatomy, bad hands';

class ParamConfig {
  int width;
  int height;
  int nSamples;

  int steps;
  String sampler;
  String noiseSchedule;
  double scale;
  double cfgRescale;
  bool sm;
  bool smDyn;
  bool varietyPlus;

  bool randomSeed;
  int seed;

  bool dynamicThresholding;
  double controlNetStrength;
  double uncondScale;

  bool qualityToggle;
  int ucPreset;
  String negativePrompt;

  bool legacy;
  bool addOriginalImage;

  ParamConfig({
    this.width = 832,
    this.height = 1216,
    this.scale = 6.5,
    this.sampler = 'k_euler_ancestral',
    this.steps = 28,
    this.randomSeed = true,
    this.seed = 0,
    this.nSamples = 1,
    this.ucPreset = 0,
    this.qualityToggle = true,
    this.sm = true,
    this.smDyn = true,
    this.dynamicThresholding = false,
    this.controlNetStrength = 1.0,
    this.legacy = false,
    this.addOriginalImage = false,
    this.uncondScale = 1.0,
    this.cfgRescale = 0.1,
    this.noiseSchedule = 'native',
    this.varietyPlus = false,
    this.negativePrompt = defaultUC,
  });

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'scale': scale,
      'sampler': sampler,
      'steps': steps,
      'n_samples': nSamples,
      'ucPreset': ucPreset,
      'qualityToggle': qualityToggle,
      'sm': sm,
      'sm_dyn': smDyn,
      'random_seed': randomSeed,
      'dynamic_thresholding': dynamicThresholding,
      'controlnet_strength': controlNetStrength,
      'legacy': legacy,
      'add_original_image': addOriginalImage,
      'uncond_scale': uncondScale,
      'cfg_rescale': cfgRescale,
      'noise_schedule': noiseSchedule,
      'negative_prompt': negativePrompt,
      'reference_image_multiple': [],
      'reference_information_extracted_multiple': [],
      'reference_strength_multiple': [],
      'variety_plus': varietyPlus,
    };
  }

  /// Different from toJson(), some fields in payload need to be calculated from other params.
  Map<String, dynamic> get payload {
    bool? preferBrownian;
    bool? deliberateEulerAncestralBug;
    if (sampler == 'k_euler_ancestral' && noiseSchedule != 'native') {
      preferBrownian = true;
      deliberateEulerAncestralBug = false;
    }
    double? skipCfgAboveSigma;
    if (varietyPlus) {
      final w = width / 8;
      final h = height / 8;
      final v = pow(4.0 * w * h / 63232, 0.5);
      skipCfgAboveSigma = 19.0 * v;
    }
    var payload = {
      'width': width,
      'height': height,
      'scale': scale,
      'sampler': sampler,
      'steps': steps,
      'n_samples': nSamples,
      'ucPreset': ucPreset,
      'qualityToggle': qualityToggle,
      'sm': sm,
      'sm_dyn': smDyn,
      'seed': randomSeed ? Random().nextInt(1 << 32 - 1) : seed,
      'dynamic_thresholding': dynamicThresholding,
      'controlnet_strength': controlNetStrength,
      'legacy': legacy,
      'add_original_image': addOriginalImage,
      'uncond_scale': uncondScale,
      'cfg_rescale': cfgRescale,
      'noise_schedule': noiseSchedule,
      'negative_prompt': negativePrompt,
      'reference_image_multiple': [],
      'reference_information_extracted_multiple': [],
      'reference_strength_multiple': [],
      'prefer_brownian': preferBrownian,
      'skip_cfg_above_sigma': skipCfgAboveSigma,
      'deliberate_euler_ancestral_bug': deliberateEulerAncestralBug,
    };
    payload.removeWhere((k, v) => v == null);
    return payload;
  }

  factory ParamConfig.fromJson(Map<String, dynamic> json) {
    return ParamConfig(
      width: json['width'],
      height: json['height'],
      scale: json['scale'],
      sampler: json['sampler'],
      steps: json['steps'],
      nSamples: json['n_samples'],
      ucPreset: json['ucPreset'] ?? 0,
      qualityToggle: json['qualityToggle'] ?? false,
      sm: json['sm'],
      smDyn: json['sm_dyn'],
      dynamicThresholding: json['dynamic_thresholding'],
      varietyPlus: json['variety_plus'] ?? false,
      controlNetStrength: json['controlnet_strength'] is int
          ? (json['controlnet_strength'] as int).toDouble()
          : json['controlnet_strength'],
      legacy: json['legacy'],
      addOriginalImage: json['add_original_image'],
      uncondScale: json['uncond_scale'] is int
          ? (json['uncond_scale'] as int).toDouble()
          : json['uncond_scale'],
      cfgRescale: json['cfg_rescale'] is int
          ? (json['cfg_rescale'] as int).toDouble()
          : json['cfg_rescale'],
      noiseSchedule: json['noise_schedule'],
      negativePrompt: json['negative_prompt'],
    );
  }

  int loadJson(Map<String, dynamic> json) {
    int loadCount = 0;
    if (json.containsKey('width')) {
      width = json['width'];
      loadCount++;
    }
    if (json.containsKey('height')) {
      height = json['height'];
      loadCount++;
    }
    if (json.containsKey('scale')) {
      scale = json['scale'];
      loadCount++;
    }
    if (json.containsKey('sampler')) {
      sampler = json['sampler'];
      loadCount++;
    }
    if (json.containsKey('steps')) {
      steps = json['steps'];
      loadCount++;
    }
    if (json.containsKey('n_samples')) {
      nSamples = json['n_samples'];
      loadCount++;
    }
    if (json.containsKey('ucPreset')) {
      ucPreset = json['ucPreset'];
      loadCount++;
    }
    if (json.containsKey('qualityToggle')) {
      qualityToggle = json['qualityToggle'];
      loadCount++;
    }
    if (json.containsKey('sm')) {
      sm = json['sm'];
      loadCount++;
    }
    if (json.containsKey('sm_dyn')) {
      smDyn = json['sm_dyn'];
      loadCount++;
    }
    if (json.containsKey('dynamic_thresholding')) {
      dynamicThresholding = json['dynamic_thresholding'];
      loadCount++;
    }
    if (json.containsKey('controlnet_strength')) {
      controlNetStrength = json['controlnet_strength'] is int
          ? (json['controlnet_strength'] as int).toDouble()
          : json['controlnet_strength'];
      loadCount++;
    }
    if (json.containsKey('legacy')) {
      legacy = json['legacy'];
      loadCount++;
    }
    if (json.containsKey('add_original_image')) {
      addOriginalImage = json['add_original_image'];
      loadCount++;
    }
    if (json.containsKey('uncond_scale')) {
      uncondScale = json['uncond_scale'] is int
          ? (json['uncond_scale'] as int).toDouble()
          : json['uncond_scale'];
      loadCount++;
    }
    if (json.containsKey('cfg_rescale')) {
      cfgRescale = json['cfg_rescale'] is int
          ? (json['cfg_rescale'] as int).toDouble()
          : json['cfg_rescale'];
      loadCount++;
    }
    if (json.containsKey('noise_schedule')) {
      noiseSchedule = json['noise_schedule'];
      loadCount++;
    }
    if (json.containsKey('negative_prompt')) {
      negativePrompt = json['negative_prompt'];
      loadCount++;
    }
    if (json.containsKey('seed')) {
      seed = json['seed'];
      randomSeed = false;
      loadCount++;
    }
    return loadCount;
  }
}
