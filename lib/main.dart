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
  
  // Audio players - eat sy death ihany
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
          await _eatSound.stop(); // Stop previous if playing
          await _eatSound.play(AssetSource('sounds/eat.wav'));
          break;
        case 'death':
          await _deathSound.stop();
          await _deathSound.play(AssetSource('sounds/death.wav'));
          break;
      }
    } catch (e) {
      // Tsy misy sound file - tsy maninona
      print('Sound not found: $e');
    }
  }

  void _loadBestScore() async {
    // Raha misy SharedPreferences dia ao no alaina
    // bestScore = prefs.getInt('bestScore') ?? 0;
  }

  void _saveBestScore() async {
    // prefs.setInt('bestScore', bestScore);
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

      // Wall collision
      if (newHead.dx < 0 || newHead.dx >= gridSize || 
          newHead.dy < 0 || newHead.dy >= gridSize) {
        gameOver();
        return;
      }

      // Self collision
      if (snake.contains(newHead)) {
        gameOver();
        return;
      }

      snake.insert(0, newHead);

      // Food eaten
      if (newHead == food) {
        score += 10;
        isEating = true;
        _playSound('eat'); // Play eat sound
        
        eatingController?.forward().then((_) {
          eatingController?.reverse();
          setState(() {
            isEating = false;
          });
        });
        
        generateFood();
        
        // Speed increase every 50 points
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
    _playSound('death'); // Play death sound
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
    // Prevent 180 degree turns
    if ((lastDirection == 'up' && newDirection == 'down') ||
        (lastDirection == 'down' && newDirection == 'up') ||
        (lastDirection == 'left' && newDirection == 'right') ||
        (lastDirection == 'right' && newDirection == 'left')) {
      return;
    }
    direction = newDirection;
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
            // Header
            _buildHeader(isSmallScreen),
            
            // Game Grid
            Expanded(
              child: _buildGameGrid(screenSize),
            ),
            
            // Controls
            if (!isPlaying)
              _buildStartButton()
            else
              _buildGameControls(isSmallScreen),
              
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🐍 SNAKE 3D',
                    style: TextStyle(
                      fontSize: isSmall ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.green.withOpacity(0.8), blurRadius: 10)
                      ]
                    ),
                  ),
                  Text(
                    'Score: $score',
                    style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: isSmall ? 20 : 24),
                    SizedBox(width: 5),
                    Text(
                      '$bestScore',
                      style: TextStyle(
                        fontSize: isSmall ? 18 : 22,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  size: isSmall ? 24 : 28,
                ),
                onPressed: () {
                  setState(() {
                    soundEnabled = !soundEnabled;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(Size screenSize) {
    return GestureDetector(
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
          gradient: RadialGradient(
            colors: [Color(0xFF1a237e), Color(0xFF0a0e27)],
            center: Alignment.center,
            radius: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.5),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
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

              if (isHead) {
                return _buildSnakeHead();
              } else if (isSnake) {
                return _buildSnakeBody(snakeIndex);
              } else if (isFood) {
                return _buildFood();
              }

              return Container(
                margin: EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
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
        double scale = 1.0 + (eatingController!.value * 0.3);
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: EdgeInsets.all(1),
            child: Image.asset(
              'snake_asset/head_${direction}.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.green[300]!, Colors.green[700]!],
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
        double pulse = 0.95 + (sin(pulsePhase * 2 * pi) * 0.05);
        
        String bodyType = 'body_vertical';
        if (index > 0 && index < snake.length - 1) {
          Offset current = snake[index];
          Offset prev = snake[index - 1];
          Offset next = snake[index + 1];
          
          // Detect body orientation
          if ((prev.dx == next.dx) || (prev.dy == next.dy)) {
            bodyType = (prev.dx == next.dx) ? 'body_vertical' : 'body_horizontal';
          }
        }
        
        return Transform.scale(
          scale: pulse,
          child: Container(
            margin: EdgeInsets.all(1),
            child: Image.asset(
              'snake_asset/$bodyType.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[800]!],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 4,
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

  Widget _buildFood() {
    return AnimatedBuilder(
      animation: bodyAnimController!,
      builder: (context, child) {
        double scale = 1.0 + (sin(bodyAnimController!.value * 2 * pi) * 0.2);
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: EdgeInsets.all(2),
            child: Image.asset(
              'snake_asset/rabbit.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.red[400]!, Colors.red[800]!],
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton.icon(
        onPressed: startGame,
        icon: Icon(Icons.play_arrow, size: 32, color: Colors.white),
        label: Text(
          'MANOMBOKA HILALAO',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          shadowColor: Colors.green.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildGameControls(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Up button
          _buildControlButton(
            icon: Icons.arrow_upward,
            onPressed: () => changeDirection('up'),
          ),
          SizedBox(height: 10),
          // Left, Down, Right buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.arrow_back,
                onPressed: () => changeDirection('left'),
              ),
              SizedBox(width: 20),
              _buildControlButton(
                icon: Icons.arrow_downward,
                onPressed: () => changeDirection('down'),
              ),
              SizedBox(width: 20),
              _buildControlButton(
                icon: Icons.arrow_forward,
                onPressed: () => changeDirection('right'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.5),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: CircleBorder(),
          child: Container(
            padding: EdgeInsets.all(15),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}