-- Rebrand: "IT Mentor" AI model names -> "iLearnCode" (safe to run again)
ALTER TABLE user_settings ALTER COLUMN ai_model SET DEFAULT 'iLearnCode v2';
UPDATE user_settings SET ai_model = replace(ai_model, 'IT Mentor', 'iLearnCode') WHERE ai_model LIKE 'IT Mentor%';