import 'dart:math' as math;
import 'dart:ui';

/// 색각 이상 시뮬레이션과 색차 계산 (색 팔레트 검증용).
///
/// - 시뮬레이션: Machado, Oliveira, Fernandes (2009)의 변환 행렬(심한 정도 1.0)을 선형 RGB에 적용한다
/// - 색차: CIEDE2000. 구현이 맞는지는 Sharma 등의 기준 데이터로 test/support/color_vision_test.dart에서 확인한다
enum ColorVision { normal, protanopia, deuteranopia, tritanopia }

const _matrices = <ColorVision, List<List<double>>>{
  ColorVision.protanopia: [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ],
  ColorVision.deuteranopia: [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.011820, 0.042940, 0.968881],
  ],
  ColorVision.tritanopia: [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.303900],
  ],
};

double _linear(double c) => c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
double _unlinear(double v) {
  final x = v.clamp(0.0, 1.0);
  return x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4).toDouble() - 0.055;
}

/// 0~255 스케일의 sRGB 세 값
List<double> _rgb(Color color) => [color.r * 255, color.g * 255, color.b * 255];

/// [vision]으로 본 색 (0~255 sRGB)
List<double> simulate(Color color, ColorVision vision) {
  final rgb = _rgb(color);
  if (vision == ColorVision.normal) return rgb;
  final linear = [for (final c in rgb) _linear(c / 255)];
  final m = _matrices[vision]!;
  return [
    for (var i = 0; i < 3; i++) 255 * _unlinear(m[i][0] * linear[0] + m[i][1] * linear[1] + m[i][2] * linear[2]),
  ];
}

/// sRGB(0~255) → CIE Lab (D65)
List<double> toLab(List<double> rgb) {
  final r = _linear(rgb[0] / 255), g = _linear(rgb[1] / 255), b = _linear(rgb[2] / 255);
  final x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b;
  final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
  final z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b;
  double f(double t) => t > 216 / 24389 ? math.pow(t, 1 / 3).toDouble() : (24389 / 27 * t + 16) / 116;
  final fx = f(x / 0.95047), fy = f(y / 1.0), fz = f(z / 1.08883);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

double _deg(double rad) => rad * 180 / math.pi;
double _rad(double deg) => deg * math.pi / 180;

/// 두 Lab 색의 CIEDE2000 색차
double deltaE2000(List<double> lab1, List<double> lab2) {
  final l1 = lab1[0], a1 = lab1[1], b1 = lab1[2];
  final l2 = lab2[0], a2 = lab2[1], b2 = lab2[2];
  final c1 = math.sqrt(a1 * a1 + b1 * b1), c2 = math.sqrt(a2 * a2 + b2 * b2);
  final cBar = (c1 + c2) / 2;
  final g = 0.5 * (1 - math.sqrt(math.pow(cBar, 7) / (math.pow(cBar, 7) + math.pow(25, 7))));
  final a1p = (1 + g) * a1, a2p = (1 + g) * a2;
  final c1p = math.sqrt(a1p * a1p + b1 * b1), c2p = math.sqrt(a2p * a2p + b2 * b2);
  final h1p = c1p == 0 ? 0.0 : (_deg(math.atan2(b1, a1p)) + 360) % 360;
  final h2p = c2p == 0 ? 0.0 : (_deg(math.atan2(b2, a2p)) + 360) % 360;
  final dLp = l2 - l1, dCp = c2p - c1p;
  double dhp;
  if (c1p * c2p == 0) {
    dhp = 0;
  } else {
    final d = h2p - h1p;
    dhp = d.abs() <= 180 ? d : (d > 180 ? d - 360 : d + 360);
  }
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(_rad(dhp / 2));
  final lBarP = (l1 + l2) / 2, cBarP = (c1p + c2p) / 2;
  double hBarP;
  if (c1p * c2p == 0) {
    hBarP = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBarP = (h1p + h2p) / 2;
  } else {
    hBarP = h1p + h2p < 360 ? (h1p + h2p + 360) / 2 : (h1p + h2p - 360) / 2;
  }
  final t = 1 -
      0.17 * math.cos(_rad(hBarP - 30)) +
      0.24 * math.cos(_rad(2 * hBarP)) +
      0.32 * math.cos(_rad(3 * hBarP + 6)) -
      0.20 * math.cos(_rad(4 * hBarP - 63));
  final dTheta = 30 * math.exp(-math.pow((hBarP - 275) / 25, 2));
  final rc = 2 * math.sqrt(math.pow(cBarP, 7) / (math.pow(cBarP, 7) + math.pow(25, 7)));
  final sl = 1 + 0.015 * math.pow(lBarP - 50, 2) / math.sqrt(20 + math.pow(lBarP - 50, 2));
  final sc = 1 + 0.045 * cBarP;
  final sh = 1 + 0.015 * cBarP * t;
  final rt = -math.sin(_rad(2 * dTheta)) * rc;
  return math.sqrt(math.pow(dLp / sl, 2) + math.pow(dCp / sc, 2) + math.pow(dHp / sh, 2) + rt * (dCp / sc) * (dHp / sh));
}

/// 두 색이 [vision]으로 보일 때의 색차
double visionDelta(Color a, Color b, ColorVision vision) =>
    deltaE2000(toLab(simulate(a, vision)), toLab(simulate(b, vision)));

/// 모든 시각 유형(정상, 적색맹, 녹색맹, 청황색맹) 중 가장 작은 색차
double worstDelta(Color a, Color b) => [for (final v in ColorVision.values) visionDelta(a, b, v)].reduce(math.min);
