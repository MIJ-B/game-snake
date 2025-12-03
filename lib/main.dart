import React, { useState, useEffect, useRef, useCallback } from 'react';

const GRID_SIZE = 20;

// Audio synthesis functions
const playEatSound = () => {
  try {
    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(400, audioContext.currentTime + 0.1);
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.1);
  } catch (e) {
    console.log('Audio not supported');
  }
};

const playDeathSound = () => {
  try {
    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.setValueAtTime(400, audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(100, audioContext.currentTime + 0.3);
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.3);
  } catch (e) {
    console.log('Audio not supported');
  }
};

const SnakeGame = () => {
  const [snake, setSnake] = useState([{ x: 10, y: 10 }]);
  const [food, setFood] = useState({ x: 15, y: 15 });
  const [direction, setDirection] = useState({ x: 1, y: 0 });
  const [nextDirection, setNextDirection] = useState({ x: 1, y: 0 });
  const [gameOver, setGameOver] = useState(false);
  const [score, setScore] = useState(0);
  const [bestScore, setBestScore] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isEating, setIsEating] = useState(false);
  const [assetsPath] = useState('/snake_asset');
  const gameLoopRef = useRef(null);

  // Determine body segment type based on adjacent segments
  const getBodySegmentType = (index) => {
    if (index === 0) {
      // Head
      const dir = getHeadDirection();
      return `head_${dir}.png`;
    }
    
    if (index === snake.length - 1) {
      // Tail
      const dir = getTailDirection();
      return `tail_${dir}.png`;
    }

    // Body segments
    const prev = snake[index - 1];
    const curr = snake[index];
    const next = snake[index + 1];

    const dx1 = curr.x - prev.x;
    const dy1 = curr.y - prev.y;
    const dx2 = next.x - curr.x;
    const dy2 = next.y - curr.y;

    // Straight segments
    if (dx1 === dx2 && dy1 === dy2) {
      return dx1 !== 0 ? 'body_horizontal.png' : 'body_vertical.png';
    }

    // Corner segments
    if (dx1 === 1 && dy2 === -1) return 'body_bottomleft.png';
    if (dx1 === 1 && dy2 === 1) return 'body_topleft.png';
    if (dx1 === -1 && dy2 === -1) return 'body_bottomright.png';
    if (dx1 === -1 && dy2 === 1) return 'body_topright.png';
    if (dy1 === 1 && dx2 === -1) return 'body_bottomleft.png';
    if (dy1 === 1 && dx2 === 1) return 'body_bottomright.png';
    if (dy1 === -1 && dx2 === -1) return 'body_topleft.png';
    if (dy1 === -1 && dx2 === 1) return 'body_topright.png';

    return 'body_horizontal.png';
  };

  const getTailDirection = () => {
    if (snake.length < 2) return 'right';
    const last = snake[snake.length - 1];
    const secondLast = snake[snake.length - 2];
    const dx = last.x - secondLast.x;
    const dy = last.y - secondLast.y;
    
    if (dx === 1) return 'right';
    if (dx === -1) return 'left';
    if (dy === 1) return 'down';
    if (dy === -1) return 'up';
    return 'right';
  };

  const getHeadDirection = () => {
    if (direction.x === 1) return 'right';
    if (direction.x === -1) return 'left';
    if (direction.y === 1) return 'down';
    if (direction.y === -1) return 'up';
    return 'right';
  };

  const generateFood = useCallback(() => {
    let newFood;
    do {
      newFood = {
        x: Math.floor(Math.random() * GRID_SIZE),
        y: Math.floor(Math.random() * GRID_SIZE)
      };
    } while (snake.some(segment => segment.x === newFood.x && segment.y === newFood.y));
    setFood(newFood);
  }, [snake]);

  const moveSnake = useCallback(() => {
    setSnake(prevSnake => {
      const head = prevSnake[0];
      const newHead = {
        x: head.x + nextDirection.x,
        y: head.y + nextDirection.y
      };

      if (
        newHead.x < 0 || newHead.x >= GRID_SIZE ||
        newHead.y < 0 || newHead.y >= GRID_SIZE ||
        prevSnake.some(segment => segment.x === newHead.x && segment.y === newHead.y)
      ) {
        playDeathSound();
        setGameOver(true);
        setIsPlaying(false);
        if (score > bestScore) {
          setBestScore(score);
        }
        return prevSnake;
      }

      const newSnake = [newHead, ...prevSnake];

      if (newHead.x === food.x && newHead.y === food.y) {
        playEatSound();
        setScore(prev => prev + 10);
        setIsEating(true);
        setTimeout(() => setIsEating(false), 200);
        generateFood();
      } else {
        newSnake.pop();
      }

      return newSnake;
    });

    setDirection(nextDirection);
  }, [nextDirection, food, score, bestScore, generateFood]);

  useEffect(() => {
    if (isPlaying) {
      gameLoopRef.current = setInterval(moveSnake, 150);
      return () => clearInterval(gameLoopRef.current);
    }
  }, [isPlaying, moveSnake]);

  useEffect(() => {
    const handleKeyPress = (e) => {
      if (!isPlaying) return;

      switch (e.key) {
        case 'ArrowUp':
          if (direction.y === 0) setNextDirection({ x: 0, y: -1 });
          break;
        case 'ArrowDown':
          if (direction.y === 0) setNextDirection({ x: 0, y: 1 });
          break;
        case 'ArrowLeft':
          if (direction.x === 0) setNextDirection({ x: -1, y: 0 });
          break;
        case 'ArrowRight':
          if (direction.x === 0) setNextDirection({ x: 1, y: 0 });
          break;
        default:
          break;
      }
    };

    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [direction, isPlaying]);

  const handleTouchStart = useRef({ x: 0, y: 0 });

  const onTouchStart = (e) => {
    handleTouchStart.current = {
      x: e.touches[0].clientX,
      y: e.touches[0].clientY
    };
  };

  const onTouchEnd = (e) => {
    if (!isPlaying) return;

    const deltaX = e.changedTouches[0].clientX - handleTouchStart.current.x;
    const deltaY = e.changedTouches[0].clientY - handleTouchStart.current.y;

    if (Math.abs(deltaX) > Math.abs(deltaY)) {
      if (deltaX > 0 && direction.x === 0) {
        setNextDirection({ x: 1, y: 0 });
      } else if (deltaX < 0 && direction.x === 0) {
        setNextDirection({ x: -1, y: 0 });
      }
    } else {
      if (deltaY > 0 && direction.y === 0) {
        setNextDirection({ x: 0, y: 1 });
      } else if (deltaY < 0 && direction.y === 0) {
        setNextDirection({ x: 0, y: -1 });
      }
    }
  };

  const startGame = () => {
    setSnake([{ x: 10, y: 10 }]);
    setFood({ x: 15, y: 15 });
    setDirection({ x: 1, y: 0 });
    setNextDirection({ x: 1, y: 0 });
    setScore(0);
    setGameOver(false);
    setIsPlaying(true);
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-green-900 via-green-800 to-emerald-900 p-4">
      <div className="w-full max-w-2xl">
        {/* Header */}
        <div className="bg-gradient-to-r from-purple-900 to-purple-700 rounded-t-2xl p-4 shadow-2xl">
          <div className="flex justify-between items-center text-white">
            <h1 className="text-3xl font-bold">🐍 Snake 3D</h1>
            <div className="text-2xl font-bold">Score: {score}</div>
          </div>
        </div>

        {/* Best Score */}
        <div className="bg-gradient-to-r from-amber-600 to-amber-500 p-3 flex items-center justify-center gap-3">
          <span className="text-2xl">🏆</span>
          <span className="text-white text-xl font-bold">Meilleur Score: {bestScore}</span>
        </div>

        {/* Game Board */}
        <div 
          className="relative bg-black rounded-b-2xl shadow-2xl overflow-hidden"
          style={{ 
            width: '100%', 
            paddingBottom: '100%',
            touchAction: 'none'
          }}
          onTouchStart={onTouchStart}
          onTouchEnd={onTouchEnd}
        >
          <div 
            className="absolute inset-0"
            style={{
              display: 'grid',
              gridTemplateColumns: `repeat(${GRID_SIZE}, 1fr)`,
              gridTemplateRows: `repeat(${GRID_SIZE}, 1fr)`,
              gap: '0px'
            }}
          >
            {Array.from({ length: GRID_SIZE * GRID_SIZE }).map((_, index) => {
              const x = index % GRID_SIZE;
              const y = Math.floor(index / GRID_SIZE);
              const snakeIndex = snake.findIndex(s => s.x === x && s.y === y);
              const isSnake = snakeIndex !== -1;
              const isFood = food.x === x && food.y === y;
              const isHead = snakeIndex === 0;

              return (
                <div 
                  key={index} 
                  className="relative w-full h-full"
                  style={{
                    transform: isHead && isEating ? 'scale(1.15)' : 'scale(1)',
                    transition: 'transform 0.2s ease-out'
                  }}
                >
                  {/* Background grass */}
                  <img 
                    src={`${assetsPath}/grass.png`} 
                    alt="" 
                    className="absolute inset-0 w-full h-full object-cover"
                    draggable="false"
                  />
                  
                  {/* Snake segments */}
                  {isSnake && (
                    <img 
                      src={`${assetsPath}/${getBodySegmentType(snakeIndex)}`}
                      alt="" 
                      className="absolute inset-0 w-full h-full object-cover"
                      draggable="false"
                      style={{
                        imageRendering: 'pixelated'
                      }}
                    />
                  )}
                  
                  {/* Food (rabbit) */}
                  {isFood && (
                    <img 
                      src={`${assetsPath}/rabbit.png`}
                      alt="" 
                      className="absolute inset-0 w-full h-full object-cover animate-bounce"
                      draggable="false"
                      style={{
                        imageRendering: 'pixelated'
                      }}
                    />
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Start Button */}
        {!isPlaying && (
          <div className="mt-6 text-center">
            <button
              onClick={startGame}
              className="bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white font-bold text-xl px-12 py-4 rounded-full shadow-2xl transform hover:scale-105 transition-all"
            >
              {gameOver ? '🔄 Hilalao indray' : '▶️ Manomboka hilalao'}
            </button>
            <div className="mt-4 text-white text-sm space-y-1">
              <p>⌨️ Desktop: Ampiasao ny zana-tsipìka</p>
              <p>📱 Mobile: Swipe mba hanova ny direction</p>
            </div>
          </div>
        )}

        {/* Game Over Message */}
        {gameOver && (
          <div className="mt-6 bg-red-900 text-white p-4 rounded-xl text-center shadow-2xl">
            <h2 className="text-3xl font-bold mb-2">💀 Game Over!</h2>
            <p className="text-xl">Score: {score}</p>
            {score === bestScore && score > 0 && (
              <p className="text-lg text-amber-300 mt-2">🎉 Record vaovao!</p>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default SnakeGame;