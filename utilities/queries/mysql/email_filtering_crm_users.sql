-- To update all emails from demo+[value]@hy.ly to mithuns+[value]@qburst.com
UPDATE users SET email = CONCAT('temp+',email) WHERE email NOT LIKE '%+%';
UPDATE users SET email = CONCAT(  'mithuns', SUBSTRING( CONCAT( LEFT( email, INSTR( email,  '@' ) ) ,  'qburst.com' ) , INSTR( email,  '+' ) ) ) WHERE email LIKE  'demo%';