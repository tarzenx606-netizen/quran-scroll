import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const gold = Color(0xFFD4AF6A);
const ivory = Color(0xFFF3ECD8);
Color goldA(double o) => Color.fromRGBO(212, 175, 106, o);

class Lang {
  final String code, label, credit, file;
  const Lang(this.code, this.label, this.credit, this.file);
}

const langs = [
  Lang('en', 'English', 'Saheeh International', 'quran_en.json'),
  Lang('ur', 'اردو', "Abul A'la Maududi", 'quran_ur.json'),
  Lang('hi', 'हिन्दी', 'Suhel Farooq Khan & Saifur Rahman Nadwi', 'hi.txt'),
  Lang('id', 'Indonesia', 'Indonesian Islamic Affairs Ministry', 'quran_id.json'),
  Lang('tr', 'Türkçe', 'Turkish Directorate of Religious Affairs (Diyanet)', 'quran_tr.json'),
];

class Surah {
  final int id;
  final String name, translit, meaning;
  final List<String> ar;
  Surah(this.id, this.name, this.translit, this.meaning, this.ar);
}

class Quran {
  final List<Surah> surahs = [];
  final Map<String, List<List<String>>> tr = {};

  static Future<Quran> load() async {
    final q = Quran();
    final raw = jsonDecode(await rootBundle.loadString('assets/data/quran_en.json')) as List;
    final en = <List<String>>[];
    var total = 0;
    for (final c in raw) {
      final vs = c['verses'] as List;
      q.surahs.add(Surah(c['id'] as int, c['name'] as String, c['transliteration'] as String,
          c['translation'] as String, vs.map((v) => v['text'] as String).toList()));
      en.add(vs.map((v) => v['translation'] as String).toList());
      total += vs.length;
    }
    if (q.surahs.length != 114 || total != 6236) {
      throw Exception('Data check failed: ${q.surahs.length} surahs, $total ayat');
    }
    q.tr['en'] = en;
    return q;
  }

  Future<bool> ensure(String code) async {
    if (tr.containsKey(code)) return true;
    try {
      final l = langs.firstWhere((x) => x.code == code);
      final s = await rootBundle.loadString('assets/data/${l.file}');
      final out = <List<String>>[];
      if (l.file.endsWith('.json')) {
        for (final c in jsonDecode(s) as List) {
          out.add((c['verses'] as List).map((v) => v['translation'] as String).toList());
        }
      } else {
        final flat = s
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && !e.startsWith('#'))
            .map((e) {
          final p = e.split('|');
          return p.length >= 3 ? p.sublist(2).join('|') : e;
        }).toList();
        if (flat.length != 6236) return false;
        var k = 0;
        for (final su in surahs) {
          out.add(flat.sublist(k, k + su.ar.length));
          k += su.ar.length;
        }
      }
      if (out.length != 114) return false;
      for (var i = 0; i < 114; i++) {
        if (out[i].length != surahs[i].ar.length) return false;
      }
      tr[code] = out;
      return true;
    } catch (_) {
      return false;
    }
  }
}

