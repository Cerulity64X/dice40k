import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

BigInt clampn(BigInt a, BigInt? min, BigInt? max) => (min != null && a < min) ? min : ((max != null && a > max) ? max : a);

abstract class JStat {
  void reset();
  String? get();
  Widget? widget();
  void setUpdate(void Function(void Function()) fn) {}
  void update() {}
}

class Numeric extends JStat {
  BigInt? num;
  BigInt? max;
  BigInt? min;
  BigInt? increment;
  bool enforce = true;

  String name;
  Numeric(this.name, {this.min, this.max, this.increment});

  late void Function(void Function()) refresh;
  @override
  void setUpdate(void Function(void Function()) fn) {
    refresh = fn;
  }

  @override
  void reset() {
    num = null;
  }

  @override
  void update() { }

  BigInt getNum() => num ?? min ?? BigInt.zero;

  @override
  String? get() => num?.toString() ?? "0";

  BigInt fix(BigInt? val) => clampn(val ?? BigInt.zero, min, max);

  @override
  Widget widget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      
      children: [
        Expanded(
          flex: 1,
          child: Text(
            name,
            textAlign: TextAlign.center
          ),
        ),
        
        Expanded(
          flex: 2,
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  num = clampn((num ?? BigInt.zero) + (increment ?? BigInt.one), min, max);
                  refresh((){});
                },
                child: const Text("+"),
              ),
              Expanded(child: Text(get()!, textAlign: TextAlign.center,)),
              TextButton(
                onPressed: () {
                  num = clampn((num ?? BigInt.zero) - (increment ?? BigInt.one), min, max);
                  refresh((){});
                },
                child: const Text("-"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class Boolean extends JStat {
  bool enabled = false;

  String name;
  Boolean(this.name);

  late void Function(void Function()) refresh;
  @override
  void setUpdate(void Function(void Function()) fn) {
    refresh = fn;
  }

  @override
  void reset() {
    enabled = false;
  }

  @override
  String? get() => enabled ? "1" : "0";

  @override
  Widget widget() {
    var cb = Checkbox(
      value: enabled,
      onChanged: (value) {
        refresh(() {enabled = (value ?? false);});
      },
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      
      children: [
        Expanded(
          flex: 1,
          child: Text(
            name,
            textAlign: TextAlign.center
          ),
        ),
        
        Expanded(child: cb, flex: 2,),
      ],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

T dbg<T>(T obj) {
  print("DBG: {$obj}");
  return obj;
}

/// Will clamp to int32 max
BigInt diceRoll(int max) => BigInt.from(Random.secure().nextInt(max) + 1);

class _MyHomePageState extends State<MyHomePage> {
  Numeric diceCount = Numeric("Dice Count", min: BigInt.from(1000), increment: BigInt.from(1000));
  Boolean isD3 = Boolean("Use D3 over D6");
  
  Numeric hitCount = Numeric("Roll to Hit", max: BigInt.from(6), min: BigInt.from(2));
  Numeric hitMod = Numeric("Hit Modifier");
  
  Numeric woundCount = Numeric("Roll to Wound", max: BigInt.from(6), min: BigInt.from(2));
  Numeric woundMod = Numeric("Wound Modifier");
  
  Numeric saveCount = Numeric("Roll to Save", max: BigInt.from(6), min: BigInt.from(2));
  Numeric saveMod = Numeric("Save Modifier");

  int kills = 0;

  late List<JStat> all;

  void update(void Function() fn) {
    setState(fn);
    hitCount.update();
  }

  @override
  Widget build(BuildContext context) {
    all = [
      diceCount, isD3,
      hitCount, hitMod,
      woundCount, woundMod,
      saveCount, saveMod
    ];
    for (var stat in all) {
      stat.setUpdate(update);
    }
    List<Widget> s = all
      .map((e) => e.widget())
      .where((element) => element != null)
      .map((e) => e!)
      .toList();
    s.add(TextButton(
      onPressed: () {
        var hitThreshold = clampn(hitCount.getNum() + hitMod.getNum(), BigInt.from(2), BigInt.from(6));
        var saveThreshold = clampn(saveCount.getNum() + saveMod.getNum(), BigInt.from(2), BigInt.from(6));
        var woundThreshold = clampn(woundCount.getNum() + woundMod.getNum(), BigInt.from(2), BigInt.from(6));

        var saves = 0;
        var hits = 0;
        var wounds = 0;

        var diceMax = isD3.enabled ? 3 : 6;

        for (var i = BigInt.zero; i < diceCount.getNum(); i += BigInt.one) {
          if (diceRoll(diceMax) >= hitThreshold) {
            hits++;
            if (diceRoll(diceMax) >= woundThreshold) {
              if (diceRoll(diceMax) >= saveThreshold) {
                saves++;
              } else {
                wounds++;
              }
            }
          }
        }

        print("$hits hits");
        print("$saves saves\n");
        print("$wounds kills");
        print("${wounds.toDouble() / diceCount.getNum().toDouble() * 100.0}% killed\n");

        setState(() {
          kills = wounds;
        });
      },
      child: const Text("Calculate")
    ));
    s.add(Text("$kills"));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: s,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
