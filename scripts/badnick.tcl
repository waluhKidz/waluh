#--------------------------------------------------------------------------------------------------------------------#
#                                               BAD NICK SCRIPT BY RANA USMAN                                        #
#--------------------------------------------------------------------------------------------------------------------#

#Author : RANA USMAN
#Email : coolguy_rusman@yahoo.com
#URL : www.ranausman.tk
#Version : 1.2
#Catch me on UNDERNET @ #VASTEYE my nick is ^Rana^Usman
###################
# Version History #
###################
#The version before was not supporting Wildcards like ** ?? etc etc
#So now in this version you can use wild cards too

###########################
#- CONFIGURATION SECTION -#
###########################

########################################################################################
#- Enter the Bad nicks Below on which you want your bot to BAN  (Wild Cards Supported)-#
########################################################################################
set bnick {
  "fuck" 
  "*gay*" 
  "*rape*" 
  "*fuk*" 
  "*badwa" 
  "*phudi*" 
  "*fudi"
  "*horny*"
  "*Lun*"
  "*gandu*"
  "*gandoo*"
  "*gand*"
  "*chood*"   
  "*pussy*" 
  "*boobs*" 
  "*porn*" 
  "*p0rn*" 
  "*hot*" 
  "*gay*"
  "*chut*"
  "*chood*"
  "*lun*"
  "*suck*"
  "*tharki*" 
  "*sux*" 
}
#########################################################################################################
##                SET The channel on which you want this script to work                                ##
## Channels Separted by space...and if you want this script to work on all channels leave it as ""     ##
#########################################################################################################

set bchan "#gila"

################
#- Set Reason -#
################

set kickreason "4Bad Nick Detected--5We dont allow users with badnick to enter this channel--12Kindly Change you nick by typing /nick newnick and rejoin--"


#--------------------------------------------------------------------------------------------------------------------#
#   SCRIPT STARTS FROM HERE...MAKE IT BETTER WITH YOUR SKILLS IF YOU CAN.I DONT RESTRICT YOU TO NOT TO TOUCH CODE!   #
#--------------------------------------------------------------------------------------------------------------------#


bind join - * join:Aad_SeVeNFoLd
proc join:Aad_SeVeNFoLd {nick uhost hand chan} {
global bnick bchan kickreason temp
if {(([lsearch -exact [string tolower $bchan] [string tolower $chan]] != -1)  || ($bchan == ""))} {
  set temp 0
	foreach i [string tolower $bnick] {
	if {[string match *$i* [string tolower $nick]]} {
	set temp 1
 	}
 	}
}
	if {!$temp} { return } {
putquick "MODE $chan +b $nick"
putquick "KICK $chan $nick :$kickreason"
 } 
}
putlog "=-\002 LOADED BAD NICK BY RANA USMAN (www.ranausman.tk)\002 -="

#Author : RANA USMAN 
