#!/usr/local/bin/bash

#
#  A-Team Systems CouchDB Compaction Script
#  http://www.ateamsystems.com/
#  
#  Copyright (c) 2008-2011, All Rights Reserved
#

#
# Example usage:
# ---------------------- -
#
# Reports only errors when passed no params:
# ./scriptfile 
#
# Verbosely shows what it is doing when passed 'int'
# ./scriptfile int
#



#
# Configuration
# ---------------------- -

# Change to the URL of your CouchDB
BASEURL="http://USERNAME:PASSOWRD@HOSTNAME:5984";

# Make sure sed, curl and awk are in the path
PATH="${PATH}:/usr/local/bin";

# ---------------------- -
# End Configuration
#



#
# ---- Functions
#

#
# Passes parms to echo if debugging is on, otherwise nothing
#
function DEcho
   {
   if [ "${TKDEBUGON}"x == "Yes"x ]
      then
      echo "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9";
   fi
   }

#
# Makes a CouchDB request via curl
#
function CouchReq( )
   {
   MODE="$1";
   URL="$2";

   if [ ${MODE}x == "GET"x ]
      then
      curl -s ${BASEURL}${URL};
   else
      curl -s -H "Content-Type: application/json" -X POST ${BASEURL}${URL};
   fi
   }

#
# ---- Command line params
#
if [ "${1}"x == "int"x ]
   then
   echo "--- Starting in interactive mode";
   INTERACTIVE="Yes";
   TKDEBUGON="Yes";
else
   INTERACTIVE="No";
fi


#
# ---- Main Run-time
#

# -- Get the list of DBs
DBLIST=`CouchReq "GET" "/_all_dbs" | sed -e s:"\["::g | sed -e s:"\]"::g | sed -e s:\"::g | sed -e s:,:" ":g`;

# -- Loop through 'em
for DB in ${DBLIST}
do
   if [ ${DB:0:1} != "_" ]
      then
      DEcho "${DB} - Triggering DB compaction ...";
      RESP=`CouchReq "POST" "/${DB}/_compact"`;
      if [ "${RESP}"x != '{"ok":true}'x ]
         then
         echo "${DB} - ERROR triggering compaction, CouchDB response : ${RESP}";
      else
         DEcho "${DB} - Compaction triggered.";
      fi

      DEcho "${DB} - Triggering outdated view clean up ...";
      RESP=`CouchReq "POST" "/${DB}/_view_cleanup"`;
      if [ "${RESP}"x != '{"ok":true}'x ]
         then
         echo "${DB} - ERROR triggering view clean up, CouchDB response : ${RESP}";
      else
         DEcho "${DB} - Clean up triggered.";
      fi
      
      DEcho "${DB} - Getting view list ...";
      DESIGNLIST=`CouchReq "GET" "/${DB}/_all_docs?startkey=\"_design/\"&amp;endkey=\"_design0\"&amp;include_docs=true" | awk -F ":" '{print $3}' | awk -F \" '{print $2}' | grep "^_design/" | sed -e s:"_design/"::g`;
      #echo "   views: ${DESIGNLIST}";

      for DESIGN in ${DESIGNLIST}
      do
         DEcho "   Compacting views in '${DESIGN}' ...";
         RESP=`CouchReq "POST" "/${DB}/_compact/${DESIGN}"`;
         if [ "${RESP}"x != '{"ok":true}'x ]
            then
            echo "      ${DESIGN} - ERROR triggering compaction, CouchDB response : ${RESP}";
         else
            DEcho "     - View compaction triggered."
         fi
      done
   fi
done
