-- To update all resident emails to mithuns+[resident_email]@qburst.com

UPDATE smartrent_residents SET email = CONCAT('temp+',email) WHERE email NOT LIKE '%+%';
UPDATE smartrent_residents SET email = CONCAT('mithuns',SUBSTRING(CONCAT(LEFT(email, INSTR(email, '@')), 'qburst.com'),INSTR( email,  '+' )));