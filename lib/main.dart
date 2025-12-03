import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(SnakeApp());

class SnakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game',
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

class _SnakeGameState extends State<SnakeGame> {
  static const int gridSize = 20;
  List<Offset> snake = [Offset(5, 5)];
  Offset food = Offset(10, 10);
  String direction = 'right';
  String? nextDirection;
  bool isPlaying = false;
  int score = 0;
  int bestScore = 0;
  Timer? timer;
  final AudioPlayer eatPlayer = AudioPlayer();
  final AudioPlayer deathPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    generateFood();
  }

  void startGame() {
    setState(() {
      snake = [Offset(5, 5)];
      direction = 'right';
      nextDirection = null;
      score = 0;
      isPlaying = true;
      generateFood();
    });

    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: 150), (timer) {
      moveSnake();
    });
  }

  void moveSnake() {
    if (nextDirection != null) {
      direction = nextDirection!;
      nextDirection = null;
    }

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

      // Check wall collision
      if (newHead.dx < 0 || newHead.dx >= gridSize || 
          newHead.dy < 0 || newHead.dy >= gridSize) {
        gameOver();
        return;
      }

      // Check self collision
      if (snake.contains(newHead)) {
        gameOver();
        return;
      }

      snake.insert(0, newHead);

      // Check food collision
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

    setState(() {
      food = newFood;
    });
  }

  void playEatSound() async {
    try {
      await eatPlayer.play(AssetSource('sounds/eat.wav'));
    } catch (e) {
      print('Error playing eat sound: $e');
    }
  }

  void playDeathSound() async {
    try {
      await deathPlayer.play(AssetSource('sounds/death.wav'));
    } catch (e) {
      print('Error playing death sound: $e');
    }
  }

  void gameOver() {
    timer?.cancel();
    playDeathSound();
    
    setState(() {
      isPlaying = false;
      if (score > bestScore) {
        bestScore = score;
      }
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Game Over!', 
          style: TextStyle(
            color: Colors.red, 
            fontSize: 28, 
            fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score', 
              style: TextStyle(fontSize: 24, color: Colors.white)
            ),
            SizedBox(height: 10),
            Text(
              'Meilleur Score: $bestScore', 
              style: TextStyle(fontSize: 20, color: Colors.amber)
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
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
                child: Text(
                  'Hilalao indray', 
                  style: TextStyle(color: Colors.white, fontSize: 18)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void changeDirection(String newDirection) {
    // Prevent 180 degree turns
    if ((direction == 'up' && newDirection == 'down') ||
        (direction == 'down' && newDirection == 'up') ||
        (direction == 'left' && newDirection == 'right') ||
        (direction == 'right' && newDirection == 'left')) {
      return;
    }
    nextDirection = newDirection;
  }

  String getHeadSprite() {
    return 'snake_asset/head_${direction}.png';
  }

  String getBodySprite(int index) {
    if (index == snake.length - 1) {
      // Tail
      Offset current = snake[index];
      Offset previous = snake[index - 1];
      
      if (previous.dx < current.dx) return 'snake_asset/tail_left.png';
      if (previous.dx > current.dx) return 'snake_asset/tail_right.png';
      if (previous.dy < current.dy) return 'snake_asset/tail_up.png';
      return 'snake_asset/tail_down.png';
    }
    
    // Body segments
    Offset previous = index > 0 ? snake[index - 1] : snake[index];
    Offset current = snake[index];
    Offset next = index < snake.length - 1 ? snake[index + 1] : snake[index];
    
    bool horizontalBefore = previous.dy == current.dy;
    bool horizontalAfter = next.dy == current.dy;
    bool verticalBefore = previous.dx == current.dx;
    bool verticalAfter = next.dx == current.dx;
    
    // Straight segments
    if (horizontalBefore && horizontalAfter) {
      return 'snake_asset/body_horizontal.png';
    }
    if (verticalBefore && verticalAfter) {
      return 'snake_asset/body_vertical.png';
    }
    
    // Corner segments
    if ((previous.dx < current.dx && next.dy < current.dy) ||
        (previous.dy < current.dy && next.dx < current.dx)) {
      return 'snake_asset/body_topleft.png';
    }
    if ((previous.dx > current.dx && next.dy < current.dy) ||
        (previous.dy < current.dy && next.dx > current.dx)) {
      return 'snake_asset/body_topright.png';
    }
    if ((previous.dx < current.dx && next.dy > current.dy) ||
        (previous.dy > current.dy && next.dx < current.dx)) {
      return 'snake_asset/body_bottomleft.png';
    }
    if ((previous.dx > current.dx && next.dy > current.dy) ||
        (previous.dy > current.dy && next.dx > current.dx)) {
      return 'snake_asset/bodybottomright.png';
    }
    
    return 'snake_asset/body_horizontal.png';
  }

  @override
  void dispose() {
    timer?.cancel();
    eatPlayer.dispose();
    deathPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Score Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: Colors.grey[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Score: $score',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Best: $bestScore',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Game Board
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (!isPlaying) return;
                      if (details.delta.dy > 5) {
                        changeDirection('down');
                      } else if (details.delta.dy < -5) {
                        changeDirection('up');
                      }
                    },
                    onHorizontalDragUpdate: (details) {
                      if (!isPlaying) return;
                      if (details.delta.dx > 5) {
                        changeDirection('right');
                      } else if (details.delta.dx < -5) {
                        changeDirection('left');
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
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

                            int snakeIndex = snake.indexOf(position);
                            bool isSnake = snakeIndex != -1;
                            bool isFood = position == food;
                            bool isHead = position == snake.first;

                            if (isHead) {
                              return Container(
                                margin: EdgeInsets.all(0.5),
                                child: Image.asset(
                                  getHeadSprite(),
                                  fit: BoxFit.fill,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.green[400],
                                      child: Icon(Icons.error, size: 10),
                                    );
                                  },
                                ),
                              );
                            } else if (isSnake) {
                              return Container(
                                margin: EdgeInsets.all(0.5),
                                child: Image.asset(
                                  getBodySprite(snakeIndex),
                                  fit: BoxFit.fill,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.green[600],
                                    );
                                  },
                                ),
                              );
                            } else if (isFood) {
                              return Container(
                                margin: EdgeInsets.all(2),
                                child: Image.asset(
                                  'snake_asset/rabbit.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                              );
                            }

                            return Container(
                              margin: EdgeInsets.all(0.5),
                              child: Image.asset(
                                'snake_asset/grass.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.green[900],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Start Button
            if (!isPlaying)
              Padding(
                padding: EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 10,
                  ),
                  child: Text(
                    'MANOMBOKA HILALAO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            
            // Control Buttons for Mobile
            if (isPlaying && isPortrait)
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Up button
                    IconButton(
                      onPressed: () => changeDirection('up'),
                      icon: Icon(Icons.arrow_drop_up),
                      iconSize: 60,
                      color: Colors.green,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left button
                        IconButton(
                          onPressed: () => changeDirection('left'),
                          icon: Icon(Icons.arrow_left),
                          iconSize: 60,
                          color: Colors.green,
                        ),
                        SizedBox(width: 60),
                        // Right button
                        IconButton(
                          onPressed: () => changeDirection('right'),
                          icon: Icon(Icons.arrow_right),
                          iconSize: 60,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    // Down button
                    IconButton(
                      onPressed: () => changeDirection('down'),
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 60,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}