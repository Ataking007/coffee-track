import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CoffeeTrackApp());

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------
const kEspresso = Color(0xFF3B2416);
const kMocha = Color(0xFF6F4E37);
const kLatte = Color(0xFFC8A27A);
const kCream = Color(0xFFF5E6D3);
const kGold = Color(0xFFE8B04B);
const kWood = Color(0xFFA0703F);

int bestScore = 0;

// ---------------------------------------------------------------------------
// Data: ingredients, menu, customers
// ---------------------------------------------------------------------------
class Ingredient {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  const Ingredient(this.id, this.name, this.emoji, this.color);
}

const List<Ingredient> ingredients = [
  Ingredient('espresso', 'Espresso', '☕', Color(0xFF4B2E1E)),
  Ingredient('choco', 'Chocolate', '🍫', Color(0xFF5C3317)),
  Ingredient('water', 'Hot Water', '💧', Color(0xFF9C6B45)),
  Ingredient('milk', 'Milk', '🥛', Color(0xFFF8F4EC)),
  Ingredient('caramel', 'Caramel', '🍯', Color(0xFFD9922E)),
  Ingredient('ice', 'Ice', '🧊', Color(0xFFBFE6F5)),
  Ingredient('foam', 'Milk Foam', '☁️', Color(0xFFEDE3D3)),
  Ingredient('cream', 'Whipped Cream', '🍦', Color(0xFFFFFBF2)),
];

Ingredient ingredientById(String id) =>
    ingredients.firstWhere((i) => i.id == id);

/// Ingredients sorted bottom-to-top as they appear in a cup.
List<Ingredient> layersOf(Set<String> ids) =>
    ingredients.where((i) => ids.contains(i.id)).toList();

class MenuItem {
  final String name;
  final String emoji;
  final int price;
  final Set<String> recipe; // empty => pastry
  const MenuItem(this.name, this.emoji, this.price, [this.recipe = const <String>{}]);
  bool get isDrink => recipe.isNotEmpty;
}

const List<MenuItem> drinks = [
  MenuItem('Espresso', '☕', 10, {'espresso'}),
  MenuItem('Americano', '☕', 12, {'espresso', 'water'}),
  MenuItem('Latte', '🥛', 14, {'espresso', 'milk'}),
  MenuItem('Cappuccino', '☁️', 16, {'espresso', 'milk', 'foam'}),
  MenuItem('Café Mocha', '🍫', 18, {'espresso', 'choco', 'milk'}),
  MenuItem('Caramel Macchiato', '🍯', 18, {'espresso', 'milk', 'caramel'}),
  MenuItem('Iced Latte', '🧊', 16, {'espresso', 'milk', 'ice'}),
  MenuItem('Con Panna', '🍦', 13, {'espresso', 'cream'}),
  MenuItem('Hot Chocolate', '🍫', 15, {'choco', 'milk', 'cream'}),
];

const List<MenuItem> pastries = [
  MenuItem('Croissant', '🥐', 6),
  MenuItem('Cheesecake', '🍰', 8),
  MenuItem('Cookie', '🍪', 5),
  MenuItem('Donut', '🍩', 6),
  MenuItem('Waffle', '🧇', 7),
  MenuItem('Pancakes', '🥞', 8),
  MenuItem('Sandwich', '🥪', 9),
  MenuItem('Cupcake', '🧁', 7),
];

class CustomerType {
  final String emoji;
  final String name;
  const CustomerType(this.emoji, this.name);
}

const List<CustomerType> customerTypes = [
  CustomerType('👩', 'Emma'),
  CustomerType('👨‍💼', 'Mr. Brown'),
  CustomerType('👵', 'Grandma Rose'),
  CustomerType('🧑‍🎓', 'Leo'),
  CustomerType('🧔', 'Jack'),
  CustomerType('👩‍🎨', 'Zoe'),
  CustomerType('👮', 'Officer Dan'),
  CustomerType('🧑‍💻', 'Sam'),
  CustomerType('👩‍🦰', 'Ruby'),
  CustomerType('👴', 'Grandpa Joe'),
];

class Order {
  final MenuItem? drink;
  final MenuItem? pastry;
  const Order(this.drink, this.pastry);
  int get price => (drink?.price ?? 0) + (pastry?.price ?? 0);
}

