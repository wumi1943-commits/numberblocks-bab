let currentScore = 0;
let highScore = 0;
let timeLeft = 30;
let gameInterval = null;
let spawnInterval = null;
let playerName = '玩家';
let gameActive = false;

const startScreen = document.getElementById('startScreen');
const gameScreen = document.getElementById('gameScreen');
const endScreen = document.getElementById('endScreen');
const rankScreen = document.getElementById('rankScreen');
const blocksContainer = document.getElementById('blocksContainer');
const currentScoreEl = document.getElementById('currentScore');
const highScoreEl = document.getElementById('highScore');
const timeLeftEl = document.getElementById('timeLeft');
const finalScoreEl = document.getElementById('finalScore');
const newHighScoreEl = document.getElementById('newHighScore');
const syncStatusEl = document.getElementById('syncStatus');
const playerNameInput = document.getElementById('playerName');

function updateSyncStatus(text, type = '') {
    syncStatusEl.textContent = text;
    syncStatusEl.className = 'sync-status' + (type ? ' ' + type : '');
}

async function loadHighScore() {
    const savedName = localStorage.getItem('playerName');
    if (savedName) {
        playerNameInput.value = savedName;
        playerName = savedName;
    }

    const localHigh = localStorage.getItem('highScore');
    if (localHigh) {
        highScore = parseInt(localHigh);
        highScoreEl.textContent = highScore;
    }

    updateSyncStatus('☁️ 正在连接云端...');
    
    try {
        const { data, error } = await supabase
            .from('game_scores')
            .select('score')
            .eq('player_name', playerName)
            .order('score', { ascending: false })
            .limit(1);

        if (error) throw error;

        if (data && data.length > 0) {
            const cloudHigh = data[0].score;
            if (cloudHigh > highScore) {
                highScore = cloudHigh;
                highScoreEl.textContent = highScore;
                localStorage.setItem('highScore', highScore);
            }
        }

        updateSyncStatus('✅ 云端已连接', 'success');
        setTimeout(() => updateSyncStatus('☁️ 云端数据已同步', 'success'), 2000);
    } catch (err) {
        console.error('加载云端数据失败:', err);
        updateSyncStatus('⚠️ 云端连接失败，使用本地数据', 'error');
    }
}

async function saveScore(score) {
    if (score <= 0) return;

    try {
        const { data, error } = await supabase
            .from('game_scores')
            .insert([
                {
                    player_name: playerName,
                    score: score
                }
            ]);

        if (error) throw error;
        
        updateSyncStatus('✅ 分数已上传', 'success');
        return true;
    } catch (err) {
        console.error('保存分数失败:', err);
        updateSyncStatus('⚠️ 上传失败，已保存到本地', 'error');
        return false;
    }
}

async function loadRank() {
    const rankList = document.getElementById('rankList');
    rankList.innerHTML = '<p class="loading">加载排行榜...</p>';

    try {
        const { data, error } = await supabase
            .from('game_scores')
            .select('player_name, score, created_at')
            .order('score', { ascending: false })
            .limit(20);

        if (error) throw error;

        if (!data || data.length === 0) {
            rankList.innerHTML = '<p class="loading">还没有记录，快来创造第一个吧！</p>';
            return;
        }

        rankList.innerHTML = '';
        data.forEach((item, index) => {
            const div = document.createElement('div');
            div.className = 'rank-item';
            
            let medal = '';
            if (index === 0) medal = '🥇';
            else if (index === 1) medal = '🥈';
            else if (index === 2) medal = '🥉';
            else medal = (index + 1);

            div.innerHTML = `
                <span class="rank-number">${medal}</span>
                <span class="rank-name">${item.player_name}</span>
                <span class="rank-score">${item.score}</span>
            `;
            rankList.appendChild(div);
        });
    } catch (err) {
        console.error('加载排行榜失败:', err);
        rankList.innerHTML = '<p class="loading">加载失败，请稍后再试</p>';
    }
}

function startGame() {
    const name = playerNameInput.value.trim();
    if (name) {
        playerName = name;
        localStorage.setItem('playerName', playerName);
    } else {
        playerName = '玩家';
    }

    currentScore = 0;
    timeLeft = 30;
    gameActive = true;
    currentScoreEl.textContent = '0';
    timeLeftEl.textContent = '30';
    blocksContainer.innerHTML = '';

    startScreen.classList.add('hidden');
    endScreen.classList.add('hidden');
    rankScreen.classList.add('hidden');
    gameScreen.classList.remove('hidden');

    gameInterval = setInterval(() => {
        timeLeft--;
        timeLeftEl.textContent = timeLeft;
        if (timeLeft <= 0) {
            endGame();
        }
    }, 1000);

    spawnBlock();
    spawnInterval = setInterval(spawnBlock, Math.max(400, 1000 - (30 - timeLeft) * 20));
}

function spawnBlock() {
    if (!gameActive) return;

    const block = document.createElement('div');
    const value = Math.floor(Math.random() * 9) + 1;
    block.className = `block block-${value}`;
    block.textContent = value;

    const gameArea = document.getElementById('gameArea');
    const maxX = gameArea.offsetWidth - 70;
    const maxY = gameArea.offsetHeight - 70;
    const x = Math.random() * maxX;
    const y = Math.random() * maxY;

    block.style.left = x + 'px';
    block.style.top = y + 'px';

    block.addEventListener('click', (e) => {
        if (!gameActive) return;
        e.stopPropagation();
        clickBlock(block, value, x + 30, y);
    });

    blocksContainer.appendChild(block);

    setTimeout(() => {
        if (block.parentNode) {
            block.remove();
        }
    }, 2000 + Math.random() * 1000);
}

function clickBlock(block, value, x, y) {
    block.classList.add('popping');
    
    const points = value * 10;
    currentScore += points;
    currentScoreEl.textContent = currentScore;

    const popup = document.createElement('div');
    popup.className = 'score-popup';
    popup.textContent = '+' + points;
    popup.style.left = x + 'px';
    popup.style.top = y + 'px';
    blocksContainer.appendChild(popup);

    setTimeout(() => {
        block.remove();
        popup.remove();
    }, 300);
}

async function endGame() {
    gameActive = false;
    clearInterval(gameInterval);
    clearInterval(spawnInterval);

    gameScreen.classList.add('hidden');
    endScreen.classList.remove('hidden');
    finalScoreEl.textContent = currentScore;

    const isNewHigh = currentScore > highScore;
    if (isNewHigh) {
        highScore = currentScore;
        highScoreEl.textContent = highScore;
        localStorage.setItem('highScore', highScore);
        newHighScoreEl.classList.remove('hidden');
    } else {
        newHighScoreEl.classList.add('hidden');
    }

    updateSyncStatus('☁️ 正在上传分数...');
    await saveScore(currentScore);
}

function showRank() {
    startScreen.classList.add('hidden');
    endScreen.classList.add('hidden');
    gameScreen.classList.add('hidden');
    rankScreen.classList.remove('hidden');
    loadRank();
}

function backToStart() {
    rankScreen.classList.add('hidden');
    endScreen.classList.add('hidden');
    gameScreen.classList.add('hidden');
    startScreen.classList.remove('hidden');
}

document.getElementById('startBtn').addEventListener('click', startGame);
document.getElementById('restartBtn').addEventListener('click', startGame);
document.getElementById('rankBtn').addEventListener('click', showRank);
document.getElementById('showRankBtn').addEventListener('click', showRank);
document.getElementById('backBtn').addEventListener('click', backToStart);

loadHighScore();
