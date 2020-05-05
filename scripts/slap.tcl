##########################################################################################################################
#------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------   solloman TCL      ---------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------#
#-----------------------------------------------------     Slap v.2.0     -----------------------------------------------#
#------------------------------------------------------------------------------------------------------------------------#
##########################################################################################################################
###################################################### English ###########################################################
############################## This TCL is for fun. Comand is (char)slap or (char)slap all ###############################
#################### EggDrop give slaps to some person or to all channel (except ChanServ and EggDrop) ###################
##################### ATTENTON!!! Files slap.tcl, ro.txt and en.txt must be in the scripts folder ########################
######## For raport buggs or suggestions, send mail to irc@solloman.ro or join to #EggHelp.Org channel (Undernet) ########
###################################################### Romana ############################################################
################## Acesta este un TCL pentru distractie. Comanda este (semn)slap sau (semn)slap all ######################
######################### Va da slap-uri la tot canalul (cu exeptia lui ChanServ si a eggdropului) #######################
################# ATENTIE!!! Fisierele slap.tcl, ro.txt si en.txt trebuiesc puse in folderul scripts #####################
###### Pentru sugestii si bugg-uri trimiteti mail la irc@solloman.ro sau intrati pe canalul #EggHelp.Org (Undernet) ######
##########################################################################################################################
### Settings / Setari ###
#########################
set sollo(chars) ". !" ; # Set public char/s ; Seteaza semnul/semnele de comanda publica
set sollo(chanserv) "X" ; # Chansetv NickName ; Nick-ul lui ChanServ
set sollo(bindflag) "m|o" ; # Who can use slap command ? ; Seteaza cine poate folosi comanda slap (global|canal)
set sollo(bindflagall) "m|m" ; # Who can use slap all command ? ; Seteaza cine poate folosi comanda slap all (global|canal)
set sollo(deflang) "ro" ; # Set default languege (en=engligh , ro=romanian) ; Seteaza liba default (ro=romana , en=engleza)
############################
### END / Sfarsit Setari ###
############################

foreach sollo(chanchar) $sollo(chars) {
bind pub $sollo(bindflag) [string trim $sollo(chanchar)]slap pub:slap
}
proc pub:slap {nick host hand chan arg} {
global botnick sollo
	set rnick [nick2hand $arg]
	set owner [nick2hand $nick]
	if {$sollo(deflang) == "ro"} {set txtfile "scripts/in.txt"}
	if {$sollo(deflang) == "en"} {set txtfile "scripts/en.txt"}
      set ranadil [open $txtfile r]
      set readvar [split [read $ranadil] \n]
	  set all [lindex $arg 0]
	  if {$all == ""} {putserv "NOTICE $nick :Use: [string trim $sollo(chanchar)]slap <nick> or [string trim $sollo(chanchar)]slap all" ; return 0}
	  if {($all != "") && ($all != "all")} {
		if {$all != "$sollo(chanserv)"} {
				if {$all != "$botnick"} {
				if {$sollo(deflang) == "ro"} {
				puthelp "PRIVMSG $chan :\001ACTION slaps $all [lindex $readvar [rand [llength $readvar]]]\001"
				return 0
    } else {
				puthelp "PRIVMSG $chan :\001ACTION ii da lui $all [lindex $readvar [rand [llength $readvar]]]\001"
				return 0
    }
   }
  }
 }
 	   if {([lindex $arg 0] == "all") && ([matchattr $hand "$sollo(bindflagall)" $chan])} {
		foreach all [chanlist $chan] {
		if {$all != "$sollo(chanserv)"} {
				if {$all != "$botnick"} {
				if {$sollo(deflang) == "ro"} {
				puthelp "PRIVMSG $chan :\001ACTION slaps $all [lindex $readvar [rand [llength $readvar]]]\001"
    } else {
		        puthelp "PRIVMSG $chan :\001ACTION ii da lui $all [lindex $readvar [rand [llength $readvar]]]\001"
     }
    }
   }
  }
 }
 close $ranadil
}

putlog "Slap TCL by solloman, successfully loaded"
