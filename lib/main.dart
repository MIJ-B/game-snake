import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(SnakeApp());
}

class SnakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
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
  String lastDirection = 'right';
  bool isPlaying = false;
  int score = 0;
  int bestScore = 0;
  Timer? timer;
  bool isEating = false;
  AnimationController? eatingController;
  AnimationController? bodyAnimController;
  AnimationController? gameOverController;
  
  final AudioPlayer _eatSound = AudioPlayer();
  final AudioPlayer _deathSound = AudioPlayer();
  
  bool soundEnabled = true;
  int gameSpeed = 200;

  @override
  void initState() {
    super.initState();
    generateFood();
    _loadBestScore();
    
    eatingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    bodyAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();

    gameOverController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }

  void _playSound(String sound) async {
    if (!soundEnabled) return;
    
    try {
      switch (sound) {
        case 'eat':
          await _eatSound.stop();
          await _eatSound.play(AssetSource('sounds/eat.wav'));
          break;
        case 'death':
          await _deathSound.stop();
          await _deathSound.play(AssetSource('sounds/death.wav'));
          break;
      }
    } catch (e) {
      print('Sound not found: $e');
    }
  }

  void _loadBestScore() async {
    // SharedPreferences implementation here
  }

  void _saveBestScore() async {
    // SharedPreferences implementation here
  }

  void startGame() {
    setState(() {
      snake = [Offset(5, 5)];
      direction = 'right';
      lastDirection = 'right';
      score = 0;
      isPlaying = true;
      gameSpeed = 200;
    });
    
    generateFood();

    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: gameSpeed), (timer) {
      moveSnake();
    });
  }

  void moveSnake() {
    setState(() {
      lastDirection = direction;
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
        _playSound('eat');
        
        eatingController?.forward().then((_) {
          eatingController?.reverse();
          setState(() {
            isEating = false;
          });
        });
        
        generateFood();
        
        if (score % 50 == 0 && gameSpeed > 100) {
          gameSpeed -= 20;
          timer?.cancel();
          timer = Timer.periodic(Duration(milliseconds: gameSpeed), (timer) {
            moveSnake();
          });
        }
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
    _playSound('death');
    gameOverController?.forward();
    
    if (score > bestScore) {
      setState(() {
        bestScore = score;
      });
      _saveBestScore();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: gameOverController!, curve: Curves.elasticOut)
        ),
        child: AlertDialog(
          backgroundColor: Colors.grey[900]?.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withOpacity(0.5), width: 2)
          ),
          title: Column(
            children: [
              Icon(Icons.sentiment_dissatisfied, color: Colors.red, size: 50),
              SizedBox(height: 10),
              Text(
                'Game Over!', 
                style: TextStyle(
                  color: Colors.red, 
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.red.withOpacity(0.5), blurRadius: 10)
                  ]
                )
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('SCORE', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('$score', style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                    SizedBox(width: 10),
                    Column(
                      children: [
                        Text('MEILLEUR', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('$bestScore', style: TextStyle(fontSize: 24, color: Colors.amber, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  gameOverController?.reverse();
                  startGame();
                },
                icon: Icon(Icons.replay, color: Colors.white),
                label: Text(
                  'HILALAO INDRAY', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void changeDirection(String newDirection) {
    if ((lastDirection == 'up' && newDirection == 'down') ||
        (lastDirection == 'down' && newDirection == 'up') ||
        (lastDirection == 'left' && newDirection == 'right') ||
        (lastDirection == 'right' && newDirection == 'left')) {
      return;
    }
    direction = newDirection;
  }

  // Function to get body part type and rotation
  String _getBodyPartImage(int index) {
    if (index >= snake.length - 1) {
      // Tail
      Offset current = snake[index];
      Offset previous = snake[index - 1];
      
      if (previous.dx < current.dx) return 'snake_asset/tail_left.png';
      if (previous.dx > current.dx) return 'snake_asset/tail_right.png';
      if (previous.dy < current.dy) return 'snake_asset/tail_up.png';
      if (previous.dy > current.dy) return 'snake_asset/tail_down.png';
      return 'snake_asset/tail_right.png';
    }
    
    // Middle body segments
    if (index > 0 && index < snake.length - 1) {
      Offset current = snake[index];
      Offset prev = snake[index - 1];
      Offset next = snake[index + 1];
      
      // Check for corners
      bool isCorner = (prev.dx != next.dx && prev.dy != next.dy);
      
      if (isCorner) {
        // Determine corner type
        if ((prev.dx < current.dx && next.dy > current.dy) || (next.dx < current.dx && prev.dy > current.dy)) {
          return 'snake_asset/body_bottomleft.png';
        }
        if ((prev.dx > current.dx && next.dy > current.dy) || (next.dx > current.dx && prev.dy > current.dy)) {
          return 'snake_asset/bodybottomright.png';
        }
        if ((prev.dx < current.dx && next.dy < current.dy) || (next.dx < current.dx && prev.dy < current.dy)) {
          return 'snake_asset/body_topleft.png';
        }
        if ((prev.dx > current.dx && next.dy < current.dy) || (next.dx > current.dx && prev.dy < current.dy)) {
          return 'snake_asset/body_topright.png';
        }
      }
      
      // Straight segments
      if (prev.dx == next.dx) {
        return 'snake_asset/body_vertical.png';
      } else {
        return 'snake_asset/body_horizontal.png';
      }
    }
    
    return 'snake_asset/body_horizontal.png';
  }

  @override
  void dispose() {
    timer?.cancel();
    eatingController?.dispose();
    bodyAnimController?.dispose();
    gameOverController?.dispose();
    _eatSound.dispose();
    _deathSound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
    return Scaffold(
      backgroundColor: Color(0xFF0a0e27),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header
            _buildCompactHeader(isSmallScreen),
            
            // Fullscreen Game Grid
            Expanded(
              child: _buildFullscreenGameGrid(screenSize),
            ),
            
            // Start Button (only when not playing)
            if (!isPlaying)
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: _buildStartButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score
          Row(
            children: [
              Text(
                '🐍',
                style: TextStyle(fontSize: isSmall ? 20 : 24),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: isSmall ? 10 : 12,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: isSmall ? 18 : 22,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Best Score
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: isSmall ? 16 : 20),
                SizedBox(width: 5),
                Text(
                  '$bestScore',
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 20,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Sound Toggle
          IconButton(
            icon: Icon(
              soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
              size: isSmall ? 20 : 24,
            ),
            onPressed: () {
              setState(() {
                soundEnabled = !soundEnabled;
              });
            },
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenGameGrid(Size screenSize) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (!isPlaying) return;
        if (details.delta.dy > 3) {
          changeDirection('down');
        } else if (details.delta.dy < -3) {
          changeDirection('up');
        }
      },
      onHorizontalDragUpdate: (details) {
        if (!isPlaying) return;
        if (details.delta.dx > 3) {
          changeDirection('right');
        } else if (details.delta.dx < -3) {
          changeDirection('left');
        }
      },
      child: Container(
        margin: EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isPlaying ? Colors.cyan.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isPlaying ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
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
              
              int snakeIndex = snake.indexOf(position);

              // Background (grass)
              if (!isSnake && !isFood) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('snake_asset/grass.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }

              if (isHead) {
                return _buildSnakeHead();
              } else if (isSnake) {
                return _buildSnakeBody(snakeIndex);
              } else if (isFood) {
                return _buildFood();
              }

              return Container();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSnakeHead() {
    return AnimatedBuilder(
      animation: eatingController!,
      builder: (context, child) {
        double scale = 1.0 + (eatingController!.value * 0.2);
        return Transform.scale(
          scale: scale,
          child: Container(
            child: Image.asset(
              'snake_asset/head_${direction}.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.green[300]!, Colors.green[700]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSnakeBody(int index) {
    return AnimatedBuilder(
      animation: bodyAnimController!,
      builder: (context, child) {
        double pulsePhase = (bodyAnimController!.value + (index / snake.length)) % 1.0;
        double pulse = 0.96 + (sin(pulsePhase * 2 * pi) * 0.04);
        
        String bodyImagePath = _getBodyPartImage(index);
        
        return Transform.scale(
          scale: pulse,
          child: Container(
            child: Image.asset(
              bodyImagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[800]!],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFood() {
    return AnimatedBuilder(
      animation: bodyAnimController!,
      builder: (context, child) {
        double scale = 1.0 + (sin(bodyAnimController!.value * 2 * pi) * 0.15);
        return Transform.scale(
          scale: scale,
          child: Container(
            child: Image.asset(
              'snake_asset/rabbit.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.red[400]!, Colors.red[800]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      onPressed: startGame,
      icon: Icon(Icons.play_arrow, size: 28, color: Colors.white),
      label: Text(
        'MANOMBOKA',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
        backgroundColor: Colors.green[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        shadowColor: Colors.green.withOpacity(0.5),
      ),
    );
  }
}