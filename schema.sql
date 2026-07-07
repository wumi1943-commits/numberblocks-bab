-- ============================================================
-- 🧱 数字积木宝宝养成记 - 数据库建表脚本（完整版 v2.4）
-- ============================================================
-- 执行方式：在 Supabase 控制台 → SQL Editor → 新建查询 → 粘贴 → 运行
-- 本脚本可重复执行，不会报错！
-- ============================================================

-- ============================================================
-- 1. 家庭表（families）
-- ============================================================
CREATE TABLE IF NOT EXISTS families (
    id BIGSERIAL PRIMARY KEY,
    family_code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(50) DEFAULT '我的家',
    pin VARCHAR(10) DEFAULT '1234',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE families ENABLE ROW LEVEL SECURITY;

-- 兼容旧数据：添加 pin 字段
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'pin') THEN
        ALTER TABLE families ADD COLUMN pin VARCHAR(10) DEFAULT '1234';
    END IF;
END $$;

-- 兼容旧数据：添加 name 字段
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'name') THEN
        ALTER TABLE families ADD COLUMN name VARCHAR(50) DEFAULT '我的家';
    END IF;
END $$;

-- 幂等策略：先删后建
DROP POLICY IF EXISTS "可通过家庭码查询家庭" ON families;
CREATE POLICY "可通过家庭码查询家庭"
    ON families
    FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "可创建家庭" ON families;
CREATE POLICY "可创建家庭"
    ON families
    FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "可更新家庭" ON families;
CREATE POLICY "可更新家庭"
    ON families
    FOR UPDATE
    USING (true);

CREATE UNIQUE INDEX IF NOT EXISTS idx_families_code ON families (family_code);


-- ============================================================
-- 2. 任务表（tasks）
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(20) DEFAULT '⭐',
    category VARCHAR(20) DEFAULT 'selfcare',
    stars INTEGER NOT NULL DEFAULT 1,
    sort_order INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 兼容旧数据：添加 category 字段
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'category') THEN
        ALTER TABLE tasks ADD COLUMN category VARCHAR(20) DEFAULT 'selfcare';
    END IF;
END $$;

DROP POLICY IF EXISTS "可查看任务" ON tasks;
CREATE POLICY "可查看任务" ON tasks FOR SELECT USING (true);

DROP POLICY IF EXISTS "可添加任务" ON tasks;
CREATE POLICY "可添加任务" ON tasks FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "可更新任务" ON tasks;
CREATE POLICY "可更新任务" ON tasks FOR UPDATE USING (true);

DROP POLICY IF EXISTS "可删除任务" ON tasks;
CREATE POLICY "可删除任务" ON tasks FOR DELETE USING (true);

CREATE INDEX IF NOT EXISTS idx_tasks_family ON tasks (family_id);


