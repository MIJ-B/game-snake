import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(SnakeApp());

class SnakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game 3D',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      home: SnakeGame(),
    );
  }
}

class SnakeGame extends StatefulWidget {
  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  static const int gridSize = 20;
  List<Offset> snake = [Offset(5, 5)];
  Offset food = Offset(10, 10);
  String direction = 'right';
  bool isPlaying = false;
  int score = 0;
  int bestScore = 0;
  Timer? timer;
  bool isEating = false;
  AnimationController? eatingController;
  AnimationController? bodyAnimController;

  @override
  void initState() {
    super.initState();
    generateFood();
    
    eatingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    bodyAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
  }

  void startGame() {
    snake = [Offset(5, 5)];
    direction = 'right';
    score = 0;
    isPlaying = true;
    generateFood();

    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      moveSnake();
    });
  }

  void moveSnake() {
    setState(() {
      Offset newHead = snake.first;

      switch (direction) {
        case 'up':
          newHead = Offset(newHead.dx, newHead.dy - 1);
          break;
        case 'down':
          newHead = Offset(newHead.dx, newHead.dy + 1);
          break;
        case 'left':
          newHead = Offset(newHead.dx - 1, newHead.dy);
          break;
        case 'right':
          newHead = Offset(newHead.dx + 1, newHead.dy);
          break;
      }

      if (newHead.dx < 0 || newHead.dx >= gridSize || 
          newHead.dy < 0 || newHead.dy >= gridSize) {
        gameOver();
        return;
      }

      if (snake.contains(newHead)) {
        gameOver();
        return;
      }

      snake.insert(0, newHead);

      if (newHead == food) {
        score += 10;
        isEating = true;
        eatingController?.forward().then((_) {
          eatingController?.reverse();
          setState(() {
            isEating = false;
          });
        });
        generateFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void generateFood() {
    Random random = Random();
    Offset newFood;
    do {
      newFood = Offset(
        random.nextInt(gridSize).toDouble(),
        random.nextInt(gridSize).toDouble(),
      );
    } while (snake.contains(newFood));

    food = newFood;
  }

  void gameOver() {
    timer?.cancel();
    isPlaying = false;
    
    // Update best score
    if (score > bestScore) {
      setState(() {
        bestScore = score;
      });
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Game Over!', style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score', style: TextStyle(fontSize: 24, color: Colors.white)),
            SizedBox(height: 10),
            Text('Meilleur Score: $bestScore', style: TextStyle(fontSize: 20, color: Colors.amber)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              startGame();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Hilalao indray', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    eatingController?.dispose();
    bodyAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Snake 3D', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Score: $score', style: TextStyle(fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.green[800],
        elevation: 10,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            color: Colors.grey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                SizedBox(width: 10),
                Text('Meilleur Score: $bestScore', 
                  style: TextStyle(fontSize: 20, color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (direction != 'up' && details.delta.dy > 0) {
                  direction = 'down';
                } else if (direction != 'down' && details.delta.dy < 0) {
                  direction = 'up';
                }
              },
              onHorizontalDragUpdate: (details) {
                if (direction != 'left' && details.delta.dx > 0) {
                  direction = 'right';
                } else if (direction != 'right' && details.delta.dx < 0) {
                  direction = 'left';
                }
              },
              child: Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, index) {
                      int x = index % gridSize;
                      int y = index ~/ gridSize;
                      Offset position = Offset(x.toDouble(), y.toDouble());

                      bool isSnake = snake.contains(position);
                      bool isFood = position == food;
                      bool isHead = position == snake.first;
                      bool isTail = snake.length > 1 && position == snake.last;
                      
                      int snakeIndex = snake.indexOf(position);
                      bool isBody = isSnake && !isHead && !isTail;

                      if (isHead) {
                        return AnimatedBuilder(
                          animation: eatingController!,
                          builder: (context, child) {
                            double scale = 1.0 + (eatingController!.value * 0.3);
                            return Transform.scale(
                              scale: scale,
                              child: SnakeHead(direction: direction, isEating: isEating),
                            );
                          },
                        );
                      } else if (isBody) {
                        return AnimatedBuilder(
                          animation: bodyAnimController!,
                          builder: (context, child) {
                            double pulsePhase = (bodyAnimController!.value + (snakeIndex / snake.length)) % 1.0;
                            double pulse = 0.95 + (sin(pulsePhase * 2 * pi) * 0.05);
                            return Transform.scale(
                              scale: pulse,
                              child: SnakeBody(),
                            );
                          },
                        );
                      } else if (isTail) {
                        return SnakeTail();
                      } else if (isFood) {
                        return FoodWidget();
                      }

                      return Container(
                        margin: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (!isPlaying)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: startGame,
                child: Text('MANOMBOKA HILALAO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 10,
                  shadowColor: Colors.green.withOpacity(0.5),
                ),
              ),
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class SnakeHead extends StatelessWidget {
  final String direction;
  final bool isEating;

  SnakeHead({required this.direction, required this.isEating});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.green[400]!, Colors.green[800]!],
          center: Alignment(-0.3, -0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Maso
          Positioned(
            top: 3,
            left: direction == 'right' ? 8 : direction == 'left' ? 2 : 3,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white, blurRadius: 2)],
                  ),
                ),
                SizedBox(width: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white, blurRadius: 2)],
                  ),
                ),
              ],
            ),
          ),
          // Vava
          Positioned(
            bottom: 3,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: isEating ? 10 : 6,
                height: isEating ? 3 : 2,
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SnakeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green[500]?.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class SnakeTail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[900]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}

class FoodWidget extends StatefulWidget {
  @override
  _FoodWidgetState createState() => _FoodWidgetState();
}

class _FoodWidgetState extends State<FoodWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.2),
          child: Container(
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.red[400]!, Colors.red[800]!],
                center: Alignment(-0.3, -0.3),
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.8),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}