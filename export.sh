#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
	SED_PLACEHOLDER=".bak"
fi

curl -X GET -H "Referer: https://docs.qq.com/sheet/DT2Nta3ZCaW9xc2Rv?tab=BB08J2" -H "Authority: docs.qq.com" -H "Accept: */*" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"  "https://docs.qq.com/dop-api/opendoc?id=DT2Nta3ZCaW9xc2Rv&noEscape=1&normal=1&outformat=1&startrow=0&endrow=60&wb=1&tab=BB08J2&nowb=0&callback=clientVarsCallback&xsrf=&t=" > doc.txt

sed -i $SED_PLACEHOLDER 's/clientVarsCallback(//' doc.txt
sed -i $SED_PLACEHOLDER 's/)$//' doc.txt

mv doc.txt doc.json

MaxRow=`jq -r '.clientVars.collab_client_vars.maxRow' doc.json`
MaxCol=`jq -r '.clientVars.collab_client_vars.maxCol' doc.json`
GlobalPadId=`jq -r '.clientVars.collab_client_vars.globalPadId' doc.json`
Rev=`jq -r '.clientVars.collab_client_vars.rev' doc.json`

curl -X GET -H "Referer: https://docs.qq.com/sheet/DT2Nta3ZCaW9xc2Rv?tab=BB08J2" -H "Authority: docs.qq.com" -H "Accept: */*" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"  "https://docs.qq.com/dop-api/get/sheet?tab=BB08J2&padId=$GlobalPadId&subId=BB08J2&outformat=1&startrow=0&endrow=$MaxRow&normal=1&preview_token=&nowb=1&rev=$Rev" > full.json

jq '.data.initialAttributedText.text[0][3][0].c[1]' full.json > sheet.json

for i in `seq 1 $MaxRow`;
do
	a=$((i*27))
	b=$((i*27+2))
	jq -r "(.\"$a\".\"2\"[1] | tostring | gsub(\"[\\n\\t]\"; \"\")) + \",\" + (.\"$b\".\"2\"[1] | tostring | gsub(\"[\\n\\t]\"; \"\"))" sheet.json >> topology.csv
done

sed -i $SED_PLACEHOLDER '/null,null/d' topology.csv
sed -i $SED_PLACEHOLDER '/,null/d' topology.csv
sed -i $SED_PLACEHOLDER '/,$/d' topology.csv

echo -n | tee topology.dot << EOF

strict graph {

    label="刘群面基拓扑"
    labelloc="t"
    layout="circo"
    oneblock=true
    
`cat topology.csv | sort | uniq  | sed -r 's/,/ -- /g'`

}

EOF

dot -Tjpg topology.dot -o topology.jpg

echo -n | tee README.md << EOF
# A Dada Group Offline Topology

![Offline Topology](topology.jpg)

EOF

rm doc.json full.json sheet.json *.bak | true