class Customer {
  final CustomerType type;
  final Order order;
  const Customer(this.type, this.order);
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------
class CoffeeTrackApp extends StatelessWidget {
  const CoffeeTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Track',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kMocha),
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Home screen
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _play() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GameScreen()));
    if (mounted) setState(() {});
  }

  void _howToPlay() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCream,
        title: const Text('How to Play ☕'),
        content: const SingleChildScrollView(
          child: Text(
            'You are the barista of Coffee Track café!\n\n'
            '1. A customer arrives and tells you their order.\n'
            '2. Tap ingredients to fill the cup (open 📖 Recipes if you forget).\n'
            '3. Tap a pastry to put it on the plate.\n'
            '4. Press SERVE before the customer loses patience.\n\n'
            'POINTS\n'
            '✅ Correct order: + price of the order\n'
            '⚡ Speed bonus: up to +10 for fast service\n'
            '🔥 Combo: 3+ correct in a row = double points\n'
            '❌ Wrong order: −5 points, −3 s patience\n'
            '😠 Customer leaves: −10 points and −1 ❤️\n\n'
            'Every 4 served customers the level goes up: '
            'customers get less patient and order combos.\n'
            'The shift ends after 120 seconds or when you lose 3 ❤️.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A3A26), kEspresso],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                  top: 30, left: 24, child: _Deco('🫘', 34, -0.4)),
              const Positioned(
                  top: 120, right: 30, child: _Deco('🥐', 40, 0.3)),
              const Positioned(
                  bottom: 140, left: 30, child: _Deco('🍩', 38, 0.2)),
              const Positioned(
                  bottom: 60, right: 40, child: _Deco('🫘', 30, 0.6)),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 140,
                        height: 140,
                        child: CupView(
                            ids: {'espresso', 'milk', 'foam'}, steam: true),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Coffee Track',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: kCream,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Run the coziest café in town!',
                        style: TextStyle(fontSize: 16, color: kLatte),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 220,
                        height: 54,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kGold,
                            foregroundColor: kEspresso,
                          ),
                          onPressed: _play,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Shift',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 220,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kCream,
                            side: const BorderSide(color: kLatte),
                          ),
                          onPressed: _howToPlay,
                          icon: const Icon(Icons.help_outline),
                          label: const Text('How to Play'),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        '🏆 Best score: $bestScore',
                        style: const TextStyle(color: kCream, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Deco extends StatelessWidget {
  final String emoji;
  final double size;
  final double angle;
  const _Deco(this.emoji, this.size, this.angle);

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: 0.35,
          child: Text(emoji, style: TextStyle(fontSize: size)),
        ),
      );
}

