# runloader.sh
wrunctl="runloader.ctl"
for mylog in camiscada*.log
do
	echo "--" > ${wrunctl} 
	echo "load data" >> ${wrunctl} 
	echo "INFILE '$mylog'" >> ${wrunctl}  
	echo "APPEND INTO TABLE M19STGLOG" >> ${wrunctl}  
	echo "FIELDS TERMINATED BY ';' TRAILING NULLCOLS" >> ${wrunctl}  	
	echo "(MWHEN DATE \"DD.MM.YYYY HH24:MI:SS\" ,MDVCID,MCOMPVAL )	" >> ${wrunctl}  			
	sqlldr riordino/riordino@riordinosvilsrv.mil.esselunga.net:1521/riordinosvilsrv control=${wrunctl} 
	mv ./$mylog ./saved/$mylog
	
done