class BgPainter extends CustomPainter {
  final int type;
  final double t;
  BgPainter(this.type, this.t);
  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    Color a = const Color(0xFF1C1007), b = const Color(0xFF050302);
    Color gl = const Color.fromRGBO(255, 200, 100, .35);
    Alignment ctr = const Alignment(0, -1);
    if (type == 1) {
      a = const Color(0xFF06110E); b = const Color(0xFF04120D);
      gl = const Color.fromRGBO(23, 113, 82, .45); ctr = const Alignment(0, -.2);
    } else if (type == 2) {
      a = const Color(0xFF0A2A22); b = const Color(0xFF040D0A);
      gl = const Color.fromRGBO(40, 150, 110, .45); ctr = const Alignment(0, -.4);
    } else if (type == 3) {
      a = const Color(0xFF0A0F2E); b = const Color(0xFF050818);
      gl = const Color.fromRGBO(70, 60, 190, .4); ctr = const Alignment(-.6, -.6);
    }
    c.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(rect));
    c.drawRect(rect, Paint()..shader = RadialGradient(center: ctr, radius: .9, colors: [gl, const Color.fromRGBO(0, 0, 0, 0)]).createShader(rect));
    if (type == 0) {
      final p = Paint()..color = const Color.fromRGBO(255, 200, 100, .10);
      for (var i = -4; i <= 4; i++) {
        final path = Path()
          ..moveTo(s.width / 2, -10)
          ..lineTo(s.width / 2 + i * s.width * .22 - s.width * .05, s.height)
          ..lineTo(s.width / 2 + i * s.width * .22 + s.width * .05, s.height)
          ..close();
        c.drawPath(path, p);
      }
    }
    if (type == 2) {
      final sp = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = goldA(.5);
      for (var k = 0; k < 2; k++) {
        final inset = s.width * (.09 + k * .07);
        c.drawRRect(
            RRect.fromLTRBAndCorners(inset, s.height * (.07 + k * .04), s.width - inset, s.height + 4,
                topLeft: Radius.circular(s.width), topRight: Radius.circular(s.width)),
            sp);
      }
    }
    final r = Random(7);
    for (var i = 0; i < 40; i++) {
      final x = r.nextDouble() * s.width;
      final sp = .3 + r.nextDouble() * .7;
      final ph = r.nextDouble();
      final rad = 1.2 + r.nextDouble() * 1.8;
      final prog = (t * 6 * sp + ph) % 1.0;
      final al = sin(prog * pi);
      c.drawCircle(Offset(x + sin((prog + ph) * 6.28) * 12, s.height * (1 - prog)), rad,
          Paint()..color = Color.fromRGBO(242, 217, 143, .8 * al)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
  }
  @override
  bool shouldRepaint(BgPainter o) => o.t != t || o.type != type;
}

class FxPainter extends CustomPainter {
  final Offset pos;
  final double v;
  FxPainter(this.pos, this.v);
  @override
  void paint(Canvas c, Size s) {
    if (v <= 0 || v >= 1) return;
    final a = 1 - v;
    c.drawCircle(pos, 10 + 110 * v,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Color.fromRGBO(242, 217, 143, a));
    for (var i = 0; i < 16; i++) {
      final ang = i * pi * 2 / 16 + i * .37;
      final d = (30 + (i % 4) * 22) * v * 1.8;
      c.drawCircle(pos + Offset(cos(ang) * d, sin(ang) * d), 3 * a + .5,
          Paint()..color = Color.fromRGBO(242, 217, 143, a)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
  }
  @override
  bool shouldRepaint(FxPainter o) => o.v != v || o.pos != pos;
}

final Future<Quran> quranFuture = Quran.load();

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Quran Scroll',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: const Color(0xFF04120D)),
        home: FutureBuilder<Quran>(
          future: quranFuture,
          builder: (c, s) {
            if (s.hasError) return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${s.error}'))));
            if (!s.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(color: gold)));
            return Feed(q: s.data!);
          },
        ),
      );
}

class Feed extends StatefulWidget {
  final Quran q;
  const Feed({super.key, required this.q});
  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> with TickerProviderStateMixin {
  late final AnimationController amb = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  late final AnimationController fx = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
  final PageController pc = PageController();
  SharedPreferences? sp;
  String lang = 'en';
  int bg = 0, si = 0, cur = 0, streak = 1;
  bool showTr = true, pulse = false;
  Set<String> marks = {};
  Offset fxPos = Offset.zero;

  Quran get q => widget.q;
  Surah get su => q.surahs[si];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    amb.dispose();
    fx.dispose();
    pc.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    sp = p;
    String d(DateTime t) => t.toIso8601String().substring(0, 10);
    final now = DateTime.now();
    final last = p.getString('last');
    var st = p.getInt('streak') ?? 0;
    if (last != d(now)) {
      st = last == d(now.subtract(const Duration(days: 1))) ? st + 1 : 1;
      await p.setString('last', d(now));
      await p.setInt('streak', st);
    }
    if (st < 1) st = 1;
    final sl = p.getString('lang') ?? 'en';
    final okLang = await q.ensure(sl);
    if (!mounted) return;
    setState(() {
      streak = st;
      bg = p.getInt('bg') ?? 0;
      si = (p.getInt('si') ?? 0).clamp(0, 113).toInt();
      marks = (p.getStringList('marks') ?? []).toSet();
      if (okLang) lang = sl;
    });
  }