// ---------------------------------------------------------------------------
// Game screen
// ---------------------------------------------------------------------------
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double shiftLength = 120;

  final _rng = Random();
  Timer? _timer;
  bool _ended = false;

  int score = 0;
  int hearts = 3;
  int streak = 0;
  int bestStreak = 0;
  int served = 0;
  double timeLeft = shiftLength;

  late Customer customer;
  double patience = 1;
  double maxPatience = 1;

  final Set<String> cup = {};
  MenuItem? plate;

  String? toast;
  Color toastColor = Colors.green;
  int _toastId = 0;
  String? reaction;

  int get level => 1 + served ~/ 4;

  String get mood {
    if (reaction != null) return reaction!;
    final f = patience / maxPatience;
    if (f > 0.6) return '🙂';
    if (f > 0.3) return '😐';
    return '😠';
  }

  @override
  void initState() {
    super.initState();
    _newCustomer();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _ended) return;
    setState(() {
      timeLeft -= 0.1;
      patience -= 0.1;
      if (patience <= 0) _customerLeft();
    });
    if (timeLeft <= 0 || hearts <= 0) _endGame();
  }

  void _newCustomer() {
    final type = customerTypes[_rng.nextInt(customerTypes.length)];
    final r = _rng.nextInt(10);
    MenuItem? d;
    MenuItem? p;
    final pickDrink = drinks[_rng.nextInt(drinks.length)];
    final pickPastry = pastries[_rng.nextInt(pastries.length)];
    if (level < 2) {
      if (r < 7) {
        d = pickDrink;
      } else {
        p = pickPastry;
      }
    } else {
      if (r < 5) {
        d = pickDrink;
      } else if (r < 7) {
        p = pickPastry;
      } else {
        d = pickDrink;
        p = pickPastry;
      }
    }
    customer = Customer(type, Order(d, p));
    maxPatience = max(9.0, 20.0 - level * 1.5) + (d != null && p != null ? 5 : 0);
    patience = maxPatience;
    cup.clear();
    plate = null;
  }

  void _showToast(String text, Color color) {
    toast = text;
    toastColor = color;
    final id = ++_toastId;
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && id == _toastId) {
        setState(() {
          toast = null;
          reaction = null;
        });
      }
    });
  }

  void _customerLeft() {
    hearts--;
    streak = 0;
    score = max(0, score - 10);
    reaction = null;
    _showToast('${customer.type.name} left angry!  −10  −1 ❤️', Colors.red);
    if (hearts > 0) _newCustomer();
  }

  void _toggleIngredient(Ingredient i) {
    setState(() {
      if (cup.contains(i.id)) {
        cup.remove(i.id);
      } else {
        cup.add(i.id);
      }
    });
  }

  void _pickPastry(MenuItem p) {
    setState(() => plate = plate == p ? null : p);
  }

  void _clearTray() {
    setState(() {
      cup.clear();
      plate = null;
    });
  }

  void _serve() {
    if (cup.isEmpty && plate == null) {
      setState(() => _showToast('Your tray is empty!', Colors.orange));
      return;
    }
    final o = customer.order;
    final drinkOk =
        o.drink == null ? cup.isEmpty : setEquals(cup, o.drink!.recipe);
    final pastryOk = plate == o.pastry;

    setState(() {
      if (drinkOk && pastryOk) {
        streak++;
        bestStreak = max(bestStreak, streak);
        served++;
        final speed = (patience / maxPatience * 10).round();
        final mult = streak >= 3 ? 2 : 1;
        final gained = (o.price + speed) * mult;
        score += gained;
        reaction = '😍';
        _showToast(
          '+$gained  (order ${o.price} + speed $speed${mult > 1 ? ' ×2 🔥' : ''})',
          Colors.green.shade700,
        );
        _newCustomer();
      } else {
        streak = 0;
        score = max(0, score - 5);
        patience -= 3;
        cup.clear();
        plate = null;
        reaction = '😤';
        _showToast('Wrong order!  −5', Colors.red);
      }
    });
  }

  void _endGame() {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    final isNewBest = score > bestScore;
    if (isNewBest) bestScore = score;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(
          score: score,
          served: served,
          bestStreak: bestStreak,
          newBest: isNewBest,
          outOfHearts: hearts <= 0,
        ),
      ),
    );
  }

  void _openRecipes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCream,
      showDragHandle: true,
      builder: (_) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Text('📖 Recipe Book',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final d in drinks)
            ListTile(
              leading: SizedBox(
                  width: 44, height: 44, child: CupView(ids: d.recipe)),
              title: Text('${d.name}  ·  ${d.price} pts'),
              subtitle: Text(
                  layersOf(d.recipe).map((i) => '${i.emoji} ${i.name}').join('  +  ')),
            ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kEspresso,
      body: SafeArea(
        child: Column(
          children: [
            _hud(),
            Expanded(flex: 5, child: _scene()),
            Expanded(flex: 6, child: _counter()),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(60),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: kCream, fontWeight: FontWeight.bold, fontSize: 14)),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          chip('⭐ $score'),
          chip('⏱ ${max(0, timeLeft.ceil())}s'),
          chip('❤️' * max(0, hearts) + '🤍' * (3 - max(0, hearts))),
          chip(streak >= 3 ? 'Lv $level 🔥' : 'Lv $level'),
        ],
      ),
    );
  }

  Widget _scene() {
    final o = customer.order;
    final f = (patience / maxPatience).clamp(0.0, 1.0);
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: CafePainter())),
        // chalkboard menu
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF263229),
              border: Border.all(color: kWood, width: 4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'COFFEE TRACK\nfresh daily ☕',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white70, fontSize: 11, height: 1.3),
            ),
          ),
        ),
        // shelf decorations
        const Positioned(
          top: 92,
          right: 18,
          child: Text('🪴 🍪 ☕ 🥐', style: TextStyle(fontSize: 18)),
        ),
        // customer + speech bubble
        Align(
          alignment: const Alignment(0, 0.95),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood, style: const TextStyle(fontSize: 24)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(customer.type.emoji,
                          key: ValueKey(customer),
                          style: const TextStyle(fontSize: 64)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: kCream,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(customer.type.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("I'd like…",
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        if (o.drink != null)
                          Row(children: [
                            SizedBox(
                                width: 36,
                                height: 36,
                                child: CupView(
                                    ids: o.drink!.recipe,
                                    steam: !o.drink!.recipe.contains('ice'))),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(o.drink!.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                          ]),
                        if (o.pastry != null)
                          Row(children: [
                            Text(o.pastry!.emoji,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 6),
                            Text(o.pastry!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: f,
                            minHeight: 7,
                            backgroundColor: Colors.black12,
                            color: f > 0.6
                                ? Colors.green
                                : (f > 0.3 ? Colors.orange : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // toast
        if (toast != null)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: toastColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(toast!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _counter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A5A33), Color(0xFF5E3B22)],
        ),
        border: Border(top: BorderSide(color: Color(0xFFC08A55), width: 6)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            // tray: cup + plate
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                  SizedBox(
                      width: 72,
                      height: 72,
                      child: CupView(
                          ids: cup,
                          steam: cup.isNotEmpty && !cup.contains('ice'))),
                  const Text('Your cup',
                      style: TextStyle(color: kCream, fontSize: 12)),
                ]),
                const SizedBox(width: 28),
                Column(children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: kLatte, width: 4),
                    ),
                    child: Text(plate?.emoji ?? '',
                        style: const TextStyle(fontSize: 36)),
                  ),
                  const Text('Your plate',
                      style: TextStyle(color: kCream, fontSize: 12)),
                ]),
              ],
            ),
            const SizedBox(height: 10),
            // ingredients
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.25,
              children: [
                for (final i in ingredients)
                  _ingredientButton(i, cup.contains(i.id)),
              ],
            ),
            const SizedBox(height: 8),
            // pastry case
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in pastries)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => _pickPastry(p),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: plate == p ? kGold : kCream,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(p.emoji,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // actions
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _clearTray,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Empty tray',
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: _openRecipes,
                  icon: const Icon(Icons.menu_book),
                  tooltip: 'Recipes',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: kEspresso,
                      ),
                      onPressed: _serve,
                      child: const Text('SERVE ☕',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientButton(Ingredient i, bool selected) {
    return InkWell(
      onTap: () => _toggleIngredient(i),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? kGold : kCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? kEspresso : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(i.emoji, style: const TextStyle(fontSize: 22)),
            Text(i.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: kEspresso)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game over screen
// ---------------------------------------------------------------------------
class GameOverScreen extends StatelessWidget {
  final int score;
  final int served;
  final int bestStreak;
  final bool newBest;
  final bool outOfHearts;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.served,
    required this.bestStreak,
    required this.newBest,
    required this.outOfHearts,
  });

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: kEspresso,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(outOfHearts ? '😵' : '🌙',
                  style: const TextStyle(fontSize: 64)),
              Text(
                outOfHearts ? 'Too many angry customers!' : 'Shift over!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (newBest)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('🏆 New best score!',
                      style: TextStyle(
                          color: kMocha,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 16),
              stat('⭐ Score', '$score'),
              stat('☕ Customers served', '$served'),
              stat('🔥 Best combo', '$bestStreak'),
              stat('🏆 Best score', '$bestScore'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: kMocha, foregroundColor: kCream),
                  onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const GameScreen())),
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visuals: cup and café background
// ---------------------------------------------------------------------------
class CupView extends StatelessWidget {
  final Set<String> ids;
  final bool steam;
  const CupView({super.key, required this.ids, this.steam = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: CupPainter(layersOf(ids), steam));
}

class CupPainter extends CustomPainter {
  final List<Ingredient> layers;
  final bool steam;
  CupPainter(this.layers, this.steam);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = h * 0.25;
    final bottom = h * 0.88;

    // saucer
    canvas.drawOval(
      Rect.fromLTRB(w * 0.05, h * 0.84, w * 0.9, h * 0.98),
      Paint()..color = const Color(0xFFE9DCCB),
    );

    final body = Path()
      ..moveTo(w * 0.14, top)
      ..lineTo(w * 0.76, top)
      ..lineTo(w * 0.67, bottom)
      ..lineTo(w * 0.23, bottom)
      ..close();

    // glass background
    canvas.drawPath(body, Paint()..color = Colors.white.withAlpha(215));

    // layers
    canvas.save();
    canvas.clipPath(body);
    if (layers.isNotEmpty) {
      final fillTop = top + (bottom - top) * 0.12;
      final layerH = (bottom - fillTop) / layers.length;
      for (var k = 0; k < layers.length; k++) {
        final ing = layers[k];
        final y2 = bottom - layerH * k;
        final y1 = y2 - layerH;
        canvas.drawRect(
            Rect.fromLTRB(0, y1, w, y2), Paint()..color = ing.color);
        if (ing.id == 'ice') {
          final p = Paint()..color = Colors.white.withAlpha(200);
          final s = layerH * 0.6;
          canvas.drawRect(Rect.fromLTWH(w * 0.3, y1 + 2, s, s), p);
          canvas.drawRect(Rect.fromLTWH(w * 0.5, y1 + 4, s, s), p);
        }
      }
      // highlight
      canvas.drawRect(
        Rect.fromLTRB(w * 0.2, fillTop, w * 0.26, bottom),
        Paint()..color = Colors.white.withAlpha(60),
      );
    }
    canvas.restore();

    final stroke = Paint()
      ..color = kEspresso
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, w * 0.035)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, stroke);

    // handle
    canvas.drawArc(
      Rect.fromLTRB(w * 0.62, h * 0.38, w * 0.94, h * 0.7),
      -pi / 2.2,
      pi / 1.1,
      false,
      stroke,
    );

    // steam
    if (steam && layers.isNotEmpty) {
      final sp = Paint()
        ..color = Colors.white.withAlpha(170)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, w * 0.025)
        ..strokeCap = StrokeCap.round;
      for (final x in [0.35, 0.5, 0.62]) {
        final path = Path()
          ..moveTo(w * x, top - h * 0.03)
          ..quadraticBezierTo(
              w * (x - 0.06), top - h * 0.1, w * x, top - h * 0.15)
          ..quadraticBezierTo(
              w * (x + 0.06), top - h * 0.2, w * x, top - h * 0.24);
        canvas.drawPath(path, sp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CupPainter old) =>
      !listEquals(old.layers, layers) || old.steam != steam;
}

class CafePainter extends CustomPainter {
  const CafePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // wall
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A5C3C), Color(0xFF6B4329)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // wall stripes
    final stripe = Paint()..color = Colors.black.withAlpha(18);
    for (double x = 0; x < w; x += 28) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 12, h * 0.62), stripe);
    }

    // wood panel lower wall
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
        Paint()..color = const Color(0xFF4A2E1C));
    final plank = Paint()
      ..color = Colors.black.withAlpha(50)
      ..strokeWidth = 2;
    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x, h * 0.62), Offset(x, h), plank);
    }
    canvas.drawRect(Rect.fromLTWH(0, h * 0.6, w, h * 0.025),
        Paint()..color = kWood);

    // window with night sky
    final win = Rect.fromLTWH(w * 0.06, h * 0.08, w * 0.3, h * 0.38);
    canvas.drawRect(
      win,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2A4A), Color(0xFF4B5D8A)],
        ).createShader(win),
    );
    canvas.drawCircle(Offset(win.left + win.width * 0.7, win.top + win.height * 0.28),
        win.width * 0.11, Paint()..color = const Color(0xFFFFF3C4));
    final star = Paint()..color = Colors.white70;
    for (final o in const [
      Offset(0.2, 0.2),
      Offset(0.4, 0.5),
      Offset(0.15, 0.65),
      Offset(0.55, 0.15),
      Offset(0.8, 0.6)
    ]) {
      canvas.drawCircle(
          Offset(win.left + win.width * o.dx, win.top + win.height * o.dy),
          1.4,
          star);
    }
    final frame = Paint()
      ..color = kWood
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRect(win, frame);
    canvas.drawLine(Offset(win.center.dx, win.top),
        Offset(win.center.dx, win.bottom), frame);
    canvas.drawLine(Offset(win.left, win.center.dy),
        Offset(win.right, win.center.dy), frame);

    // shelf
    canvas.drawRect(Rect.fromLTWH(w * 0.6, h * 0.36, w * 0.38, 5),
        Paint()..color = kWood);

    // pendant lamps
    for (final x in [w * 0.48, w * 0.72]) {
      canvas.drawLine(Offset(x, 0), Offset(x, h * 0.1),
          Paint()
            ..color = Colors.black54
            ..strokeWidth = 2);
      canvas.drawCircle(
        Offset(x, h * 0.16),
        h * 0.18,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFE6A0).withAlpha(110),
            const Color(0xFFFFE6A0).withAlpha(0),
          ]).createShader(
              Rect.fromCircle(center: Offset(x, h * 0.16), radius: h * 0.18)),
      );
      final shade = Path()
        ..moveTo(x - 14, h * 0.16)
        ..lineTo(x - 6, h * 0.1)
        ..lineTo(x + 6, h * 0.1)
        ..lineTo(x + 14, h * 0.16)
        ..close();
      canvas.drawPath(shade, Paint()..color = const Color(0xFF2F4F4F));
      canvas.drawCircle(Offset(x, h * 0.165), 4,
          Paint()..color = const Color(0xFFFFF1B8));
    }

    // counter top edge
    canvas.drawRect(Rect.fromLTWH(0, h * 0.93, w, h * 0.07),
        Paint()..color = const Color(0xFFC08A55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
