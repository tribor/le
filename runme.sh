# INIT
#dhparam="/opt/le/dhparams"
port=80
curdir=$(pwd)
le_runlog="$curdir/le-runlog.txt"
. $curdir/config.sh # WELLKNOWN kommt aus diesem inkludierten file
wwwdir=${WELLKNOWN/.well-known\/acme-challenge/}

# --- FUNCTIONS ---
error() {
        echo "Fehler: $1"
        exit 1
}

function clean_up {
  kill $(ps aux | grep SimpleHTTPServer | grep -o $(pgrep python) )
  rm -rf $wwwdir/.well-known
}


function fehler_bei_ausfuehrung {
  echo "============= ENDE LE-TOOL  ============="
  echo
  echo "Bei dem Versuch, das o.g. Zertifikat zu erstellen, ist ein Fehler aufgetreten"  
  exit 1
}

testchain() {
  test $(sh $curdir/listchain.sh  $i.pem  | grep CN | wc -l ) -eq 3 || error "Zertifikatskette besteht nicht aus Cert, Zwischenzertifikat, Root-CA bei '$i'"
  sh $curdir/listchain.sh  $i.pem  | grep -q "Let's Encrypt" || error "Kein Zwischenzertifikat mit CN='Let's Encrypt' gefunden bei '$i'"
  grep -q "PRIVATE KEY" $i.pem || error "Fehlender Private-Key bei '$i'"
  grep -q "DH PARAMETERS" $i.pem || error "Fehlender DH-Parameter bei '$i'"
}

pre_tests ()
{
  test -s domains.txt || error "keine domain.txt gefunden"
 # test -e $dhparam || error "keine dhparam gefunden"
  openssl version > /dev/null || error "openssl nicht gefunden"
  test -d $WELLKNOWN || mkdir -p $WELLKNOWN || error "kann Unterverzeichniss '$WELLKNOWN' nicht anlegen"
  touch $WELLKNOWN/test || error "kann in '$WELLKNOWN' nicht schreiben"
  touch $curdir/accounts/test || error "kann in 'accounts' nicht schreiben"
  touch $curdir/certs/letestwrite.txt && rm $curdir/certs/letestwrite.txt || error "kann in 'certs' nicht schreiben"

}

check_certs ()
{
  cd $curdir/certs
  echo; echo "Überprüfe Zertifikate"
  for i in $( find -path './*' -prune -type d) ; do  echo $i;test -e $i/fullchain.pem && cat $i/privkey.pem $i/fullchain.pem  > $i.pem; testchain; done
  chmod 600  $curdir/certs/*.pem
}


delete_oldstuff ()
{
  find $curdir/certs/ -mtime +90 -type f -delete
  find $curdir/certs/ -mtime +90 -type d | xargs  rm -rf
}

## BEGIN
echo Beginn LE-Wrapper
# TESTs
pre_tests
#Starte lokalen Webserver
cd $wwwdir
python -m SimpleHTTPServer $port  > /dev/null &
trap clean_up 0 1 2 3 15
cd $curdir
echo
echo "============= Ausgabe Domainliste ======="
cat domains.txt
echo "============= Ende Domainliste =========="
echo
echo "============= BEGIN LE-TOOL ============="
bash letsencrypt.sh -c -f config.sh 2>&1 | tee $le_runlog
grep -qi error $le_runlog  && fehler_bei_ausfuehrung || echo "Alle Zertifikate erstellt"
echo "============= ENDE LE-TOOL  ============="
echo
# certs/-ketten/dhparam überprüfen
check_certs
# lösche alte verzeichnisse + dateien 
delete_oldstuff
echo LE-Wrapper done
echo
