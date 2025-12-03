import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String nextDirection = 'right';
  bool isPlaying = false;
  int score = 0;
  int highScore = 0;
  Timer? timer;
  final AudioPlayer audioPlayer = AudioPlayer();
  late AnimationController mouthController;
  late Animation<double> mouthAnimation;
  bool isMouthOpen = false;

  @override
  void initState() {
    super.initState();
    generateFood();
    loadHighScore();
    
    // Animation pour la bouche
    mouthController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    mouthAnimation = Tween<double>(begin: 0, end: 1).animate(mouthController);
  }

  Future<void> loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> saveHighScore() async {
    if (score > highScore) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void playEatSound() {
    // Animation de la bouche
    mouthController.forward().then((_) => mouthController.reverse());
    
    // Son de manger (utilise un beep court)
    try {
      audioPlayer.play(AssetSource('eat.mp3'));
    } catch (e) {
      // Si pas de fichier audio, utilise HapticFeedback
      HapticFeedback.mediumImpact();
    }
  }

  void startGame() {
    snake = [Offset(5, 5)];
    direction = 'right';
    nextDirection = 'right';
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
      direction = nextDirection;
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

      // Check collision avec mur
      if (newHead.dx < 0 || newHead.dx >= gridSize || 
          newHead.dy < 0 || newHead.dy >= gridSize) {
        gameOver();
        return;
      }

      // Check collision avec le corps
      if (snake.contains(newHead)) {
        gameOver();
        return;
      }

      snake.insert(0, newHead);

      // Check si mange la nourriture
      if (newHead == food) {
        score += 10;
        playEatSound();
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
    saveHighScore();
    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'GAME OVER!',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'Meilleur Score: $highScore',
              style: TextStyle(fontSize: 18, color: Colors.amber),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              startGame();
            },
            child: Text('JOUER ENCORE', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void changeDirection(String newDirection) {
    // Empêche le retour en arrière
    if (direction == 'up' && newDirection == 'down') return;
    if (direction == 'down' && newDirection == 'up') return;
    if (direction == 'left' && newDirection == 'right') return;
    if (direction == 'right' && newDirection == 'left') return;
    
    nextDirection = newDirection;
  }

  @override
  void dispose() {
    timer?.cancel();
    mouthController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Snake Game 3D'),
        centerTitle: true,
        backgroundColor: Colors.green[900],
      ),
      body: Column(
        children: [
          // Score display
          Container(
            padding: EdgeInsets.all(15),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('SCORE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('$score', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 2, height: 40, color: Colors.grey),
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 5),
                        Text('MEILLEUR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Text('$highScore', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          // Game grid
          Expanded(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0) {
                  changeDirection('down');
                } else if (details.delta.dy < 0) {
                  changeDirection('up');
                }
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0) {
                  changeDirection('right');
                } else if (details.delta.dx < 0) {
                  changeDirection('left');
                }
              },
              child: Container(
                color: Colors.black,
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

                    bool isHead = position == snake.first;
                    bool isBody = snake.skip(1).take(snake.length - 2).contains(position);
                    bool isTail = snake.length > 1 && position == snake.last;
                    bool isFood = position == food;

                    if (isHead) {
                      return SnakeHead(direction: direction, mouthAnimation: mouthAnimation);
                    } else if (isBody) {
                      return SnakeBody();
                    } else if (isTail) {
                      return SnakeTail();
                    } else if (isFood) {
                      return Food();
                    } else {
                      return Container(
                        margin: EdgeInsets.all(0.5),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          border: Border.all(color: Colors.grey[800]!, width: 0.5),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          
          // Controls
          if (!isPlaying)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: startGame,
                child: Text('COMMENCER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      ControlButton(
                        icon: Icons.arrow_upward,
                        onPressed: () => changeDirection('up'),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          ControlButton(
                            icon: Icons.arrow_back,
                            onPressed: () => changeDirection('left'),
                          ),
                          SizedBox(width: 100),
                          ControlButton(
                            icon: Icons.arrow_forward,
                            onPressed: () => changeDirection('right'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ControlButton(
                        icon: Icons.arrow_downward,
                        onPressed: () => changeDirection('down'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SnakeHead extends StatelessWidget {
  final String direction;
  final Animation<double> mouthAnimation;

  SnakeHead({required this.direction, required this.mouthAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mouthAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: direction == 'right' ? 0 : 
                 direction == 'down' ? pi / 2 : 
                 direction == 'left' ? pi : 
                 -pi / 2,
          child: Container(
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.green[400]!, Colors.green[800]!],
              ),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Yeux
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                  ),
                ),
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                  ),
                ),
                // Bouche
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 3 + (mouthAnimation.value * 2),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SnakeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 5,
          ),
        ],
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
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class Food extends StatefulWidget {
  @override
  _FoodState createState() => _FoodState();
}

class _FoodState extends State<Food> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.red[400]!, Colors.red[800]!],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.green[700],
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 60,
          height: 60,
          child: Icon(icon, size: 35, color: Colors.white),
        ),
      ),
    );
  }
}