  void burst(Offset p) {
    fxPos = p;
    fx.forward(from: 0);
    HapticFeedback.lightImpact();
    setState(() => pulse = true);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => pulse = false);
    });
  }

  Future<void> setLang(String code) async {
    if (!await q.ensure(code)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Is zuban ka verified data load nahi hua')));
      return;
    }
    setState(() => lang = code);
    sp?.setString('lang', code);
  }

  void goSurah(int i, [int page = 0]) {
    setState(() {
      si = i;
      cur = page;
    });
    sp?.setInt('si', i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pc.hasClients) pc.jumpToPage(page);
    });
  }

  void toggleMark() {
    if (cur >= su.ar.length) return;
    final k = '${su.id}:${cur + 1}';
    setState(() {
      if (!marks.remove(k)) marks.add(k);
    });
    sp?.setStringList('marks', marks.toList());
    HapticFeedback.mediumImpact();
  }

  String markTitle(String k) {
    final p = k.split(':');
    return '${q.surahs[int.parse(p[0]) - 1].translit}  ·  $k';
  }

  void showMarks() {
    final list = marks.toList()
      ..sort((a, b) {
        final x = a.split(':'), y = b.split(':');
        final c = int.parse(x[0]).compareTo(int.parse(y[0]));
        return c != 0 ? c : int.parse(x[1]).compareTo(int.parse(y[1]));
      });
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1A15),
      builder: (c) => list.isEmpty
          ? const SizedBox(height: 160, child: Center(child: Text('Abhi koi bookmark nahi')))
          : ListView(children: [
              for (final k in list)
                ListTile(
                  title: Text(markTitle(k)),
                  onTap: () {
                    Navigator.pop(c);
                    final p = k.split(':');
                    goSurah(int.parse(p[0]) - 1, int.parse(p[1]) - 1);
                  },
                ),
            ]),
    );
  }

  void pickSurah() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1A15),
      builder: (c) => SizedBox(
        height: MediaQuery.of(c).size.height * .75,
        child: ListView.builder(
          itemCount: 114,
          itemBuilder: (c, i) {
            final s = q.surahs[i];
            return ListTile(
              leading: Text('${s.id}', style: const TextStyle(color: gold)),
              title: Text(s.translit),
              subtitle: Text('${s.meaning} · ${s.ar.length} ayat'),
              trailing: Text(s.name, style: GoogleFonts.amiriQuran(fontSize: 22, color: ivory)),
              onTap: () {
                Navigator.pop(c);
                goSurah(i);
              },
            );
          },
        ),
      ),
    );
  }

  void pickLang() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1A15),
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final l in langs)
            ListTile(
              title: Text(l.label),
              subtitle: Text(l.credit, style: const TextStyle(fontSize: 12)),
              trailing: l.code == lang ? const Icon(Icons.check, color: gold) : null,
              onTap: () async {
                Navigator.pop(c);
                await setLang(l.code);
              },
            ),
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text("Arabic: The Noble Qur'an Encyclopedia. Tarjume: Tanzil.net / quranenc.com",
                style: TextStyle(fontSize: 11, color: Colors.white54)),
          ),
        ]),
      ),
    );
  }

  void pickBg() {
    const names = ['Golden Rays', 'Emerald Night', 'Emerald Arch', 'Midnight'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1A15),
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < names.length; i++)
            ListTile(
              title: Text(names[i]),
              trailing: i == bg ? const Icon(Icons.check, color: gold) : null,
              onTap: () {
                Navigator.pop(c);
                setState(() => bg = i);
                sp?.setInt('bg', i);
              },
            ),
        ]),
      ),
    );
  }

  TextStyle trStyle() {
    const col = Color(0xFFD9D2BD);
    if (lang == 'ur') return GoogleFonts.notoNastaliqUrdu(fontSize: 19, height: 2.2, color: col);
    if (lang == 'hi') return GoogleFonts.notoSansDevanagari(fontSize: 17, height: 1.6, color: col);
    return GoogleFonts.cormorantGaramond(fontSize: 20, height: 1.45, color: col, fontWeight: FontWeight.w500);
  }

  Widget orn() => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 1, color: goldA(.6)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(width: 8, height: 8, decoration: BoxDecoration(border: Border.all(color: gold))),
          ),
        ),
        Container(width: 40, height: 1, color: goldA(.6)),
      ]);

  Widget ayah(int i) {
    final ar = su.ar[i];
    final t = q.tr[lang]![si][i];
    final fs = ar.length < 70 ? 36.0 : ar.length < 160 ? 30.0 : ar.length < 300 ? 25.0 : 21.0;
    final credit = langs.firstWhere((l) => l.code == lang).credit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 90, 26, 120),
      child: Center(
        child: SingleChildScrollView(
          child: AnimatedScale(
            scale: pulse ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 220),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${su.translit.toUpperCase()}  ·  ${su.id}:${i + 1}',
                  style: const TextStyle(color: gold, fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 22),
              Text(ar,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiriQuran(
                      fontSize: fs, height: 2.0, color: ivory, shadows: [Shadow(color: goldA(.35), blurRadius: 22)])),
              const SizedBox(height: 16),
              orn(),
              const SizedBox(height: 16),
              if (showTr)
                Text(t,
                    textAlign: TextAlign.center,
                    textDirection: lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                    style: trStyle()),
              if (showTr)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(credit, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget endPage() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline, color: gold, size: 56),
          const SizedBox(height: 14),
          Text(su.translit, style: const TextStyle(color: gold, fontSize: 18)),
          const SizedBox(height: 18),
          if (si < 113)
            FilledButton(
              onPressed: () => goSurah(si + 1),
              style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: const Color(0xFF1A1304)),
              child: Text('Agli surah: ${q.surahs[si + 1].translit}'),
            ),
        ]),
      );

  Widget rb(IconData i, VoidCallback f, {bool on = false}) => Material(
        color: on ? gold : const Color.fromRGBO(15, 61, 46, .75),
        shape: CircleBorder(side: BorderSide(color: goldA(.5))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: f,
          child: SizedBox(width: 50, height: 50, child: Icon(i, color: on ? const Color(0xFF1A1304) : gold)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final marked = cur < su.ar.length && marks.contains('${su.id}:${cur + 1}');
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: amb,
            builder: (c, w) => CustomPaint(painter: BgPainter(bg, amb.value), size: Size.infinite),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (d) => burst(d.localPosition),
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: pc,
              itemCount: su.ar.length + 1,
              onPageChanged: (i) => setState(() => cur = i),
              itemBuilder: (c, i) => i < su.ar.length ? ayah(i) : endPage(),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: fx,
              builder: (c, w) => CustomPaint(painter: FxPainter(fxPos, fx.value), size: Size.infinite),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: pickSurah,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(15, 61, 46, .6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: goldA(.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${su.id}. ${su.translit}', style: const TextStyle(color: ivory)),
                      const Icon(Icons.arrow_drop_down, color: gold),
                    ]),
                  ),
                ),
                const Spacer(),
                Text('🔥 $streak din', style: const TextStyle(color: gold, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                rb(marked ? Icons.favorite : Icons.favorite_border, toggleMark, on: marked),
                const SizedBox(width: 10),
                rb(Icons.bookmarks_outlined, showMarks),
                const SizedBox(width: 10),
                rb(Icons.text_fields, () => setState(() => showTr = !showTr), on: showTr),
                const SizedBox(width: 10),
                rb(Icons.translate, pickLang),
                const SizedBox(width: 10),
                rb(Icons.palette_outlined, pickBg),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
