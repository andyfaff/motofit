#pragma rtGlobals=1		// Use modern global access method.
#pragma independentmodule=Ind_Process


// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

static function parseReply(msg,lhs,rhs)
	string msg
	string &lhs,&rhs
	lhs = ""
	rhs = ""
	msg=replacestring(" = ",msg, "=")
      msg = removeending(msg, "\n")
	variable items = itemsinlist(msg,"=")
	if(items==2)
		lhs = replacestring(" ", stringfromlist(0,msg, "="),"")
		rhs = stringfromlist(1,msg, "=")
	endif
	return items
end

Function cmdProcessor(w,x)
	Wave/t w
	variable x
	if(itemsinlist(winlist("sicscmdpanel",";","")))
		notebook sicscmdpanel#NB0_tab0, selection = {endoffile,endoffile}, textRGB = (0,0,0),fstyle=0
		notebook sicscmdpanel#NB0_tab0, selection={endoffile,endoffile}, text="\t"+w[x][0]+"\r"
	endif
End

Function interestProcessor(w,x)
	Wave/t w
	variable x
	//used as a sockit for the SICS_interest channel
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	
	//current status of SICS
	SVAR sicsstatus = root:packages:platypus:SICS:sicsstatus
	
	//the SICS statemonitor
	Wave/t statemon = root:packages:platypus:SICS:statemon

	//current datafilename
	SVAR samplename = root:packages:platypus:SICS:sampleStr

	variable num,col,row,items,pos
	string str,str1,str2

	//list of all the hipadaba paths and their values
	Wave/t hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths
	
	//first see if it's a position that has changed?
	//the list of current motor positions is kept in axeslist
	//have to change the axeslist colour if the motor is moving.  THis is done by changing the value of the background col plane in selaxeslist
	Wave/t axeslist = root:packages:platypus:SICS:axeslist
	Wave selaxeslist = root:packages:platypus:sics:selAxesList
	items = parseReply(w[x][0],str1,str2)
//	print x, "                ", w[x][0]
	//this code should parse upper and lower limit changes, as well as position changes.
	if(items==2)
		strswitch(str1)//see what the message is about
			case "STARTED":		//this is listening to the statemon starting an axis
				redimension/n=(numpnts(statemon)+1) statemon
				statemon[inf] = str2
				
				//if its a motor axis we want to change the colour in the panel.
				Findvalue/Text=str2/TXOP=4 axeslist
				if(v_value !=-1)
					col = floor(v_value/dimsize(axeslist,0))
					row = v_value-col*dimsize(axeslist,0)
					if(col==1 || col==0)
						selaxeslist[row][][1] = 1
					endif
				endif
				
				break
			case "FINISH":		//this is listening to the statemon finishing an axis
				Findvalue/Text=str2/TXOP=4 statemon
				if(V_Value != -1)
					deletepoints V_Value, 1, statemon
				endif
				
				//if its an motor axis we want to change the colour in the axeslist
				Findvalue/Text=str2/TXOP=4 axeslist
				if(v_value !=-1)
					col = floor(v_value/dimsize(axeslist,0))
					row = v_value-col*dimsize(axeslist,0)
					if(col==1 || col==0)
						selaxeslist[row][][1] = 0
					endif
				endif
				break
			case "status":
				sicsstatus = str2
				if(stringmatch(str2, "Eager to execute commands"))
					SetVariable/Z sicsstatus win=instrumentlayout, valueBackColor=(0,65280,0)
					SetVariable/Z sicsstatus_tab0 win=SICScmdPanel, valueBackColor=(0,65280,0)
				else
					SetVariable/Z sicsstatus win=instrumentlayout, valueBackColor=(65280,0,0)
					SetVariable/Z sicsstatus_tab0 win=SICScmdPanel, valueBackColor=(65280,0,0)
				endif
				break
			case "/sample/name":
				sampleName = str2
				break
			default:
				Findvalue/Text=str1/TXOP=4 axeslist
				if(v_value !=-1)
					col = floor(v_value/dimsize(axeslist,0))
					row = v_value-col*dimsize(axeslist,0)
					if(col==1 || col==0)
						axeslist[row][2] = num2str(str2num(str2))				
						//update the layout picture
						updatelayout(axeslist[row][0])
						//				beep
					endif
		
					if(col==3 || col ==5)
						axeslist[row][col+1] = num2str(str2num(str2))
						//if the softlimits have changed, need to update positions, as a notify isn't always sent.
						//send on the interest channel.  SHould just be able to send the short axis name
						//this will make this processor function slightly recursive
						sockitsendmsg/time=1 sock_interest,axeslist[row][0]+"\n"
					endif
				endif
				break
		endswitch
		
		//search for it in the hipadaba_paths
		findvalue/text=str1/txop=4/z hipadaba_paths
		if(v_value != -1)
			col = floor(v_value/dimsize(hipadaba_paths,0))
			row = v_value-col*dimsize(hipadaba_paths,0)
			if(col==0)
				hipadaba_paths[row][1] = str2
			endif
		endif
	endif
