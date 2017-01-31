echo "Zertifikatkskette (key -> Zert -> Intermed -> Root -> dhparam)"
filename=`mktemp`
awk -v FN=$filename '/BEGIN CERTIFICATE/{++i;}{print > (FN i)} ' $1
for i in $filename*; do  openssl x509 -noout -subject -issuer -in $i ; done  2>&1 | egrep -o "CN=.*" | uniq
rm $filename*
