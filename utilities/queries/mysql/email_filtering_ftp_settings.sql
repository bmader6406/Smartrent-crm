-- To update recepient in ftp_setting column in imports table to mithuns@qburst.com

UPDATE imports SET ftp_setting =  CONCAT(CONCAT(LEFT(ftp_setting,INSTR(ftp_setting,"recipient")+11),"mithuns@qburst.com"),
	RIGHT(ftp_setting,LENGTH(ftp_setting)-INSTR(ftp_setting,"recipient")-11-
		INSTR(RIGHT(ftp_setting,LENGTH(ftp_setting)-INSTR(ftp_setting,"recipient")-11),'"')+1));