End

Function updatelayout(motor)
	string motor
	Wave/t axeslist = root:packages:platypus:SICS:axeslist
	variable rowsinwave = dimsize(axeslist,0),col,row,val,ii

	string controls = controlnamelist("instrumentlayout","",motor)
	if(itemsinlist(controls)) 
		findvalue/z/text = motor axeslist
		if(V_value==-1)
			return 0
		endif
		col=floor(V_value/rowsInWave)
		row=V_value-col*rowsInWave
		val = str2num(axeslist[row][col+1])
		
		titlebox/z $motor,win=instrumentlayout,title = motor+"="+ axeslist[row][col+2]
	Endif
end

Function processBMON3rate(w,x)
	Wave/t w
	variable x
	//a SOCKIT processor function for the messages coming back from the open TCPIP connection to beam monitor 3.
	//the whole point of this is to make sure that the detector isn't overwhelmed.
//	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
//	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
		
	NVAR bmon3_rate = root:packages:platypus:SICS:bmon3_rate
	NVAR bmon3_counts = root:packages:platypus:SICS:bmon3_counts
	string rateStr
	rateStr = w[x][0]
	variable val0,val1,val2,val3,val4,val5,val6,val7,val8,val9
	sscanf rateStr,"%d:%d:%g ( %g), %d (%d),%g ( %g, %g, %g)" , val0,val1,val2,val3,val4,val5,val6,val7,val8,val9
	bmon3_rate = val6

//	if(bmon3_rate > 20000 &&  val4 >= bmon3_counts)
//		sockitsendmsg sock_interupt,"INT1712 3\n"
//		doxopidle
//		sleep/t 20
//		sockitsendmsg SOCK_interest,"bat send oscd=0\n"
//		sockitsendmsg SOCK_interest,"run ss1vg 0\nrun ss2vg 0\nrun ss3vg 0\nrun ss4vg 0\n"
//		sockitsendmsg SOCK_interest,"run bz 250\n"
//		print "DETECTOR RATE IS TOO HIGH, CLOSING SLITS, inserting ATTENUATOR (processBMON3rate)"
//	endif
	bmon3_counts = val4
	return 0
End

Threadsafe Function DetectorSentinel()
	variable sock_sics, sock_bmon3, ii
	variable val0,val1,val2,val3,val4,val5,val6,val7,val8,val9, bmon3_rate, bmon3_counts
	string msg,temp
	
	sock_sics=sockitopenconnectionF("137.157.202.139",60003,10)
	sock_bmon3=sockitopenconnectionF("137.157.202.140",30002,10)
	
	if(sockitisitopen(sock_sics)==-1 || sockitisitopen(sock_bmon3)==-1)
		print "ERROR couldn't open sentinel sockets"
	endif
	
	sockitsendmsgF(sock_SICS,"manager ansto\n")
	sockitsendmsgF(sock_bmon3,"REPORT ON\n")
	bmon3_counts = 0
	print "Detector Sentinel started"
	
	do
		temp = SOCKITPeek(sock_sics)
		msg = SOCKITpeek(sock_bmon3)
		for(ii=0 ; ii<itemsinlist(msg, "\n") ; ii+=1)
			sscanf stringfromlist(ii, msg, "\n"), "%d:%d:%g ( %g), %d (%d),%g ( %g, %g, %g)" , val0,val1,val2,val3,val4,val5,val6,val7,val8,val9
			bmon3_rate = val6
			if(bmon3_rate > 30000 &&  val4 > bmon3_counts)
				sockitsendmsgF(sock_sics,"INT1712 3\n")
				temp = ThreadGroupGetDF(0, 200 )
				sockitsendmsgf(sock_sics,"bat send oscd=0\nrun ss1vg 0\nrun ss2vg 0\nrun ss3vg 0\nrun ss4vg 0\ndrive bz 250\n")
				print "DETECTOR RATE IS TOO HIGH, CLOSING SLITS, inserting ATTENUATOR (DetectorSentinel)"
				temp = ThreadGroupGetDF(0, 10000 )
			endif
			bmon3_counts = val4
		endfor
		temp = ThreadGroupGetDF(0, 1000 )
		
		if(sockitisitopen(sock_sics)==-1)
			sock_sics=sockitopenconnectionF("137.157.202.139",60003,10)
			if(sock_sics==-1)
				print "ERROR sentinel socket closed"
				return 1
			endif
		endif
		if(sockitisitopen(sock_bmon3)==-1)
			sock_bmon3=sockitopenconnectionF("137.157.202.140",30002,10)
			if(sock_bmon3==-1)
				print "ERROR sentinel socket closed"
				return 1
			endif
		endif
	while(1)

	sockitcloseconnection(sock_SICS)
	sockitcloseconnection(sock_bmon3)
	return 0
End