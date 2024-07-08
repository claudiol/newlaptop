echo "Generating naked tests in [`pwd`]"
for i in $(find . -type f -iname 'Chart.yaml' -not -path "./common/*" -exec dirname "{}"  \; | \
sed -e 's/.\///'); do s=$(echo $i | sed -e s@/@-@g -e s@charts-@@); echo $s; \
helm template $i -f values-global.yaml --name-template $s > tests/$s-naked.expected.yaml; done

if [ $? == 0 ]; then 
  echo "Success"
else
  echo "Failed"
  exit
fi

echo "Generating normal tests in [`pwd`]"
for i in $(find . -type f -iname 'Chart.yaml' -not -path "./common/*" -exec dirname "{}"  \; | sed -e 's/.\///'); do \
s=$(echo $i | sed -e s@/@-@g -e s@charts-@@); echo $s; helm template $i --name-template $s \
-f common/examples/values-secret.yaml -f values-global.yaml --set global.repoURL=https://github.com/pattern-clone/mypattern \
--set main.git.repoURL=https://github.com/pattern-clone/mypattern --set main.git.revision=main --set main.options.bootstrap=1 \
--set global.valuesDirectoryURL=https://github.com/pattern-clone/mypattern/raw/main --set global.pattern=mypattern \
--set global.namespace=pattern-namespace --set global.hubClusterDomain=hub.example.com --set global.localClusterDomain=region.example.com \
-f values-datacenter.yaml -f values-global.yaml  > tests/$s-normal.expected.yaml; done

if [ $? == 0 ]; then 
  echo "Success"
else
  echo "Failed"
  exit
fi
