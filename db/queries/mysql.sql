-- To update all emails from demo+[value]@hy.ly to mithuns+[value]@qburst.com

UPDATE users SET email = CONCAT(  'mithuns', SUBSTRING( CONCAT( LEFT( email, INSTR( email,  '@' ) ) ,  'qburst.com' ) , INSTR( email,  '+' ) ) ) WHERE email LIKE  'demo%';

-- To update recepient in ftp_setting column in imports table to mithuns@qburst.com

UPDATE imports SET ftp_setting = CONCAT(LEFT(ftp_setting,INSTR(ftp_setting,"recipient")+10),'"mithuns@qburst.com"}');