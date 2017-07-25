-- To update recepient in ftp_setting column in imports table to mithuns@qburst.com

UPDATE imports SET ftp_setting = CONCAT(LEFT(ftp_setting,INSTR(ftp_setting,"recipient")+10),'"mithuns@qburst.com"}');