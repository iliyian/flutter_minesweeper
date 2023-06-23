import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() {
    return _MainAppState();
  }
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Minesweeper",
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class Grid {
  int x;
  int y;
  int value = 0;
  bool sweeped = false;
  bool hasMine = false;
  bool flagged = false;

  Grid(this.x, this.y);
}

class _HomePageState extends State<HomePage> {
  var grids = <Grid>[];
  bool gameLost = false;
  bool gameWon = false;
  bool firstMined = true;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  bool _checkGrid(x, y, forMine) {
    if (!_inRange(x, y)) {
      return false;
    }
    if (forMine && grids[x * 10 + y].hasMine) {
      return true;
    } else if (!forMine && grids[x * 10 + y].flagged) {
      return true;
    }
    return false;
  }

  void _newGame() {
    gameLost = false;
    grids = <Grid>[];
    firstMined = true;
    gameWon = false;
    for (var i = 0; i < 100; i++) {
      var grid = Grid(i ~/ 10, i % 10);
      grids.add(grid);
      if (Random().nextDouble() <= 0.15) {
        grid.hasMine = true;
      }
    }
    for (var i = 0; i < 100; i++) {
      var grid = grids[i];
      var x = i ~/ 10, y = i % 10;
      grid.value = _getNearbyCount(x, y, true);
    }
    setState(() {});
  }

  void _press(Grid g) {
    if (gameLost) {
      return;
    }
    if (firstMined && g.hasMine) {
      _newGame();
      var g0 = grids[g.x * 10 + g.y];
      _press(g0);
      return;
    }
    firstMined = false;
    print("Pressed ${g.x} ${g.y}");
    setState(() {
      if (g.hasMine) {
        _loseGame();
      } else {
        _expose(g.x, g.y);
      }
      _checkWin();
    });
  }

  void _loseGame() {
    print("Game lost.");
    gameLost = true;
    for (var g in grids) {
      if (g.hasMine) {
        g.sweeped = true;
      }
    }
    AlertDialog(title: const Text("提示"), content: const Text("游戏结束"), actions: [
      TextButton(
        child: const Text("重新开始"),
        onPressed: () {
          _newGame();
        },
      )
    ]);
    setState(() {});
  }

  void _expose(int x, int y) {
    if (!_inRange(x, y)) return;
    print("Try to expose $x $y");
    var grid = grids[x * 10 + y];
    if (grid.sweeped) {
      return;
    } else {
      grid.sweeped = true;
      if (grid.value == 0) {
        _expose(x - 1, y - 1);
        _expose(x - 1, y);
        _expose(x - 1, y + 1);
        _expose(x, y - 1);
        _expose(x, y + 1);
        _expose(x + 1, y - 1);
        _expose(x + 1, y);
        _expose(x + 1, y + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            height: 600,
            width: 600,
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primaryContainer)),
              child: _getGrids(context),
            ),
          ),
          Expanded(
            child: Center(
                child: ElevatedButton.icon(
                    icon: _getButtonIcon(),
                    style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.primary),
                        iconColor:
                            const MaterialStatePropertyAll(Colors.white)),
                    onPressed: _newGame,
                    label: _getButtonText())),
          )
        ],
      ),
    );
  }

  Icon _getButtonIcon() {
    if (gameLost) {
      return const Icon(Icons.restart_alt);
    } else if (gameWon) {
      return const Icon(Icons.star);
    } else {
      return const Icon(Icons.nightlight_round);
    }
  }

  Text _getButtonText() {
    var str = "";
    if (gameLost) {
      str = "Game Lost!";
    } else if (gameWon) {
      str = "Game Won!";
    } else {
      str = "New Game";
    }
    return Text(str, style: const TextStyle(color: Colors.white));
  }

  GridView _getGrids(BuildContext context) {
    return GridView.count(
      crossAxisCount: 10,
      children: [
        for (var grid in grids)
          GridTile(
              child: Container(
            decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).colorScheme.secondary),
                borderRadius: const BorderRadius.all(Radius.circular(2.0))),
            child: TextButton(
                key: Key("${grid.x}|${grid.y}"),
                onPressed: () {
                  _press(grid);
                },
                onLongPress: () {
                  _longPress(grid);
                },
                child: _getGridWidget(grid)),
          )),
      ],
    );
  }

  int _getNearbyCount(x, y, forMine) {
    var count = 0;
    for (var i = -1; i <= 1; i++) {
      for (var j = -1; j <= 1; j++) {
        if ((i != 0 || j != 0) && _checkGrid(x + i, y + j, forMine)) {
          count++;
        }
      }
    }
    return count;
  }

  void _longPress(Grid g) {
    if (!g.sweeped) {
      g.flagged = !g.flagged;
    } else if (g.value != 0) {
      var x = g.x, y = g.y;
      for (var i = -1; i <= 1; i++) {
        for (var j = -1; j <= 1; j++) {
          if ((i != 0 || j != 0) && _inRange(x + i, y + j)) {
            var g0 = grids[(x + i) * 10 + y + j];
            if (g0.flagged != g0.hasMine) {
              return;
            }
          }
        }
      }
      for (var i = -1; i <= 1; i++) {
        for (var j = -1; j <= 1; j++) {
          if ((i != 0 || j != 0) && _inRange(x + i, y + j)) {
            var g0 = grids[(x + i) * 10 + y + j];
            if (!g0.flagged) {
              _expose(g0.x, g0.y);
            }
          }
        }
      }
    }
    _checkWin();
    setState(() {});
  }

  void _checkWin() {
    for (var g in grids) {
      if (g.flagged != g.hasMine) {
        return;
      }
    }
    gameWon = true;
    setState(() {});
  }

  Widget _getGridWidget(Grid grid) {
    if (grid.sweeped) {
      if (grid.hasMine) {
        return const Icon(Icons.sunny);
      } else {
        if (grid.value == 0) {
          return const Text(" ");
        } else {
          return Text("${grid.value}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold));
        }
      }
    } else if (grid.flagged) {
      return const Icon(Icons.flag);
    } else {
      return const Text("<>",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold));
    }
  }

  bool _inRange(int x, int y) {
    if (x < 0 || x >= 10 || y < 0 || y >= 10) {
      return false;
    }
    return true;
  }
}