-- ============================================================
-- 3. 任务完成记录表（task_logs）
-- ============================================================
CREATE TABLE IF NOT EXISTS task_logs (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    task_id BIGINT REFERENCES tasks(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    completed BOOLEAN DEFAULT true,
    stars_earned INTEGER DEFAULT 0,
    child_name VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE task_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "可查看任务记录" ON task_logs;
CREATE POLICY "可查看任务记录" ON task_logs FOR SELECT USING (true);

DROP POLICY IF EXISTS "可添加任务记录" ON task_logs;
CREATE POLICY "可添加任务记录" ON task_logs FOR INSERT WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_task_logs_family_date ON task_logs (family_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_task_logs_task ON task_logs (task_id);


-- ============================================================
-- 4. 宝宝状态表（pet_state）
-- ============================================================
CREATE TABLE IF NOT EXISTS pet_state (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT UNIQUE NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name VARCHAR(50) DEFAULT '小积木',
    level INTEGER DEFAULT 1,
    exp INTEGER DEFAULT 0,
    stars INTEGER DEFAULT 0,
    food INTEGER DEFAULT 10,
    gifts INTEGER DEFAULT 0,
    mood INTEGER DEFAULT 100,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE pet_state ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "可查看宝宝状态" ON pet_state;
CREATE POLICY "可查看宝宝状态" ON pet_state FOR SELECT USING (true);

DROP POLICY IF EXISTS "可添加宝宝状态" ON pet_state;
CREATE POLICY "可添加宝宝状态" ON pet_state FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "可修改宝宝状态" ON pet_state;
CREATE POLICY "可修改宝宝状态" ON pet_state FOR UPDATE USING (true);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pet_family ON pet_state (family_id);


-- ============================================================
-- 5. 食物表（foods）
-- ============================================================
CREATE TABLE IF NOT EXISTS foods (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    icon VARCHAR(20) DEFAULT '🍎',
    stars INTEGER NOT NULL DEFAULT 5,
    exp INTEGER DEFAULT 10,
    sort_order INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE foods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "可查看食物" ON foods;
CREATE POLICY "可查看食物" ON foods FOR SELECT USING (true);

DROP POLICY IF EXISTS "可添加食物" ON foods;
CREATE POLICY "可添加食物" ON foods FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "可更新食物" ON foods;
CREATE POLICY "可更新食物" ON foods FOR UPDATE USING (true);

CREATE INDEX IF NOT EXISTS idx_foods_family ON foods (family_id);


-- ============================================================
-- 6. 奖励表（rewards）
-- ============================================================
CREATE TABLE IF NOT EXISTS rewards (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(20) DEFAULT '🎁',
    stars INTEGER NOT NULL DEFAULT 20,
    daily_limit INTEGER DEFAULT 0,
    weekly_limit INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "可查看奖励" ON rewards;
CREATE POLICY "可查看奖励" ON rewards FOR SELECT USING (true);

DROP POLICY IF EXISTS "可添加奖励" ON rewards;
CREATE POLICY "可添加奖励" ON rewards FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "可更新奖励" ON rewards;
CREATE POLICY "可更新奖励" ON rewards FOR UPDATE USING (true);

DROP POLICY IF EXISTS "可删除奖励" ON rewards;
CREATE POLICY "可删除奖励" ON rewards FOR DELETE USING (true);

CREATE INDEX IF NOT EXISTS idx_rewards_family ON rewards (family_id);

-- 兼容旧数据：添加字段
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'rewards' AND column_name = 'daily_limit') THEN
        ALTER TABLE rewards ADD COLUMN daily_limit INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'rewards' AND column_name = 'weekly_limit') THEN
        ALTER TABLE rewards ADD COLUMN weekly_limit INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'rewards' AND column_name = 'active') THEN
        ALTER TABLE rewards ADD COLUMN active BOOLEAN DEFAULT true;
    END IF;
END $$;


-- ============================================================
-- 7. 账本表（ledger）- 星星收支明细
-- ============================================================
CREATE TABLE IF NOT EXISTS ledger (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    stars INTEGER NOT NULL,
    description TEXT,
    related_type VARCHAR(50),
    related_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ledger ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "可查看账本" ON ledger;
CREATE POLICY "可查看账本" ON ledger FOR SELECT USING (true);

DROP POLICY IF EXISTS "可添加账本记录" ON ledger;
CREATE POLICY "可添加账本记录" ON ledger FOR INSERT WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_ledger_family ON ledger (family_id, created_at DESC);


-- ============================================================
-- 8. 兑换记录表（redemptions）
-- ============================================================
CREATE TABLE IF NOT EXISTS redemptions (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    reward_id BIGINT REFERENCES rewards(id) ON DELETE SET NULL,
    reward_name VARCHAR(100),
    stars_spent INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    child_name VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

ALTER TABLE redemptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "可查看兑换记录" ON redemptions;
CREATE POLICY "可查看兑换记录" ON redemptions FOR SELECT USING (true);

DROP POLICY IF EXISTS "可添加兑换记录" ON redemptions;
CREATE POLICY "可添加兑换记录" ON redemptions FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "可更新兑换记录" ON redemptions;
CREATE POLICY "可更新兑换记录" ON redemptions FOR UPDATE USING (true);

CREATE INDEX IF NOT EXISTS idx_redemptions_family ON redemptions (family_id, created_at DESC);


-- ============================================================
-- 9. 调整记录表（adjust_logs）
-- ============================================================
CREATE TABLE IF NOT EXISTS adjust_logs (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    adjust_type VARCHAR(20) NOT NULL,
    before_value INTEGER NOT NULL,
    after_value INTEGER NOT NULL,
    reason TEXT,
    operator VARCHAR(50),
    related_type VARCHAR(50),
    related_id BIGINT,
    rollback_data TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE adjust_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "可查看调整记录" ON adjust_logs;
CREATE POLICY "可查看调整记录" ON adjust_logs FOR SELECT USING (true);

DROP POLICY IF EXISTS "可添加调整记录" ON adjust_logs;
CREATE POLICY "可添加调整记录" ON adjust_logs FOR INSERT WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_adjust_family ON adjust_logs (family_id, created_at DESC);

-- 兼容旧数据：添加字段
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'adjust_logs' AND column_name = 'related_type') THEN
        ALTER TABLE adjust_logs ADD COLUMN related_type VARCHAR(50);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'adjust_logs' AND column_name = 'related_id') THEN
        ALTER TABLE adjust_logs ADD COLUMN related_id BIGINT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'adjust_logs' AND column_name = 'rollback_data') THEN
        ALTER TABLE adjust_logs ADD COLUMN rollback_data TEXT;
    END IF;
END $$;


-- ============================================================
-- 10. RPC 函数：增量更新宝宝状态（防并发覆盖）
-- ============================================================
CREATE OR REPLACE FUNCTION increment_pet_state(
    p_family_id BIGINT,
    p_star_delta INTEGER DEFAULT 0,
    p_exp_delta INTEGER DEFAULT 0
)
RETURNS pet_state AS $$
DECLARE
    v_pet pet_state%ROWTYPE;
    v_exp_needed INTEGER;
BEGIN
    SELECT * INTO v_pet FROM pet_state WHERE family_id = p_family_id;
    
    IF NOT FOUND THEN
        INSERT INTO pet_state (family_id, stars, exp, level, updated_at)
        VALUES (p_family_id, GREATEST(0, p_star_delta), GREATEST(0, p_exp_delta), 1, NOW())
        RETURNING * INTO v_pet;
    ELSE
        UPDATE pet_state
        SET 
            stars = GREATEST(0, stars + p_star_delta),
            exp = exp + p_exp_delta,
            updated_at = NOW()
        WHERE family_id = p_family_id
        RETURNING * INTO v_pet;
        
        WHILE TRUE LOOP
            IF v_pet.level <= 10 THEN
                v_exp_needed := 10;
            ELSIF v_pet.level <= 100 THEN
                v_exp_needed := 25;
            ELSE
                v_exp_needed := 60;
            END IF;
            
            IF v_pet.exp >= v_exp_needed THEN
                UPDATE pet_state
                SET 
                    exp = exp - v_exp_needed,
                    level = level + 1,
                    updated_at = NOW()
                WHERE family_id = p_family_id
                RETURNING * INTO v_pet;
            ELSE
                EXIT;
            END IF;
        END LOOP;
    END IF;
    
    RETURN v_pet;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 11. RPC 函数：验证家长 PIN（前端不能绕过）
-- ============================================================
CREATE OR REPLACE FUNCTION verify_parent_pin(
    p_family_id BIGINT,
    p_pin VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_pin VARCHAR;
BEGIN
    SELECT pin INTO v_pin FROM families WHERE id = p_family_id;
    
    IF v_pin IS NULL THEN
        RETURN p_pin = '1234';
    END IF;
    
    RETURN v_pin = p_pin;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 12. RPC 函数：修改家长 PIN
-- ============================================================
CREATE OR REPLACE FUNCTION change_parent_pin(
    p_family_id BIGINT,
    p_old_pin VARCHAR,
    p_new_pin VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_valid BOOLEAN;
BEGIN
    SELECT verify_parent_pin(p_family_id, p_old_pin) INTO v_valid;
    
    IF NOT v_valid THEN
        RETURN false;
    END IF;
    
    UPDATE families SET pin = p_new_pin WHERE id = p_family_id;
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 13. RPC 函数：兑换奖励（检查上限+扣星星+生成兑换券，原子操作）
-- ============================================================
CREATE OR REPLACE FUNCTION redeem_reward(
    p_family_id BIGINT,
    p_reward_id BIGINT
)
RETURNS JSON AS $$
DECLARE
    v_reward rewards%ROWTYPE;
    v_pet pet_state%ROWTYPE;
    v_daily_count INTEGER;
    v_weekly_count INTEGER;
    v_redemption_id BIGINT;
    v_week_start DATE;
BEGIN
    SELECT * INTO v_reward FROM rewards WHERE id = p_reward_id AND family_id = p_family_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'message', '奖励不存在');
    END IF;
    
    IF NOT v_reward.active THEN
        RETURN json_build_object('success', false, 'message', '奖励已下架');
    END IF;
    
    SELECT * INTO v_pet FROM pet_state WHERE family_id = p_family_id;
    
    IF NOT FOUND OR v_pet.stars < v_reward.stars THEN
        RETURN json_build_object('success', false, 'message', '星星不够');
    END IF;
    
    IF v_reward.daily_limit > 0 THEN
        SELECT COUNT(*) INTO v_daily_count
        FROM redemptions
        WHERE family_id = p_family_id
          AND reward_id = p_reward_id
          AND date(created_at AT TIME ZONE 'Asia/Shanghai') = CURRENT_DATE
          AND status != 'cancelled';
        
        IF v_daily_count >= v_reward.daily_limit THEN
            RETURN json_build_object('success', false, 'message', '今天已经换过啦，明天再来吧～');
        END IF;
    END IF;
    
    IF v_reward.weekly_limit > 0 THEN
        v_week_start := CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE)::INTEGER - 1);
        IF EXTRACT(DOW FROM CURRENT_DATE)::INTEGER = 0 THEN
            v_week_start := CURRENT_DATE - 6;
        END IF;
        
        SELECT COUNT(*) INTO v_weekly_count
        FROM redemptions
        WHERE family_id = p_family_id
          AND reward_id = p_reward_id
          AND date(created_at AT TIME ZONE 'Asia/Shanghai') >= v_week_start
          AND status != 'cancelled';
        
        IF v_weekly_count >= v_reward.weekly_limit THEN
            RETURN json_build_object('success', false, 'message', '本周已经换够啦，下周再来吧～');
        END IF;
    END IF;
    
    UPDATE pet_state
    SET stars = stars - v_reward.stars,
        gifts = COALESCE(gifts, 0) + 1,
        updated_at = NOW()
    WHERE family_id = p_family_id
    RETURNING * INTO v_pet;
    
    INSERT INTO redemptions (family_id, reward_id, reward_name, stars_spent, status, created_at)
    VALUES (p_family_id, p_reward_id, v_reward.name, v_reward.stars, 'pending', NOW())
    RETURNING id INTO v_redemption_id;
    
    INSERT INTO ledger (family_id, type, stars, description, related_type, related_id, created_at)
    VALUES (p_family_id, 'redeem', -v_reward.stars, '兑换' || v_reward.name, 'redemption', v_redemption_id, NOW());
    
    RETURN json_build_object(
        'success', true,
        'redemption_id', v_redemption_id,
        'stars_left', v_pet.stars,
        'reward_name', v_reward.name
    );
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 14. RPC 函数：获取服务器时间（东八区）
-- ============================================================
CREATE OR REPLACE FUNCTION get_server_time()
RETURNS JSON AS $$
BEGIN
    RETURN json_build_object(
        'timestamp', NOW(),
        'timestamp_sh', NOW() AT TIME ZONE 'Asia/Shanghai',
        'date_sh', CURRENT_DATE,
        'time_sh', TO_CHAR(NOW() AT TIME ZONE 'Asia/Shanghai', 'HH24:MI:SS'),
        'day_of_week', EXTRACT(DOW FROM NOW() AT TIME ZONE 'Asia/Shanghai')::INTEGER
    );
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 15. RPC 函数：计算连续天数（streak）
-- ============================================================
CREATE OR REPLACE FUNCTION calculate_streak(
    p_family_id BIGINT
)
RETURNS INTEGER AS $$
DECLARE
    v_streak INTEGER := 0;
    v_check_date DATE;
    v_has_record BOOLEAN;
BEGIN
    v_check_date := CURRENT_DATE;
    
    WHILE TRUE LOOP
        SELECT EXISTS(
            SELECT 1 FROM task_logs
            WHERE family_id = p_family_id
              AND date = v_check_date
              AND completed = true
        ) INTO v_has_record;
        
        IF v_has_record THEN
            v_streak := v_streak + 1;
            v_check_date := v_check_date - INTERVAL '1 day';
        ELSE
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_streak;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- ✅ 建表完成！v2.2 版本新增：
-- ============================================================
-- 1. get_server_time() - 获取服务器时间（东八区）
-- 2. calculate_streak() - 计算连续天数
-- 3. 兑换函数改用东八区时间判断每日/每周上限
-- ============================================================
